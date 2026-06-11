import Foundation
import SwiftData

/// Contenedor de modelos compartido a nivel de proceso.
///
/// Los App Intents no pueden leer el entorno de SwiftUI, así que la app
/// publica aquí su `ModelContainer` al arrancar para que cualquier
/// componente fuera de la jerarquía de vistas pueda usarlo.
@MainActor
final class SharedModelContainer {
    /// Instancia única compartida.
    static let shared = SharedModelContainer()

    /// Contenedor activo de la app; lo asigna `SubscriptionGuardianApp` al lanzar.
    var container: ModelContainer?

    private init() {}
}
