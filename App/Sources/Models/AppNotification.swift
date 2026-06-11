import Foundation
import SwiftData
import SubscriptionGuardianCore

/// Notificación interna mostrada en el buzón de la app.
/// Modelo compatible con CloudKit: sin atributos únicos y todas las
/// propiedades con valor por defecto u opcionales.
@Model
final class AppNotification {
    /// Identificador único de la notificación.
    var id: UUID = UUID()
    /// Tipo de notificación, almacenado como cadena cruda.
    var typeRaw: String = AppNotificationType.renewalUpcoming.rawValue
    /// Título mostrado al usuario.
    var title: String = ""
    /// Cuerpo del mensaje.
    var body: String = ""
    /// Fecha de la notificación.
    var date: Date = Date()
    /// Indica si el usuario ya la ha leído.
    var isRead: Bool = false
    /// Identificador de la suscripción o financiación relacionada, si aplica.
    var relatedEntityID: UUID?

    /// Acceso tipado al tipo de notificación (no persistido).
    var type: AppNotificationType {
        get { AppNotificationType(rawValue: typeRaw) ?? .renewalUpcoming }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        type: AppNotificationType = .renewalUpcoming,
        title: String = "",
        body: String = "",
        date: Date = Date(),
        isRead: Bool = false,
        relatedEntityID: UUID? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.title = title
        self.body = body
        self.date = date
        self.isRead = isRead
        self.relatedEntityID = relatedEntityID
    }
}
