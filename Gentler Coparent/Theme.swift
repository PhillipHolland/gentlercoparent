import SwiftUI

// MARK: - Gentler Coparent design tokens
/// Brand palette: soft sky blue (#BADFE7) canvas, teal primary (#388083), mint accents.
enum GCPTheme {
    // Brand (classic app colors)
    static let primary = Color(hex: "388083")       // brand teal
    static let secondary = Color(hex: "6FB3B8")     // lighter teal
    static let mint = Color(hex: "C2EDCE")          // soft mint chips / selections
    static let sky = Color(hex: "BADFE7")           // signature light blue shell
    static let cream = Color(hex: "F6F6F2")         // warm paper for cards
    static let accentSoft = Color(hex: "D4E8E6")
    
    // Surfaces — chat must use sky so the light blue shows (not near-white cream)
    static let canvas = sky
    static let chatCanvas = sky
    static let cardFill = Color.white
    static let fieldFill = Color.white
    
    /// Assistant bubbles — lighter mint card on sky so contrast holds (not mint-on-sky wash)
    static let assistantBubble = Color(hex: "F2FBF6")
    static let assistantBubbleStroke = Color(hex: "388083").opacity(0.12)
    static let assistantText = Color(hex: "1C2B2C")
    
    /// User message bubbles
    static let userBubble = primary
    static let userText = Color.white
    
    /// Typing / soft chrome
    static let typingFill = Color(hex: "E3F2F4")
    
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
