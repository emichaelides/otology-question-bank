import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isCreatingAccount = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                appleSignInButton
                orDivider
                emailForm
                if let msg = errorMessage {
                    Text(msg)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "ear.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
            Text("Otology Question Bank")
                .font(.title2)
                .fontWeight(.bold)
            Text("Sign in to sync your progress")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Apple Sign In

    private var appleSignInButton: some View {
        SignInWithAppleButton(isCreatingAccount ? .signUp : .signIn) { request in
            let hashedNonce = authManager.prepareAppleRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce
        } onCompletion: { result in
            Task {
                switch result {
                case .success(let auth):
                    guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
                    isLoading = true
                    do {
                        try await authManager.handleAppleCredential(credential)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                case .failure(let error):
                    let code = (error as NSError).code
                    if code != ASAuthorizationError.canceled.rawValue {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Divider

    private var orDivider: some View {
        HStack {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
            Text("or")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
        }
    }

    // MARK: - Email Form

    private var emailForm: some View {
        VStack(spacing: 14) {
            if isCreatingAccount {
                TextField("Display name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(isCreatingAccount ? .newPassword : .password)

            Button {
                Task { await submitEmailForm() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(isCreatingAccount ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isLoading)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCreatingAccount.toggle()
                    errorMessage = nil
                }
            } label: {
                Text(isCreatingAccount
                    ? "Already have an account? Sign In"
                    : "New here? Create Account")
                    .font(.footnote)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    // MARK: - Actions

    private func submitEmailForm() async {
        errorMessage = nil
        isLoading = true
        do {
            if isCreatingAccount {
                let name = displayName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else {
                    errorMessage = "Please enter your display name."
                    isLoading = false
                    return
                }
                try await authManager.createAccount(
                    email: email,
                    password: password,
                    displayName: name
                )
            } else {
                try await authManager.signInWithEmail(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
