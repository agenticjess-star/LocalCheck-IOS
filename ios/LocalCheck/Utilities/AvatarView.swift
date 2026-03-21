import SwiftUI

struct AvatarView: View {
    let name: String
    let size: CGFloat

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }

    private var backgroundColor: Color {
        let hash = abs(name.hashValue)
        let colors: [Color] = [
            Theme.orange,
            Color(red: 0.3, green: 0.7, blue: 0.9),
            Color(red: 0.6, green: 0.4, blue: 0.9),
            Theme.green,
            Color(red: 0.9, green: 0.6, blue: 0.3),
            Color(red: 0.4, green: 0.8, blue: 0.7),
        ]
        return colors[hash % colors.count]
    }

    var body: some View {
        Circle()
            .fill(backgroundColor.opacity(0.25))
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(backgroundColor)
            }
    }
}
