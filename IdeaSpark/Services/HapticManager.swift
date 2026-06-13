import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    enum HapticType {
        case generate
        case favoriteChanged
        case error
    }

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        selectionGenerator.prepare()
        impactGenerator.prepare()
    }

    func fire(_ type: HapticType, isEnabled: Bool) {
        guard isEnabled else {
            return
        }

        switch type {
        case .generate:
            impactGenerator.impactOccurred()
        case .favoriteChanged:
            selectionGenerator.selectionChanged()
        case .error:
            notificationGenerator.notificationOccurred(.warning)
        }
    }
}
