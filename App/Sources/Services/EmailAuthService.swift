//
//  EmailAuthService.swift
//  Subscription Guardian
//
//  Registro e inicio de sesión con correo y contraseña. Las cuentas se
//  guardan localmente en el llavero (sal aleatoria + hash SHA-256); cuando
//  exista un backend, este servicio es el único punto a sustituir.
//

import Foundation
import CryptoKit
import Security

/// Errores del registro e inicio de sesión con correo.
enum EmailAuthError: Error {
    case invalidEmail
    case weakPassword
    case accountExists
    case accountNotFound
    case invalidCredentials
}

enum EmailAuthService {
    /// Longitud mínima exigida a la contraseña.
    static let minimumPasswordLength = 8

    /// Crea una cuenta local. Lanza error si el correo no es válido,
    /// la contraseña es débil o la cuenta ya existe.
    static func register(email: String, password: String) throws {
        let normalized = try normalize(email)
        guard password.count >= minimumPasswordLength else {
            throw EmailAuthError.weakPassword
        }
        guard KeychainHelper.get(key(for: normalized)) == nil else {
            throw EmailAuthError.accountExists
        }
        let salt = randomSalt()
        KeychainHelper.set("\(salt):\(hash(password, salt: salt))", for: key(for: normalized))
    }

    /// Verifica las credenciales de una cuenta local existente.
    static func signIn(email: String, password: String) throws {
        let normalized = try normalize(email)
        guard let stored = KeychainHelper.get(key(for: normalized)) else {
            throw EmailAuthError.accountNotFound
        }
        let parts = stored.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, hash(password, salt: parts[0]) == parts[1] else {
            throw EmailAuthError.invalidCredentials
        }
    }

    // MARK: - Privado

    private static func key(for email: String) -> String {
        "email.account.\(email)"
    }

    /// Valida el formato del correo y lo devuelve normalizado en minúsculas.
    private static func normalize(_ email: String) throws -> String {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              parts[1].contains("."),
              !parts[1].hasPrefix("."),
              !parts[1].hasSuffix("."),
              !trimmed.contains(" ") else {
            throw EmailAuthError.invalidEmail
        }
        return trimmed
    }

    private static func randomSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }

    private static func hash(_ password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + password).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
