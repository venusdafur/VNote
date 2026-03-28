import SwiftUI

struct StatusBarView: View {
    let mode: EditorMode
    let wrapsText: Bool
    let cursorSummary: String
    let lineSummary: String
    let typingSummary: String

    var body: some View {
        HStack(spacing: 14) {
            Label(mode.title, systemImage: iconName)
            Text(mode == .typingTest ? typingSummary : lineSummary)
            Spacer()
            if mode != .typingTest {
                Text(wrapsText ? "Wrap On" : "Wrap Off")
                Text(cursorSummary)
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private var iconName: String {
        switch mode {
        case .text: "doc.text"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .typingTest: "timer"
        }
    }
}
