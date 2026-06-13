import SwiftData
import SwiftUI

@MainActor
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("aiGenerationEnabled") private var aiGenerationEnabled = false
    @AppStorage("backendURLString") private var backendURLString = AppConfiguration.configuredBackendURLString
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        Form {
            Section("AI-Generierung") {
                Toggle("AI-Ideen aktivieren", isOn: $aiGenerationEnabled)
                    .accessibilityIdentifier("settings.aiToggle")

                TextField("Backend-URL", text: $backendURLString)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .accessibilityIdentifier("settings.backendURL")

                if !isBackendURLValid {
                    Label("Die Backend-URL muss eine gueltige HTTPS-Adresse ohne Zugangsdaten oder URL-Parameter sein.", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Ungueltige Backend-URL. Die Adresse muss HTTPS verwenden und darf keine Zugangsdaten oder URL-Parameter enthalten.")
                }

                Text("Die iOS-App spricht nur mit deinem Backend-Endpunkt. API-Keys gehoeren nicht in die App.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Daten") {
                Button(role: .destructive) {
                    clearHistory()
                } label: {
                    Label("Verlauf loeschen", systemImage: "trash")
                }
                .accessibilityIdentifier("settings.clearHistory")

                Button(role: .destructive) {
                    clearFavorites()
                } label: {
                    Label("Favoriten loeschen", systemImage: "heart.slash")
                }
                .accessibilityIdentifier("settings.clearFavorites")
            }

            Section("Feedback") {
                Toggle("Haptisches Feedback", isOn: $hapticsEnabled)
                    .accessibilityIdentifier("settings.hapticsToggle")
            }

            Section("App") {
                LabeledContent("Version", value: appVersion)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var isBackendURLValid: Bool {
        AppConfiguration.backendURL(from: backendURLString) != nil
    }

    private func clearHistory() {
        do {
            try HistoryStore.removeAll(in: modelContext)
            HapticManager.shared.fire(.favoriteChanged, isEnabled: hapticsEnabled)
        } catch {
            HapticManager.shared.fire(.error, isEnabled: hapticsEnabled)
        }
    }

    private func clearFavorites() {
        do {
            try FavoriteStore.removeAll(in: modelContext)
            HapticManager.shared.fire(.favoriteChanged, isEnabled: hapticsEnabled)
        } catch {
            HapticManager.shared.fire(.error, isEnabled: hapticsEnabled)
        }
    }
}

#Preview("Settings Light") {
    SettingsView()
        .modelContainer(for: [
            FavoriteIdeaEntity.self,
            HistoryIdeaEntity.self
        ], inMemory: true)
        .preferredColorScheme(.light)
}

#Preview("Settings Dark Dynamic Type") {
    SettingsView()
        .modelContainer(for: [
            FavoriteIdeaEntity.self,
            HistoryIdeaEntity.self
        ], inMemory: true)
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility2)
}
