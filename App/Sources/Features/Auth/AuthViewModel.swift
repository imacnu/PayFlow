//
//  AuthViewModel.swift
//  Subscription Guardian
//
//  Lógica de la pantalla de autenticación: Apple, Google y modo invitado.
//

import Foundation
import Observation
import AuthenticationServices

/// ViewModel de la pantalla de inicio de sesión.
@MainActor
@Observable
final class AuthViewModel {
    /// Dependencias inyectadas desde la vista vía `configure(deps:)`.
    private var deps: AppDependencies?

    /// Mensaje de error a mostrar en la vista, si lo hay.
    var errorMessage: String?

    /// Indica si hay un inicio de sesión en curso (Google).
    var isSigningIn = false

    /// Inyecta las dependencias de la app. Debe llamarse desde `.task`/onAppear.
    func configure(deps: AppDependencies?) {
        self.deps = deps
    }

    /// Procesa el resultado del botón "Iniciar sesión con Apple".
    func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        guard let deps else { return }
        do {
            let credential = try AppleSignInService.credential(from: result)
            deps.session.signIn(
                appleUserID: credential.userID,
                email: credential.email,
                fullName: credential.fullName
            )
            errorMessage = nil
        } catch {
            // La cancelación del usuario no es un error que haya que mostrar.
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            errorMessage = String(
                localized: "auth.error.apple",
                defaultValue: "No se pudo iniciar sesión con Apple. Inténtalo de nuevo."
            )
        }
    }

    /// Lanza el flujo de inicio de sesión con Google.
    func signInWithGoogle() async {
        guard let deps else { return }
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            let profile = try await deps.googleSignIn.signIn()
            deps.session.signIn(googleEmail: profile.email, displayName: profile.displayName)
            errorMessage = nil
        } catch {
            errorMessage = String(
                localized: "auth.error.google",
                defaultValue: "No se pudo iniciar sesión con Google. Inténtalo de nuevo."
            )
        }
    }

    /// Inicia sesión en modo invitado (datos solo locales).
    func signInAsGuest() {
        deps?.session.signInAsGuest()
    }
}
