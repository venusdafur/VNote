import Foundation

enum EditorMode: String, CaseIterable, Identifiable {
    case text
    case code
    case typingTest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: "Text"
        case .code: "Code"
        case .typingTest: "Typing Test"
        }
    }

    var subtitle: String {
        switch self {
        case .text: "Plain writing"
        case .code: "Syntax-aware editor"
        case .typingTest: "Random word sprint"
        }
    }
}
