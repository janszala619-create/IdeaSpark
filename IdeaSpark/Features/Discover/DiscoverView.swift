import SwiftData
import SwiftUI

@MainActor
struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteIdeaEntity]
    @AppStorage("aiGenerationEnabled") private var aiGenerationEnabled = false
    @AppStorage("backendURLString") private var backendURLString = AppConfiguration.configuredBackendURLString
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @State private var viewModel = DiscoverViewModel()
    @State private var selectedCategory: IdeaCategory?
    @State private var selectedDifficulty: DifficultyLevel?
    @State private var selectedSource: IdeaSource = .local
    @State private var ideaPrompt = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                controls

                if let notice = viewModel.notice {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(notice, systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if selectedSource == .ai, aiGenerationEnabled {
                            Button {
                                Task {
                                    await generate()
                                }
                            } label: {
                                Label("AI erneut versuchen", systemImage: "arrow.clockwise")
                            }
                            .font(.footnote.weight(.semibold))
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(.horizontal)
                }

                content
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .task {
            if viewModel.currentIdea == nil {
                await generate()
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                CategoryPicker(selection: $selectedCategory)
                    .pickerStyle(.menu)

                Picker("Schwierigkeit", selection: $selectedDifficulty) {
                    Text("Alle Level").tag(Optional<DifficultyLevel>.none)
                    ForEach(DifficultyLevel.allCases) { difficulty in
                        Label(difficulty.displayName, systemImage: difficulty.symbolName)
                            .tag(Optional(difficulty))
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Schwierigkeit filtern")
                .accessibilityIdentifier("filters.difficulty")
            }

            Picker("Quelle", selection: $selectedSource) {
                ForEach(IdeaSource.allCases) { source in
                    Text(source.displayName).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Ideenquelle")
            .accessibilityIdentifier("discover.sourcePicker")

            if selectedSource == .ai {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stichworte")
                        .font(.subheadline.weight(.semibold))
                    TextField(
                        "z.B. Fitness, Studenten, Gamification, Kalender",
                        text: $ideaPrompt,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Stichworte fuer AI-Idee")
                    .accessibilityIdentifier("discover.ideaPrompt")
                }
            }

            Button {
                Task {
                    await generate()
                }
            } label: {
                Label(viewModel.isLoading ? "Generiere..." : "Neue Idee generieren", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier("discover.generateButton")
            .accessibilityHint("Waehlt eine neue Projektidee anhand der aktuellen Filter aus")
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            IdeaCardView(
                idea: .preview,
                isFavorite: false,
                showsFavoriteButton: false
            )
            .redacted(reason: .placeholder)
            .padding(.horizontal)
        case let .loaded(idea):
            IdeaCardView(
                idea: idea,
                isFavorite: isFavorite(idea),
                onToggleFavorite: { toggleFavorite(idea) }
            )
            .padding(.horizontal)
        case let .failed(error):
            ContentUnavailableView {
                Label("Keine Idee gefunden", systemImage: "tray")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button("Erneut versuchen") {
                    Task {
                        await generate()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
    }

    private func generate() async {
        await viewModel.generateIdea(
            category: selectedCategory,
            difficulty: selectedDifficulty,
            source: selectedSource,
            aiGenerationEnabled: aiGenerationEnabled,
            backendURLString: backendURLString,
            prompt: ideaPrompt
        )

        if let idea = viewModel.currentIdea {
            do {
                try HistoryStore.record(idea, in: modelContext)
                HapticManager.shared.fire(.generate, isEnabled: hapticsEnabled)
            } catch {
                HapticManager.shared.fire(.error, isEnabled: hapticsEnabled)
                #if DEBUG
                print("Failed to record generated idea history: \(error)")
                #endif
            }
        } else {
            HapticManager.shared.fire(.error, isEnabled: hapticsEnabled)
        }
    }

    private func isFavorite(_ idea: ProjectIdea) -> Bool {
        favorites.contains { $0.ideaID == idea.id }
    }

    private func toggleFavorite(_ idea: ProjectIdea) {
        do {
            _ = try FavoriteStore.toggle(idea, in: modelContext)
            HapticManager.shared.fire(.favoriteChanged, isEnabled: hapticsEnabled)
        } catch {
            HapticManager.shared.fire(.error, isEnabled: hapticsEnabled)
        }
    }
}
