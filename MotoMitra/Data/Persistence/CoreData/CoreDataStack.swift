import CoreData
import Foundation

/// Core Data stack manager
class CoreDataStack {
    static let shared = CoreDataStack()
    
    private let modelName = "MotoMitra"
    private let storeType = NSSQLiteStoreType
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        // Configure for CloudKit sync if enabled
        if FeatureFlags.isCloudSyncEnabled {
            container.persistentStoreDescriptions.forEach { storeDescription in
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: "iCloud.com.motomitra.app"
                )
            }
        }
        
        // Enable lightweight migration
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        // Set store location
        let storeURL = self.storeURL
        description?.url = storeURL
        
        // Load persistent stores
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, report this error to crash analytics
                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
            }
            
            print("Core Data loaded successfully at: \(storeDescription.url?.absoluteString ?? "unknown")")
        }
        
        // Configure context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Store URL
    
    private var storeURL: URL {
        let storeDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return storeDirectory.appendingPathComponent("\(modelName).sqlite")
    }
    
    // MARK: - Save Context
    
    func save() {
        let context = viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Core Data save error: \(nsError), \(nsError.userInfo)")
            // In production, report this error
        }
    }
    
    // MARK: - Background Context
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Batch Operations
    
    func batchDelete<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil) async throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
        fetchRequest.predicate = predicate
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        try await performBackgroundTask { context in
            let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
            
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
            }
        }
    }
    
    // MARK: - Migration
    
    func migrateIfNeeded() {
        // Check current model version
        let currentVersion = getCurrentModelVersion()
        let lastVersion = UserDefaults.standard.integer(forKey: "CoreDataModelVersion")
        
        if currentVersion > lastVersion {
            performMigration(from: lastVersion, to: currentVersion)
            UserDefaults.standard.set(currentVersion, forKey: "CoreDataModelVersion")
        }
    }
    
    private func getCurrentModelVersion() -> Int {
        // Version 1: Initial release
        // Version 2: Added fuel consumption tracking
        // Version 3: Added document vault
        return 1
    }
    
    private func performMigration(from oldVersion: Int, to newVersion: Int) {
        print("Migrating Core Data from version \(oldVersion) to \(newVersion)")
        
        // Implement specific migration logic for each version
        switch (oldVersion, newVersion) {
        case (0, 1):
            // Initial setup, no migration needed
            break
        case (1, 2):
            // Migration for version 2
            migrateToVersion2()
        case (2, 3):
            // Migration for version 3
            migrateToVersion3()
        default:
            break
        }
    }
    
    private func migrateToVersion2() {
        // Example: Add fuel consumption fields
        // This would typically involve custom migration mapping
    }
    
    private func migrateToVersion3() {
        // Example: Add document vault entities
    }
    
    // MARK: - Data Export/Import
    
    func exportData() async throws -> Data {
        let context = viewContext
        var exportData: [String: Any] = [:]
        
        // Export all entities
        let entities = ["RideEntity", "ExpenseEntity", "VehicleEntity", "POIEntity"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            let objects = try context.fetch(fetchRequest)
            
            let dictionaries = objects.compactMap { object -> [String: Any]? in
                return object.dictionaryWithValues(forKeys: Array(object.entity.attributesByName.keys))
            }
            
            exportData[entityName] = dictionaries
        }
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    func importData(_ data: Data) async throws {
        let context = newBackgroundContext()
        
        guard let importData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CoreDataError.invalidImportData
        }
        
        // Import each entity type
        for (entityName, objects) in importData {
            guard let objectDictionaries = objects as? [[String: Any]] else { continue }
            
            for dictionary in objectDictionaries {
                let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
                let object = NSManagedObject(entity: entity, insertInto: context)
                
                for (key, value) in dictionary {
                    object.setValue(value, forKey: key)
                }
            }
        }
        
        try context.save()
    }
    
    // MARK: - Cleanup
    
    func cleanup() async {
        // Delete old rides (> 1 year)
        let oneYearAgo = Date().addingTimeInterval(-365 * 24 * 60 * 60)
        let predicate = NSPredicate(format: "startTime < %@", oneYearAgo as NSDate)
        
        do {
            try await batchDelete(RideEntity.self, predicate: predicate)
        } catch {
            print("Failed to cleanup old rides: \(error)")
        }
    }
}

