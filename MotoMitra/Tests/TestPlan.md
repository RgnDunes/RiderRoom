# MotoMitra Test Plan

## Test Coverage Goals
- Unit Tests: 80% code coverage
- UI Tests: Critical user flows
- Integration Tests: API and database operations
- Performance Tests: Recording and sync operations

## 1. Unit Tests

### Domain Layer
- [ ] **Ride Entity Tests**
  - Calculate duration correctly
  - Calculate odometer distance
  - Validate GPS vs odometer discrepancy
  - Audit log entries

- [ ] **Expense Entity Tests**
  - Split calculation for different types
  - Participant management
  - Category validation

- [ ] **Settlement Optimizer Tests**
  - Minimal settlement calculation
  - Balance calculation
  - Edge cases (single payer, no expenses, equal splits)

- [ ] **Vehicle Entity Tests**
  - Odometer validation
  - Service reminder calculations
  - Fuel efficiency tracking

### Use Cases
- [ ] **Start Ride Use Case**
  - Auto mode detection logic
  - Manual mode start
  - Pre-ride validation
  - Odometer validation

- [ ] **Record Expense Use Case**
  - OCR parsing accuracy
  - Fuel receipt parsing
  - Split calculations
  - Location tagging

- [ ] **Settlement Use Case**
  - Room expense aggregation
  - Member balance calculation
  - Settlement optimization

### Services
- [ ] **Location Manager Tests**
  - Accuracy filtering
  - Battery optimization
  - Background mode handling

- [ ] **OCR Parser Tests**
  - Fuel receipt parsing
  - Amount extraction
  - Vendor detection
  - Confidence scoring

- [ ] **PDF Renderer Tests**
  - Ride PDF generation
  - Room PDF generation
  - Chart rendering
  - Data formatting

## 2. UI/Snapshot Tests

### Critical Views
- [ ] **Recording View**
  - Recording states (not started, recording, paused)
  - Metrics display
  - Map integration
  - Control buttons

- [ ] **Ride Room View**
  - Member list
  - Expense list
  - Settlement display
  - Balance overview

- [ ] **Pre/Post Ride Sheets**
  - Odometer input
  - Vehicle selection
  - Fuel level selection
  - Tags and notes

### Components
- [ ] Design system components
- [ ] Custom buttons and controls
- [ ] Chart views
- [ ] Map overlays

## 3. UI Flow Tests

### Test Case 1: Auto Mode Recording
```swift
func testAutoModeRecording() {
    // 1. Launch app
    // 2. Enable auto mode
    // 3. Simulate motion activity
    // 4. Verify pre-ride sheet appears
    // 5. Enter odometer
    // 6. Verify recording starts
    // 7. Simulate pause conditions
    // 8. Verify auto-pause
    // 9. Simulate end conditions
    // 10. Verify post-ride sheet
    // 11. Enter end odometer
    // 12. Verify ride saved
    // 13. Export PDF
    // 14. Verify PDF generated
}
```

### Test Case 2: Manual Mode Recording
```swift
func testManualModeRecording() {
    // 1. Launch app
    // 2. Switch to manual mode
    // 3. Tap start button
    // 4. Fill pre-ride sheet
    // 5. Verify recording starts
    // 6. Add waypoint
    // 7. Pause recording
    // 8. Resume recording
    // 9. Stop recording
    // 10. Fill post-ride sheet
    // 11. Handle odometer reconciliation
    // 12. Verify ride saved
}
```

### Test Case 3: Ride Room Flow
```swift
func testRideRoomFlow() {
    // 1. Create room
    // 2. Share invite code
    // 3. Add shared expense
    // 4. Select participants
    // 5. Choose split type
    // 6. Verify balances update
    // 7. View settlements
    // 8. Mark settlement paid
    // 9. Export room PDF
    // 10. Verify all members in PDF
}
```

### Test Case 4: Fuel Expense OCR
```swift
func testFuelExpenseOCR() {
    // 1. Start expense flow
    // 2. Select fuel category
    // 3. Capture/select fuel pump photo
    // 4. Verify OCR extraction
    // 5. Edit extracted values
    // 6. Confirm expense
    // 7. Verify location tagged
    // 8. Verify station brand detected
}
```

## 4. Integration Tests

### Firebase Integration
- [ ] Authentication flow (Apple/Google)
- [ ] Firestore CRUD operations
- [ ] Real-time listeners
- [ ] Offline persistence
- [ ] Conflict resolution

