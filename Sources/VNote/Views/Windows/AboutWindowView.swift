import SwiftUI

struct AboutWindowView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.top, 8)

            VStack(spacing: 6) {
                Text("VNote")
                    .font(.system(size: 26, weight: .semibold))

                Text("Text, code, and typing test")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text("A rebuilt note app with plain writing mode, a lightweight code editor, and a random-word typing sprint.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Spacer()
        }
        .padding(28)
    }
}
