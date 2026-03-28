import AppKit
import Foundation

final class EditorViewModel: ObservableObject {
    struct ReplacementSummary: Equatable {
        let updatedText: String
        let replacements: Int
    }

    @Published var text = ""
    @Published var searchText = ""
    @Published var replaceText = ""
    @Published var isShowingFindAndReplace = false
    @Published var notificationMessage: String?
    @Published var currentURL: URL?
    @Published var lastSavedText = ""
    @Published var showingSavePrompt = false
    @Published var editorMode: EditorMode = .text
    @Published var wrapsText = true
    @Published var selectedRange = NSRange(location: 0, length: 0)
    @Published var typingTest = TypingTestState()

    var hasUnsavedChanges: Bool {
        text != lastSavedText
    }

    var documentName: String {
        switch editorMode {
        case .typingTest:
            "Typing Test"
        case .text, .code:
            currentURL?.lastPathComponent ?? "Untitled"
        }
    }

    var subtitle: String {
        switch editorMode {
        case .typingTest:
            "Random word sprint with live stats"
        case .text:
            currentURL?.path(percentEncoded: false) ?? "Unsaved plain-text document"
        case .code:
            currentURL?.path(percentEncoded: false) ?? "Unsaved source file"
        }
    }

    var canEditDocument: Bool {
        editorMode != .typingTest
    }

    func newDocument(window: NSWindow?) {
        guard checkUnsavedChanges(window: window) else {
            return
        }

        text = ""
        currentURL = nil
        editorMode = .text
        wrapsText = true
        markSaved()
    }

