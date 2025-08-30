#!/bin/bash

# MotoMitra iOS App Setup Script
echo "🏍️ Setting up MotoMitra iOS App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script requires macOS to run Xcode${NC}"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode is not installed. Please install Xcode from the Mac App Store${NC}"
    exit 1
fi

# Create Xcode project structure
echo -e "${GREEN}Creating Xcode project structure...${NC}"

# Create the main project directory if it doesn't exist
PROJECT_NAME="MotoMitra"
BUNDLE_ID="com.motomitra.app"

# Create Info.plist
cat > Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations~iphone</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>MotoMitra needs location access to track your rides and provide navigation. Location is only used during active rides.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>MotoMitra needs location access to track your rides and show your position on the map.</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>MotoMitra needs background location access for automatic ride detection and recording while the app is in background.</string>
    <key>NSMotionUsageDescription</key>
    <string>MotoMitra uses motion detection to automatically detect when you start riding your motorcycle.</string>
    <key>NSCameraUsageDescription</key>
    <string>MotoMitra needs camera access to scan fuel receipts and capture documents.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>MotoMitra needs photo library access to save and select receipt images.</string>
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
        <string>fetch</string>
        <string>processing</string>
    </array>
</dict>
</plist>
EOF

echo -e "${GREEN}✓ Created Info.plist${NC}"

# Create Package.swift for SPM dependencies
cat > Package.swift << 'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MotoMitra",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MotoMitra",
            targets: ["MotoMitra"])
    ],
    dependencies: [
        // Firebase
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        // Google Maps
        .package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "8.0.0"),
        // RevenueCat (optional)
        // .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "MotoMitra",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "GoogleMaps", package: "ios-maps-sdk"),
            ],
            path: "."
        )
    ]
)
EOF

echo -e "${GREEN}✓ Created Package.swift${NC}"

# Create .gitignore
cat > .gitignore << 'EOF'
# Xcode
#
# gitignore contributors: remember to update Global/Xcode.gitignore, Objective-C.gitignore & Swift.gitignore

## User settings
xcuserdata/

## compatibility with Xcode 8 and earlier (ignoring not required starting Xcode 9)
*.xcscmblueprint
*.xccheckout

## compatibility with Xcode 3 and earlier (ignoring not required starting Xcode 4)
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

## Obj-C/Swift specific
*.hmap

## App packaging
*.ipa
*.dSYM.zip
*.dSYM

## Playgrounds
timeline.xctimeline
playground.xcworkspace

# Swift Package Manager
.build/
.swiftpm/

# CocoaPods
Pods/

# Carthage
Carthage/Build/

# Firebase
GoogleService-Info.plist

# Environment
.env
*.env

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
*.xcworkspace
!default.xcworkspace
iOSInjectionProject/
EOF

echo -e "${GREEN}✓ Created .gitignore${NC}"

# Create environment template
cat > Configuration/.env.example << 'EOF'
# MotoMitra Environment Variables
# Copy this file to .env and fill in your actual values

# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Google Places API Key  
GOOGLE_PLACES_API_KEY=your_google_places_api_key_here

# Firebase Configuration (these will be in GoogleService-Info.plist)
FIREBASE_API_KEY=your_firebase_api_key_here
FIREBASE_PROJECT_ID=your_firebase_project_id_here

# RevenueCat API Key (optional)
REVENUECAT_API_KEY=your_revenuecat_api_key_here
EOF

echo -e "${GREEN}✓ Created environment template${NC}"

# Create a simple xcconfig file
cat > Configuration/Debug.xcconfig << 'EOF'
// Debug Configuration
PRODUCT_NAME = MotoMitra
PRODUCT_BUNDLE_IDENTIFIER = com.motomitra.app.debug
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG
SWIFT_OPTIMIZATION_LEVEL = -Onone
EOF

cat > Configuration/Release.xcconfig << 'EOF'
// Release Configuration  
PRODUCT_NAME = MotoMitra
PRODUCT_BUNDLE_IDENTIFIER = com.motomitra.app
SWIFT_OPTIMIZATION_LEVEL = -O
EOF

echo -e "${GREEN}✓ Created configuration files${NC}"

echo ""
echo -e "${YELLOW}📱 Next Steps to Run the App:${NC}"
echo ""
echo "1. Open Xcode and create a new project:"
echo "   - Choose 'App' template"
echo "   - Product Name: MotoMitra"
echo "   - Team: Your Apple Developer Team"
echo "   - Organization Identifier: com.motomitra"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Use Core Data: ✓"
echo "   - Include Tests: ✓"
echo ""
echo "2. Replace the generated files with the files from this workspace"
echo ""
echo "3. Add Swift Package Dependencies in Xcode:"
echo "   - File → Add Package Dependencies"
echo "   - Add Firebase: https://github.com/firebase/firebase-ios-sdk"
echo "   - Add Google Maps: Follow instructions at https://developers.google.com/maps/documentation/ios-sdk/start"
echo ""
echo "4. Configure API Keys:"
echo "   - Copy Configuration/.env.example to Configuration/.env"
echo "   - Add your Google Maps API key"
echo "   - Add GoogleService-Info.plist from Firebase Console"
echo ""
echo "5. Build and Run:"
echo "   - Select iPhone simulator (iPhone 15 recommended)"
echo "   - Press Cmd+R or click the Run button"
echo ""
echo -e "${GREEN}✅ Setup script completed!${NC}"