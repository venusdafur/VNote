import AppKit
import SwiftUI

final class TextViewCoordinator: ObservableObject {
    fileprivate weak var textView: CodeTextView?
    @Published var cursorSummary = "Ln 1, Col 1"
    @Published var lineSummary = "1 line"

    func refreshText(_ text: String) {
        guard let textView, textView.string != text else {
            return
        }

        textView.string = text
        textView.applyPresentation()
        updateStatus(using: textView)
    }

    func applyMode(_ mode: EditorMode, wrapsText: Bool) {
        guard let textView else {
            return
        }

        textView.editorMode = mode
        textView.wrapsText = wrapsText
        textView.configureForCurrentMode()
        textView.applyPresentation()
        updateStatus(using: textView)
    }

    func findNext(search: String) {
        guard let textView, !search.isEmpty else {
            return
        }

        let fullText = textView.string
        let selectedRange = textView.selectedRange()
        let selectedLocation = selectedRange.location
        let searchStart = min(selectedLocation + max(selectedRange.length, 1), fullText.count)
        let searchRange = fullText.index(fullText.startIndex, offsetBy: searchStart)..<fullText.endIndex

        if let foundRange = fullText.range(of: search, options: [], range: searchRange) ?? fullText.range(of: search) {
            let nsRange = NSRange(foundRange, in: fullText)
            textView.setSelectedRange(nsRange)
            textView.scrollRangeToVisible(nsRange)
            textView.showFindIndicator(for: nsRange)
            updateStatus(using: textView)
        }
    }

    @discardableResult
    func replaceCurrent(search: String, replacement: String) -> Bool {
        guard let textView, !search.isEmpty else {
            return false
        }

        let selectedRange = textView.selectedRange()
        let current = textView.string as NSString

        if selectedRange.location != NSNotFound,
           selectedRange.location + selectedRange.length <= current.length,
           current.substring(with: selectedRange) == search {
            textView.insertText(replacement, replacementRange: selectedRange)
            textView.applyPresentation()
            updateStatus(using: textView)
            return true
        }

        findNext(search: search)
        return false
    }

    func updateStatus(using textView: NSTextView) {
        let nsText = textView.string as NSString
        let range = textView.selectedRange()
        let safeLocation = min(range.location, nsText.length)
        let prefix = nsText.substring(to: safeLocation)
        let line = max(prefix.components(separatedBy: "\n").count, 1)
        let column = (prefix.components(separatedBy: "\n").last?.count ?? 0) + 1
        let lineCount = max(nsText.components(separatedBy: "\n").count, 1)

        cursorSummary = "Ln \(line), Col \(column)"
        lineSummary = lineCount == 1 ? "1 line" : "\(lineCount) lines"
    }
}

struct CustomTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    let mode: EditorMode
    let wrapsText: Bool
    var coordinator: TextViewCoordinator

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.usesPredominantAxisScrolling = false

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        layoutManager.addTextContainer(textContainer)

        let textView = CodeTextView(frame: .zero, textContainer: textContainer)
        textView.editorMode = mode
        textView.wrapsText = wrapsText
        textView.string = text
        textView.onTextDidChange = { updatedText in
            if text != updatedText {
                text = updatedText
            }
        }
        textView.onSelectionChange = { range in
            if selectedRange != range {
                selectedRange = range
            }
            coordinator.updateStatus(using: textView)
        }

        scrollView.documentView = textView
        scrollView.hasHorizontalRuler = mode == .code
        scrollView.rulersVisible = mode == .code
        scrollView.verticalRulerView = LineNumberRulerView(scrollView: scrollView, textView: textView)

        textView.configureForCurrentMode()
        textView.applyPresentation()
        coordinator.textView = textView
        coordinator.updateStatus(using: textView)
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? CodeTextView else {
            return
        }

        textView.onTextDidChange = { updatedText in
            if text != updatedText {
                text = updatedText
            }
        }
        textView.onSelectionChange = { range in
            if selectedRange != range {
                selectedRange = range
            }
            coordinator.updateStatus(using: textView)
        }
        textView.editorMode = mode
        textView.wrapsText = wrapsText
        textView.configureForCurrentMode()

        if textView.string != text {
            textView.string = text
        }

        if textView.selectedRange() != selectedRange {
            textView.setSelectedRange(selectedRange)
        }

        nsView.hasHorizontalRuler = mode == .code
        nsView.rulersVisible = mode == .code
        if let ruler = nsView.verticalRulerView as? LineNumberRulerView {
            ruler.needsDisplay = true
        }
        coordinator.textView = textView
        textView.applyPresentation()
        coordinator.updateStatus(using: textView)
    }
}

