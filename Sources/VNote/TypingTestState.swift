import Foundation

enum TypingTestKind: String, CaseIterable, Identifiable {
    case time
    case words

    var id: String { rawValue }

    var title: String {
        switch self {
        case .time: "Time"
        case .words: "Words"
        }
    }
}

struct TypingTestState: Equatable {
    var kind: TypingTestKind = .time
    var selectedDuration: Int = 60
    var selectedWordTarget: Int = 50
    var promptWords: [String] = RandomWordBank.makePrompt(wordCount: 250)
    var enteredWords: [String] = []
    var currentInput = ""
    var startedAt: Date?
    var finishedAt: Date?

    var prompt: String {
        promptWords.joined(separator: " ")
    }

    var elapsed: TimeInterval {
        let end = finishedAt ?? Date()
        guard let startedAt else {
            return 0
        }
        return min(duration, end.timeIntervalSince(startedAt))
    }

    var duration: TimeInterval {
        TimeInterval(selectedDuration)
    }

    var remaining: TimeInterval {
        kind == .time ? max(duration - elapsed, 0) : max(duration - elapsed, 0)
    }

    var isRunning: Bool {
        startedAt != nil && finishedAt == nil && !isFinished
    }

    var isFinished: Bool {
        switch kind {
        case .time:
            return finishedAt != nil || remaining == 0
        case .words:
            return finishedAt != nil || enteredWords.count >= selectedWordTarget
        }
    }

    var typedWords: [String] {
        enteredWords
    }

    var currentWordIndex: Int {
        min(enteredWords.count, max(promptWords.count - 1, 0))
    }

    var accuracy: Int {
        guard !enteredWords.isEmpty else {
            return 100
        }

        let correct = zip(enteredWords, promptWords).filter(==).count
        return Int((Double(correct) / Double(enteredWords.count)) * 100)
    }

    var wordsPerMinute: Int {
        let minutes = max(elapsed / 60, 1 / 60)
        return Int(Double(enteredWords.count) / minutes)
    }

    var progress: Double {
        switch kind {
        case .time:
            return duration == 0 ? 0 : min(elapsed / duration, 1)
        case .words:
            return selectedWordTarget == 0 ? 0 : min(Double(enteredWords.count) / Double(selectedWordTarget), 1)
        }
    }

    var correctWordCount: Int {
        zip(enteredWords, promptWords).filter(==).count
    }

    var currentTargetWord: String {
        guard currentWordIndex < promptWords.count else {
            return ""
        }
        return promptWords[currentWordIndex]
    }

    var wordsRemaining: Int {
        max(selectedWordTarget - enteredWords.count, 0)
    }

    var activePromptWordCount: Int {
        switch kind {
        case .time:
            return 5000
        case .words:
            return min(max(selectedWordTarget, 25), 5000)
        }
    }
}

enum RandomWordBank {
    static let words = [
        "pixel", "signal", "canvas", "ember", "syntax", "forest", "rocket", "velvet",
        "monarch", "quartz", "orbit", "groove", "anchor", "harbor", "breeze", "lantern",
        "ripple", "fable", "drift", "magnet", "silver", "mosaic", "cinder", "echo",
        "logic", "tunnel", "frost", "garden", "marble", "stream", "planet", "glimmer",
        "tempo", "vector", "copper", "cabin", "prism", "thunder", "spiral", "horizon",
        "notion", "feather", "signal", "matrix", "wander", "glacier", "sprint", "rhythm",
        "cipher", "delta", "ember", "fiction", "atlas", "meadow", "comet", "binary"
    ]

    static func makePrompt(wordCount: Int = 35) -> [String] {
        (0..<wordCount).map { _ in words.randomElement() ?? "note" }
    }
}
