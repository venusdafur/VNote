import SwiftUI

struct ContentView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    @StateObject private var textViewCoordinator = TextViewCoordinator()
    @State private var nsWindow: NSWindow?
    @State private var windowDelegate: WindowDelegate?

    var body: some View {
        VStack(spacing: 0) {
            CustomTitleView(
                documentName: editorViewModel.documentName,
                subtitle: editorViewModel.subtitle,
                hasUnsavedChanges: editorViewModel.hasUnsavedChanges && editorViewModel.canEditDocument,
                selectedMode: $editorViewModel.editorMode,
                wrapsText: editorViewModel.wrapsText,
                canEditDocument: editorViewModel.canEditDocument,
                onOpen: { editorViewModel.openDocument(window: nsWindow) },
                onSave: { _ = editorViewModel.saveDocument(window: nsWindow) },
                onFind: { editorViewModel.showFind() },
                onWrapToggle: { editorViewModel.toggleWrapsText() }
            )

            if editorViewModel.isShowingFindAndReplace {
                FindAndReplaceView(
                    searchText: $editorViewModel.searchText,
                    replaceText: $editorViewModel.replaceText,
                    onFindNext: { textViewCoordinator.findNext(search: editorViewModel.searchText) },
                    onReplace: {
                        if textViewCoordinator.replaceCurrent(
                            search: editorViewModel.searchText,
                            replacement: editorViewModel.replaceText
                        ) {
                            editorViewModel.showNotification("Replaced!")
                        }
                    },
                    onReplaceAll: {
                        editorViewModel.replaceAll()
                        textViewCoordinator.refreshText(editorViewModel.text)
                    },
                    onClose: { editorViewModel.hideFind() }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            ZStack(alignment: .topTrailing) {
                Group {
                    switch editorViewModel.editorMode {
                    case .text, .code:
                        CustomTextView(
                            text: $editorViewModel.text,
                            selectedRange: $editorViewModel.selectedRange,
                            mode: editorViewModel.editorMode,
                            wrapsText: editorViewModel.wrapsText,
                            coordinator: textViewCoordinator
                        )
                    case .typingTest:
                        TypingTestView(editorViewModel: editorViewModel)
                    }
                }

                if let notification = editorViewModel.notificationMessage {
                    NotificationView(message: notification)
                        .padding(16)
                }
            }

            StatusBarView(
                mode: editorViewModel.editorMode,
                wrapsText: editorViewModel.wrapsText,
                cursorSummary: textViewCoordinator.cursorSummary,
                lineSummary: textViewCoordinator.lineSummary,
                typingSummary: typingSummary
            )
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.snappy(duration: 0.18), value: editorViewModel.isShowingFindAndReplace)
        .background(WindowAccessor(window: $nsWindow))
        .focusedSceneValue(\.editorViewModel, editorViewModel)
        .onChange(of: editorViewModel.text) {
            textViewCoordinator.refreshText(editorViewModel.text)
        }
        .onChange(of: editorViewModel.editorMode) {
            editorViewModel.setMode(editorViewModel.editorMode)
            textViewCoordinator.applyMode(editorViewModel.editorMode, wrapsText: editorViewModel.wrapsText)
            textViewCoordinator.refreshText(editorViewModel.text)
        }
        .onChange(of: editorViewModel.wrapsText) {
            textViewCoordinator.applyMode(editorViewModel.editorMode, wrapsText: editorViewModel.wrapsText)
        }
        .onChange(of: nsWindow) {
            guard let nsWindow else {
                return
            }

            let delegate = WindowDelegate(editorViewModel: editorViewModel)
            nsWindow.delegate = delegate
            windowDelegate = delegate
        }
        .onAppear {
            editorViewModel.setMode(editorViewModel.editorMode)
            textViewCoordinator.refreshText(editorViewModel.text)
        }
    }

    private var typingSummary: String {
        let test = editorViewModel.typingTest
        return "\(Int(test.remaining))s left  \(test.wordsPerMinute) WPM  \(test.accuracy)% accuracy"
    }
}

struct EditorCommands: Commands {
    @FocusedValue(\.editorViewModel) private var focusedEditorViewModel
    let editorViewModel: EditorViewModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New") {
                activeEditor.newDocument(window: NSApp.keyWindow)
            }
            .keyboardShortcut("n")

            Button("Open…") {
                activeEditor.openDocument(window: NSApp.keyWindow)
            }
            .keyboardShortcut("o")

            Button("Save…") {
                _ = activeEditor.saveDocument(window: NSApp.keyWindow)
            }
            .keyboardShortcut("s")

            Button("Save As…") {
                _ = activeEditor.saveDocumentAs(window: NSApp.keyWindow)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }

        CommandMenu("Mode") {
            ForEach(EditorMode.allCases) { mode in
                Button(mode.title) {
                    activeEditor.setMode(mode)
                }
                .keyboardShortcut(mode.shortcutKey, modifiers: [.command, .option])
            }

            Divider()

            Button("Toggle Wrap") {
                activeEditor.toggleWrapsText()
            }
            .keyboardShortcut("w", modifiers: [.command, .option])
            .disabled(activeEditor.editorMode == .typingTest)
        }

        CommandMenu("Find") {
            Button("Find") {
                activeEditor.showFind()
            }
            .keyboardShortcut("f")
            .disabled(!activeEditor.canEditDocument)
        }

        CommandMenu("Code") {
            Button("Toggle Comment") {
                activeEditor.toggleCommentSelection()
            }
            .keyboardShortcut("/", modifiers: [.command])
            .disabled(activeEditor.editorMode != .code)
        }
    }

    private var activeEditor: EditorViewModel {
        focusedEditorViewModel ?? editorViewModel
    }
}

private struct EditorViewModelFocusedValueKey: FocusedValueKey {
    typealias Value = EditorViewModel
}

extension FocusedValues {
    var editorViewModel: EditorViewModel? {
        get { self[EditorViewModelFocusedValueKey.self] }
        set { self[EditorViewModelFocusedValueKey.self] = newValue }
    }
}

private extension EditorMode {
    var shortcutKey: KeyEquivalent {
        switch self {
        case .text: "1"
        case .code: "2"
        case .typingTest: "3"
        }
    }
}
