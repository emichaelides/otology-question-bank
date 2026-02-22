import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LeaderboardEntry: Identifiable, Hashable {
    let id: String          // uid
    let displayName: String
    let totalAttempts: Int
    let totalCorrect: Int
    var accuracy: Double { totalAttempts > 0 ? Double(totalCorrect) / Double(totalAttempts) : 0 }
}

struct LeaderboardView: View {
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        List(entries) { entry in
            let rank = (entries.firstIndex(of: entry) ?? 0) + 1
            NavigationLink(value: entry) {
                LeaderboardRow(rank: rank, entry: entry)
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            } else if entries.isEmpty {
                Text("No users yet.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Leaderboard")
        .navigationDestination(for: LeaderboardEntry.self) { entry in
            UserStatsView(user: entry)
        }
        .task { await loadEntries() }
        .refreshable { await loadEntries() }
    }

    private func loadEntries() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("users").getDocuments()
            let loaded: [LeaderboardEntry] = snapshot.documents.compactMap { doc in
                let data = doc.data()
                guard let name = data["displayName"] as? String else { return nil }
                let attempts = data["totalAttempts"] as? Int ?? 0
                let correct  = data["totalCorrect"]  as? Int ?? 0
                return LeaderboardEntry(id: doc.documentID, displayName: name,
                                        totalAttempts: attempts, totalCorrect: correct)
            }
            // Sort: most accurate first; zero-activity users go to the bottom
            entries = loaded.sorted {
                if $0.totalAttempts == 0 && $1.totalAttempts == 0 { return $0.displayName < $1.displayName }
                if $0.totalAttempts == 0 { return false }
                if $1.totalAttempts == 0 { return true }
                return $0.accuracy > $1.accuracy
            }
        } catch {
            print("[Leaderboard] Load failed: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

// MARK: - Row

struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            Text(rankLabel)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(rankColor)
                .frame(width: 32, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.headline)
                Text(entry.totalAttempts > 0
                     ? "\(entry.totalAttempts) answered · \(entry.totalCorrect) correct"
                     : "No activity yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if entry.totalAttempts > 0 {
                Text("\(Int(entry.accuracy * 100))%")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(accuracyColor(entry.accuracy))
            }
        }
        .padding(.vertical, 2)
    }

    private var rankLabel: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    private var rankColor: Color {
        rank <= 3 ? .primary : .secondary
    }

    private func accuracyColor(_ value: Double) -> Color {
        if value >= 0.8 { return .green }
        if value >= 0.5 { return .orange }
        return .red
    }
}
