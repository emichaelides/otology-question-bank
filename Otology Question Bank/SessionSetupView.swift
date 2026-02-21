import SwiftUI

struct SessionSetupView: View {
    @EnvironmentObject private var engine: QuizEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                lengthSection
                categoriesSection
                difficultiesSection
                availableSection
            }
            .navigationTitle("Session Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Start Quiz") {
                        engine.startNewSession()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(engine.filteredQuestions.isEmpty)
                }
            }
        }
    }

    // MARK: - Sections

    private var categoriesSection: some View {
        Section {
            // Select All / None
            Button {
                if engine.activeCategories.count == engine.allCategories.count {
                    engine.activeCategories = []
                } else {
                    engine.activeCategories = Set(engine.allCategories)
                }
            } label: {
                Text(engine.activeCategories.count == engine.allCategories.count ? "Deselect All" : "Select All")
                    .font(.subheadline)
            }

            ForEach(engine.allCategories, id: \.self) { category in
                Toggle(isOn: Binding(
                    get: { engine.activeCategories.contains(category) },
                    set: { on in
                        if on { engine.activeCategories.insert(category) }
                        else  { engine.activeCategories.remove(category) }
                    }
                )) {
                    Text(category)
                        .font(.subheadline)
                }
            }
        } header: {
            Text("Categories (\(engine.activeCategories.count) of \(engine.allCategories.count))")
        }
    }

    private var difficultiesSection: some View {
        Section("Difficulty") {
            ForEach(["easy", "medium", "hard"], id: \.self) { diff in
                let (label, color): (String, Color) = switch diff {
                case "easy":   ("Easy",   .green)
                case "medium": ("Medium", .orange)
                default:       ("Hard",   .red)
                }
                Toggle(isOn: Binding(
                    get: { engine.activeDifficulties.contains(diff) },
                    set: { on in
                        if on { engine.activeDifficulties.insert(diff) }
                        else  { engine.activeDifficulties.remove(diff) }
                    }
                )) {
                    Label(label, systemImage: "circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(color)
                        .font(.subheadline)
                }
            }
        }
    }

    private var lengthSection: some View {
        Section("Session Length") {
            Picker("Questions", selection: $engine.sessionLength) {
                Text("5").tag(5)
                Text("10").tag(10)
                Text("20").tag(20)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
    }

    private var availableSection: some View {
        Section {
            let count = engine.filteredQuestions.count
            HStack {
                Image(systemName: count > 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(count > 0 ? .green : .orange)
                Text(count > 0 ? "\(count) questions available" : "No questions match the selected filters")
                    .font(.subheadline)
                    .foregroundStyle(count > 0 ? Color.primary : Color.orange)
            }
        }
    }
}

#Preview {
    SessionSetupView()
        .environmentObject(QuizEngine())
}
