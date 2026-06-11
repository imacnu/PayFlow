import Foundation

/// Configuración central de la app. Todos los identificadores que dependen de la
/// cuenta de desarrollador de Apple/Google viven aquí con valores de relleno.
/// Consulta el README para los pasos de configuración en macOS.
enum AppConfig {
    // MARK: - iCloud / CloudKit

    /// Identificador del contenedor de CloudKit. Debe coincidir con los entitlements.
    static let cloudKitContainerID = "iCloud.com.example.subscriptionguardian"

    /// La sincronización con CloudKit está desactivada por defecto para que la app
    /// funcione en el simulador y sin cuenta de iCloud. Actívala tras crear el
    /// contenedor en el portal de desarrollador.
    static let cloudKitEnabled = false

    // MARK: - App Group (compartido con la extensión de widgets)

    static let appGroupID = "group.com.example.subscriptionguardian"

    /// Clave en UserDefaults compartido donde la app publica el snapshot para los widgets.
    static let widgetSnapshotKey = "widget.snapshot.v1"

    // MARK: - Google Sign In

    /// Desactivado por defecto: requiere un Client ID real en Info.plist (GIDClientID)
    /// y el esquema de URL invertido. Ver README.
    static let googleSignInEnabled = false

    // MARK: - StoreKit

    static let monthlyProductID = "sg.premium.monthly"
    static let yearlyProductID = "sg.premium.yearly"
    static var productIDs: [String] { [monthlyProductID, yearlyProductID] }

    // MARK: - Límites del plan gratuito

    static let freeSubscriptionLimit = 15
    static let freeFinancingLimit = 5
}
