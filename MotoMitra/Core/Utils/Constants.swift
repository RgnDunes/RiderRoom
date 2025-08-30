import Foundation
import CoreLocation

/// App-wide constants
enum Constants {
    
    // MARK: - App Info
    enum App {
        static let name = "MotoMitra"
        static let bundleId = "com.motomitra.app"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Recording Parameters
    enum Recording {
        // Auto mode thresholds
        static let autoStartSpeedThreshold: CLLocationSpeed = 8.0 / 3.6 // 8 km/h in m/s
        static let autoStartDuration: TimeInterval = 20.0 // seconds
        static let autoPauseSpeedThreshold: CLLocationSpeed = 2.0 / 3.6 // 2 km/h in m/s
        static let autoPauseDuration: TimeInterval = 60.0 // seconds
        static let autoEndDuration: TimeInterval = 480.0 // 8 minutes
        
        // Location accuracy
        static let desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBestForNavigation
        static let distanceFilter: CLLocationDistance = 5.0 // meters
        static let pausedDistanceFilter: CLLocationDistance = 50.0 // meters when paused
        static let maxAcceptableAccuracy: CLLocationAccuracy = 20.0 // meters
        
        // Battery optimization
        static let deferredUpdateDistance: CLLocationDistance = 100.0 // meters
        static let deferredUpdateTimeout: TimeInterval = 60.0 // seconds
    }
    
    // MARK: - Odometer
    enum Odometer {
        static let maxDiscrepancyPercent = 0.1 // 10% difference threshold
        static let minValidOdometer: Double = 0
        static let maxValidOdometer: Double = 999999
    }
    
    // MARK: - Fuel & Economy
    enum Fuel {
        static let defaultTankCapacity: Double = 15.0 // liters
        static let minKmpl: Double = 10.0
        static let maxKmpl: Double = 100.0
        static let defaultKmpl: Double = 40.0
        
        enum Type: String, CaseIterable {
            case petrol = "Petrol"
            case diesel = "Diesel"
            case electric = "Electric"
            
            var icon: String {
                switch self {
                case .petrol: return "fuelpump.fill"
                case .diesel: return "fuelpump.circle.fill"
                case .electric: return "bolt.fill"
                }
            }
        }
    }
    
    // MARK: - Expense Categories
    enum ExpenseCategory: String, CaseIterable {
        case fuel = "Fuel"
        case food = "Food"
        case hotel = "Hotel"
        case toll = "Toll"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .fuel: return DesignSystem.Icons.fuel
            case .food: return DesignSystem.Icons.food
            case .hotel: return DesignSystem.Icons.hotel
            case .toll: return DesignSystem.Icons.toll
            case .other: return DesignSystem.Icons.other
            }
        }
        
