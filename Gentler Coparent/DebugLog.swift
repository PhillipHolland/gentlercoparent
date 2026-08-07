import Foundation

/// Lightweight logger — silent in Release so App Store builds stay clean and fast.
enum DebugLog {
    static func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        let line = items.map { "\($0)" }.joined(separator: separator)
        Swift.print(line, terminator: terminator)
        #endif
    }
}
