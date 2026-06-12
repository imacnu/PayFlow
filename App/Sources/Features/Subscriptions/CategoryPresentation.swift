//
//  CategoryPresentation.swift
//  Subscription Guardian
//
//  Presentación localizada de los enums de dominio (categoría, frecuencia
//  y proveedor BNPL). Este archivo es el ÚNICO propietario de estas
//  extensiones para evitar símbolos duplicados entre módulos de features.
//

import SwiftUI
import SubscriptionGuardianCore

// MARK: - ServiceCategory

extension ServiceCategory {
    /// Nombre localizado de la categoría.
    var localizedName: String {
        switch self {
        case .streaming:
            return String(localized: "subscriptions.category.streaming", defaultValue: "Streaming")
        case .ai:
            return String(localized: "subscriptions.category.ai", defaultValue: "IA")
        case .productivity:
            return String(localized: "subscriptions.category.productivity", defaultValue: "Productividad")
        case .music:
            return String(localized: "subscriptions.category.music", defaultValue: "Música")
        case .finance:
            return String(localized: "subscriptions.category.finance", defaultValue: "Finanzas")
        case .fitness:
            return String(localized: "subscriptions.category.fitness", defaultValue: "Fitness")
        case .insurance:
            return String(localized: "subscriptions.category.insurance", defaultValue: "Seguros")
        case .membership:
            return String(localized: "subscriptions.category.membership", defaultValue: "Membresías")
        case .other:
            return String(localized: "subscriptions.category.other", defaultValue: "Otros")
        }
    }

    /// Color de acento asociado a la categoría (familia neón del mockup).
    var tintColor: Color {
        switch self {
        case .streaming: return .appCyan
        case .ai: return .appTeal
        case .productivity: return .appMagenta
        case .music: return .appLime
        case .finance: return .appAmber
        case .fitness: return Color(hex: "FF6C62")
        case .insurance: return .electricBlue
        case .membership: return Color(hex: "7E82FF")
        case .other: return .appMuted
        }
    }

    /// Símbolo SF representativo de la categoría.
    var symbolName: String {
        switch self {
        case .streaming: return "play.tv.fill"
        case .ai: return "brain.head.profile"
        case .productivity: return "briefcase.fill"
        case .music: return "music.note"
        case .finance: return "banknote.fill"
        case .fitness: return "figure.run"
        case .insurance: return "shield.fill"
        case .membership: return "person.2.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
}

// MARK: - BillingFrequency

extension BillingFrequency {
    /// Nombre localizado de la frecuencia de facturación.
    var localizedName: String {
        switch self {
        case .weekly:
            return String(localized: "subscriptions.frequency.weekly", defaultValue: "Semanal")
        case .monthly:
            return String(localized: "subscriptions.frequency.monthly", defaultValue: "Mensual")
        case .quarterly:
            return String(localized: "subscriptions.frequency.quarterly", defaultValue: "Trimestral")
        case .semiannual:
            return String(localized: "subscriptions.frequency.semiannual", defaultValue: "Semestral")
        case .annual:
            return String(localized: "subscriptions.frequency.annual", defaultValue: "Anual")
        }
    }
}

// MARK: - BNPLProvider

extension BNPLProvider {
    /// Nombre localizado del proveedor. Los nombres de marca no se traducen;
    /// solo "custom" se muestra localizado como "Otro".
    var localizedName: String {
        switch self {
        case .custom:
            return String(localized: "financing.provider.custom", defaultValue: "Otro")
        default:
            return displayName
        }
    }
}
