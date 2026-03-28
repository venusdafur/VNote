import Testing
@testable import VNote

@Test
func replacingAllMatchesReturnsExpectedCount() {
    let result = EditorViewModel.replaceAllOccurrences(
        of: "note",
        with: "page",
        in: "note taking note"
    )

    #expect(result.updatedText == "page taking page")
    #expect(result.replacements == 2)
}

@Test
func documentNameFallsBackForUntitledDocuments() {
    let model = EditorViewModel()

    #expect(model.documentName == "Untitled")
}

@Test
func typingTestResetCreatesNewPrompt() {
    let model = EditorViewModel()
    let original = model.typingTest.promptWords

    model.resetTypingTest()

    #expect(model.typingTest.promptWords.count == 35)
    #expect(model.typingTest.promptWords != original || model.typingTest.promptWords.count == original.count)
}
