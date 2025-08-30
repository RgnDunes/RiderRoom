import SwiftUI

/// Central design system for MotoMitra
enum DesignSystem {
    
    // MARK: - Colors
    enum Colors {
        // Primary palette
        static let primary = Color("PrimaryColor", bundle: .main)
            .defaulting(to: Color(hex: "FF6B35")) // Saffron orange
        static let primaryDark = Color("PrimaryDarkColor", bundle: .main)
            .defaulting(to: Color(hex: "E85A2C"))
        static let primaryLight = Color("PrimaryLightColor", bundle: .main)
            .defaulting(to: Color(hex: "FF8F66"))
        
        // Secondary palette
        static let secondary = Color("SecondaryColor", bundle: .main)
            .defaulting(to: Color(hex: "1E3A8A")) // Deep blue
        static let secondaryDark = Color("SecondaryDarkColor", bundle: .main)
            .defaulting(to: Color(hex: "172554"))
        static let secondaryLight = Color("SecondaryLightColor", bundle: .main)
            .defaulting(to: Color(hex: "3B82F6"))
        
        // Semantic colors
        static let success = Color(hex: "10B981")
        static let warning = Color(hex: "F59E0B")
        static let error = Color(hex: "EF4444")
        static let info = Color(hex: "3B82F6")
        
        // Background colors
        static let background = Color("BackgroundColor", bundle: .main)
            .defaulting(to: Color(hex: "0F0F0F"))
        static let surface = Color("SurfaceColor", bundle: .main)
            .defaulting(to: Color(hex: "1A1A1A"))
        static let surfaceElevated = Color("SurfaceElevatedColor", bundle: .main)
            .defaulting(to: Color(hex: "242424"))
        
        // Text colors
        static let textPrimary = Color("TextPrimaryColor", bundle: .main)
            .defaulting(to: Color(hex: "FFFFFF"))
        static let textSecondary = Color("TextSecondaryColor", bundle: .main)
            .defaulting(to: Color(hex: "A3A3A3"))
        static let textTertiary = Color("TextTertiaryColor", bundle: .main)
            .defaulting(to: Color(hex: "737373"))
        
        // Special colors
        static let fuel = Color(hex: "FCD34D") // Fuel yellow
        static let food = Color(hex: "FB923C") // Food orange
        static let hotel = Color(hex: "8B5CF6") // Hotel purple
        static let toll = Color(hex: "06B6D4") // Toll cyan
        static let other = Color(hex: "6B7280") // Other gray
    }
    
    // MARK: - Typography
    enum Typography {
        // Display
        static let displayLarge = Font.system(size: 57, weight: .regular, design: .rounded)
        static let displayMedium = Font.system(size: 45, weight: .regular, design: .rounded)
        static let displaySmall = Font.system(size: 36, weight: .regular, design: .rounded)
        
        // Headline
        static let headlineLarge = Font.system(size: 32, weight: .semibold, design: .default)
        static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .default)
        static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)
        
        // Title
        static let titleLarge = Font.system(size: 22, weight: .medium, design: .default)
        static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
        static let titleSmall = Font.system(size: 14, weight: .medium, design: .default)
        
        // Body
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // Label
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
        
        // Special
        static let monospace = Font.system(size: 14, weight: .regular, design: .monospaced)
        static let odometer = Font.system(size: 48, weight: .bold, design: .monospaced)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let xxxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let none: CGFloat = 0
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
    }
    
    // MARK: - Elevation (Shadows)
    enum Elevation {
        static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
        static let sm = Shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        static let md = Shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        static let lg = Shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        static let xl = Shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
        
        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animation
    enum Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // MARK: - Icons
    enum Icons {
        // Navigation
        static let home = "house.fill"
        static let ride = "location.circle.fill"
        static let expense = "indianrupeesign.circle.fill"
        static let vehicle = "car.fill"
        static let insights = "chart.line.uptrend.xyaxis"
        static let settings = "gearshape.fill"
        
        // Actions
        static let add = "plus.circle.fill"
        static let edit = "pencil.circle.fill"
        static let delete = "trash.fill"
        static let share = "square.and.arrow.up"
        static let scan = "camera.viewfinder"
        static let search = "magnifyingglass"
        
        // Categories
        static let fuel = "fuelpump.fill"
        static let food = "fork.knife"
        static let hotel = "bed.double.fill"
        static let toll = "road.lanes"
        static let other = "ellipsis.circle.fill"
        
        // Status
        static let success = "checkmark.circle.fill"
        static let warning = "exclamationmark.triangle.fill"
        static let error = "xmark.circle.fill"
        static let info = "info.circle.fill"
        
        // Misc
        static let odometer = "speedometer"
        static let map = "map.fill"
        static let group = "person.3.fill"
        static let document = "doc.fill"
        static let pdf = "doc.richtext.fill"
        static let location = "location.fill"
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func defaulting(to defaultColor: Color) -> Color {
        return self
    }
}