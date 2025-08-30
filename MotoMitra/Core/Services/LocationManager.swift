import Foundation
import CoreLocation
import Combine

/// Location manager for ride tracking with battery optimization
class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdatingLocation = false
    @Published var locationError: Error?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    private var significantChangeHandler: ((CLLocation) -> Void)?
    private var lastValidLocation: CLLocation?
    private var isInBackground = false
    private var deferredUpdatesEnabled = false
    
    // MARK: - Configuration
    private var currentAccuracy: CLLocationAccuracy = Constants.Recording.desiredAccuracy
    private var currentDistanceFilter: CLLocationDistance = Constants.Recording.distanceFilter
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        
        // Request authorization
        requestAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // Request when in use first, then always
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Upgrade to always authorization for background tracking
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            // Already have the permission we need
            break
        case .denied, .restricted:
            // Handle denied case
            locationError = LocationError.authorizationDenied
        @unknown default:
            break
        }
    }
    
    // MARK: - Location Updates Control
    
    /// Start high-accuracy updates for active recording
    func startHighAccuracyUpdates() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            locationError = LocationError.authorizationDenied
            return
        }
        
        isUpdatingLocation = true
        currentAccuracy = Constants.Recording.desiredAccuracy
        currentDistanceFilter = Constants.Recording.distanceFilter
        
        locationManager.desiredAccuracy = currentAccuracy
        locationManager.distanceFilter = currentDistanceFilter
        locationManager.startUpdatingLocation()
        
        // Enable deferred updates for battery optimization
        if !isInBackground {
            enableDeferredUpdates()
        }
        
        print("📍 Started high-accuracy location updates")
    }
    
    /// Switch to reduced accuracy mode (for paused state)
    func reducedAccuracyMode() {
        currentAccuracy = kCLLocationAccuracyHundredMeters
        currentDistanceFilter = Constants.Recording.pausedDistanceFilter
        
        locationManager.desiredAccuracy = currentAccuracy
        locationManager.distanceFilter = currentDistanceFilter
        
        disableDeferredUpdates()
        
        print("📍 Switched to reduced accuracy mode")
    }
    
    /// Start monitoring significant location changes (for auto-detection)
    func startMonitoringSignificantChanges() {
        guard authorizationStatus == .authorizedAlways else {
            locationError = LocationError.backgroundAuthorizationRequired
            return
        }
        
        locationManager.startMonitoringSignificantLocationChanges()
        print("📍 Started monitoring significant location changes")
    }
    
    /// Stop all location updates
    func stopUpdates() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        disableDeferredUpdates()
        print("📍 Stopped all location updates")
    }
    
    // MARK: - Background Mode
    
    func enterBackgroundMode() {
        isInBackground = true
        
        if isUpdatingLocation {
            // Switch to deferred updates for battery saving
            enableDeferredUpdates()
            
            // Reduce accuracy slightly
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
    }
    
    func enterForegroundMode() {
        isInBackground = false
        
        if isUpdatingLocation {
            // Resume high accuracy
            locationManager.desiredAccuracy = Constants.Recording.desiredAccuracy
            disableDeferredUpdates()
        }
    }
    
    // MARK: - Deferred Updates
    
    private func enableDeferredUpdates() {
        guard !deferredUpdatesEnabled,
              CLLocationManager.deferredLocationUpdatesAvailable() else { return }
        
        locationManager.allowDeferredLocationUpdates(
            untilTraveled: Constants.Recording.deferredUpdateDistance,
            timeout: Constants.Recording.deferredUpdateTimeout
        )
        deferredUpdatesEnabled = true
        print("📍 Enabled deferred location updates")
    }
    
    private func disableDeferredUpdates() {
        guard deferredUpdatesEnabled else { return }
        
        locationManager.disallowDeferredLocationUpdates()
        deferredUpdatesEnabled = false
        print("📍 Disabled deferred location updates")
    }
    
    // MARK: - Location Filtering
    
    private func isValidLocation(_ location: CLLocation) -> Bool {
        // Check accuracy
        guard location.horizontalAccuracy > 0,
              location.horizontalAccuracy <= Constants.Recording.maxAcceptableAccuracy else {
            return false
        }
        
        // Check timestamp (not older than 5 seconds)
        guard abs(location.timestamp.timeIntervalSinceNow) < 5 else {
            return false
        }
        
        // Check for duplicate location
        if let lastLocation = lastValidLocation {
            let distance = location.distance(from: lastLocation)
            let timeDiff = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            
            // Reject if no movement in last update
            if distance < 1 && timeDiff < 1 {
                return false
            }
            
            // Check for unrealistic speed (> 200 km/h for motorcycles)
            if timeDiff > 0 {
                let speed = (distance / timeDiff) * 3.6 // Convert to km/h
                if speed > 200 {
                    return false
                }
            }
        }
        
        return true
    }
    
    // MARK: - Helpers
    
    func requestSingleLocation(completion: @escaping (CLLocation?) -> Void) {
        locationManager.requestLocation()
        locationUpdateHandler = { location in
            completion(location)
            self.locationUpdateHandler = nil
        }
    }
    
    func distanceBetween(_ location1: CLLocation, _ location2: CLLocation) -> CLLocationDistance {
        return location1.distance(from: location2)
    }
    
    func calculateSpeed(from locations: [CLLocation]) -> Double {
        guard locations.count >= 2 else { return 0 }
        
        var totalSpeed: Double = 0
        var validSpeeds = 0
        
        for i in 1..<locations.count {
            let location = locations[i]
            if location.speed >= 0 {
                totalSpeed += location.speed
                validSpeeds += 1
            } else {
                // Calculate speed from distance and time
                let previousLocation = locations[i-1]
                let distance = location.distance(from: previousLocation)
                let timeDiff = location.timestamp.timeIntervalSince(previousLocation.timestamp)
                
                if timeDiff > 0 {
                    let speed = distance / timeDiff
                    totalSpeed += speed
                    validSpeeds += 1
                }
            }
        }
        
        return validSpeeds > 0 ? (totalSpeed / Double(validSpeeds)) * 3.6 : 0 // Convert to km/h
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            // Can start updates
            print("📍 Location authorization granted: \(authorizationStatus.rawValue)")
        case .denied, .restricted:
            locationError = LocationError.authorizationDenied
            print("📍 Location authorization denied")
        case .notDetermined:
            print("📍 Location authorization not determined")
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter invalid locations
        guard isValidLocation(location) else {
            print("📍 Filtered out invalid location: accuracy=\(location.horizontalAccuracy)m")
            return
        }
        
        // Update current location
        currentLocation = location
        lastValidLocation = location
        
        // Call handler if set
        locationUpdateHandler?(location)
        
        // Log for debugging
        #if DEBUG
        print("📍 Location update: \(location.coordinate.latitude), \(location.coordinate.longitude) " +
              "accuracy: \(location.horizontalAccuracy)m, speed: \(location.speed * 3.6)km/h")
        #endif
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        print("📍 Location error: \(error.localizedDescription)")
        
        // Handle specific errors
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                stopUpdates()
            case .locationUnknown:
                // Temporary error, keep trying
                break
            default:
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        deferredUpdatesEnabled = false
        
        if let error = error {
            print("📍 Deferred updates error: \(error.localizedDescription)")
        }
        
        // Re-enable if still needed
        if isInBackground && isUpdatingLocation {
            enableDeferredUpdates()
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("📍 Location updates paused by system")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("📍 Location updates resumed by system")
    }
}

// MARK: - Location Errors

enum LocationError: LocalizedError {
    case authorizationDenied
    case backgroundAuthorizationRequired
    case locationServicesDisabled
    case invalidLocation
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Location access denied. Please enable in Settings."
        case .backgroundAuthorizationRequired:
            return "Background location access required for auto-detection. Please enable 'Always Allow' in Settings."
        case .locationServicesDisabled:
            return "Location services are disabled. Please enable in Settings."
        case .invalidLocation:
            return "Unable to determine accurate location."
        }
    }
}