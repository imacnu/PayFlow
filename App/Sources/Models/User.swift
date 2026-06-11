import Foundation
import SwiftData

/// Proveedor de autenticación con el que se creó la cuenta del usuario.
enum AuthProvider: String, Codable, Sendable {
    case apple
    case google
    case guest
}

/// Usuario de la app. Modelo compatible con CloudKit: sin atributos únicos,
/// todas las propiedades con valor por defecto u opcionales y relaciones opcionales.
@Model
final class User {
    /// Identificador único del usuario.
    var id: UUID = UUID()
    /// Correo electrónico, si el proveedor de autenticación lo facilita.
    var email: String?
    /// Nombre para mostrar.
    var displayName: String = ""
    /// Símbolo SF usado como avatar.
    var avatarSymbol: String = "person.crop.circle.fill"
    /// Color del avatar en hexadecimal "RRGGBB".
    var avatarColorHex: String = "1F6FEB"
    /// Proveedor de autenticación, almacenado como cadena cruda.
    var authProviderRaw: String = AuthProvider.guest.rawValue
    /// Fecha de creación del registro.
    var createdAt: Date = Date()

    /// Suscripciones del usuario. Se eliminan en cascada al borrar el usuario.
    @Relationship(deleteRule: .cascade, inverse: \Subscription.owner)
    var subscriptions: [Subscription]? = []

    /// Financiaciones del usuario. Se eliminan en cascada al borrar el usuario.
    @Relationship(deleteRule: .cascade, inverse: \Financing.owner)
    var financings: [Financing]? = []

    /// Acceso tipado al proveedor de autenticación (no persistido).
    var authProvider: AuthProvider {
        get { AuthProvider(rawValue: authProviderRaw) ?? .guest }
        set { authProviderRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        email: String? = nil,
        displayName: String = "",
        avatarSymbol: String = "person.crop.circle.fill",
        avatarColorHex: String = "1F6FEB",
        authProvider: AuthProvider = .guest,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarSymbol = avatarSymbol
        self.avatarColorHex = avatarColorHex
        self.authProviderRaw = authProvider.rawValue
        self.createdAt = createdAt
        self.subscriptions = []
        self.financings = []
    }
}
