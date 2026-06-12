//
//  AppPreferences.swift
//  Subscription Guardian
//
//  Preferencias de usuario persistidas en UserDefaults vía @AppStorage:
//  apariencia (claro/oscuro/sistema) e idioma de la interfaz.
//

import SwiftUI
import UIKit

/// Apariencia de la interfaz: seguir al sistema o forzar claro/oscuro.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "pref.appearance"

    var id: String { rawValue }

    /// Estilo de interfaz de UIKit equivalente.
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }

    var localizedName: String {
        switch self {
        case .system:
            return String(localized: "appearance.system", defaultValue: "Sistema")
        case .light:
            return String(localized: "appearance.light", defaultValue: "Claro")
        case .dark:
            return String(localized: "appearance.dark", defaultValue: "Oscuro")
        }
    }

    /// Aplica la apariencia a todas las ventanas de la app. A diferencia de
    /// `preferredColorScheme` (que no alcanza a las hojas modales), el
    /// override de la ventana afecta a toda la jerarquía, Ajustes incluido.
    @MainActor
    func applyToWindows() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = interfaceStyle
            }
        }
    }
}

/// Idioma de la interfaz. El cambio se aplica en caliente redirigiendo las
/// búsquedas de cadenas al `.lproj` elegido (ver `LanguageOverrideBundle`).
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case spanish = "es"
    case english = "en"

    static let storageKey = "pref.language"

    var id: String { rawValue }

    /// Nombre del idioma en su propio idioma (endónimo), sin localizar.
    var displayName: String {
        switch self {
        case .system:
            return String(localized: "language.system", defaultValue: "Sistema")
        case .spanish:
            return "Castellano"
        case .english:
            return "English"
        }
    }

    /// Locale para los formatos de fecha y número de SwiftUI.
    var locale: Locale? {
        switch self {
        case .system: return nil
        case .spanish: return Locale(identifier: "es_ES")
        case .english: return Locale(identifier: "en_US")
        }
    }

    /// Idioma persistido, leído directamente de UserDefaults (para el arranque,
    /// antes de que @AppStorage esté disponible).
    static var persisted: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .system
    }

    /// Aplica el idioma de inmediato (override del bundle) y lo persiste
    /// también en `AppleLanguages` para que el sistema lo respete al reiniciar.
    @MainActor
    func apply() {
        LanguageOverrideBundle.activate(languageCode: self == .system ? nil : rawValue)
        switch self {
        case .system:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        case .spanish, .english:
            UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        }
    }
}

/// Subclase de Bundle que redirige las búsquedas de cadenas localizadas al
/// idioma elegido en la app. Se instala sobre `Bundle.main` con
/// `object_setClass`, de modo que `String(localized:)` y `Text` resuelven
/// contra el `.lproj` del idioma forzado sin reiniciar la app.
private final class LanguageOverrideBundle: Bundle, @unchecked Sendable {
    /// Bundle del idioma forzado; `nil` sigue al sistema.
    /// Solo se escribe desde el hilo principal.
    nonisolated(unsafe) private static var overrideBundle: Bundle?
    nonisolated(unsafe) private static var isInstalled = false

    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = Self.overrideBundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }

    @MainActor
    static func activate(languageCode: String?) {
        if !isInstalled {
            object_setClass(Bundle.main, LanguageOverrideBundle.self)
            isInstalled = true
        }
        guard let languageCode,
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            overrideBundle = nil
            return
        }
        overrideBundle = bundle
    }
}
