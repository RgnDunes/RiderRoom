# How to Run MotoMitra iOS App

## 🚀 Quick Start (Simulator Only)

If you just want to see the app running quickly without full setup:

### Prerequisites
- Mac with macOS 12+ 
- Xcode 15+ (free from Mac App Store)
- ~10GB free disk space

### Steps

1. **Open Xcode**
   - Launch Xcode
   - Select "Create New Project"
   - Choose "iOS" → "App"
   - Configure:
     - Product Name: `MotoMitra`
     - Team: None (for simulator testing)
     - Organization Identifier: `com.motomitra`
     - Interface: `SwiftUI`
     - Language: `Swift`
     - Use Core Data: ✓
     - Include Tests: ✓

2. **Copy Project Files**
   ```bash
   # In Terminal, navigate to your new Xcode project folder
   cd ~/path/to/your/MotoMitra
   
   # Copy all Swift files from this workspace
   cp -r /workspace/MotoMitra/* .
   ```

3. **Add Mock Configuration**
   - In Xcode, create a new Swift file: `Configuration.swift`
   - Add this mock configuration:
   ```swift
   struct Configuration {
       static let googleMapsAPIKey: String? = "MOCK_KEY"
       static let googlePlacesAPIKey: String? = "MOCK_KEY" 
       static let firebaseAPIKey: String? = "MOCK_KEY"
   }
   ```

4. **Disable External Dependencies (Temporary)**
   - Comment out Firebase imports in `MotoMitraApp.swift`
   - Comment out Google Maps imports in `GoogleMapsClient.swift`
   - The app will run with mock data

5. **Run the App**
   - Select iPhone 15 Pro simulator from the device dropdown
   - Press `Cmd + R` or click the ▶️ Run button
   - The app will build and launch in the simulator

## 📱 Full Setup (With All Features)

For complete functionality including maps, authentication, and OCR:

### 1. Prerequisites

- **Mac with Xcode 15+**
- **Apple Developer Account** (free for simulator, $99/year for device)
- **Google Cloud Account** (for Maps API)
- **Firebase Account** (free tier available)

### 2. Project Setup

1. **Create Xcode Project** (as above)

2. **Install Dependencies**

   Using Swift Package Manager in Xcode:
   - File → Add Package Dependencies
   - Add Firebase:
     ```
     https://github.com/firebase/firebase-ios-sdk
     ```
     Select: FirebaseAuth, FirebaseFirestore, FirebaseStorage
   
   - For Google Maps (requires CocoaPods):
     ```bash
     # Install CocoaPods if needed
     sudo gem install cocoapods
     
     # In project directory
     pod init
     
     # Edit Podfile and add:
     pod 'GoogleMaps'
     pod 'GooglePlaces'
     
     # Install
     pod install
     
     # Open .xcworkspace file instead of .xcodeproj
     ```

### 3. Configure API Keys

1. **Google Maps**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create new project or select existing
   - Enable APIs: Maps SDK for iOS, Places API
   - Create API key with iOS restrictions
   - Add to `Info.plist`:
     ```xml
     <key>GMSApiKey</key>
     <string>YOUR_GOOGLE_MAPS_KEY</string>
     ```

2. **Firebase**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create new project
   - Add iOS app with bundle ID: `com.motomitra.app`
   - Download `GoogleService-Info.plist`
   - Drag into Xcode project root

3. **Update Configuration.swift**
   ```swift
   struct Configuration {
       static let googleMapsAPIKey = "YOUR_ACTUAL_KEY"
       static let googlePlacesAPIKey = "YOUR_ACTUAL_KEY"
       static let firebaseAPIKey = "AUTO_FROM_PLIST"
   }
   ```

### 4. Permissions Setup

Add to `Info.plist`:
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>MotoMitra needs location access to track your rides even when the app is in background.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>MotoMitra needs location access to track your rides.</string>

<key>NSMotionUsageDescription</key>
<string>MotoMitra uses motion detection to automatically detect rides.</string>

