import Foundation
import SwiftData
import SubscriptionGuardianCore

/// Compra financiada en plazos (BNPL).
/// Modelo compatible con CloudKit: sin atributos únicos, todas las propiedades
/// con valor por defecto u opcionales y relaciones opcionales.
@Model
final class Financing {
    /// Identificador único de la financiación.
    var id: UUID = UUID()
    /// Comercio donde se realizó la compra (p. ej. "MediaMarkt").
    var merchant: String = ""
    /// Proveedor BNPL, almacenado como cadena cruda.
    var providerRaw: String = BNPLProvider.custom.rawValue
    /// Importe total financiado.
    var totalAmount: Decimal = 0
    /// Importe de cada cuota mensual.
    var monthlyAmount: Decimal = 0
    /// Tipo de interés aplicado (porcentaje, 0 si es sin intereses).
    var interestRate: Decimal = 0
    /// Número total de cuotas.
    var totalInstallments: Int = 1
    /// Número de cuotas ya pagadas.
    var paidInstallments: Int = 0
    /// Fecha de la primera cuota.
    var firstInstallmentDate: Date?
    /// Estado de la financiación, almacenado como cadena cruda.
    var statusRaw: String = FinancingStatus.active.rawValue
    /// Notas libres del usuario.
    var notes: String = ""
    /// Fecha de creación del registro.
    var createdAt: Date = Date()
    /// Usuario propietario. Relación opcional por compatibilidad con CloudKit.
    var owner: User?

    /// Acceso tipado al proveedor (no persistido).
    var provider: BNPLProvider {
        get { BNPLProvider(rawValue: providerRaw) ?? .custom }
        set { providerRaw = newValue.rawValue }
    }

    /// Acceso tipado al estado (no persistido).
    var status: FinancingStatus {
        get { FinancingStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    // MARK: - Valores derivados (delegan en FinancingCalculator vía `summary`)

    /// Número de cuotas pendientes (nunca negativo).
    var pendingInstallments: Int {
        FinancingCalculator.pendingInstallments(summary)
    }

    /// Progreso de pago entre 0 y 1.
    var progress: Double {
        FinancingCalculator.progress(summary)
    }

    /// Fecha de la próxima cuota, si la financiación está activa y quedan plazos.
    var nextInstallmentDate: Date? {
        FinancingCalculator.nextInstallmentDate(summary)
    }

    /// Fecha de la última cuota.
    var endDate: Date? {
        FinancingCalculator.endDate(summary)
    }

    /// Capital pendiente de pago.
    var pendingCapital: Decimal {
        FinancingCalculator.pendingCapital(summary)
    }

    init(
        id: UUID = UUID(),
        merchant: String = "",
        provider: BNPLProvider = .custom,
        totalAmount: Decimal = 0,
        monthlyAmount: Decimal = 0,
        interestRate: Decimal = 0,
        totalInstallments: Int = 1,
        paidInstallments: Int = 0,
        firstInstallmentDate: Date? = nil,
        status: FinancingStatus = .active,
        notes: String = "",
        createdAt: Date = Date(),
        owner: User? = nil
    ) {
        self.id = id
        self.merchant = merchant
        self.providerRaw = provider.rawValue
        self.totalAmount = totalAmount
        self.monthlyAmount = monthlyAmount
        self.interestRate = interestRate
        self.totalInstallments = totalInstallments
        self.paidInstallments = paidInstallments
        self.firstInstallmentDate = firstInstallmentDate
        self.statusRaw = status.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.owner = owner
    }
}
