import AppKit
import SwiftUI

@main
struct VNoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var editorViewModel = EditorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(editorViewModel: editorViewModel)
                .frame(minWidth: 860, minHeight: 620)
        }
        .commands {
            AboutWindowCommand()
            EditorCommands(editorViewModel: editorViewModel)
        }

        Window("About VNote", id: AboutWindowCommand.windowID) {
            AboutWindowView()
                .frame(width: 430, height: 300)
        }
        .windowResizability(.contentSize)
    }
}