    func openDocument(window: NSWindow?) {
        guard checkUnsavedChanges(window: window) else {
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.plainText]

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try open(url: url)
        } catch {
            showError(
                title: "Unable to Open File",
                message: "'\(url.lastPathComponent)' could not be opened."
            )
        }
    }

    func open(url: URL) throws {
        let contents = try String(contentsOf: url, encoding: .utf8)
        text = contents
        currentURL = url
        editorMode = inferredMode(for: url)
        wrapsText = editorMode == .text
        markSaved()
    }

    @discardableResult
    func saveDocument(window: NSWindow?) -> Bool {
        guard canEditDocument else {
            showNotification("Typing test mode does not save files.")
            return false
        }

        if let currentURL {
            return writeDocument(to: currentURL)
        }

        return saveDocumentAs(window: window)
    }

    @discardableResult
    func saveDocumentAs(window: NSWindow?) -> Bool {
        guard canEditDocument else {
            showNotification("Typing test mode does not save files.")
            return false
        }

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = documentName
        panel.title = "Save as"
        panel.message = editorMode == .code ? "Choose where to save your code file." : "Choose where to save your note."
        panel.allowedContentTypes = [.plainText]

        guard panel.runModal() == .OK, let url = panel.url else {
            return false
        }

        return writeDocument(to: url)
    }

    func checkUnsavedChanges(window: NSWindow?) -> Bool {
        guard canEditDocument else {
            return true
        }

        guard hasUnsavedChanges else {
            return true
        }

        let alert = NSAlert()
        alert.messageText = "Do you want to save the changes made to this document?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        showingSavePrompt = true
        let response = alert.runModal()
        showingSavePrompt = false

        switch response {
        case .alertFirstButtonReturn:
            return saveDocument(window: window)
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    func markSaved() {
        lastSavedText = text
    }

    func showNotification(_ message: String) {
        notificationMessage = message

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            if self?.notificationMessage == message {
                self?.notificationMessage = nil
            }
        }
    }

    func showFind() {
        guard canEditDocument else {
            return
        }
        isShowingFindAndReplace = true
    }

    func hideFind() {
        isShowingFindAndReplace = false
    }

    func replaceAll() {
        let result = Self.replaceAllOccurrences(of: searchText, with: replaceText, in: text)
        guard result.replacements > 0 else {
            return
        }

        text = result.updatedText
        showNotification("Replaced!")
    }

    func setMode(_ mode: EditorMode) {
        editorMode = mode
        if mode == .typingTest {
            hideFind()
        } else if mode == .text {
            wrapsText = true
        } else if mode == .code {
            wrapsText = false
        }
    }

    func toggleWrapsText() {
        wrapsText.toggle()
    }

    func toggleCommentSelection() {
        guard editorMode == .code else {
            return
        }

        let nsText = text as NSString
        let safeLocation = min(selectedRange.location, nsText.length)
        let safeLength = min(selectedRange.length, nsText.length - safeLocation)
        let effectiveRange = nsText.lineRange(for: NSRange(location: safeLocation, length: safeLength))
        let lines = nsText.substring(with: effectiveRange).components(separatedBy: .newlines)
        let shouldUncomment = lines
            .filter { !$0.isEmpty }
            .allSatisfy { $0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }

        let updatedLines = lines.map { line -> String in
            guard !line.isEmpty else {
                return line
            }

            let indentation = line.prefix { $0 == " " || $0 == "\t" }
            let remainder = String(line.dropFirst(indentation.count))
            if shouldUncomment, remainder.hasPrefix("//") {
                return String(indentation) + String(remainder.dropFirst(2)).trimmingPrefix(" ")
            }

            return String(indentation) + "// " + remainder
        }

        text = nsText.replacingCharacters(in: effectiveRange, with: updatedLines.joined(separator: "\n"))
    }

    func resetTypingTest() {
        let kind = typingTest.kind
        let selectedDuration = typingTest.selectedDuration
        let selectedWordTarget = typingTest.selectedWordTarget
        typingTest = TypingTestState(
            kind: kind,
            selectedDuration: selectedDuration,
            selectedWordTarget: selectedWordTarget,
            promptWords: RandomWordBank.makePrompt(wordCount: promptWordCount(for: kind, selectedWordTarget: selectedWordTarget))
        )
    }

    func updateTypingInput(_ value: String) {
        guard editorMode == .typingTest else {
            return
        }

        let normalized = value.replacingOccurrences(of: "\n", with: "")

        if typingTest.startedAt == nil, !normalized.isEmpty {
            typingTest.startedAt = Date()
        }

        typingTest.currentInput = normalized
        if typingTest.kind == .time, typingTest.remaining <= 0 {
            typingTest.finishedAt = typingTest.finishedAt ?? Date()
        }
    }

    func commitTypingWord() {
        guard editorMode == .typingTest, !typingTest.isFinished else {
            return
        }

        let trimmed = typingTest.currentInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return
        }

        if typingTest.startedAt == nil {
            typingTest.startedAt = Date()
        }

        if typingTest.enteredWords.count < typingTest.promptWords.count {
            typingTest.enteredWords.append(trimmed)
        }
        typingTest.currentInput = ""

        if typingTest.kind == .words, typingTest.enteredWords.count >= typingTest.selectedWordTarget {
            typingTest.finishedAt = typingTest.finishedAt ?? Date()
        }

        if typingTest.kind == .time, typingTest.remaining <= 0 {
            typingTest.finishedAt = typingTest.finishedAt ?? Date()
        }
    }

    func tickTypingTest() {
        guard typingTest.startedAt != nil, typingTest.finishedAt == nil else {
            return
        }

        if typingTest.kind == .time, typingTest.remaining <= 0 {
            typingTest.finishedAt = Date()
        }
    }

    func setTypingTestKind(_ kind: TypingTestKind) {
        typingTest.kind = kind
        resetTypingTest()
    }

    func setTypingDuration(_ seconds: Int) {
        typingTest.selectedDuration = min(max(seconds, 15), 3600)
        if typingTest.kind == .time {
            resetTypingTest()
        }
    }

    func setTypingWordTarget(_ count: Int) {
        typingTest.selectedWordTarget = min(max(count, 10), 5000)
        if typingTest.kind == .words {
            resetTypingTest()
        }
    }

    static func replaceAllOccurrences(of searchText: String, with replaceText: String, in text: String) -> ReplacementSummary {
        guard !searchText.isEmpty else {
            return ReplacementSummary(updatedText: text, replacements: 0)
        }

        let parts = text.components(separatedBy: searchText)
        let replacements = max(parts.count - 1, 0)
        let updatedText = parts.joined(separator: replaceText)
        return ReplacementSummary(updatedText: updatedText, replacements: replacements)
    }

    @discardableResult
    private func writeDocument(to url: URL) -> Bool {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            currentURL = url
            markSaved()
            return true
        } catch {
            showError(
                title: "Unable to Save File",
                message: "The file could not be saved."
            )
            return false
        }
    }

    private func showError(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }

    private func inferredMode(for url: URL) -> EditorMode {
        let codeExtensions: Set<String> = [
            "c", "cc", "cpp", "cs", "css", "go", "h", "hpp", "html", "java", "js",
            "json", "kt", "m", "md", "php", "py", "rb", "rs", "sh", "sql", "swift",
            "ts", "tsx", "xml", "yaml", "yml"
        ]
        return codeExtensions.contains(url.pathExtension.lowercased()) ? .code : .text
    }

    private func promptWordCount(for kind: TypingTestKind, selectedWordTarget: Int) -> Int {
        switch kind {
        case .time:
            return 5000
        case .words:
            return min(max(selectedWordTarget, 25), 5000)
        }
    }
}

private extension String {
    func trimmingPrefix(_ prefix: Character) -> String {
        guard first == prefix else {
            return self
        }
        return String(dropFirst())
    }
}
