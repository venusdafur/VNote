# VNote

VNote is a simple, just-works all-in-one macOS text editor.

It gives you:
- a plain text mode for notes and drafts
- a code mode with syntax coloring and lightweight editor features
- a built-in typing test for quick practice without leaving the app

The goal is not to be a giant IDE. It is one fast desktop editor that covers everyday writing, casual coding, and typing practice in a single window.

## Features

- Plain text editing
- Code editing with syntax highlighting
- Find and replace
- Line numbers and code-focused editing behavior
- Typing test with time or word-count runs
- SwiftUI + AppKit macOS app

## Project Structure

- `Sources/VNote/` app source
- `Sources/VNote/Views/` editor and window views
- `Tests/VNoteTests/` lightweight tests

## Build

The package is configured as a Swift Package:

```bash
swift build
```

In this environment I verified the app with direct `swiftc` compilation because SwiftPM manifest execution is sandbox-limited.
