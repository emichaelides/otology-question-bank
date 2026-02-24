import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject private var engine: QuizEngine
    @EnvironmentObject private var authManager: AuthManager
    @State private var showSetup = false
    @State private var showQuiz = false
    @State private var sessionStarted = false
    @State private var showSignOutConfirm = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Account button
                HStack {
                    Spacer()
                    Button {
                        showSignOutConfirm = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }

                // Header
                VStack(spacing: 10) {
                    Image(systemName: "ear.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                    Text("Otology Question Bank")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Board Exam Preparation")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let email = authManager.user?.email {
                        Text(authManager.user?.displayName ?? email)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Text("v1.01")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                .padding(.top, 16)
                .padding(.bottom, 48)

                // Action cards
                VStack(spacing: 14) {
                    Button { showSetup = true } label: {
                        HomeActionCard(
                            title: "Start Quiz",
                            subtitle: "Weighted practice sessions",
                            icon: "play.circle.fill",
                            color: .accentColor
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        StatsView()
                    } label: {
                        HomeActionCard(
                            title: "Review Progress",
                            subtitle: "Accuracy by category & difficulty",
                            icon: "chart.bar.fill",
                            color: .green
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        BrowseView()
                    } label: {
                        HomeActionCard(
                            title: "Browse",
                            subtitle: "\(engine.questions.count) questions · \(engine.allCategories.count) categories",
                            icon: "books.vertical.fill",
                            color: .orange
                        )
                    }
                    .buttonStyle(.plain)

                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { try? authManager.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to sync your progress.")
        }
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView()
                .environmentObject(engine)
        }
        .sheet(isPresented: $showSetup, onDismiss: {
            if sessionStarted {
                sessionStarted = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showQuiz = true
                }
            }
        }) {
            SessionSetupView(onStart: { sessionStarted = true })
                .environmentObject(engine)
        }
    }
}

// MARK: - Home Action Card

struct HomeActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(color)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(QuizEngine())
}