<key>NSCameraUsageDescription</key>
<string>MotoMitra needs camera access to scan fuel receipts.</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
</array>
```

### 5. Run the App

1. **Select Target Device**
   - Simulator: Choose iPhone 15 Pro or any iOS 17+ device
   - Real Device: Connect iPhone, trust computer, select device

2. **Build and Run**
   - Press `Cmd + R` or click Run button
   - First build may take 2-5 minutes

## 🧪 Testing the App

### Simulator Testing

1. **Test Ride Recording**
   - Click "Start Ride" on home screen
   - In simulator: Debug → Location → Freeway Drive
   - This simulates movement for testing auto-detection

2. **Test Manual Recording**
   - Switch to Manual mode in settings
   - Tap Start Recording
   - Enter odometer: 15000
   - Let it run for a minute
   - Stop and enter end odometer: 15010

3. **Test OCR (Fuel Scanning)**
   - Go to Expenses tab
   - Tap + button
   - Select "Fuel"
   - Tap "Scan Receipt"
   - Simulator: Will use mock data

4. **Test Ride Rooms**
   - Go to Rooms tab
   - Create new room
   - Add mock expenses
   - View settlements

### Real Device Testing

1. **Enable Developer Mode**
   - Settings → Privacy & Security → Developer Mode → ON
   - Restart device

2. **Trust Developer Certificate**
   - After first install: Settings → General → VPN & Device Management
   - Trust your developer certificate

3. **Test Real Features**
   - Actual GPS tracking works
   - Motion detection works
   - Camera OCR works
   - Background recording works

## 🐛 Troubleshooting

### Common Issues

1. **"No such module 'Firebase'"**
   - Solution: Add Firebase package dependency in Xcode
   - File → Add Package Dependencies → Add Firebase URL

2. **"GoogleMaps not found"**
   - Solution: Use CocoaPods to install Google Maps
   - Run `pod install` and open `.xcworkspace`

3. **Location not working in simulator**
   - Solution: Debug → Location → Choose a simulation
   - Or: Features → Location → Custom Location

4. **App crashes on launch**
   - Check: GoogleService-Info.plist is added
   - Check: Info.plist has all required keys
   - Check: Bundle identifier matches Firebase config

5. **OCR not working**
   - Simulator: OCR will return mock data
   - Device: Ensure camera permission granted

### Running Without External Services

To run the app without setting up Firebase/Google Maps:

1. Create `MockMode.swift`:
```swift
// Set this to true to run without external services
let MOCK_MODE = true

// Mock location manager
class MockLocationManager: LocationManager {
    override func startHighAccuracyUpdates() {
        // Simulate location updates
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Update with mock location
        }
    }
}

// Use in Container.swift:
if MOCK_MODE {
    registerSingleton(LocationManager.self) { MockLocationManager() }
}
```

2. The app will run with:
   - Mock ride data from `SampleDataGenerator`
   - Simulated location updates
   - Mock OCR results
   - Local-only storage (no sync)

## 📊 Verifying the App Works

Once running, verify these features:

✅ **Home Screen** displays with Start Ride button
✅ **Recording View** shows map and metrics
✅ **Pre-Ride Sheet** appears and requires odometer
✅ **Post-Ride Sheet** shows summary and requires end odometer
✅ **Expenses** can be added with mock OCR
✅ **Ride Rooms** can be created with mock data
✅ **Settings** shows recording mode toggle

## 🎯 Next Steps

1. **For Development**
   - Set up actual API keys
   - Configure Firebase project
   - Test on real device
   - Implement remaining features

2. **For Testing**
   - Run unit tests: `Cmd + U`
   - Run UI tests: `Cmd + Shift + U`
   - Check test coverage: Enable in scheme settings

3. **For Distribution**
   - Set up provisioning profiles
   - Configure app signing
   - Archive for TestFlight
   - Submit to App Store

## 📚 Resources

- [Xcode Documentation](https://developer.apple.com/xcode/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Google Maps iOS Guide](https://developers.google.com/maps/documentation/ios-sdk)

## 💡 Tips

- Use Xcode Previews for quick UI iteration: `Cmd + Option + P`
- Use Xcode Console for debug output: `Cmd + Shift + Y`
- Test different iPhone sizes using simulator device menu
- Use Network Link Conditioner to test poor connectivity
- Enable Dark Mode in simulator: Settings → Developer → Dark Appearance

---

**Need Help?** 
- Check the [ARCHITECTURE.md](./ARCHITECTURE.md) for code structure
- Review [TestPlan.md](./Tests/TestPlan.md) for testing scenarios
- See [EXECUTION_PLAN.md](./EXECUTION_PLAN.md) for feature roadmap