final class CodeTextView: NSTextView {
    var editorMode: EditorMode = .text
    var wrapsText = true
    var onTextDidChange: ((String) -> Void)?
    var onSelectionChange: ((NSRange) -> Void)?
    private let indent = "    "

    override var selectedRanges: [NSValue] {
        didSet {
            onSelectionChange?(selectedRange())
            needsDisplay = true
            enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }
    }

    func configureForCurrentMode() {
        isRichText = false
        allowsUndo = true
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isAutomaticSpellingCorrectionEnabled = editorMode == .text
        isContinuousSpellCheckingEnabled = editorMode == .text
        smartInsertDeleteEnabled = editorMode == .text
        usesFindPanel = true
        drawsBackground = true
        backgroundColor = editorMode == .code ? NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.14, alpha: 1) : .textBackgroundColor
        textColor = editorMode == .code ? NSColor(calibratedWhite: 0.9, alpha: 1) : .textColor
        insertionPointColor = editorMode == .code ? NSColor.systemMint : .labelColor
        selectedTextAttributes = [
            .backgroundColor: editorMode == .code ? NSColor.systemBlue.withAlphaComponent(0.35) : NSColor.selectedTextBackgroundColor
        ]
        font = editorMode == .code
            ? .monospacedSystemFont(ofSize: 14, weight: .regular)
            : .systemFont(ofSize: 15, weight: .regular)
        textContainerInset = NSSize(width: editorMode == .code ? 18 : 16, height: 20)

        guard let textContainer else {
            return
        }

        textContainer.widthTracksTextView = wrapsText
        textContainer.containerSize = wrapsText
            ? NSSize(width: max(bounds.width, 200), height: CGFloat.greatestFiniteMagnitude)
            : NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        isHorizontallyResizable = !wrapsText
        autoresizingMask = wrapsText ? [.width] : []
        maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        isHorizontallyResizable = !wrapsText
        isVerticallyResizable = true
    }

    func applyPresentation() {
        guard let textStorage else {
            return
        }

        let selectedRange = selectedRange()
        let string = textStorage.string
        let fullRange = NSRange(location: 0, length: (string as NSString).length)
        let baseFont = font ?? .monospacedSystemFont(ofSize: 14, weight: .regular)

        textStorage.beginEditing()
        textStorage.setAttributes([
            .font: baseFont,
            .foregroundColor: editorMode == .code ? NSColor(calibratedWhite: 0.9, alpha: 1) : NSColor.textColor
        ], range: fullRange)

        if editorMode == .code {
            SyntaxHighlighter.apply(to: textStorage, baseFont: baseFont)
        }

        textStorage.endEditing()
        setSelectedRange(selectedRange)
        needsDisplay = true
        enclosingScrollView?.verticalRulerView?.needsDisplay = true
    }

    override func didChangeText() {
        super.didChangeText()
        applyPresentation()
        onTextDidChange?(string)
        onSelectionChange?(selectedRange())
    }

    override func keyDown(with event: NSEvent) {
        guard editorMode == .code else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 48 {
            insertText(indent, replacementRange: selectedRange())
            return
        }

        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty,
              let characters = event.characters else {
            super.keyDown(with: event)
            return
        }

        switch characters {
        case "{", "(", "[", "\"", "'":
            insertPair(for: characters)
        case "\r":
            insertSmartNewline()
        default:
            super.keyDown(with: event)
        }
    }

    override func drawBackground(in rect: NSRect) {
        backgroundColor.setFill()
        rect.fill()

        if editorMode == .code {
            drawCurrentLineHighlight()
        }
    }

    private func drawCurrentLineHighlight() {
        guard let layoutManager, let textContainer else {
            return
        }

        let range = selectedRange()
        let lineRange = (string as NSString).lineRange(for: range)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
        var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        lineRect.origin.x = 0
        lineRect.size.width = bounds.width
        lineRect.origin.y += textContainerInset.height
        lineRect.size.height = max(lineRect.height, font?.pointSize ?? 16 + 8)

        NSColor.systemMint.withAlphaComponent(0.08).setFill()
        lineRect.fill()
    }

    private func insertPair(for opening: String) {
        let pairs = ["{": "}", "(": ")", "[": "]", "\"": "\"", "'": "'"]
        guard let closing = pairs[opening] else {
            super.insertText(opening, replacementRange: selectedRange())
            return
        }

        let range = selectedRange()
        if range.length > 0 {
            let current = string as NSString
            let selected = current.substring(with: range)
            insertText(opening + selected + closing, replacementRange: range)
            setSelectedRange(NSRange(location: range.location + 1, length: range.length))
        } else {
            insertText(opening + closing, replacementRange: range)
            setSelectedRange(NSRange(location: range.location + 1, length: 0))
        }
    }

    private func insertSmartNewline() {
        let current = string as NSString
        let range = selectedRange()
        let location = min(range.location, current.length)
        let lineRange = current.lineRange(for: NSRange(location: location, length: 0))
        let line = current.substring(with: lineRange)
        let indentation = line.prefix { $0 == " " || $0 == "\t" }
        let previousCharacter = location > 0 ? current.substring(with: NSRange(location: location - 1, length: 1)) : ""
        let nextCharacter = location < current.length ? current.substring(with: NSRange(location: location, length: 1)) : ""

        var insertion = "\n" + indentation
        if previousCharacter == "{" {
            insertion += indent
            if nextCharacter == "}" {
                insertion += "\n" + indentation
            }
        }

        insertText(insertion, replacementRange: range)
        if previousCharacter == "{", nextCharacter == "}" {
            setSelectedRange(NSRange(location: location + indentation.count + indent.count + 1, length: 0))
        }
    }
}

