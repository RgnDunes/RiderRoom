# Core Data Migration Plan

## Current Schema Version: 1

### Version History

#### Version 1 (Initial Release)
- **Entities**: RideEntity, ExpenseEntity, VehicleEntity, ServiceReminderEntity, DocumentEntity, POIEntity
- **Features**: Basic ride tracking, expense management, vehicle management, service reminders, document vault, POI storage

### Future Migration Plans

#### Version 2 (Planned - Fuel Efficiency)
**Changes:**
- Add `fuelConsumed` field to RideEntity
- Add `fuelEfficiency` calculated field to RideEntity
- Add `tankCapacity` field to VehicleEntity
- Add `lastRefuelOdometer` field to VehicleEntity

**Migration Strategy:**
- Lightweight migration for new optional fields
- Background task to calculate fuel efficiency for existing rides

#### Version 3 (Planned - Enhanced Groups)
**Changes:**
- Add RoomEntity for offline room caching
- Add SettlementEntity for settlement tracking
- Add relationship between ExpenseEntity and RoomEntity
- Add `roomId` to RideEntity for room-associated rides

**Migration Strategy:**
- Custom migration mapping for new entities
- Preserve existing expense data
- Link expenses to rooms based on roomId field

#### Version 4 (Planned - Analytics)
**Changes:**
- Add RideStatisticsEntity for cached analytics
- Add MonthlyStatsEntity for aggregated data
- Add index on date fields for faster queries

**Migration Strategy:**
- Progressive migration with background calculation
- Generate statistics from existing ride data

## Migration Implementation

### Lightweight Migration
Used for simple schema changes:
- Adding new optional attributes
- Adding new entities without relationships
- Renaming attributes with renaming identifiers

### Custom Migration
Required for:
- Complex data transformations
- Relationship changes
- Data type changes
- Merging or splitting entities

### Migration Process

1. **Pre-Migration Backup**
   ```swift
   func backupDatabase() async throws {
       let backupURL = documentDirectory.appendingPathComponent("backup_v\(oldVersion).sqlite")
       try FileManager.default.copyItem(at: storeURL, to: backupURL)
   }
   ```

2. **Version Detection**
   ```swift
   func detectModelVersion() -> Int {
       // Check model metadata
       // Compare with stored version in UserDefaults
       return currentVersion
   }
   ```

3. **Progressive Migration**
   ```swift
   func performProgressiveMigration() async {
       // Migrate in steps if jumping multiple versions
       for version in (oldVersion + 1)...newVersion {
           try await migrateToVersion(version)
       }
   }
   ```

4. **Validation**
   ```swift
   func validateMigration() async throws {
       // Verify data integrity
       // Check relationships
       // Validate calculated fields
   }
   ```

## Testing Strategy

### Unit Tests
- Test each migration path independently
- Verify data integrity after migration
- Test rollback scenarios

### Integration Tests
- Test migration with production-like data volumes
- Test migration performance
- Test app functionality post-migration

### Migration Test Data
```swift
func generateTestData(for version: Int) -> URL {
    // Create test database with schema version
    // Populate with representative data
    // Return database URL
}
```

## Rollback Plan

1. **Automatic Rollback Triggers**
   - Migration failure
   - Data validation failure
   - App crash during migration

2. **Rollback Process**
   - Restore from pre-migration backup
   - Clear migration flags
   - Notify user of rollback

3. **Recovery Options**
   - Retry migration
   - Export data and clean install
   - Contact support for manual recovery

## Best Practices

1. **Always backup before migration**
2. **Test migrations with production data copies**
3. **Implement progressive migration for large datasets**
4. **Provide user feedback during migration**
5. **Log migration steps for debugging**
6. **Version all model files in source control**
7. **Document all schema changes**
8. **Keep migration code for at least 3 versions**

## Migration Monitoring

### Metrics to Track
- Migration duration
- Success/failure rate
- Data volume migrated
- Rollback frequency

### Error Reporting
```swift
func reportMigrationError(_ error: Error, version: Int) {
    // Log to analytics
    // Send crash report
    // Store for support diagnosis
}
```

## Cloud Sync Considerations

1. **Disable sync during migration**
2. **Clear sync metadata after schema changes**
3. **Re-enable sync after validation**
4. **Handle conflicts from other devices**

## Performance Optimization

1. **Batch Processing**
   - Process records in chunks
   - Use background contexts
   - Release memory periodically

2. **Index Management**
   - Add indexes before bulk operations
   - Rebuild indexes after migration

3. **Vacuum Database**
   ```swift
   func vacuumDatabase() async throws {
       let sql = "VACUUM"
       try context.execute(NSAsynchronousFetchRequest(sql))
   }
   ```