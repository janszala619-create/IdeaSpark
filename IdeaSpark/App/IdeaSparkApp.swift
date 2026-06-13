import SwiftData
import SwiftUI

@main
struct IdeaSparkApp: App {
    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .modelContainer(for: [
            FavoriteIdeaEntity.self,
            HistoryIdeaEntity.self
        ])
    }
}
