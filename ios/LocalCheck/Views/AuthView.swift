import SwiftUI
import UIKit

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @State private var mode: Mode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var displayName: String = ""

    private enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case signUp = "Create Account"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    logo
                    authForm
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 48)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .onChange(of: mode) { _, _ in
            appState.authNotice = nil
            appState.errorMessage = nil
        }
    }

    // MARK: - Logo

    private var logo: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.orange.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.orange)
            }

            Text("LocalCheck")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            Text("Your court. Your community.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Auth form

    private var authForm: some View {
        VStack(spacing: 20) {
            // Mode picker
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)

            // Notices
            if let notice = appState.authNotice {
                noticeCard(text: notice, tint: Theme.green)
            }

            // Fields
            VStack(spacing: 14) {
                if mode == .signUp {
                    field(
                        title: "Display Name",
                        text: $displayName,
                        keyboard: .default,
                        contentType: .name,
                        capitalization: .words
                    )
                }

                field(
                    title: "Email",
                    text: $email,
                    keyboard: .emailAddress,
                    contentType: .emailAddress,
                    capitalization: .never
                )

                SecureField("Password", text: $password)
                    .textContentType(mode == .signUp ? .newPassword : .password)
                    .padding(.horizontal, 16)
                    .frame(height: Theme.inputHeight)
                    .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.inputCornerRadius, style: .continuous))
                    .foregroundStyle(Theme.textPrimary)
            }

            // Sign in / up button
            Button {
                submit()
            } label: {
                HStack(spacing: 8) {
                    if appState.isAuthenticating {
                        ProgressView().tint(.white)
                    }
                    Text(mode == .signIn ? "Sign In" : "Create Account")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .background(
                    canSubmit ? Theme.orange : Theme.surfaceCard,
                    in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                )
            }
            .disabled(!canSubmit)

            // Divider
            HStack(spacing: 12) {
                Rectangle().fill(Theme.surfaceBorder).frame(height: 1)
                Text("or").font(.footnote.weight(.medium)).foregroundStyle(Theme.textTertiary)
                Rectangle().fill(Theme.surfaceBorder).frame(height: 1)
            }

            // Apple sign in
            Button {
                appState.authNotice = "Apple Sign-In will be enabled closer to launch. Use email for now."
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                        .font(.body.weight(.semibold))
                    Text("Continue with Apple")
                        .font(.body.weight(.semibold))
                    Spacer()
                    Text("Soon")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.surfaceBorder, in: Capsule())
                }
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .padding(.horizontal, 16)
                .background(
                    Color.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
            }

            Text(mode == .signUp
                 ? "We'll never share your email. Apple Sign-In coming soon."
                 : "Sign in with the same account across all your devices.")
                .font(.footnote)
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.screenPadding)
        .background(
            Theme.surfaceElevated,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.surfaceBorder, lineWidth: 1)
        }
    }

    // MARK: - Components

    private func field(
        title: String,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        contentType: UITextContentType,
        capitalization: TextInputAutocapitalization
    ) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboard)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled()
            .textContentType(contentType)
            .padding(.horizontal, 16)
            .frame(height: Theme.inputHeight)
            .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.inputCornerRadius, style: .continuous))
            .foregroundStyle(Theme.textPrimary)
    }

    private func noticeCard(text: String, tint: Color) -> some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .foregroundStyle(tint)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.inputCornerRadius, style: .continuous))
    }

    // MARK: - Logic

    private var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasName = mode == .signIn || !trimmedName.isEmpty
        return !trimmedEmail.isEmpty && password.count >= 6 && hasName && !appState.isAuthenticating
    }

    private func submit() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            switch mode {
            case .signIn:
                await appState.signIn(email: trimmedEmail, password: password)
            case .signUp:
                await appState.signUp(email: trimmedEmail, password: password, displayName: trimmedName)
            }
        }
    }
}
