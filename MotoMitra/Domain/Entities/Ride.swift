import Foundation
import CoreLocation

/// Core ride entity
struct Ride: Identifiable, Codable, Equatable {
    let id: String
    let vehicleId: String
    let userId: String
    
    // Timing
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    // Odometer readings
    let startOdometer: Double // in km
    var endOdometer: Double? // in km
    var odometerDistance: Double? {
        guard let end = endOdometer else { return nil }
        return end - startOdometer
    }
    
    // GPS tracking
    var gpsDistance: Double = 0 // in km
    var maxSpeed: Double = 0 // in km/h
    var averageSpeed: Double = 0 // in km/h
    var movingTime: TimeInterval = 0
    var stoppedTime: TimeInterval = 0
    
    // Route
    var routePoints: [RidePoint] = []
    var startLocation: Location?
    var endLocation: Location?
    var waypoints: [Waypoint] = []
    
    // Metadata
    var title: String?
    var notes: String?
    var tags: [String] = []
    var weather: Weather?
    var fuelLevel: FuelLevel?
    var tyrePressure: TyrePressure?
    
    // Recording info
    let recordingMode: RecordingMode
    var recordingState: RecordingState = .notStarted
    var auditLog: [AuditEntry] = []
    
    // Expenses
    var expenseIds: [String] = []
    var totalExpense: Double = 0
    
    // Room association
    var roomId: String?
    
    // Sync
    var isSynced: Bool = false
    var lastModified: Date = Date()
    
    init(id: String = UUID().uuidString,
         vehicleId: String,
         userId: String,
         startTime: Date = Date(),
         startOdometer: Double,
         recordingMode: RecordingMode) {
        self.id = id
        self.vehicleId = vehicleId
        self.userId = userId
        self.startTime = startTime
        self.startOdometer = startOdometer
        self.recordingMode = recordingMode
    }
}

/// Recording mode for rides
enum RecordingMode: String, Codable, CaseIterable {
    case auto = "auto"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .manual: return "Manual"
        }
    }
    
    var description: String {
        switch self {
        case .auto: return "Automatically detect and record rides"
        case .manual: return "Manually start and stop recording"
        }
    }
}

/// Recording state
enum RecordingState: String, Codable {
    case notStarted = "not_started"
    case recording = "recording"
    case paused = "paused"
    case ended = "ended"
}

/// Ride point for GPS tracking
struct RidePoint: Codable, Equatable {
    let timestamp: Date
    let coordinate: Coordinate
    let altitude: Double? // meters
    let speed: Double? // m/s
    let course: Double? // degrees
    let horizontalAccuracy: Double // meters
    let verticalAccuracy: Double? // meters
    
    var speedKmh: Double? {
        guard let speed = speed else { return nil }
        return speed * 3.6 // Convert m/s to km/h
    }
    
    init(from location: CLLocation) {
        self.timestamp = location.timestamp
        self.coordinate = Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        self.altitude = location.altitude
        self.speed = location.speed >= 0 ? location.speed : nil
        self.course = location.course >= 0 ? location.course : nil
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
    }
}

/// Coordinate wrapper for Codable
struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    
    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Location details
struct Location: Codable, Equatable {
    let coordinate: Coordinate
    let address: String?
    let placeName: String?
    let placeId: String? // Google Places ID
    let locality: String?
    let administrativeArea: String?
    let country: String?
}

/// Waypoint during ride
struct Waypoint: Codable, Equatable, Identifiable {
    let id: String
    let timestamp: Date
    let coordinate: Coordinate
    let type: WaypointType
    let title: String?
    let notes: String?
    let photoUrl: String?
    
    enum WaypointType: String, Codable {
        case stop = "stop"
        case photo = "photo"
        case note = "note"
        case poi = "poi"
        case expense = "expense"
    }
}

/// Fuel level
enum FuelLevel: String, Codable, CaseIterable {
    case empty = "empty"
    case low = "low"
    case quarter = "quarter"
    case half = "half"
    case threeQuarter = "three_quarter"
    case full = "full"
    
    var percentage: Int {
        switch self {
        case .empty: return 0
        case .low: return 10
        case .quarter: return 25
        case .half: return 50
        case .threeQuarter: return 75
        case .full: return 100
        }
    }
    
    var displayName: String {
        switch self {
        case .empty: return "Empty"
        case .low: return "Low"
        case .quarter: return "1/4"
        case .half: return "1/2"
        case .threeQuarter: return "3/4"
        case .full: return "Full"
        }
    }
}

/// Tyre pressure
struct TyrePressure: Codable, Equatable {
    let front: Double? // PSI
    let rear: Double? // PSI
    let checkedAt: Date
}

/// Weather conditions
struct Weather: Codable, Equatable {
    let condition: Condition
    let temperature: Double? // Celsius
    let humidity: Double? // Percentage
    
    enum Condition: String, Codable, CaseIterable {
        case clear = "clear"
        case cloudy = "cloudy"
        case lightRain = "light_rain"
        case heavyRain = "heavy_rain"
        case fog = "fog"
        case snow = "snow"
        
        var displayName: String {
            switch self {
            case .clear: return "Clear"
            case .cloudy: return "Cloudy"
            case .lightRain: return "Light Rain"
            case .heavyRain: return "Heavy Rain"
            case .fog: return "Foggy"
            case .snow: return "Snow"
            }
        }
        
        var icon: String {
            switch self {
            case .clear: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .lightRain: return "cloud.drizzle.fill"
            case .heavyRain: return "cloud.rain.fill"
            case .fog: return "cloud.fog.fill"
            case .snow: return "cloud.snow.fill"
            }
        }
    }
}

/// Audit log entry
struct AuditEntry: Codable, Equatable {
    let timestamp: Date
    let action: String
    let reason: String?
    let automatic: Bool
    
    enum Action {
        static let autoStartDetected = "auto_start_detected"
        static let manualStart = "manual_start"
        static let autoPaused = "auto_paused"
        static let manualPaused = "manual_paused"
        static let autoResumed = "auto_resumed"
        static let manualResumed = "manual_resumed"
        static let autoEndDetected = "auto_end_detected"
        static let manualEnd = "manual_end"
        static let odometerOverride = "odometer_override"
        static let reconciliation = "reconciliation"
    }
}