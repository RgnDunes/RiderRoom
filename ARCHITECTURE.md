# MotoMitra Architecture

## High-Level Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        App[App Entry]
        Features[Feature Modules]
        DS[Design System]
    end
    
    subgraph "Domain Layer"
        UC[Use Cases]
        Entities[Domain Entities]
        Repos[Repository Protocols]
    end
    
    subgraph "Data Layer"
        CoreData[Core Data]
        Firebase[Firebase Services]
        Maps[Maps Services]
        OCR[Vision OCR]
        Network[Network Client]
    end
    
    subgraph "Core"
        DI[Dependency Injection]
        Utils[Utilities]
        Extensions[Extensions]
    end
    
    App --> Features
    Features --> UC
    Features --> DS
    UC --> Entities
    UC --> Repos
    Repos --> CoreData
    Repos --> Firebase
    Repos --> Maps
    Repos --> OCR
    Repos --> Network
    Features --> DI
    UC --> DI
    Data --> DI
```

## Module Structure

```
MotoMitra/
├── App/
│   ├── MotoMitraApp.swift
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Info.plist
│   └── Assets.xcassets
│
├── Core/
│   ├── DI/
│   │   ├── Container.swift
│   │   ├── Resolver.swift
│   │   └── Injectable.swift
│   ├── DesignSystem/
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   ├── Spacing.swift
│   │   ├── Components/
│   │   └── Modifiers/
│   ├── Navigation/
│   │   ├── Router.swift
│   │   ├── NavigationPath.swift
│   │   └── Coordinator.swift
│   ├── Utils/
│   │   ├── Extensions/
│   │   ├── Formatters/
│   │   ├── Validators/
│   │   └── Constants.swift
│   └── FeatureFlags/
│       └── FeatureFlags.swift
│
├── Domain/
│   ├── Entities/
│   │   ├── Ride.swift
│   │   ├── Expense.swift
│   │   ├── Vehicle.swift
│   │   ├── RideRoom.swift
│   │   ├── Settlement.swift
│   │   └── POI.swift
│   ├── UseCases/
│   │   ├── RideRecording/
│   │   ├── ExpenseManagement/
│   │   ├── RoomManagement/
│   │   └── VehicleService/
│   └── Repositories/
│       ├── RideRepository.swift
│       ├── ExpenseRepository.swift
│       ├── VehicleRepository.swift
│       └── RoomRepository.swift
│
├── Data/
│   ├── Persistence/
│   │   ├── CoreData/
│   │   │   ├── MotoMitra.xcdatamodeld
│   │   │   ├── CoreDataStack.swift
│   │   │   ├── Migrations/
│   │   │   └── Repositories/
│   │   └── Keychain/
│   │       └── KeychainService.swift
│   ├── Network/
│   │   ├── Firebase/
│   │   │   ├── AuthClient.swift
│   │   │   ├── FirestoreClient.swift
│   │   │   └── StorageClient.swift
│   │   ├── API/
│   │   │   └── NetworkClient.swift
│   │   └── Reachability/
│   ├── Maps/
│   │   ├── GoogleMapsClient.swift
│   │   ├── PlacesClient.swift
│   │   └── LocationManager.swift
│   ├── OCR/
│   │   ├── VisionOCRClient.swift
│   │   ├── FuelReceiptParser.swift
│   │   └── DocumentScanner.swift
│   └── Export/
│       ├── PDFRenderer.swift
│       └── CSVExporter.swift
│
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── Components/
│   ├── RideRecord/
│   │   ├── RecordView.swift
│   │   ├── RecordViewModel.swift
│   │   ├── PreRideSheet.swift
│   │   ├── PostRideSheet.swift
│   │   ├── AutoDetection/
│   │   └── Components/
│   ├── RideDetail/
│   │   ├── RideDetailView.swift
│   │   ├── RideDetailViewModel.swift
│   │   └── Components/
│   ├── Expenses/
│   │   ├── ExpenseListView.swift
│   │   ├── AddExpenseView.swift
│   │   ├── FuelScannerView.swift
│   │   ├── ExpenseViewModel.swift
│   │   └── OCR/
│   ├── RideRooms/
│   │   ├── RoomListView.swift
│   │   ├── RoomDetailView.swift
│   │   ├── SettlementView.swift
│   │   ├── RoomViewModel.swift
│   │   └── Components/
│   ├── Vehicles/
│   │   ├── VehicleListView.swift
│   │   ├── VehicleDetailView.swift
│   │   ├── VehicleViewModel.swift
│   │   └── Components/
│   ├── Service/
│   │   ├── ServiceListView.swift
│   │   ├── ServiceReminderView.swift
│   │   ├── ServiceViewModel.swift
│   │   └── Components/
│   ├── Documents/
│   │   ├── DocumentVaultView.swift
│   │   ├── DocumentViewModel.swift
│   │   └── Components/
│   ├── POI/
│   │   ├── POIExplorerView.swift
│   │   ├── POIDetailView.swift
│   │   ├── POIViewModel.swift
│   │   └── Components/
│   ├── Insights/
│   │   ├── InsightsView.swift
│   │   ├── InsightsViewModel.swift
│   │   └── Charts/
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── SettingsViewModel.swift
│   │   └── Components/
│   └── Onboarding/
│       ├── OnboardingView.swift
│       ├── PermissionsView.swift
│       └── Components/
│
├── Resources/
│   ├── Localizable.strings
│   ├── Localizable.strings (hi)
│   └── GoogleService-Info.plist
│
├── Tests/
│   ├── UnitTests/
│   ├── SnapshotTests/
│   └── UITests/
│
└── Configuration/
    ├── Debug.xcconfig
    ├── Release.xcconfig
    └── .env.example
```

## Dependency Graph

```mermaid
graph LR
    subgraph "External Dependencies"
        GoogleMaps[Google Maps SDK]
        Firebase[Firebase SDK]
        RevenueCat[RevenueCat SDK]
    end
    
    subgraph "Feature Modules"
        RideRecord --> Core
        RideRecord --> Domain
        RideRecord --> Maps
        
        Expenses --> Core
        Expenses --> Domain
        Expenses --> OCR
        
        RideRooms --> Core
        RideRooms --> Domain
        RideRooms --> Firebase
        
        Insights --> Core
        Insights --> Domain
        Insights --> Charts
    end
    
    Maps --> GoogleMaps
    Firebase --> FirebaseSDK
    IAP --> RevenueCat
```

## Data Flow

```mermaid
sequenceDiagram
    participant UI as SwiftUI View
    participant VM as ViewModel
    participant UC as UseCase
    participant Repo as Repository
    participant Data as Data Layer
    
    UI->>VM: User Action
    VM->>UC: Execute UseCase
    UC->>Repo: Repository Call
    Repo->>Data: Fetch/Store Data
    Data-->>Repo: Return Data
    Repo-->>UC: Domain Entity
    UC-->>VM: Result
    VM-->>UI: Update State
```