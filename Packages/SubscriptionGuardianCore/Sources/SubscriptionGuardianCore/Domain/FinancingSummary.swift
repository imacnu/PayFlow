import Foundation

/// Resumen inmutable de una compra financiada (BNPL),
/// usado por los cálculos del paquete.
public struct FinancingSummary: Sendable, Codable, Hashable, Identifiable {
    /// Identificador único de la financiación.
    public let id: UUID
    /// Comercio donde se realizó la compra (p. ej. "MediaMarkt").
    public let merchant: String
    /// Proveedor BNPL que gestiona los plazos.
    public let provider: BNPLProvider
    /// Importe total financiado.
    public let totalAmount: Decimal
    /// Importe de cada cuota mensual.
    public let monthlyAmount: Decimal
    /// Número total de cuotas.
    public let totalInstallments: Int
    /// Número de cuotas ya pagadas.
    public let paidInstallments: Int
    /// Fecha de la primera cuota, si se conoce.
    public let firstInstallmentDate: Date?
    /// Estado actual de la financiación.
    public let status: FinancingStatus
    /// Tipo de interés aplicado (porcentaje, 0 si es sin intereses).
    public let interestRate: Decimal

    public init(
        id: UUID = UUID(),
        merchant: String,
        provider: BNPLProvider = .custom,
        totalAmount: Decimal,
        monthlyAmount: Decimal,
        totalInstallments: Int,
        paidInstallments: Int = 0,
        firstInstallmentDate: Date? = nil,
        status: FinancingStatus = .active,
        interestRate: Decimal = 0
    ) {
        self.id = id
        self.merchant = merchant
        self.provider = provider
        self.totalAmount = totalAmount
        self.monthlyAmount = monthlyAmount
        self.totalInstallments = totalInstallments
        self.paidInstallments = paidInstallments
        self.firstInstallmentDate = firstInstallmentDate
        self.status = status
        self.interestRate = interestRate
    }
}
