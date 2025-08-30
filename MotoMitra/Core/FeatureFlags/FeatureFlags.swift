import Foundation

/// Feature flags for controlling app features
enum FeatureFlags {
    // MARK: - Feature Toggles
    static var isProEnabled: Bool {
        #if DEBUG
        return true // All features enabled in debug
        #else
        return UserDefaults.standard.bool(forKey: "feature.pro.enabled")
        #endif
    }
    
    static var isRideRoomsEnabled: Bool {
        return true // Core feature, always enabled
    }
    
    static var isOCREnabled: Bool {
        return true // Core feature for fuel scanning
    }
    
    static var isGoogleMapsEnabled: Bool {
        // Check if API key is configured
        return !Constants.APIKey.googleMaps.isEmpty
    }
    
    static var isAppleMapsEnabled: Bool {
        // Fallback when Google Maps is not available
        return !isGoogleMapsEnabled
    }
    
    static var isCloudSyncEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "feature.cloudSync.enabled")
    }
    
    static var isOfflineModeEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "feature.offlineMode.enabled")
    }
    
    static var isAutoRecordingEnabled: Bool {
        return true // Core feature
    }
    
    static var isPDFExportEnabled: Bool {
        return true // Core feature
    }
    
    static var isCSVExportEnabled: Bool {
        return isProEnabled
    }
    
    static var isAdvancedAnalyticsEnabled: Bool {
        return isProEnabled
    }
    
    static var isMultiDeviceSyncEnabled: Bool {
        return isProEnabled
    }
    
    static var isCustomPDFBrandingEnabled: Bool {
        return isProEnabled
    }
    
    static var isUnlimitedRideRoomsEnabled: Bool {
        return isProEnabled
    }
    
    // MARK: - Future Features (Scaffolded)
    
    /// Friend lifetime access - NOT IMPLEMENTED
    /// TODO: Implement friend access code validation
    /// TODO: Add entitlement management
    /// TODO: Create UI for code redemption
    static var friendLifetimeAccess: Bool = false
    
    /// IAP via RevenueCat - NOT IMPLEMENTED
    /// TODO: Integrate RevenueCat SDK
    /// TODO: Configure products and entitlements
    /// TODO: Add purchase flow UI
    static var isIAPEnabled: Bool = false
    
    /// Web link sharing - NOT IMPLEMENTED
    /// TODO: Implement dynamic links
    /// TODO: Create web viewer for shared rides
    /// TODO: Add share sheet integration
    static var isWebSharingEnabled: Bool = false
    
    // MARK: - Debug Features
    #if DEBUG
    static var isDebugMenuEnabled: Bool = true
    static var isMockDataEnabled: Bool = true
    static var isNetworkLoggingEnabled: Bool = true
    #else
    static var isDebugMenuEnabled: Bool = false
    static var isMockDataEnabled: Bool = false
    static var isNetworkLoggingEnabled: Bool = false
    #endif
    
    // MARK: - Configuration
    static func configure() {
        // Set default values if not already set
        let defaults: [String: Any] = [
            "feature.pro.enabled": false,
            "feature.cloudSync.enabled": true,
            "feature.offlineMode.enabled": true
        ]
        
        UserDefaults.standard.register(defaults: defaults)
        
        // Load remote config if available
        loadRemoteConfig()
    }
    
    private static func loadRemoteConfig() {
        // TODO: Implement Firebase Remote Config
        // This would allow updating feature flags without app update
    }
    
    // MARK: - Pro Features Check
    static func requiresPro(for feature: ProFeature) -> Bool {
        switch feature {
        case .unlimitedRooms:
            return !isUnlimitedRideRoomsEnabled
        case .advancedAnalytics:
            return !isAdvancedAnalyticsEnabled
        case .multiDeviceSync:
            return !isMultiDeviceSyncEnabled
        case .customPDFBranding:
            return !isCustomPDFBrandingEnabled
        case .csvExport:
            return !isCSVExportEnabled
        }
    }
    
    enum ProFeature {
        case unlimitedRooms
        case advancedAnalytics
        case multiDeviceSync
        case customPDFBranding
        case csvExport
        
        var displayName: String {
            switch self {
            case .unlimitedRooms:
                return "Unlimited Ride Rooms"
            case .advancedAnalytics:
                return "Advanced Analytics"
            case .multiDeviceSync:
                return "Multi-Device Sync"
            case .customPDFBranding:
                return "Custom PDF Branding"
            case .csvExport:
                return "CSV Export"
            }
        }
        
        var description: String {
            switch self {
            case .unlimitedRooms:
                return "Create unlimited group ride rooms"
            case .advancedAnalytics:
                return "Detailed insights and trend analysis"
            case .multiDeviceSync:
                return "Sync data across all your devices"
            case .customPDFBranding:
                return "Add your logo to exported PDFs"
            case .csvExport:
                return "Export data in CSV format"
            }
        }
    }
}

// MARK: - Friend Access (Scaffolded)
/// Placeholder for friend lifetime access feature
/// TODO: Implement when feature is ready
struct FriendAccessCode {
    let code: String
    let expiresAt: Date?
    let usageLimit: Int?
    
    // TODO: Validate code format
    // TODO: Check expiration
    // TODO: Track usage
}

struct FriendEntitlement {
    let userId: String
    let accessCode: FriendAccessCode
    let grantedAt: Date
    
    // TODO: Store in Keychain
    // TODO: Sync with backend
    // TODO: Validate on app launch
}