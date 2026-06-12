import Foundation
import SwiftData
import SubscriptionGuardianCore

/// Borrador editable de una financiación, usado por los formularios de alta y edición.
struct FinancingDraft {
    var merchant: String = ""
    var provider: BNPLProvider = .custom
    var totalAmount: Decimal = 0
    var monthlyAmount: Decimal = 0
    var interestRate: Decimal = 0
    var totalInstallments: Int = 1
    var firstInstallmentDate: Date?
    var notes: String = ""
}

/// Contrato del repositorio de financiaciones.
@MainActor
protocol FinancingRepositoryProtocol: AnyObject {
    func all() throws -> [Financing]
    func active() throws -> [Financing]
    func create(from draft: FinancingDraft) throws -> Financing
    func update(_ financing: Financing, with draft: FinancingDraft) throws
    func delete(_ financing: Financing) throws
    func summaries() throws -> [FinancingSummary]
}

/// Repositorio de financiaciones respaldado por SwiftData.
@MainActor
final class SwiftDataFinancingRepository: FinancingRepositoryProtocol {
    private let context: ModelContext
    private let entitlements: EntitlementStore

    /// Callback invocado tras cada mutación; la capa de DI lo conecta con la
    /// escritura del snapshot del widget y la reprogramación de notificaciones.
    var onChange: @MainActor () -> Void

    init(
        context: ModelContext,
        entitlements: EntitlementStore,
        onChange: @escaping @MainActor () -> Void = {}
    ) {
        self.context = context
        self.entitlements = entitlements
        self.onChange = onChange
    }

    /// Todas las financiaciones, con las cuotas devengadas sincronizadas:
    /// el paso del tiempo marca como pagadas las cuotas ya vencidas.
    func all() throws -> [Financing] {
        let descriptor = FetchDescriptor<Financing>(
            sortBy: [SortDescriptor(\Financing.merchant)]
        )
        let financings = try context.fetch(descriptor)
        var changed = false
        for financing in financings where syncAccruedInstallments(financing) {
            changed = true
        }
        // Sin `onChange()`: este método se invoca desde la propia propagación
        // de cambios y volver a dispararla provocaría reentradas.
        if changed { try context.save() }
        return financings
    }

    /// Financiaciones activas. Filtrado en memoria por las mismas razones
    /// que en el repositorio de suscripciones.
    func active() throws -> [Financing] {
        try all().filter { $0.statusRaw == FinancingStatus.active.rawValue }
    }

    func create(from draft: FinancingDraft) throws -> Financing {
        let currentCount = try all().count
        guard entitlements.canAddFinancing(currentCount: currentCount) else {
            throw RepositoryError.freeTierLimitReached(kind: .financings)
        }
        let financing = Financing()
        apply(draft, to: financing)
        context.insert(financing)
        try context.save()
        onChange()
        return financing
    }

    func update(_ financing: Financing, with draft: FinancingDraft) throws {
        apply(draft, to: financing)
        // Mantenemos la coherencia si baja el número total de cuotas.
        if financing.paidInstallments > financing.totalInstallments {
            financing.paidInstallments = financing.totalInstallments
        }
        try context.save()
        onChange()
    }

    func delete(_ financing: Financing) throws {
        context.delete(financing)
        try context.save()
        onChange()
    }

    func summaries() throws -> [FinancingSummary] {
        try all().map { $0.summary }
    }

    // MARK: - Privado

    /// Vuelca los campos del borrador en el modelo y recalcula las cuotas
    /// devengadas a partir de la fecha de primera cuota.
    private func apply(_ draft: FinancingDraft, to financing: Financing) {
        financing.merchant = draft.merchant
        financing.provider = draft.provider
        financing.totalAmount = draft.totalAmount
        financing.monthlyAmount = draft.monthlyAmount
        financing.interestRate = draft.interestRate
        financing.totalInstallments = max(1, draft.totalInstallments)
        financing.firstInstallmentDate = draft.firstInstallmentDate
        financing.notes = draft.notes
        _ = syncAccruedInstallments(financing)
    }

    /// Sincroniza las cuotas pagadas con las devengadas por el paso del tiempo
    /// (vencimiento anterior o igual a hoy). Devuelve `true` si hubo cambios.
    @discardableResult
    private func syncAccruedInstallments(_ financing: Financing) -> Bool {
        guard financing.status != .cancelled,
              let firstDate = financing.firstInstallmentDate else {
            return false
        }
        let accrued = FinancingCalculator.accruedInstallments(
            firstInstallmentDate: firstDate,
            totalInstallments: financing.totalInstallments
        )
        let newStatus: FinancingStatus = accrued >= financing.totalInstallments
            ? .completed
            : .active
        guard financing.paidInstallments != accrued || financing.status != newStatus else {
            return false
        }
        financing.paidInstallments = accrued
        financing.status = newStatus
        return true
    }
}
