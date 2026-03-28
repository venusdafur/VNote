import SwiftUI

struct CustomTitleView: View {
    let documentName: String
    let subtitle: String
    let hasUnsavedChanges: Bool
    @Binding var selectedMode: EditorMode
    let wrapsText: Bool
    let canEditDocument: Bool
    let onOpen: () -> Void
    let onSave: () -> Void
    let onFind: () -> Void
    let onWrapToggle: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(documentName)
                            .font(.system(size: 18, weight: .semibold))

                        if hasUnsavedChanges {
                            Circle()
                                .fill(.orange)
                                .frame(width: 7, height: 7)
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Button("Open", action: onOpen)
                Button("Save", action: onSave)
                    .disabled(!canEditDocument)
                Button("Find", action: onFind)
                    .disabled(!canEditDocument)
            }

            HStack(spacing: 14) {
                Picker("Mode", selection: $selectedMode) {
                    ForEach(EditorMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 340)

                Spacer()

                if selectedMode != .typingTest {
                    Button(wrapsText ? "Wrap On" : "Wrap Off", action: onWrapToggle)
                }
            }
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