// MARK: - Core Data Entities (Swift representations)

// These would typically be generated from the .xcdatamodeld file
// Showing manual definitions for clarity

@objc(RideEntity)
public class RideEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var vehicleId: String
    @NSManaged public var userId: String
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date?
    @NSManaged public var startOdometer: Double
    @NSManaged public var endOdometer: Double
    @NSManaged public var gpsDistance: Double
    @NSManaged public var maxSpeed: Double
    @NSManaged public var averageSpeed: Double
    @NSManaged public var movingTime: Double
    @NSManaged public var title: String?
    @NSManaged public var notes: String?
    @NSManaged public var tags: String? // JSON array
    @NSManaged public var recordingMode: String
    @NSManaged public var isSynced: Bool
    @NSManaged public var lastModified: Date
    @NSManaged public var routePointsData: Data? // Encoded route points
    @NSManaged public var expenses: NSSet?
    @NSManaged public var vehicle: VehicleEntity?
}

@objc(ExpenseEntity)
public class ExpenseEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var rideId: String?
    @NSManaged public var roomId: String?
    @NSManaged public var category: String
    @NSManaged public var amount: Double
    @NSManaged public var expenseDescription: String?
    @NSManaged public var timestamp: Date
    @NSManaged public var paidBy: String
    @NSManaged public var splitType: String
    @NSManaged public var participants: String? // JSON array
    @NSManaged public var splits: String? // JSON dictionary
    @NSManaged public var receiptImageUrl: String?
    @NSManaged public var isVerified: Bool
    @NSManaged public var isSynced: Bool
    @NSManaged public var ride: RideEntity?
}

@objc(VehicleEntity)
public class VehicleEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var make: String
    @NSManaged public var model: String
    @NSManaged public var year: Int16
    @NSManaged public var registrationNumber: String
    @NSManaged public var engineCC: Int16
    @NSManaged public var fuelType: String
    @NSManaged public var currentOdometer: Double
    @NSManaged public var purchaseDate: Date?
    @NSManaged public var color: String?
    @NSManaged public var chassisNumber: String?
    @NSManaged public var engineNumber: String?
    @NSManaged public var insuranceExpiry: Date?
    @NSManaged public var pucExpiry: Date?
    @NSManaged public var baselineKmpl: Double
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var rides: NSSet?
    @NSManaged public var serviceReminders: NSSet?
}

@objc(ServiceReminderEntity)
public class ServiceReminderEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var vehicleId: String
    @NSManaged public var type: String
    @NSManaged public var name: String
    @NSManaged public var intervalKm: Int32
    @NSManaged public var intervalDays: Int32
    @NSManaged public var lastServiceKm: Double
    @NSManaged public var lastServiceDate: Date?
    @NSManaged public var nextDueKm: Double
    @NSManaged public var nextDueDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var vehicle: VehicleEntity?
}

@objc(DocumentEntity)
public class DocumentEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var vehicleId: String?
    @NSManaged public var type: String
    @NSManaged public var name: String
    @NSManaged public var fileUrl: String
    @NSManaged public var expiryDate: Date?
    @NSManaged public var reminderDays: Int16
    @NSManaged public var isEncrypted: Bool
    @NSManaged public var uploadedAt: Date
    @NSManaged public var vehicle: VehicleEntity?
}

@objc(POIEntity)
public class POIEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var placeId: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var type: String
    @NSManaged public var address: String?
    @NSManaged public var rating: Double
    @NSManaged public var isFavorite: Bool
    @NSManaged public var brand: String?
    @NSManaged public var notes: String?
    @NSManaged public var lastVisited: Date?
    @NSManaged public var createdAt: Date
}

// MARK: - Errors

enum CoreDataError: LocalizedError {
    case saveFailed
    case fetchFailed
    case invalidImportData
    case migrationFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .fetchFailed:
            return "Failed to fetch data"
        case .invalidImportData:
            return "Invalid import data format"
        case .migrationFailed:
            return "Database migration failed"
        }
    }
}