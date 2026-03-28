import SwiftUI

struct TypingTestView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @FocusState private var inputFocused: Bool
    @State private var inputBuffer = ""

    var body: some View {
        let test = editorViewModel.typingTest

        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Random Word Typing Test")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Type through the prompt as fast as you can. Stats update live, then freeze at the end of the round.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                metricCard(title: test.kind == .time ? "Time" : "Words", value: progressValue(test))
                metricCard(title: "WPM", value: "\(test.wordsPerMinute)")
                metricCard(title: "Accuracy", value: "\(test.accuracy)%")
            }

            HStack(spacing: 12) {
                Picker("Test Type", selection: Binding(
                    get: { test.kind },
                    set: { editorViewModel.setTypingTestKind($0); inputBuffer = ""; inputFocused = true }
                )) {
                    ForEach(TypingTestKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)

                if test.kind == .time {
                    Picker("Duration", selection: Binding(
                        get: { test.selectedDuration },
                        set: { editorViewModel.setTypingDuration($0); inputBuffer = ""; inputFocused = true }
                    )) {
                        ForEach([15, 30, 60, 120, 300, 600, 1800, 3600], id: \.self) { seconds in
                            Text(label(for: seconds)).tag(seconds)
                        }
                    }
                    .frame(maxWidth: 180)
                } else {
                    Picker("Words", selection: Binding(
                        get: { test.selectedWordTarget },
                        set: { editorViewModel.setTypingWordTarget($0); inputBuffer = ""; inputFocused = true }
                    )) {
                        ForEach([10, 25, 50, 100, 250, 500, 1000, 2500, 5000], id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .frame(maxWidth: 180)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(nsColor: .textBackgroundColor))

                    Text(attributedPrompt)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("", text: $inputBuffer)
                        .textFieldStyle(.plain)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundStyle(.clear)
                        .accentColor(.black)
                        .focused($inputFocused)
                        .disabled(test.isFinished)
                        .padding(18)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(minHeight: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.black.opacity(0.08))
                )

                Text("Current word: \(currentWord)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: test.progress)
                .tint(.black.opacity(0.75))

            HStack {
                Button("New Prompt") {
                    editorViewModel.resetTypingTest()
                    inputBuffer = ""
                    inputFocused = true
                }
                .buttonStyle(.borderedProminent)

                if test.isFinished {
                    Text("Round complete.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding(24)
        .background(Color(nsColor: .textBackgroundColor))
        .onReceive(timer) { _ in
            editorViewModel.tickTypingTest()
        }
        .onAppear {
            inputBuffer = editorViewModel.typingTest.currentInput
            inputFocused = true
        }
        .onChange(of: inputBuffer) {
            handleInputChange(inputBuffer)
        }
        .onChange(of: editorViewModel.typingTest.currentInput) {
            if editorViewModel.typingTest.currentInput != inputBuffer {
                inputBuffer = editorViewModel.typingTest.currentInput
            }
        }
    }

    private var currentWord: String {
        let test = editorViewModel.typingTest
        guard test.currentWordIndex < test.promptWords.count else {
            return "Done"
        }
        return test.promptWords[test.currentWordIndex]
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(nsColor: .underPageBackgroundColor))
        )
    }

    private var attributedPrompt: AttributedString {
        let test = editorViewModel.typingTest
        var output = AttributedString()

        for (index, word) in test.promptWords.enumerated() {
            output.append(styledWord(word, at: index))
            if index < test.promptWords.count - 1 {
                output.append(AttributedString(" "))
            }
            if test.kind == .words, index + 1 >= test.selectedWordTarget {
                break
            }
        }

        return output
    }

    private func styledWord(_ word: String, at index: Int) -> AttributedString {
        let test = editorViewModel.typingTest
        if index < test.enteredWords.count {
            return styledCompletedWord(target: word, typed: test.enteredWords[index])
        }

        if index == test.currentWordIndex {
            return styledCurrentWord(word, input: test.currentInput)
        }

        var fragment = AttributedString(word)
        fragment.foregroundColor = NSColor.secondaryLabelColor
        return fragment
    }

    private func styledCurrentWord(_ word: String, input: String) -> AttributedString {
        var output = AttributedString()
        let target = Array(word)
        let typed = Array(input)
        let caretIndex = min(typed.count, target.count)

        if caretIndex == 0 {
            output.append(caretFragment)
        }

        for index in target.indices {
            var fragment = AttributedString(String(target[index]))
            if index < typed.count {
                fragment.foregroundColor = NSColor(target[index] == typed[index] ? Color.primary : Color.red.opacity(0.9))
            } else {
                fragment.foregroundColor = NSColor.labelColor
            }
            output.append(fragment)
            if index + 1 == caretIndex {
                output.append(caretFragment)
            }
        }

        if typed.count > target.count {
            for character in typed.dropFirst(target.count) {
                var fragment = AttributedString(String(character))
                fragment.foregroundColor = NSColor(Color.red.opacity(0.9))
                output.append(fragment)
            }
            output.append(caretFragment)
        }

        return output
    }

    private func styledCompletedWord(target: String, typed: String) -> AttributedString {
        var output = AttributedString()
        let targetChars = Array(target)
        let typedChars = Array(typed)
        let overlap = max(targetChars.count, typedChars.count)

        for index in 0..<overlap {
            if index < targetChars.count {
                var fragment = AttributedString(String(targetChars[index]))
                if index < typedChars.count {
                    fragment.foregroundColor = NSColor(targetChars[index] == typedChars[index] ? Color.green.opacity(0.85) : Color.red.opacity(0.9))
                } else {
                    fragment.foregroundColor = NSColor(Color.red.opacity(0.9))
                }
                output.append(fragment)
            } else {
                var fragment = AttributedString(String(typedChars[index]))
                fragment.foregroundColor = NSColor(Color.red.opacity(0.9))
                output.append(fragment)
            }
        }

        return output
    }

    private var caretFragment: AttributedString {
        var caret = AttributedString("|")
        caret.foregroundColor = .systemRed
        return caret
    }

    private func handleInputChange(_ value: String) {
        guard editorViewModel.editorMode == .typingTest else {
            return
        }

        if value.contains(" ") {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            editorViewModel.updateTypingInput(trimmed)
            editorViewModel.commitTypingWord()
            inputBuffer = ""
            return
        }

        editorViewModel.updateTypingInput(value)
    }

    private func label(for seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        if seconds < 3600 {
            return "\(seconds / 60)m"
        }
        return "1h"
    }

    private func progressValue(_ test: TypingTestState) -> String {
        switch test.kind {
        case .time:
            return "\(Int(test.remaining))s"
        case .words:
            return "\(test.enteredWords.count)/\(test.selectedWordTarget)"
        }
    }
}
