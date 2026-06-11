import Foundation
import Security

/// Acceso mínimo al llavero del sistema para cadenas de texto
/// (contraseñas genéricas asociadas al servicio de la app).
enum KeychainHelper {
    /// Identificador de servicio bajo el que se guardan todas las entradas.
    private static let service = "com.example.subscriptionguardian"

    /// Guarda (o reemplaza) un valor para la clave dada.
    static func set(_ value: String, for key: String) {
        // Eliminamos primero cualquier entrada previa para evitar errSecDuplicateItem.
        delete(key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: Data(value.utf8)
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Recupera el valor de la clave dada, o `nil` si no existe.
    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Elimina la entrada de la clave dada (si existe).
    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
