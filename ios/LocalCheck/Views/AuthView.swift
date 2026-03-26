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
            LinearGradient(
                colors: [Theme.surface, Theme.surfaceElevated, Theme.orangeDark.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hero
                    authCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
            .scrollIndicators(.hidden)
        }
        .onChange(of: mode) { _, _ in
            appState.authNotice = nil
            appState.errorMessage = nil
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Theme.orange.opacity(0.16))
                        .frame(width: 74, height: 74)
                    Image(systemName: "basketball.fill")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(Theme.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("LocalCheck")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Know the run before you lace up.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Text("Find courts, see who checked in, schedule runs, and build your local reputation without group-text chaos.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 10) {
                featurePill(title: "Live check-ins", icon: "mappin.circle.fill")
                featurePill(title: "Scheduled runs", icon: "calendar.badge.clock")
                featurePill(title: "ELO tracking", icon: "chart.line.uptrend.xyaxis")
            }
        }
    }

    private func featurePill(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.surfaceCard.opacity(0.9), in: Capsule())
    }

    private var authCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if let notice = appState.authNotice {
                messageCard(text: notice, tint: Theme.green)
            }

            VStack(spacing: 14) {
                if mode == .signUp {
                    inputField(
                        title: "Display Name",
                        text: $displayName,
                        keyboard: .default,
                        contentType: .name,
                        capitalization: .words
                    )
                }
                inputField(
                    title: "Email",
                    text: $email,
                    keyboard: .emailAddress,
                    contentType: .emailAddress,
                    capitalization: .never
                )
                SecureField("Password", text: $password)
                    .textContentType(mode == .signUp ? .newPassword : .password)
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(Theme.textPrimary)
            }

            Button {
                submit()
            } label: {
                HStack {
                    if appState.isAuthenticating {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(primaryActionTitle)
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(canSubmit ? Theme.orange : Theme.surfaceCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!canSubmit)

            HStack {
                Rectangle()
                    .fill(Theme.surfaceBorder)
                    .frame(height: 1)
                Text("or")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                Rectangle()
                    .fill(Theme.surfaceBorder)
                    .frame(height: 1)
            }

            Button {
                appState.authNotice = "Apple sign-in will be enabled closer to launch. Use email and password for preview builds on your phone."
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                        .font(.headline)
                    Text("Continue with Apple")
                        .font(.headline)
                    Spacer()
                    Text("Soon")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.surfaceBorder, in: Capsule())
                }
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
            }

            Text(mode == .signUp ? "Email and password is the active preview path. Apple sign-in stays visible here so the launch direction is clear." : "Use the same email account across phone and simulator while we finish the rest of the product flow.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(22)
        .background(Theme.surfaceElevated.opacity(0.96), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Theme.surfaceBorder, lineWidth: 1)
        }
    }

    private func inputField(
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
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(Theme.textPrimary)
    }

    private func messageCard(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasName = mode == .signIn || !trimmedName.isEmpty
        return !trimmedEmail.isEmpty && password.count >= 6 && hasName && !appState.isAuthenticating
    }

    private var primaryActionTitle: String {
        switch mode {
        case .signIn:
            return "Sign In"
        case .signUp:
            return "Create Account"
        }
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
