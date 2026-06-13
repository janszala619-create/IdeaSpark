import SwiftUI

@MainActor
struct AppView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @State private var selectedTab: AppTab = .discover

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    tab.makeContentView()
                        .navigationTitle(tab.title)
                }
                .tabItem { tab.label }
                .tag(tab)
            }
        }
        .tint(.indigo)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.fire(.generate, isEnabled: hapticsEnabled)
        }
    }
}
