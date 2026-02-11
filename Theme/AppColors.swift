import SwiftUI

struct AppColors {
    // Primary brand colors
    static let sageGreen = Color(hex: "7D9B76")
    static let warmCream = Color(hex: "FDF8F3")
    static let softTerracotta = Color(hex: "D4A574")
    static let deepForest = Color(hex: "2D4739")
    static let mutedGold = Color(hex: "C9B896")

    // Semantic colors
    static let primary = sageGreen
    static let background = warmCream
    static let accent = softTerracotta
    static let text = deepForest
    static let highlight = mutedGold

    // UI variants
    static let cardBackground = Color.white
    static let completedGreen = Color(hex: "4CAF50")
    static let streakGold = Color(hex: "FFD700")

    // Gradient backgrounds
    static var gradientBackground: some View {
        LinearGradient(
            colors: [sageGreen, deepForest],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var onboardingGradient: some View {
        LinearGradient(
            colors: [sageGreen.opacity(0.9), deepForest.opacity(0.95)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

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
}
