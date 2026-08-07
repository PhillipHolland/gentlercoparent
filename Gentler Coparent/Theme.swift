import SwiftUI

// MARK: - Gentler Coparent design tokens
/// OG: sky-blue frame (#BADFE7) + cream chat paper (#F6F6F2) + mint AI bubbles (#C2EDCE).
enum GCPTheme {
    // Brand
    static let primary = Color(hex: "388083")       // brand teal
    static let secondary = Color(hex: "6FB3B8")
    static let mint = Color(hex: "C2EDCE")          // AI bubbles / chips
    static let sky = Color(hex: "BADFE7")           // BLUE FRAMING — outer shell, never remove
    static let cream = Color(hex: "F6F6F2")         // cream chat paper (message column only)
    static let accentSoft = Color(hex: "D4E8E6")
    
    // Surfaces
    static let canvas = sky                         // app chrome / blue frame
    static let chatFrame = sky                      // alias: outer chat tab blue
    static let chatCanvas = cream                   // message paper inside the blue frame
    static let cardFill = Color.white
    static let fieldFill = Color.white
    
    /// Assistant — mint on cream (OG)
    static let assistantBubble = mint
    static let assistantBubbleStroke = Color.clear
    static let assistantText = Color(hex: "1C2B2C")
    
    /// User — teal
    static let userBubble = primary
    static let userText = Color.white
    
    static let typingFill = Color(hex: "EEF4F1")
    
    /// Side inset so sky blue peeks around the cream message card
    static let chatFrameInset: CGFloat = 10
    
    // Typography (custom fonts OK per product preference)
    static func title(_ size: CGFloat = 18) -> Font {
        .custom("Avenir-Heavy", size: size)
    }
    static func body(_ size: CGFloat = 16) -> Font {
        .custom("Avenir-Book", size: size)
    }
    static func bodyMedium(_ size: CGFloat = 14) -> Font {
        .custom("Avenir-Medium", size: size)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .custom("Avenir-Book", size: size)
    }
    
    // Radii
    static let radiusChip: CGFloat = 16
    static let radiusField: CGFloat = 22
    static let radiusBubble: CGFloat = 18
    static let radiusCard: CGFloat = 20
    
    // Spacing
    static let spaceXS: CGFloat = 4
    static let spaceS: CGFloat = 8
    static let spaceM: CGFloat = 12
    static let spaceL: CGFloat = 16
    static let spaceXL: CGFloat = 24
}

// MARK: - App root tabs (Learning hidden for now; Settings in tab bar)
enum GCPTab: Hashable {
    case chat
    case journal
    case bookmarks
    case history
    case settings
}

// MARK: - Shared format helpers (fresh instances avoid concurrency warnings)
enum GCPFormatters {
    static func shortDateTimeString(_ date: Date) -> String {
        date.formatted(date: .numeric, time: .shortened)
    }
    
    static func relativeString(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }
}