        var color: Color {
            switch self {
            case .fuel: return DesignSystem.Colors.fuel
            case .food: return DesignSystem.Colors.food
            case .hotel: return DesignSystem.Colors.hotel
            case .toll: return DesignSystem.Colors.toll
            case .other: return DesignSystem.Colors.other
            }
        }
    }
    
    // MARK: - Service Intervals
    enum ServiceInterval {
        static let engineOilKm = 5000
        static let engineOilMonths = 6
        static let airFilterKm = 10000
        static let airFilterMonths = 12
        static let chainCleanKm = 1000
        static let chainCleanDays = 30
        static let tyreCheckKm = 5000
        static let tyreCheckMonths = 3
        
        // Reminder thresholds
        static let kmWarning1 = 200
        static let kmWarning2 = 50
        static let daysWarning1 = 7
        static let daysWarning2 = 3
        static let daysWarning3 = 1
    }
    
    // MARK: - POI Search
    enum POI {
        static let minSearchRadius: Double = 5000 // 5 km in meters
        static let maxSearchRadius: Double = 20000 // 20 km in meters
        static let defaultSearchRadius: Double = 10000 // 10 km in meters
        
        enum PlaceType: String, CaseIterable {
            case gasStation = "gas_station"
            case cafe = "cafe"
            case restaurant = "restaurant"
            case lodging = "lodging"
            case mechanic = "car_repair"
            case hospital = "hospital"
            
            var displayName: String {
                switch self {
                case .gasStation: return "Fuel Station"
                case .cafe: return "Cafe"
                case .restaurant: return "Restaurant"
                case .lodging: return "Hotel/Lodge"
                case .mechanic: return "Mechanic"
                case .hospital: return "Hospital"
                }
            }
            
            var icon: String {
                switch self {
                case .gasStation: return "fuelpump.fill"
                case .cafe: return "cup.and.saucer.fill"
                case .restaurant: return "fork.knife"
                case .lodging: return "bed.double.fill"
                case .mechanic: return "wrench.fill"
                case .hospital: return "cross.fill"
                }
            }
        }
        
        // Indian fuel brands
        static let fuelBrands = [
            "IOCL", "Indian Oil",
            "HPCL", "Hindustan Petroleum",
            "BPCL", "Bharat Petroleum",
            "Shell",
            "Reliance",
            "Essar",
            "Nayara"
        ]
    }
    
    // MARK: - Formatting
    enum Format {
        static let currencyCode = "INR"
        static let currencySymbol = "₹"
        static let dateFormat = "dd-MM-yyyy"
        static let timeFormat = "HH:mm"
        static let dateTimeFormat = "dd-MM-yyyy HH:mm"
        static let distanceUnit = "km"
        static let speedUnit = "km/h"
        static let volumeUnit = "L"
        static let economyUnit = "km/L"
    }
    
    // MARK: - Notifications
    enum Notification {
        static let rideStarted = "ride.started"
        static let rideEnded = "ride.ended"
        static let serviceReminder = "service.reminder"
        static let documentExpiry = "document.expiry"
        static let roomInvite = "room.invite"
        static let expenseAdded = "expense.added"
    }
    
    // MARK: - Background Tasks
    enum BackgroundTask {
        static let refreshIdentifier = "com.motomitra.refresh"
        static let processingIdentifier = "com.motomitra.processing"
        static let refreshInterval: TimeInterval = 3600 // 1 hour
    }
    
    // MARK: - Firebase Collections
    enum FirebaseCollection {
        static let users = "users"
        static let rides = "rides"
        static let expenses = "expenses"
        static let rooms = "rooms"
        static let roomMembers = "room_members"
        static let settlements = "settlements"
        static let pois = "pois"
    }
    
    // MARK: - Keychain Keys
    enum KeychainKey {
        static let authToken = "com.motomitra.authToken"
        static let refreshToken = "com.motomitra.refreshToken"
        static let userCredentials = "com.motomitra.userCredentials"
    }
    
    // MARK: - UserDefaults Keys
    enum UserDefaultsKey {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let recordingMode = "recordingMode"
        static let selectedVehicleId = "selectedVehicleId"
        static let lastKnownOdometer = "lastKnownOdometer"
        static let preferredMapProvider = "preferredMapProvider"
        static let enabledNotifications = "enabledNotifications"
        static let dataUsageMode = "dataUsageMode"
    }
    
    // MARK: - API Keys (loaded from config)
    enum APIKey {
        static let googleMaps = Configuration.googleMapsAPIKey ?? ""
        static let googlePlaces = Configuration.googlePlacesAPIKey ?? ""
        static let firebase = Configuration.firebaseAPIKey ?? ""
    }
    
    // MARK: - Limits
    enum Limits {
        static let maxPhotoSize = 10 * 1024 * 1024 // 10 MB
        static let maxDocumentSize = 25 * 1024 * 1024 // 25 MB
        static let maxRoomMembers = 20
        static let maxExpensesPerRide = 100
        static let maxVehiclesPerUser = 10
        static let maxPOIsCache = 500
    }
}