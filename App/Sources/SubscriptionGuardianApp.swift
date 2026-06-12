import SwiftUI
import SwiftData

/// Punto de entrada de la app Subscription Guardian.
@main
struct SubscriptionGuardianApp: App {
    /// Dependencias de la app, construidas una sola vez al arrancar.
    @State private var deps: AppDependencies

    /// Apariencia preferida (sistema, claro u oscuro).
    @AppStorage(AppAppearance.storageKey) private var appearanceRaw = AppAppearance.system.rawValue
    /// Idioma de la interfaz (sistema, castellano o inglés).
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    init() {
        let container = ModelContainerFactory.make()
        let dependencies = AppDependencies(container: container)
        // Publicamos el contenedor para componentes fuera de SwiftUI (App Intents).
        SharedModelContainer.shared.container = container
        _deps = State(initialValue: dependencies)
        // El idioma forzado debe instalarse antes de renderizar la primera vista.
        AppLanguage.persisted.apply()
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // Reconstruye toda la jerarquía al cambiar de idioma para que
                // las cadenas ya renderizadas se vuelvan a resolver.
                .id(languageRaw)
                .environment(\.locale, language.locale ?? .current)
                .environment(\.dependencies, deps)
                .modelContainer(deps.container)
                .task {
                    // Arranque: apariencia, derechos de compra, sesión
                    // persistida y primera propagación de datos.
                    (AppAppearance(rawValue: appearanceRaw) ?? .system).applyToWindows()
                    deps.entitlements.listenForUpdates()
                    await deps.entitlements.refresh()
                    deps.session.loadPersisted()
                    deps.dataDidChange()
                }
                .onChange(of: appearanceRaw) { _, newValue in
                    (AppAppearance(rawValue: newValue) ?? .system).applyToWindows()
                }
                .onChange(of: languageRaw) { _, newValue in
                    (AppLanguage(rawValue: newValue) ?? .system).apply()
                }
        }
    }
}
