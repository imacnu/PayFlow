import Foundation
import UIKit
import GoogleSignIn

/// Errores del flujo de inicio de sesión con Google.
enum GoogleSignInError: Error {
    /// La integración está desactivada en `AppConfig` (falta el Client ID).
    case disabled
    /// No se encontró un view controller raíz desde el que presentar el flujo.
    case noPresenter
    /// El resultado no incluye perfil de usuario.
    case noProfile
}

/// Único punto de la app que importa el SDK de GoogleSignIn.
/// Presenta el flujo de Google y devuelve los datos básicos del perfil.
@MainActor
final class GoogleSignInService {
    /// Lanza el flujo de inicio de sesión con Google.
    /// - Returns: correo y nombre para mostrar del usuario autenticado.
    func signIn() async throws -> (email: String, displayName: String?) {
        guard AppConfig.googleSignInEnabled else {
            throw GoogleSignInError.disabled
        }
        guard let presenter = Self.rootViewController() else {
            throw GoogleSignInError.noPresenter
        }

        let profileData: (email: String, displayName: String?) = try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let profile = result?.user.profile else {
                    continuation.resume(throwing: GoogleSignInError.noProfile)
                    return
                }
                continuation.resume(returning: (email: profile.email, displayName: profile.name))
            }
        }
        return profileData
    }

    // MARK: - Privado

    /// Obtiene el view controller raíz de la escena activa para presentar el flujo.
    private static func rootViewController() -> UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        guard let windowScene else { return nil }
        let window = windowScene.keyWindow ?? windowScene.windows.first
        return window?.rootViewController
    }
}
