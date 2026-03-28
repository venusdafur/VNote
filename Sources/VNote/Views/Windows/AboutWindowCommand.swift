import SwiftUI

struct AboutWindowCommand: Commands {
    static let windowID = "about-window"

    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About VNote") {
                openWindow(id: Self.windowID)
            }
        }
    }
}
