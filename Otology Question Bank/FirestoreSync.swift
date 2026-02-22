import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Handles all Firestore write operations. Fire-and-forget: call with `Task { await ... }`.
enum FirestoreSync {

    private static let db = Firestore.firestore()

    // MARK: - Upsert user document

    /// Creates or merges the /users/{uid} document. Safe to call on every sign-in.
    static func upsertUserDoc(user: FirebaseAuth.User, displayName: String? = nil) async {
        let name = displayName ?? user.displayName ?? "Resident"
        let data: [String: Any] = [
            "displayName": name,
            "email": user.email ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection("users").document(user.uid)
            .setData(data, merge: true)
    }

    // MARK: - Upload session

    /// Writes one session document + upserts per-question stats in a single batch.
    /// Gets UID directly from FirebaseAuth — no need to thread it through SwiftUI environment.
    static func uploadSession(engine: QuizEngine) async {
        let uid = Auth.auth().currentUser?.uid
        let entryCount = await MainActor.run { engine.sessionEntries.count }
        guard let uid, entryCount > 0 else {
            await MainActor.run {
                engine.lastSyncMessage = "Skipped — uid:\(uid ?? "nil") entries:\(entryCount)"
            }
            return
        }

        let batch = db.batch()
        let now = Timestamp(date: Date())
        let sessionStart = engine.sessionStartTime ?? Date()
        let durationSeconds = Int(Date().timeIntervalSince(sessionStart))

        let correctCount = engine.sessionEntries.filter(\.wasCorrect).count
        let total = engine.sessionEntries.count
        let accuracy = total > 0 ? Double(correctCount) / Double(total) : 0.0

        // 1. Upsert /users/{uid}
        let userRef = db.collection("users").document(uid)
        batch.setData([
            "displayName": Auth.auth().currentUser?.displayName ?? "Resident",
            "email": Auth.auth().currentUser?.email ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: userRef, merge: true)

        // 2. Write /users/{uid}/sessions/{sessionId}
        let sessionRef = db
            .collection("users").document(uid)
            .collection("sessions").document(engine.sessionId)

        let entryMaps: [[String: Any]] = engine.sessionEntries.map { entry in
            [
                "questionId": entry.question.id,
                "category": entry.question.category,
                "difficulty": entry.question.difficulty,
                "correct": entry.wasCorrect,
                "timeSpentSeconds": entry.timeSpentSeconds
            ]
        }

        batch.setData([
            "startedAt": Timestamp(date: sessionStart),
            "endedAt": now,
            "durationSeconds": durationSeconds,
            "correct": correctCount,
            "total": total,
            "accuracy": accuracy,
            "categoryFilters": Array(engine.activeCategories),
            "difficultyFilters": Array(engine.activeDifficulties),
            "entries": entryMaps
        ], forDocument: sessionRef)

        // 3. Upsert each /users/{uid}/questionStats/{questionId}
        for entry in engine.sessionEntries {
            let statsRef = db
                .collection("users").document(uid)
                .collection("questionStats").document(entry.question.id)
            batch.setData([
                "attempts": FieldValue.increment(Int64(1)),
                "correct": FieldValue.increment(Int64(entry.wasCorrect ? 1 : 0)),
                "category": entry.question.category,
                "difficulty": entry.question.difficulty,
                "lastAnsweredAt": now
            ], forDocument: statsRef, merge: true)
        }

        do {
            try await batch.commit()
            await MainActor.run { engine.lastSyncMessage = "Synced ✓" }
        } catch {
            let msg = error.localizedDescription
            print("[FirestoreSync] Batch upload failed: \(msg)")
            await MainActor.run { engine.lastSyncMessage = "Sync failed: \(msg)" }
        }
    }
}
