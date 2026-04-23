import SwiftUI

enum JALTheme {
    // Crane red — JAL's signature
    static let crane     = Color(red: 0.90, green: 0.00, blue: 0.07)
    static let craneDark = Color(red: 0.66, green: 0.00, blue: 0.05)
    static let craneSoft = Color(red: 1.00, green: 0.94, blue: 0.94)

    // Neutrals
    static let ink       = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let inkSoft   = Color(red: 0.36, green: 0.38, blue: 0.42)
    static let line      = Color(red: 0.89, green: 0.90, blue: 0.92)
    static let mist      = Color(red: 0.965, green: 0.965, blue: 0.975)
    static let card      = Color.white

    // Accents
    static let gold      = Color(red: 0.83, green: 0.69, blue: 0.22)
    static let success   = Color(red: 0.16, green: 0.65, blue: 0.42)
    static let warning   = Color(red: 0.95, green: 0.62, blue: 0.18)
    static let sky       = Color(red: 0.42, green: 0.72, blue: 0.95)

    static let craneGradient = LinearGradient(
        colors: [crane, craneDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let dawnGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.83, blue: 0.61),
            Color(red: 0.96, green: 0.50, blue: 0.50),
            Color(red: 0.51, green: 0.36, blue: 0.69)
        ],
        startPoint: .top, endPoint: .bottom
    )

    static let nightGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.08, blue: 0.20),
            Color(red: 0.13, green: 0.16, blue: 0.34)
        ],
        startPoint: .top, endPoint: .bottom
    )
}

extension Font {
    static func jal(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func jalMono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension View {
    func jalCard(padding: CGFloat = 20, radius: CGFloat = 24) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(JALTheme.card)
                    .shadow(color: JALTheme.ink.opacity(0.06), radius: 18, x: 0, y: 8)
            )
    }
}