enum SyntaxHighlighter {
    static func apply(to textStorage: NSTextStorage, baseFont: NSFont) {
        let string = textStorage.string
        let nsString = string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        guard fullRange.length > 0 else {
            return
        }

        applyPattern(#"(?m)//.*$"#, color: .systemGreen, to: textStorage, in: fullRange, baseFont: baseFont)
        applyPattern(#"(?s)/\*.*?\*/"#, color: .systemGreen, to: textStorage, in: fullRange, baseFont: baseFont)
        applyPattern(#""([^"\\]|\\.)*""#, color: .systemOrange, to: textStorage, in: fullRange, baseFont: baseFont)
        applyPattern(#"'([^'\\]|\\.)*'"#, color: .systemOrange, to: textStorage, in: fullRange, baseFont: baseFont)
        applyPattern(#"\b\d+(\.\d+)?\b"#, color: .systemPurple, to: textStorage, in: fullRange, baseFont: baseFont)
        applyPattern(keywordPattern, color: .systemPink, to: textStorage, in: fullRange, baseFont: baseFont, weight: .semibold)
        applyPattern(typePattern, color: .systemTeal, to: textStorage, in: fullRange, baseFont: baseFont)
    }

    private static let keywordPattern = #"\b(class|struct|enum|protocol|extension|func|let|var|if|else|switch|case|default|guard|return|import|for|while|break|continue|public|private|fileprivate|internal|open|static|final|async|await|throw|throws|try|catch|nil|true|false)\b"#
    private static let typePattern = #"\b(String|Int|Double|Bool|Void|Self|Any|Date|URL|Array|Dictionary|Set|Result)\b"#

    private static func applyPattern(
        _ pattern: String,
        color: NSColor,
        to textStorage: NSTextStorage,
        in range: NSRange,
        baseFont: NSFont,
        weight: NSFont.Weight = .regular
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return
        }

        let font = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: weight)
        regex.enumerateMatches(in: textStorage.string, range: range) { match, _, _ in
            guard let match else {
                return
            }
            textStorage.addAttributes([
                .foregroundColor: color,
                .font: font
            ], range: match.range)
        }
    }
}

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(scrollView: NSScrollView, textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        ruleThickness = 54
        clientView = textView
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return
        }

        NSColor(calibratedRed: 0.09, green: 0.1, blue: 0.12, alpha: 1).setFill()
        rect.fill()

        let relativePoint = self.convert(NSPoint.zero, from: textView)
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textContainer)
        let text = textView.string as NSString
        let lineFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: lineFont,
            .foregroundColor: NSColor(calibratedWhite: 0.55, alpha: 1)
        ]

        var glyphIndex = visibleGlyphRange.location
        var lineNumber = text.substring(to: min(layoutManager.characterIndexForGlyph(at: glyphIndex), text.length))
            .components(separatedBy: "\n")
            .count

        while glyphIndex < NSMaxRange(visibleGlyphRange) {
            let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let lineRange = text.lineRange(for: NSRange(location: characterIndex, length: 0))
            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            lineRect.origin.y += textView.textContainerInset.height
            let y = lineRect.minY + relativePoint.y

            let label = "\(lineNumber)" as NSString
            let labelSize = label.size(withAttributes: attributes)
            let x = ruleThickness - labelSize.width - 10
            label.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)

            glyphIndex = NSMaxRange(glyphRange)
            lineNumber += 1
        }
    }
}
