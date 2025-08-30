import SwiftUI
import Combine
import CoreLocation
import CoreMotion

/// View model for ride recording
@MainActor
class RecordViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var recordingState: RecordingState = .notStarted
    @Published var currentRide: Ride?
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentSpeed: Double = 0 // km/h
    @Published var distance: Double = 0 // km
    @Published var averageSpeed: Double = 0 // km/h
    @Published var maxSpeed: Double = 0 // km/h
    @Published var currentLocation: CLLocation?
    @Published var routePolyline: [CLLocationCoordinate2D] = []
    @Published var isAutoDetecting = false
    @Published var autoDetectionCountdown: Int = 0
    @Published var showPreRideSheet = false
    @Published var showPostRideSheet = false
    @Published var showOdometerReconciliation = false
    
    // MARK: - Dependencies
    private let startRideUseCase: StartRideUseCase
    private let locationManager: LocationManager
    private let motionManager: MotionActivityManager
    @AppStorage("recordingMode") private var recordingMode: RecordingMode = .auto
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var autoDetectionTimer: Timer?
    private var pauseDetectionTimer: Timer?
    private var endDetectionTimer: Timer?
    private var lastMovementTime = Date()
    private var speedBuffer: [Double] = []
    private let speedBufferSize = 5
    
    // MARK: - Initialization
    init(startRideUseCase: StartRideUseCase,
         locationManager: LocationManager,
         motionManager: MotionActivityManager) {
        self.startRideUseCase = startRideUseCase
        self.locationManager = locationManager
        self.motionManager = motionManager
        
        setupBindings()
        
        if recordingMode == .auto {
            startAutoDetection()
        }
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Location updates
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
        
        // Motion activity updates
        motionManager.$currentActivity
            .sink { [weak self] activity in
                self?.handleMotionUpdate(activity)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Auto Detection
    func startAutoDetection() {
        guard recordingMode == .auto else { return }
        
        isAutoDetecting = true
        motionManager.startActivityUpdates()
        locationManager.startMonitoringSignificantChanges()
    }
    
    private func handleMotionUpdate(_ activity: CMMotionActivity?) {
        guard let activity = activity,
              recordingMode == .auto,
              recordingState == .notStarted else { return }
        
        // Check if automotive motion detected
        if activity.automotive && activity.confidence == .high {
            checkAutoStartConditions()
        }
    }
    
    private func checkAutoStartConditions() {
        guard let location = locationManager.currentLocation,
              location.speed >= 0 else { return }
        
        let speedKmh = location.speed * 3.6
        
        if speedKmh >= Constants.Recording.autoStartSpeedThreshold * 3.6 {
            if autoDetectionTimer == nil {
                // Start countdown
                autoDetectionCountdown = Int(Constants.Recording.autoStartDuration)
                autoDetectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.updateAutoDetectionCountdown()
                }
            }
        } else {
            // Cancel auto-start if speed drops
            cancelAutoDetection()
        }
    }
    
    private func updateAutoDetectionCountdown() {
        autoDetectionCountdown -= 1
        
        if autoDetectionCountdown <= 0 {
            // Show pre-ride sheet
            autoDetectionTimer?.invalidate()
            autoDetectionTimer = nil
            showPreRideSheet = true
        }
    }
    
    private func cancelAutoDetection() {
        autoDetectionTimer?.invalidate()
        autoDetectionTimer = nil
        autoDetectionCountdown = 0
    }
    
    // MARK: - Recording Control
    func startRecording(vehicle: Vehicle, startOdometer: Double, fuelLevel: FuelLevel?, tyrePressure: TyrePressure?) {
        guard recordingState == .notStarted else { return }
        
        // Create new ride
        var ride = Ride(
            vehicleId: vehicle.id,
            userId: getCurrentUserId(),
            startOdometer: startOdometer,
            recordingMode: recordingMode
        )
        
        ride.fuelLevel = fuelLevel
        ride.tyrePressure = tyrePressure
        ride.recordingState = .recording
        ride.startLocation = locationToLocation(currentLocation)
        
        // Add audit entry
        ride.auditLog.append(AuditEntry(
            timestamp: Date(),
            action: recordingMode == .auto ? AuditEntry.Action.autoStartDetected : AuditEntry.Action.manualStart,
            reason: nil,
            automatic: recordingMode == .auto
        ))
        
        currentRide = ride
        recordingState = .recording
        
        // Start high-accuracy location updates
        locationManager.startHighAccuracyUpdates()
        
        // Start timer
        startTimer()
        
        // Start pause detection if auto mode
        if recordingMode == .auto {
            startPauseDetection()
        }
        
        // Save to repository
        Task {
            await startRideUseCase.execute(ride: ride)
        }
    }
    
    func pauseRecording() {
        guard recordingState == .recording else { return }
        
        recordingState = .paused
        currentRide?.recordingState = .paused
        
        // Add audit entry
        currentRide?.auditLog.append(AuditEntry(
            timestamp: Date(),
            action: AuditEntry.Action.manualPaused,
            reason: nil,
            automatic: false
        ))
        
        // Reduce location accuracy to save battery
        locationManager.reducedAccuracyMode()
        
        // Stop pause detection, start resume detection
        stopPauseDetection()
        if recordingMode == .auto {
            startResumeDetection()
        }
    }
    
    func resumeRecording() {
        guard recordingState == .paused else { return }
        
        recordingState = .recording
        currentRide?.recordingState = .recording
        
        // Add audit entry
        currentRide?.auditLog.append(AuditEntry(
            timestamp: Date(),
            action: AuditEntry.Action.manualResumed,
            reason: nil,
            automatic: false
        ))
        
        // Resume high-accuracy updates
        locationManager.startHighAccuracyUpdates()
        
        // Resume pause detection
        if recordingMode == .auto {
            startPauseDetection()
            stopResumeDetection()
        }
    }
    
    func stopRecording() {
        guard recordingState == .recording || recordingState == .paused else { return }
        
        recordingState = .ended
        currentRide?.recordingState = .ended
        currentRide?.endTime = Date()
        currentRide?.endLocation = locationToLocation(currentLocation)
        
        // Add audit entry
        currentRide?.auditLog.append(AuditEntry(
            timestamp: Date(),
            action: recordingMode == .auto ? AuditEntry.Action.autoEndDetected : AuditEntry.Action.manualEnd,
            reason: nil,
            automatic: recordingMode == .auto
        ))
        
        // Stop updates
        locationManager.stopUpdates()
        stopTimer()
        stopAllDetection()
        
        // Show post-ride sheet
        showPostRideSheet = true
    }
    
    // MARK: - Location Handling
    private func handleLocationUpdate(_ location: CLLocation) {
        guard recordingState == .recording else { return }
        
        // Update current speed
        if location.speed >= 0 {
            let speedKmh = location.speed * 3.6
            currentSpeed = speedKmh
            
            // Update speed buffer for averaging
            speedBuffer.append(speedKmh)
            if speedBuffer.count > speedBufferSize {
                speedBuffer.removeFirst()
            }
            averageSpeed = speedBuffer.reduce(0, +) / Double(speedBuffer.count)
            
            // Update max speed
            if speedKmh > maxSpeed {
                maxSpeed = speedKmh
                currentRide?.maxSpeed = speedKmh
            }
        }
        
        // Add route point if accuracy is acceptable
        if location.horizontalAccuracy <= Constants.Recording.maxAcceptableAccuracy {
            let point = RidePoint(from: location)
            currentRide?.routePoints.append(point)
            routePolyline.append(location.coordinate)
            
            // Calculate distance
            if let lastPoint = currentRide?.routePoints.dropLast().last {
                let lastLocation = CLLocation(
                    latitude: lastPoint.coordinate.latitude,
                    longitude: lastPoint.coordinate.longitude
                )
                let distanceMeters = location.distance(from: lastLocation)
                distance += distanceMeters / 1000 // Convert to km
                currentRide?.gpsDistance = distance
            }
        }
        
        currentLocation = location
        
        // Check for auto-pause/end conditions
        if recordingMode == .auto {
            checkAutoPauseConditions(speedKmh: location.speed * 3.6)
        }
    }
    
    // MARK: - Auto Pause/Resume/End Detection
    private func startPauseDetection() {
        // Implemented in handleLocationUpdate
    }
    
    private func stopPauseDetection() {
        pauseDetectionTimer?.invalidate()
        pauseDetectionTimer = nil
    }
    
    private func checkAutoPauseConditions(speedKmh: Double) {
        if speedKmh < Constants.Recording.autoPauseSpeedThreshold * 3.6 {
            if pauseDetectionTimer == nil {
                pauseDetectionTimer = Timer.scheduledTimer(
                    withTimeInterval: Constants.Recording.autoPauseDuration,
                    repeats: false
                ) { [weak self] _ in
                    self?.autoPause()
                }
            }
        } else {
            stopPauseDetection()
            lastMovementTime = Date()
        }
    }
    
    private func autoPause() {
        recordingState = .paused
        currentRide?.recordingState = .paused
        currentRide?.auditLog.append(AuditEntry(
            timestamp: Date(),
            action: AuditEntry.Action.autoPaused,
            reason: "Speed below threshold for \(Int(Constants.Recording.autoPauseDuration))s",
            automatic: true
        ))
        
        locationManager.reducedAccuracyMode()
        startEndDetection()
    }
    
    private func startResumeDetection() {
        // Monitor for movement to auto-resume
    }
    
    private func stopResumeDetection() {
        // Stop monitoring
    }
    
    private func startEndDetection() {
        endDetectionTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.Recording.autoEndDuration,
            repeats: false
        ) { [weak self] _ in
            self?.autoEnd()
        }
    }
    
    private func autoEnd() {
        stopRecording()
    }
    
    private func stopAllDetection() {
        stopPauseDetection()
        stopResumeDetection()
        endDetectionTimer?.invalidate()
        endDetectionTimer = nil
    }
    
    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.recordingState == .recording else { return }
            self.elapsedTime += 1
            self.currentRide?.movingTime = self.elapsedTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Post-Ride
    func saveRide(endOdometer: Double, tags: [String], notes: String?) {
        currentRide?.endOdometer = endOdometer
        currentRide?.tags = tags
        currentRide?.notes = notes
        currentRide?.averageSpeed = averageSpeed
        
        // Check for odometer discrepancy
        if let ride = currentRide,
           let odometerDistance = ride.odometerDistance {
            let discrepancy = abs(odometerDistance - ride.gpsDistance) / odometerDistance
            if discrepancy > Constants.Odometer.maxDiscrepancyPercent {
                showOdometerReconciliation = true
                return
            }
        }
        
        // Save ride
        Task {
            if let ride = currentRide {
                await saveRideToRepository(ride)
            }
        }
    }
    
    func reconcileOdometer(finalDistance: Double, reason: String) {
        currentRide?.auditLog.append(AuditEntry(
            timestamp: Date(),
            action: AuditEntry.Action.reconciliation,
            reason: reason,
            automatic: false
        ))
        
        // Adjust end odometer based on reconciled distance
        if let startOdometer = currentRide?.startOdometer {
            currentRide?.endOdometer = startOdometer + finalDistance
        }
        
        Task {
            if let ride = currentRide {
                await saveRideToRepository(ride)
            }
        }
    }
    
    // MARK: - Helpers
    private func getCurrentUserId() -> String {
        // TODO: Get from auth service
        return "current_user_id"
    }
    
    private func locationToLocation(_ clLocation: CLLocation?) -> Location? {
        guard let clLocation = clLocation else { return nil }
        
        return Location(
            coordinate: Coordinate(
                latitude: clLocation.coordinate.latitude,
                longitude: clLocation.coordinate.longitude
            ),
            address: nil,
            placeName: nil,
            placeId: nil,
            locality: nil,
            administrativeArea: nil,
            country: nil
        )
    }
    
    private func saveRideToRepository(_ ride: Ride) async {
        // TODO: Implement repository save
    }
}