### Google Maps Integration
- [ ] Map initialization
- [ ] Route drawing
- [ ] POI search
- [ ] Reverse geocoding
- [ ] Place details

### Core Data Integration
- [ ] Entity creation
- [ ] Relationship management
- [ ] Migration testing
- [ ] Sync with Firestore
- [ ] Background operations

## 5. Performance Tests

### Recording Performance
- [ ] Battery usage during recording (target: <3%/hour)
- [ ] Memory usage with long rides
- [ ] Location update frequency
- [ ] Route point storage efficiency

### Data Operations
- [ ] Large ride list scrolling
- [ ] PDF generation time
- [ ] Image upload/download
- [ ] Database query performance

### Network Performance
- [ ] Offline mode functionality
- [ ] Sync queue management
- [ ] API rate limiting
- [ ] Retry mechanisms

## 6. Acceptance Tests

### Auto Mode
- [ ] Starts within 20-30s of sustained motion
- [ ] Ends within 8-10 min of sustained stop
- [ ] User can override auto decisions
- [ ] Battery drain ≤3%/hour

### Odometer Tracking
- [ ] Pre-ride prompt appears 100% of time
- [ ] Post-ride prompt appears 100% of time
- [ ] Reconciliation UI for >10% discrepancy
- [ ] Service reminders update correctly

### Fuel OCR
- [ ] ≥80% accuracy on clear images
- [ ] Extracts at least 2 of 3 fields
- [ ] Manual override always available
- [ ] Station brand detection works

### Privacy & Security
- [ ] No location access outside rides
- [ ] Documents encrypted at rest
- [ ] Secure credential storage
- [ ] Data export/import works

## 7. Edge Cases & Error Handling

### Location Services
- [ ] GPS signal loss
- [ ] Poor accuracy handling
- [ ] Background termination
- [ ] Permission denied

### Network Issues
- [ ] Offline mode
- [ ] Partial sync
- [ ] Timeout handling
- [ ] Retry logic

### Data Validation
- [ ] Invalid odometer values
- [ ] Future dates
- [ ] Negative amounts
- [ ] Missing required fields

## 8. Accessibility Tests

- [ ] VoiceOver navigation
- [ ] Dynamic Type support
- [ ] Color contrast (WCAG AA)
- [ ] Touch target sizes (≥44pt)
- [ ] Semantic labels

## 9. Localization Tests

- [ ] Hindi language support
- [ ] Date formatting (dd-MM-yyyy)
- [ ] Currency formatting (₹)
- [ ] Number formatting (Indian system)
- [ ] RTL support (future)

## 10. Device & OS Testing

### Devices
- [ ] iPhone SE (small screen)
- [ ] iPhone 13/14 (standard)
- [ ] iPhone 15 Pro Max (large)
- [ ] iPad (if supported)

### iOS Versions
- [ ] iOS 17.0 (minimum)
- [ ] iOS 17.x (latest)
- [ ] iOS 18 beta (if available)

## Test Data Requirements

### Users
- Single vehicle owner
- Multi-vehicle owner
- Room owner
- Room member

### Vehicles
- Motorcycle (RE, KTM, etc.)
- Scooter (Activa, etc.)
- High/Low mileage vehicles

### Rides
- Short commutes (<20km)
- Medium rides (50-100km)
- Long tours (>200km)
- Multi-day trips

### Expenses
- Individual expenses
- Shared expenses (equal split)
- Shared expenses (custom split)
- Various categories

## Automation Strategy

### CI/CD Pipeline
```yaml
stages:
  - lint
  - unit_tests
  - build
  - ui_tests
  - deploy_testflight

lint:
  script:
    - swiftlint

unit_tests:
  script:
    - xcodebuild test -scheme MotoMitra
  coverage: '/Test Coverage: (\d+\.\d+)%/'

ui_tests:
  script:
    - xcodebuild test -scheme MotoMitraUITests
  artifacts:
    - screenshots/
    - test_results/
```

### Test Execution Schedule
- Unit tests: On every commit
- UI tests: On PR to main
- Full regression: Before release
- Performance tests: Weekly
- Accessibility tests: Before release

## Success Metrics

- [ ] All acceptance criteria met
- [ ] Zero critical bugs
- [ ] <5 minor bugs
- [ ] Performance targets achieved
- [ ] 80% unit test coverage
- [ ] All critical flows tested
- [ ] Accessibility compliance
- [ ] Crash-free rate >99.5%