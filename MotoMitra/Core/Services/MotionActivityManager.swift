import Foundation
import CoreMotion
import Combine

/// Motion activity manager for detecting automotive motion
class MotionActivityManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentActivity: CMMotionActivity?
    @Published var isAutomotiveMotion = false
    @Published var confidence: CMMotionActivityConfidence = .low
    @Published var isMonitoring = false
    @Published var motionError: Error?
    
    // MARK: - Private Properties
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    private var activityQueue = OperationQueue()
    private var lastAutomotiveDetection: Date?
    private var automotiveConfidenceBuffer: [Bool] = []
    private let confidenceBufferSize = 5
    
    // MARK: - Initialization
    init() {
        activityQueue.maxConcurrentOperationCount = 1
        activityQueue.name = "com.motomitra.motion"
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() -> Bool {
        return CMMotionActivityManager.isActivityAvailable()
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // Motion activity authorization is requested on first use
        guard CMMotionActivityManager.isActivityAvailable() else {
            completion(false)
            return
        }
        
        // Trigger authorization by querying historical data
        let now = Date()
        let past = now.addingTimeInterval(-60)
        
        activityManager.queryActivityStarting(from: past, to: now, to: activityQueue) { _, error in
            DispatchQueue.main.async {
                if error != nil {
                    self.motionError = error
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Activity Monitoring
    
    func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            motionError = MotionError.notAvailable
            return
        }
        
        isMonitoring = true
        
        activityManager.startActivityUpdates(to: activityQueue) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            DispatchQueue.main.async {
                self.processActivity(activity)
            }
        }
        
        print("🏃 Started motion activity updates")
    }
    
    func stopActivityUpdates() {
        isMonitoring = false
        activityManager.stopActivityUpdates()
        print("🏃 Stopped motion activity updates")
    }
    
    // MARK: - Activity Processing
    
    private func processActivity(_ activity: CMMotionActivity) {
        currentActivity = activity
        confidence = activity.confidence
        
        // Check for automotive motion
        let isAutomotive = activity.automotive && activity.confidence != .low
        
        // Add to confidence buffer for smoothing
        automotiveConfidenceBuffer.append(isAutomotive)
        if automotiveConfidenceBuffer.count > confidenceBufferSize {
            automotiveConfidenceBuffer.removeFirst()
        }
        
        // Require majority of recent readings to be automotive
        let automotiveCount = automotiveConfidenceBuffer.filter { $0 }.count
        let wasAutomotive = isAutomotiveMotion
        isAutomotiveMotion = automotiveCount >= (confidenceBufferSize / 2 + 1)
        
        // Track state changes
        if isAutomotiveMotion && !wasAutomotive {
            lastAutomotiveDetection = Date()
            print("🏃 Automotive motion detected with confidence: \(activity.confidence.rawValue)")
        } else if !isAutomotiveMotion && wasAutomotive {
            print("🏃 Automotive motion ended")
        }
        
        // Log other activities for debugging
        #if DEBUG
        var activities: [String] = []
        if activity.walking { activities.append("walking") }
        if activity.running { activities.append("running") }
        if activity.cycling { activities.append("cycling") }
        if activity.automotive { activities.append("automotive") }
        if activity.stationary { activities.append("stationary") }
        if activity.unknown { activities.append("unknown") }
        
        if !activities.isEmpty {
            print("🏃 Activities: \(activities.joined(separator: ", ")) - Confidence: \(confidence.rawValue)")
        }
        #endif
    }
    
    // MARK: - Historical Data
    
    func queryRecentActivity(duration: TimeInterval = 300, completion: @escaping ([CMMotionActivity]) -> Void) {
        guard CMMotionActivityManager.isActivityAvailable() else {
            completion([])
            return
        }
        
        let now = Date()
        let past = now.addingTimeInterval(-duration)
        
        var activities: [CMMotionActivity] = []
        
        activityManager.queryActivityStarting(from: past, to: now, to: activityQueue) { activity, error in
            if let activity = activity {
                activities.append(activity)
            }
            
            if error != nil || activity == nil {
                DispatchQueue.main.async {
                    completion(activities)
                }
            }
        }
    }
    
    // MARK: - Pedometer (for additional validation)
    
    func startPedometerUpdates() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        
        pedometer.startUpdates(from: Date()) { [weak self] pedometerData, error in
            guard let data = pedometerData else { return }
            
            // Use pedometer data to validate non-automotive motion
            // High step count indicates walking/running, not driving
            DispatchQueue.main.async {
                if let stepRate = data.currentPace?.doubleValue {
                    // If significant step rate detected, likely not in vehicle
                    if stepRate > 0 && self?.isAutomotiveMotion == true {
                        print("🏃 Step rate detected (\(stepRate)), validating automotive motion...")
                    }
                }
            }
        }
    }
    
    func stopPedometerUpdates() {
        pedometer.stopUpdates()
    }
    
    // MARK: - Helpers
    
    func isLikelyDriving() -> Bool {
        // Combined check for automotive motion with high confidence
        return isAutomotiveMotion && confidence != .low
    }
    
    func timeSinceLastAutomotiveMotion() -> TimeInterval? {
        guard let lastDetection = lastAutomotiveDetection else { return nil }
        return Date().timeIntervalSince(lastDetection)
    }
    
    func resetDetection() {
        automotiveConfidenceBuffer.removeAll()
        isAutomotiveMotion = false
        lastAutomotiveDetection = nil
    }
}

// MARK: - Motion Errors

enum MotionError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Motion activity detection is not available on this device"
        case .authorizationDenied:
            return "Motion & Fitness access denied. Please enable in Settings."
        case .unknown:
            return "Unknown motion detection error"
        }
    }
}

// MARK: - CMMotionActivityConfidence Extension

extension CMMotionActivityConfidence {
    var description: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        @unknown default:
            return "Unknown"
        }
    }
}