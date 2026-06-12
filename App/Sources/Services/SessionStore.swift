import Foundation
import Observation
import AuthenticationServices

/// Estado de autenticación de la sesión actual.
enum AuthState: Codable, Equatable {
    case signedOut
    case guest
    case apple(userID: String)
    case google(email: String)
    case email(email: String)
}

/// Almacén de sesión: mantiene el estado de autenticación, lo persiste en
/// UserDefaults (datos no sensibles) y en el llavero (identificador de Apple),
/// y revalida la credencial de Apple al arrancar.
@MainActor
@Observable
final class SessionStore {
    /// Estado de autenticación actual.
    private(set) var state: AuthState = .signedOut

    /// Indica si hay una sesión iniciada (incluido el modo invitado).
    var isAuthenticated: Bool { state != .signedOut }

    /// Correo electrónico conocido del usuario, si lo hay.
    private(set) var email: String?

    /// Nombre para mostrar guardado (puede estar vacío).
    private var storedDisplayName: String = ""

    /// Nombre para mostrar derivado del estado actual.
    var displayName: String {
        if !storedDisplayName.isEmpty { return storedDisplayName }
        switch state {
        case .google(let email), .email(let email):
            return email
        case .apple:
            return email ?? String(
                localized: "session.displayname.apple",
                defaultValue: "Mi cuenta"
            )
        case .guest:
            return String(localized: "session.displayname.guest", defaultValue: "Invitado")
        case .signedOut:
            return ""
        }
    }

    // MARK: - Claves de persistencia

    private static let defaultsKey = "session.state.v1"
    private static let appleUserIDKey = "apple.user.id"

    /// Datos no sensibles persistidos en UserDefaults.
    private struct PersistedSession: Codable {
        enum Kind: String, Codable {
            case guest, apple, google, email
        }
        var kind: Kind
        var email: String?
        var displayName: String?
    }

    // MARK: - Carga

    /// Restaura la sesión persistida. Para Apple, revalida en segundo plano
    /// el estado de la credencial y cierra sesión si fue revocada.
    func loadPersisted() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let persisted = try? JSONDecoder().decode(PersistedSession.self, from: data) else {
            state = .signedOut
            return
        }
        email = persisted.email
        storedDisplayName = persisted.displayName ?? ""

        switch persisted.kind {
        case .guest:
            state = .guest
        case .google:
            state = .google(email: persisted.email ?? "")
        case .email:
            state = .email(email: persisted.email ?? "")
        case .apple:
            guard let userID = KeychainHelper.get(Self.appleUserIDKey) else {
                signOut()
                return
            }
            state = .apple(userID: userID)
            // Revalidación asíncrona de la credencial de Apple.
            Task { await self.revalidateAppleCredential(userID: userID) }
        }
    }

    // MARK: - Inicio y cierre de sesión

    /// Inicia sesión en modo invitado (datos solo locales).
    func signInAsGuest() {
        email = nil
        storedDisplayName = ""
        state = .guest
        persist(kind: .guest)
    }

    /// Inicia sesión con Apple. Guarda el identificador de usuario en el llavero.
    func signIn(appleUserID: String, email: String?, fullName: PersonNameComponents?) {
        KeychainHelper.set(appleUserID, for: Self.appleUserIDKey)
        self.email = email
        if let fullName {
            let formatter = PersonNameComponentsFormatter()
            storedDisplayName = formatter.string(from: fullName)
        } else {
            storedDisplayName = ""
        }
        state = .apple(userID: appleUserID)
        persist(kind: .apple)
    }

    /// Inicia sesión con Google.
    func signIn(googleEmail: String, displayName: String?) {
        email = googleEmail
        storedDisplayName = displayName ?? ""
        state = .google(email: googleEmail)
        persist(kind: .google)
    }

    /// Inicia sesión con una cuenta de correo y contraseña ya verificada
    /// por `EmailAuthService`.
    func signIn(emailAccount: String) {
        email = emailAccount
        storedDisplayName = ""
        state = .email(email: emailAccount)
        persist(kind: .email)
    }

    /// Cierra la sesión y elimina toda la información persistida.
    func signOut() {
        state = .signedOut
        email = nil
        storedDisplayName = ""
        KeychainHelper.delete(Self.appleUserIDKey)
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
    }

    // MARK: - Privado

    /// Comprueba con Apple el estado de la credencial; si fue revocada
    /// o no se encuentra, cierra la sesión.
    private func revalidateAppleCredential(userID: String) async {
        let provider = ASAuthorizationAppleIDProvider()
        let credentialState = try? await provider.credentialState(forUserID: userID)
        if credentialState == .revoked || credentialState == .notFound {
            signOut()
        }
    }

    /// Persiste el estado actual (sin datos sensibles) en UserDefaults.
    private func persist(kind: PersistedSession.Kind) {
        let persisted = PersistedSession(
            kind: kind,
            email: email,
            displayName: storedDisplayName
        )
        guard let data = try? JSONEncoder().encode(persisted) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
