import SwiftUI
import Firebase
import GoogleMaps
import CoreData

/// Main app entry point for MotoMitra
@main
struct MotoMitraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var navigationRouter = NavigationRouter()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        setupDependencies()
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(navigationRouter)
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
                .onAppear {
                    requestInitialPermissions()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    private func setupDependencies() {
        // Initialize DI Container
        Container.shared.register()
        
        // Configure feature flags
        FeatureFlags.configure()
    }
    
    private func configureAppearance() {
        // Set up global UI appearance
        UINavigationBar.appearance().tintColor = UIColor(DesignSystem.Colors.primary)
        UITabBar.appearance().tintColor = UIColor(DesignSystem.Colors.primary)
    }
    
    private func requestInitialPermissions() {
        Task {
            await PermissionManager.shared.requestInitialPermissions()
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            appState.isActive = true
            LocationManager.shared.resumeUpdatesIfNeeded()
        case .inactive:
            appState.isActive = false
        case .background:
            appState.isActive = false
            LocationManager.shared.enterBackgroundMode()
            scheduleBackgroundTasks()
        @unknown default:
            break
        }
    }
    
    private func scheduleBackgroundTasks() {
        BackgroundTaskScheduler.shared.scheduleAppRefresh()
        BackgroundTaskScheduler.shared.scheduleProcessing()
    }
}

/// App delegate for handling app lifecycle and third-party SDK initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Maps
        if let apiKey = Configuration.googleMapsAPIKey {
            GMSServices.provideAPIKey(apiKey)
        }
        
        // Setup push notifications
        UNUserNotificationCenter.current().delegate = self
        
        // Configure background modes
        configureBackgroundModes()
        
        // Initialize crash reporting (if enabled)
        #if !DEBUG
        CrashReporter.shared.initialize()
        #endif
        
        return true
    }
    
    func application(_ application: UIApplication,
                    configurationForConnecting connectingSceneSession: UISceneSession,
                    options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    private func configureBackgroundModes() {
        // Register background tasks
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.motomitra.refresh",
            using: nil
        ) { task in
            BackgroundTaskHandler.shared.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.motomitra.processing",
            using: nil
        ) { task in
            BackgroundTaskHandler.shared.handleProcessing(task: task as! BGProcessingTask)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationHandler.shared.handleNotificationResponse(response)
        completionHandler()
    }
}

/// Global app state
class AppState: ObservableObject {
    @Published var isActive = true
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var selectedVehicle: Vehicle?
    @Published var activeRide: Ride?
    @Published var recordingMode: RecordingMode = .auto
    
    init() {
        loadUserPreferences()
    }
    
    private func loadUserPreferences() {
        recordingMode = UserDefaults.standard.recordingMode
        // Load other preferences
    }
}

/// Main content view with tab navigation
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var navigationRouter: NavigationRouter
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if appState.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .preferredColorScheme(.dark) // Default to dark mode
    }
}