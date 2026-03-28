import SwiftUI

struct FindAndReplaceView: View {
    @Binding var searchText: String
    @Binding var replaceText: String
    let onFindNext: () -> Void
    let onReplace: () -> Void
    let onReplaceAll: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            StyledSearchTextField("Find", text: $searchText)
                .frame(maxWidth: 220)

            StyledTextField("Replace", text: $replaceText)
                .frame(maxWidth: 220)

            Button("Find", action: onFindNext)
                .buttonStyle(.borderedProminent)

            Button("Replace", action: onReplace)
                .buttonStyle(ReplaceButtonStyle())

            Button("Replace All", action: onReplaceAll)
                .buttonStyle(ReplaceButtonStyle())

            Spacer(minLength: 0)

            Button("Done", action: onClose)
                .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .underPageBackgroundColor))
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct ReplaceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: configuration.isPressed ? .selectedControlColor.withAlphaComponent(0.6) : .selectedControlColor.withAlphaComponent(0.25)))
            )
    }
}

struct StyledTextField: NSViewRepresentable {
    private let placeholder: String
    @Binding private var text: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        _text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = placeholder
        field.delegate = context.coordinator
        field.isBordered = false
        field.focusRingType = .none
        field.backgroundColor = .clear
        field.font = .systemFont(ofSize: 13, weight: .medium)
        field.lineBreakMode = .byTruncatingTail
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else {
                return
            }

            text = field.stringValue
        }
    }
}

struct StyledSearchTextField: NSViewRepresentable {
    private let placeholder: String
    @Binding private var text: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        _text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = placeholder
        field.delegate = context.coordinator
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 13, weight: .medium)
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSSearchField else {
                return
            }

            text = field.stringValue
        }
    }
}
