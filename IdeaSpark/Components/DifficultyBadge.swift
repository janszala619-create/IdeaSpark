import SwiftUI

struct DifficultyBadge: View {
    let difficulty: DifficultyLevel

    var body: some View {
        Label(difficulty.displayName, systemImage: difficulty.symbolName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .foregroundStyle(.white)
            .background(backgroundStyle, in: Capsule())
            .accessibilityLabel("Schwierigkeit: \(difficulty.displayName)")
    }

    private var backgroundStyle: Color {
        switch difficulty {
        case .beginner:
            return .green
        case .intermediate:
            return .blue
        case .advanced:
            return .red
        }
    }
}
