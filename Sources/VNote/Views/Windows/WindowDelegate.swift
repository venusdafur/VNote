import AppKit

final class WindowDelegate: NSObject, NSWindowDelegate {
    weak var editorViewModel: EditorViewModel?

    init(editorViewModel: EditorViewModel?) {
        self.editorViewModel = editorViewModel
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        editorViewModel?.checkUnsavedChanges(window: sender) ?? true
    }
}
