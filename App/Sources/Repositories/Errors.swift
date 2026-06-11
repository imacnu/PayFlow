import Foundation

/// Errores comunes de la capa de repositorios.
enum RepositoryError: Error {
    /// Se ha alcanzado el límite del plan gratuito para el tipo indicado.
    case freeTierLimitReached(kind: LimitKind)

    /// Tipo de entidad sujeta a límite en el plan gratuito.
    enum LimitKind: Sendable {
        case subscriptions
        case financings
    }
}
