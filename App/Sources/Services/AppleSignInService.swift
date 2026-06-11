import Foundation
import AuthenticationServices

/// Errores al procesar el resultado de "Iniciar sesión con Apple".
enum AppleSignInError: Error {
    /// El resultado no contiene una credencial de Apple ID válida.
    case invalidCredential
}

/// Ayudante mínimo para extraer los datos útiles del resultado del botón
/// `SignInWithAppleButton` de SwiftUI. La vista lanza la petición; aquí
/// solo se procesa la respuesta.
enum AppleSignInService {
    /// Extrae (userID, email, fullName) de un resultado de autorización.
    /// Lanza el error original si la autorización falló.
    static func credential(
        from result: Result<ASAuthorization, Error>
    ) throws -> (userID: String, email: String?, fullName: PersonNameComponents?) {
        switch result {
        case .failure(let error):
            throw error
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AppleSignInError.invalidCredential
            }
            return (credential.user, credential.email, credential.fullName)
        }
    }
}
