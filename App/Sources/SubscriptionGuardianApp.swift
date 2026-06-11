import SwiftUI
import SwiftData

/// Punto de entrada de la app Subscription Guardian.
@main
struct SubscriptionGuardianApp: App {
    /// Dependencias de la app, construidas una sola vez al arrancar.
    @State private var deps: AppDependencies

    init() {
        let container = ModelContainerFactory.make()
        let dependencies = AppDependencies(container: container)
        // Publicamos el contenedor para componentes fuera de SwiftUI (App Intents).
        SharedModelContainer.shared.container = container
        _deps = State(initialValue: dependencies)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.dependencies, deps)
                .modelContainer(deps.container)
                .task {
                    // Arranque: derechos de compra, sesión persistida y
                    // primera propagación de datos (snapshot + notificaciones).
                    deps.entitlements.listenForUpdates()
                    await deps.entitlements.refresh()
                    deps.session.loadPersisted()
                    deps.dataDidChange()
                }
        }
    }
}
