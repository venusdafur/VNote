import SwiftUI

struct NotificationView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.black.opacity(0.78))
            )
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }
}
