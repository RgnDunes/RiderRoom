# MotoMitra 🏍️

A comprehensive ride tracking and expense management iOS app designed specifically for Indian motorcycle enthusiasts.

## Features

### Core Functionality
- **Automatic Ride Detection**: Uses Core Motion and Location to automatically detect and record rides
- **Manual Recording Mode**: Full control over ride start/stop for users who prefer manual operation
- **Odometer Tracking**: Mandatory pre/post-ride odometer entry with reconciliation
- **Fuel Receipt OCR**: Scan fuel pump displays to automatically extract amount, litres, and price/L
- **Group Ride Rooms**: Create rooms for group trips with shared expense tracking
- **Smart Settlements**: Automatic calculation of minimal settlement transactions
- **PDF Export**: Professional ride and room reports with route maps and statistics

### India-Specific Features
- ₹ INR currency throughout
- Kilometer/liter fuel economy
- Indian fuel station brand detection (IOCL, HPCL, BPCL)
- dd-MM-yyyy date format
- Hindi language support (coming soon)

## Tech Stack

- **Platform**: iOS 17+ (Swift 5.9+, SwiftUI)
- **Architecture**: Clean Architecture + MVVM
- **Persistence**: Core Data (local), Firebase Firestore (sync)
- **Maps**: Google Maps SDK (primary), Apple Maps (fallback)
- **Auth**: Firebase Auth (Apple/Google Sign In)
- **OCR**: Apple Vision Framework
- **Charts**: Swift Charts
- **PDF**: PDFKit

## Getting Started

### Prerequisites

1. Xcode 15+
2. iOS 17+ device or simulator
3. Apple Developer account
4. Google Cloud Platform account
5. Firebase project

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourorg/motomitra.git
cd motomitra
```

2. Install dependencies:
```bash
# If using SPM, dependencies will auto-resolve
# If using CocoaPods:
pod install
```

3. Configure API keys:
```bash
cp Configuration/.env.example Configuration/.env
# Edit .env with your API keys
```

4. Add configuration files:
- Add `GoogleService-Info.plist` to the project
- Configure Google Maps API key in `Info.plist`

5. Open in Xcode:
```bash
open MotoMitra.xcworkspace
```

6. Build and run (⌘+R)

## Project Structure

```
MotoMitra/
├── App/                    # App entry point and configuration
├── Core/                   # Shared utilities and services
│   ├── DI/                # Dependency injection
│   ├── DesignSystem/      # Colors, typography, components
│   ├── Navigation/        # Navigation router
│   └── Utils/             # Extensions and helpers
├── Domain/                # Business logic
│   ├── Entities/          # Domain models
│   ├── UseCases/          # Business rules
│   └── Repositories/      # Repository protocols
├── Data/                  # Data layer
│   ├── Persistence/       # Core Data
│   ├── Network/           # Firebase, API clients
│   ├── Maps/              # Google Maps integration
│   └── OCR/               # Vision framework
├── Features/              # Feature modules
│   ├── RideRecord/        # Recording functionality
│   ├── RideRooms/         # Group features
│   ├── Expenses/          # Expense management
│   └── ...
└── Tests/                 # Test suites
```

## Key Features Implementation

### Auto Recording Mode
- Detects automotive motion via Core Motion
- Starts recording when speed > 8 km/h for 20+ seconds
- Auto-pauses when speed < 2 km/h for 60+ seconds
- Auto-ends after 8 minutes of no movement
- All automatic actions can be overridden by user

### Fuel OCR
- Uses Vision framework to extract text from fuel pump photos
- Targets: Total amount (₹), Litres (L), Price/L (₹/L)
- Automatic station brand detection
- Confidence scoring with manual correction

### Settlement Optimization
- Calculates minimal transaction set for group expenses
- Handles uneven splits, percentage splits, and exclusions
- Generates settlement plan with who-pays-whom
- Tracks settlement status and methods

## Testing

Run tests:
```bash
# Unit tests
xcodebuild test -scheme MotoMitra -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests
xcodebuild test -scheme MotoMitraUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Roadmap

- [x] Core ride recording
- [x] Group ride rooms
- [x] PDF export
- [ ] Fuel OCR implementation
- [ ] Service reminders
- [ ] Document vault
- [ ] POI discovery
- [ ] Apple Watch app
- [ ] CarPlay support

## License

Proprietary - All rights reserved

## Support

- Documentation: [docs.motomitra.app](https://docs.motomitra.app)
- Issues: [GitHub Issues](https://github.com/yourorg/motomitra/issues)
- Email: support@motomitra.app

## Acknowledgments

- Google Maps SDK for iOS
- Firebase SDK
- RevenueCat (IAP)
- The Indian motorcycling community for feedback and testing

---

Built with ❤️ for Indian riders 🏍️🇮🇳