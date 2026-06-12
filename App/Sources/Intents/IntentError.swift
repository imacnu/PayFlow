//
//  IntentError.swift
//  Subscription Guardian
//
//  Errores comunes de los App Intents.
//

import Foundation
import AppIntents

/// Error lanzado por los intents cuando la app aún no está lista.
enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case notReady

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notReady:
            return "Abre Subscription Guardian al menos una vez para usar esta función."
        }
    }
}
