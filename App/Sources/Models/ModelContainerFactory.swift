import Foundation
import SwiftData

/// Fábrica del contenedor de SwiftData de la app.
@MainActor
enum ModelContainerFactory {
    /// Esquema completo de la app.
    private static func makeSchema() -> Schema {
        Schema([User.self, Subscription.self, Financing.self, AppNotification.self])
    }

    /// Crea el contenedor de producción.
    ///
    /// Intenta CloudKit si `AppConfig.cloudKitEnabled`; si falla, cae a un
    /// almacén local en disco; como último recurso devuelve uno en memoria
    /// para que la app nunca arranque sin contenedor.
    static func make() -> ModelContainer {
        let schema = makeSchema()

        if AppConfig.cloudKitEnabled {
            do {
                let configuration = ModelConfiguration(
                    schema: schema,
                    cloudKitDatabase: .private(AppConfig.cloudKitContainerID)
                )
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                // CloudKit no disponible (sin entitlements o sin cuenta de iCloud):
                // continuamos con el almacén local.
            }
        }

        do {
            // Almacén local explícito, sin sincronización con CloudKit.
            let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Último recurso: contenedor en memoria.
            return makeInMemory()
        }
    }

    /// Contenedor en memoria para previews y tests.
    static func makeInMemory() -> ModelContainer {
        let schema = makeSchema()
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // En memoria no hay E/S de disco; un fallo aquí sería un error de programación.
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}
