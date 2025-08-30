import SwiftUI
import Combine

/// Navigation router for managing app navigation
class NavigationRouter: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: Tab = .home
    @Published var presentedSheet: Sheet?
    @Published var presentedFullScreen: FullScreen?
    @Published var alertItem: AlertItem?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Tab Navigation
    enum Tab: String, CaseIterable {
        case home = "Home"
        case rides = "Rides"
        case expenses = "Expenses"
        case vehicles = "Vehicles"
        case insights = "Insights"
        
        var icon: String {
            switch self {
            case .home: return DesignSystem.Icons.home
            case .rides: return DesignSystem.Icons.ride
            case .expenses: return DesignSystem.Icons.expense
            case .vehicles: return DesignSystem.Icons.vehicle
            case .insights: return DesignSystem.Icons.insights
            }
        }
    }
    
    // MARK: - Navigation Destinations
    enum Destination: Hashable {
        case rideDetail(rideId: String)
        case expenseDetail(expenseId: String)
        case vehicleDetail(vehicleId: String)
        case serviceReminder(vehicleId: String)
        case rideRoom(roomId: String)
        case poiDetail(poiId: String)
        case documentDetail(documentId: String)
        case settings
        case profile
    }
    
    // MARK: - Sheet Presentations
    enum Sheet: Identifiable {
        case preRide(vehicle: Vehicle?)
        case postRide(ride: Ride)
        case addExpense(ride: Ride?)
        case scanFuelReceipt
        case addVehicle
        case editVehicle(vehicle: Vehicle)
        case createRideRoom
        case joinRideRoom
        case exportPDF(ride: Ride)
        case documentScanner
        case poiSearch
        
        var id: String {
            switch self {
            case .preRide: return "preRide"
            case .postRide: return "postRide"
            case .addExpense: return "addExpense"
            case .scanFuelReceipt: return "scanFuelReceipt"
            case .addVehicle: return "addVehicle"
            case .editVehicle: return "editVehicle"
            case .createRideRoom: return "createRideRoom"
            case .joinRideRoom: return "joinRideRoom"
            case .exportPDF: return "exportPDF"
            case .documentScanner: return "documentScanner"
            case .poiSearch: return "poiSearch"
            }
        }
    }
    
    // MARK: - Full Screen Presentations
    enum FullScreen: Identifiable {
        case recording(mode: RecordingMode)
        case odometerReconciliation(ride: Ride)
        case settlementCalculator(room: RideRoom)
        case pdfViewer(url: URL)
        
        var id: String {
            switch self {
            case .recording: return "recording"
            case .odometerReconciliation: return "odometerReconciliation"
            case .settlementCalculator: return "settlementCalculator"
            case .pdfViewer: return "pdfViewer"
            }
        }
    }
    
    // MARK: - Alert Item
    struct AlertItem: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let primaryButton: Alert.Button
        let secondaryButton: Alert.Button?
        
        init(title: String,
             message: String,
             primaryButton: Alert.Button = .default(Text("OK")),
             secondaryButton: Alert.Button? = nil) {
            self.title = title
            self.message = message
            self.primaryButton = primaryButton
            self.secondaryButton = secondaryButton
        }
    }
    
    // MARK: - Navigation Methods
    func navigate(to destination: Destination) {
        navigationPath.append(destination)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func navigateToRoot() {
        navigationPath = NavigationPath()
    }
    
    func switchTab(to tab: Tab) {
        selectedTab = tab
    }
    
    func presentSheet(_ sheet: Sheet) {
        presentedSheet = sheet
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func presentFullScreen(_ fullScreen: FullScreen) {
        presentedFullScreen = fullScreen
    }
    
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
    
    func showAlert(_ alert: AlertItem) {
        alertItem = alert
    }
    
    func dismissAlert() {
        alertItem = nil
    }
    
    // MARK: - Deep Linking
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else { return }
        
        switch host {
        case "ride":
            if let rideId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                navigate(to: .rideDetail(rideId: rideId))
            }
        case "room":
            if let roomId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                navigate(to: .rideRoom(roomId: roomId))
            }
        case "join":
            if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                presentSheet(.joinRideRoom)
                // Pass the code to the join room view
            }
        default:
            break
        }
    }
}

// MARK: - Navigation View Modifier
struct NavigationDestinationModifier: ViewModifier {
    @EnvironmentObject var router: NavigationRouter
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationRouter.Destination.self) { destination in
                switch destination {
                case .rideDetail(let rideId):
                    RideDetailView(rideId: rideId)
                case .expenseDetail(let expenseId):
                    ExpenseDetailView(expenseId: expenseId)
                case .vehicleDetail(let vehicleId):
                    VehicleDetailView(vehicleId: vehicleId)
                case .serviceReminder(let vehicleId):
                    ServiceReminderView(vehicleId: vehicleId)
                case .rideRoom(let roomId):
                    RideRoomDetailView(roomId: roomId)
                case .poiDetail(let poiId):
                    POIDetailView(poiId: poiId)
                case .documentDetail(let documentId):
                    DocumentDetailView(documentId: documentId)
                case .settings:
                    SettingsView()
                case .profile:
                    ProfileView()
                }
            }
    }
}

extension View {
    func withNavigation() -> some View {
        modifier(NavigationDestinationModifier())
    }
}