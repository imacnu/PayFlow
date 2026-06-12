//
//  InsightCardView.swift
//  Subscription Guardian
//
//  Tarjeta que traduce los datos semánticos de un Insight a texto
//  localizado con icono y acento por tipo.
//

import SwiftUI
import SubscriptionGuardianCore

struct InsightCardView: View {
    let insight: Insight
    let currencyCode: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(tint))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let saving = insight.estimatedAnnualSaving, saving > 0 {
                    PillBadge(
                        text: String(
                            localized: "insights.savingBadge",
                            defaultValue: "Ahorra \(saving.formatted(.currency(code: currencyCode)))/año"
                        ),
                        tint: .green
                    )
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .glassCard()
    }

    // MARK: - Presentación por tipo

    private var iconName: String {
        switch insight.kind {
        case .duplicateCategory: return "square.on.square"
        case .unusedSubscription: return "moon.zzz.fill"
        case .priceIncrease: return "arrow.up.circle.fill"
        case .financingAlmostDone: return "flag.checkered"
        case .dominantCategory: return "chart.pie.fill"
        }
    }

    private var tint: Color {
        switch insight.kind {
        case .duplicateCategory: return .orange
        case .unusedSubscription: return .purple
        case .priceIncrease: return .red
        case .financingAlmostDone: return .green
        case .dominantCategory: return .appCyan
        }
    }

    private var title: String {
        switch insight.kind {
        case .duplicateCategory:
            return String(localized: "insights.duplicate.title", defaultValue: "Posible duplicado")
        case .unusedSubscription:
            return String(localized: "insights.unused.title", defaultValue: "Suscripción sin uso")
        case .priceIncrease:
            return String(localized: "insights.priceIncrease.title", defaultValue: "Subida de precio")
        case .financingAlmostDone:
            return String(localized: "insights.almostDone.title", defaultValue: "Financiación casi terminada")
        case .dominantCategory:
            return String(localized: "insights.dominant.title", defaultValue: "Categoría dominante")
        }
    }

    private var message: String {
        let names = insight.subscriptionNames
        let firstName = names.first ?? ""
        let categoryName = insight.category?.localizedName ?? ""

        switch insight.kind {
        case .duplicateCategory:
            let joined = names.joined(separator: ", ")
            return String(
                localized: "insights.duplicate.message",
                defaultValue: "Tienes \(names.count) servicios de \(categoryName): \(joined). Podrías cancelar el más barato."
            )
        case .unusedSubscription:
            return String(
                localized: "insights.unused.message",
                defaultValue: "No usas \(firstName) desde hace tiempo. Valora cancelarla."
            )
        case .priceIncrease:
            let increase = insight.amount?.formatted(.currency(code: currencyCode)) ?? ""
            return String(
                localized: "insights.priceIncrease.message",
                defaultValue: "\(firstName) ha subido de precio (+\(increase)/año)."
            )
        case .financingAlmostDone:
            let monthly = insight.amount?.formatted(.currency(code: currencyCode)) ?? ""
            if let endDate = insight.referenceDate {
                let dateText = endDate.formatted(.dateTime.day().month(.wide))
                return String(
                    localized: "insights.almostDone.messageWithDate",
                    defaultValue: "\(firstName) termina el \(dateText): liberarás \(monthly)/mes."
                )
            }
            return String(
                localized: "insights.almostDone.message",
                defaultValue: "\(firstName) termina pronto: liberarás \(monthly)/mes."
            )
        case .dominantCategory:
            // El símbolo % va dentro de la interpolación para no dejar un "%"
            // suelto en la cadena de formato localizada.
            let percent = insight.amount.map { "\($0) %" } ?? ""
            return String(
                localized: "insights.dominant.message",
                defaultValue: "\(categoryName) supone el \(percent) de tu gasto mensual."
            )
        }
    }
}
