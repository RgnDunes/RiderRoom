import Foundation
import Combine

/// Dependency Injection Container for managing app dependencies
final class Container {
    static let shared = Container()
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    
    private init() {}
    
    /// Register all dependencies
    func register() {
        // MARK: - Core Services
        registerSingleton(LocationManager.self) { LocationManager() }
        registerSingleton(MotionActivityManager.self) { MotionActivityManager() }
        registerSingleton(NotificationManager.self) { NotificationManager() }
        registerSingleton(PermissionManager.self) { PermissionManager() }
        registerSingleton(KeychainService.self) { KeychainService() }
        registerSingleton(CoreDataStack.self) { CoreDataStack.shared }
        
        // MARK: - Network Clients
        registerSingleton(NetworkClient.self) { NetworkClient() }
        registerSingleton(AuthClient.self) { FirebaseAuthClient() }
        registerSingleton(FirestoreClient.self) { FirestoreClient() }
        registerSingleton(StorageClient.self) { FirebaseStorageClient() }
        
        // MARK: - Maps & Places
        registerSingleton(MapsClient.self) { GoogleMapsClient() }
        registerSingleton(PlacesClient.self) { GooglePlacesClient() }
        
        // MARK: - OCR & Vision
        registerSingleton(OCRClient.self) { VisionOCRClient() }
        registerSingleton(FuelReceiptParser.self) { FuelReceiptParser() }
        registerSingleton(DocumentScanner.self) { DocumentScanner() }
        
        // MARK: - Export Services
        registerSingleton(PDFRenderer.self) { PDFRenderer() }
        registerSingleton(CSVExporter.self) { CSVExporter() }
        
        // MARK: - Repositories
        registerSingleton(RideRepository.self) {
            RideRepositoryImpl(
                coreDataStack: self.resolve(CoreDataStack.self),
                firestoreClient: self.resolve(FirestoreClient.self)
            )
        }
        
        registerSingleton(ExpenseRepository.self) {
            ExpenseRepositoryImpl(
                coreDataStack: self.resolve(CoreDataStack.self),
                firestoreClient: self.resolve(FirestoreClient.self)
            )
        }
        
        registerSingleton(VehicleRepository.self) {
            VehicleRepositoryImpl(
                coreDataStack: self.resolve(CoreDataStack.self)
            )
        }
        
        registerSingleton(RideRoomRepository.self) {
            RideRoomRepositoryImpl(
                firestoreClient: self.resolve(FirestoreClient.self),
                authClient: self.resolve(AuthClient.self)
            )
        }
        
        registerSingleton(POIRepository.self) {
            POIRepositoryImpl(
                placesClient: self.resolve(PlacesClient.self),
                coreDataStack: self.resolve(CoreDataStack.self)
            )
        }
        
        // MARK: - Use Cases
        registerFactory(StartRideUseCase.self) {
            StartRideUseCase(
                rideRepository: self.resolve(RideRepository.self),
                vehicleRepository: self.resolve(VehicleRepository.self),
                locationManager: self.resolve(LocationManager.self),
                motionManager: self.resolve(MotionActivityManager.self)
            )
        }
        
        registerFactory(RecordExpenseUseCase.self) {
            RecordExpenseUseCase(
                expenseRepository: self.resolve(ExpenseRepository.self),
                ocrClient: self.resolve(OCRClient.self),
                placesClient: self.resolve(PlacesClient.self)
            )
        }
        
        registerFactory(CreateRideRoomUseCase.self) {
            CreateRideRoomUseCase(
                roomRepository: self.resolve(RideRoomRepository.self),
                authClient: self.resolve(AuthClient.self)
            )
        }
        
        registerFactory(CalculateSettlementsUseCase.self) {
            CalculateSettlementsUseCase(
                roomRepository: self.resolve(RideRoomRepository.self),
                expenseRepository: self.resolve(ExpenseRepository.self)
            )
        }
        
        registerFactory(ExportRidePDFUseCase.self) {
            ExportRidePDFUseCase(
                rideRepository: self.resolve(RideRepository.self),
                expenseRepository: self.resolve(ExpenseRepository.self),
                pdfRenderer: self.resolve(PDFRenderer.self)
            )
        }
        
        // MARK: - ViewModels
        registerFactory(HomeViewModel.self) {
            HomeViewModel(
                rideRepository: self.resolve(RideRepository.self),
                vehicleRepository: self.resolve(VehicleRepository.self)
            )
        }
        
        registerFactory(RecordViewModel.self) {
            RecordViewModel(
                startRideUseCase: self.resolve(StartRideUseCase.self),
                locationManager: self.resolve(LocationManager.self),
                motionManager: self.resolve(MotionActivityManager.self)
            )
        }
        
        registerFactory(ExpenseViewModel.self) {
            ExpenseViewModel(
                recordExpenseUseCase: self.resolve(RecordExpenseUseCase.self),
                ocrClient: self.resolve(OCRClient.self)
            )
        }
        
        registerFactory(RideRoomViewModel.self) {
            RideRoomViewModel(
                createRoomUseCase: self.resolve(CreateRideRoomUseCase.self),
                calculateSettlementsUseCase: self.resolve(CalculateSettlementsUseCase.self)
            )
        }
    }
    
    /// Register a singleton service
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        services[key] = factory()
    }
    
    /// Register a factory for creating new instances
    func registerFactory<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// Resolve a dependency
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        if let service = services[key] as? T {
            return service
        }
        
        if let factory = factories[key], let service = factory() as? T {
            return service
        }
        
        fatalError("⚠️ Dependency \(key) not registered in Container")
    }
}

/// Property wrapper for dependency injection
@propertyWrapper
struct Injected<T> {
    private let dependency: T
    
    init() {
        self.dependency = Container.shared.resolve(T.self)
    }
    
    var wrappedValue: T {
        return dependency
    }
}

/// Protocol for injectable view models
protocol Injectable {
    associatedtype Dependencies
    init(dependencies: Dependencies)
}

/// Resolver for view model dependencies
struct Resolver {
    static func resolve<T>(_ type: T.Type) -> T {
        return Container.shared.resolve(type)
    }
}