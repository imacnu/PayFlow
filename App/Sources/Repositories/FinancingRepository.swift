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
    func markInstallmentPaid(_ financing: Financing) throws
    func undoInstallment(_ financing: Financing) throws
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

    func all() throws -> [Financing] {
        let descriptor = FetchDescriptor<Financing>(
            sortBy: [SortDescriptor(\Financing.merchant)]
        )
        return try context.fetch(descriptor)
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

    /// Marca una cuota como pagada. Al llegar al total, la financiación
    /// pasa a estado completado.
    func markInstallmentPaid(_ financing: Financing) throws {
        guard financing.paidInstallments < financing.totalInstallments else { return }
        financing.paidInstallments += 1
        if financing.paidInstallments >= financing.totalInstallments {
            financing.status = .completed
        }
        try context.save()
        onChange()
    }

    /// Deshace la última cuota pagada y reactiva la financiación si estaba completada.
    func undoInstallment(_ financing: Financing) throws {
        guard financing.paidInstallments > 0 else { return }
        financing.paidInstallments -= 1
        if financing.status == .completed {
            financing.status = .active
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

    /// Vuelca los campos del borrador en el modelo.
    private func apply(_ draft: FinancingDraft, to financing: Financing) {
        financing.merchant = draft.merchant
        financing.provider = draft.provider
        financing.totalAmount = draft.totalAmount
        financing.monthlyAmount = draft.monthlyAmount
        financing.interestRate = draft.interestRate
        financing.totalInstallments = max(1, draft.totalInstallments)
        financing.firstInstallmentDate = draft.firstInstallmentDate
        financing.notes = draft.notes
    }
}
