//
//  AuthLandingView.swift
//  Subscription Guardian
//
//  Pantalla de bienvenida con las opciones de inicio de sesión:
//  Apple, Google (si está habilitado) y modo invitado.
//

import SwiftUI
import AuthenticationServices

/// Pantalla de autenticación mostrada cuando no hay sesión iniciada.
struct AuthLandingView: View {
    @Environment(\.dependencies) private var deps

    @State private var viewModel = AuthViewModel()
    /// Controla la animación de entrada del contenido.
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: AppSpacing.l) {
            Spacer()

            hero
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 24)

            Spacer()

            buttons
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 32)

            footer
                .opacity(hasAppeared ? 1 : 0)
        }
        .padding(AppSpacing.l)
        .appBackground()
        .task {
            viewModel.configure(deps: deps)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Secciones

    /// Marca de la app: icono con gradiente, nombre y eslogan.
    private var hero: some View {
        VStack(spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(LinearGradient.appAccent)
                    .frame(width: 104, height: 104)
                    .shadow(color: Color.appCyan.opacity(0.35), radius: 20, x: 0, y: 10)

                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(verbatim: "Subscription Guardian")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text(String(
                localized: "auth.tagline",
                defaultValue: "Controla tus suscripciones y financiaciones"
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }

    /// Botones de inicio de sesión.
    private var buttons: some View {
        VStack(spacing: AppSpacing.m) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                viewModel.handleAppleResult(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(Capsule())

            if AppConfig.googleSignInEnabled {
                Button {
                    Task { await viewModel.signInWithGoogle() }
                } label: {
                    HStack(spacing: AppSpacing.s) {
                        Image(systemName: "globe")
                        Text(String(
                            localized: "auth.google",
                            defaultValue: "Continuar con Google"
                        ))
                    }
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 26)
                }
                .glassCard(cornerRadius: 25, padding: 12)
                .disabled(viewModel.isSigningIn)
            }

            Button {
                viewModel.signInAsGuest()
            } label: {
                Text(String(
                    localized: "auth.guest",
                    defaultValue: "Continuar como invitado"
                ))
                .font(.subheadline.weight(.medium))
            }
            .padding(.top, AppSpacing.s)
        }
    }

    /// Nota de privacidad.
    private var footer: some View {
        Text(String(
            localized: "auth.privacy",
            defaultValue: "Tus datos se guardan en tu dispositivo. No compartimos tu información con terceros."
        ))
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Vista previa

#Preview {
    AuthLandingView()
        .environment(\.dependencies, AppDependencies.preview())
}
