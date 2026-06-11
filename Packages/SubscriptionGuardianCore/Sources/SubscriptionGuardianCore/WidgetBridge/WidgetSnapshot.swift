import Foundation

/// Próximo cargo (renovación o cuota) que se muestra en el widget.
public struct UpcomingPayment: Sendable, Codable, Hashable, Identifiable {
    public let id: UUID
    /// Nombre del servicio o comercio.
    public let name: String
    /// Importe del cargo.
    public let amount: Decimal
    /// Código ISO 4217 de la divisa.
    public let currencyCode: String
    /// Fecha del cargo.
    public let date: Date
    /// Tipo de cargo: "subscription" o "financing".
    public let kindRaw: String

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        currencyCode: String = "EUR",
        date: Date,
        kindRaw: String = "subscription"
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currencyCode = currencyCode
        self.date = date
        self.kindRaw = kindRaw
    }
}

/// Instantánea de datos que la app comparte con el widget
/// (serializada como JSON en el contenedor compartido del App Group).
public struct WidgetSnapshot: Sendable, Codable, Hashable {
    /// Momento en el que se generó la instantánea.
    public let generatedAt: Date
    /// Gasto mensual total.
    public let monthlyTotal: Decimal
    /// Código ISO 4217 de la divisa principal.
    public let currencyCode: String
    /// Número de suscripciones activas.
    public let activeSubscriptions: Int
    /// Número de financiaciones activas.
    public let activeFinancings: Int
    /// Indica si el usuario tiene la suscripción premium de la app.
    public let isPremium: Bool
    /// Próximos cargos ordenados por fecha.
    public let nextPayments: [UpcomingPayment]
    /// Desglose del gasto mensual por categoría.
    public let categoryBreakdown: [SpendingCalculator.CategorySlice]

    public init(
        generatedAt: Date = Date(),
        monthlyTotal: Decimal,
        currencyCode: String = "EUR",
        activeSubscriptions: Int,
        activeFinancings: Int,
        isPremium: Bool = false,
        nextPayments: [UpcomingPayment] = [],
        categoryBreakdown: [SpendingCalculator.CategorySlice] = []
    ) {
        self.generatedAt = generatedAt
        self.monthlyTotal = monthlyTotal
        self.currencyCode = currencyCode
        self.activeSubscriptions = activeSubscriptions
        self.activeFinancings = activeFinancings
        self.isPremium = isPremium
        self.nextPayments = nextPayments
        self.categoryBreakdown = categoryBreakdown
    }

    /// Datos de ejemplo realistas para previsualizaciones y placeholders del widget.
    public static let placeholder: WidgetSnapshot = {
        let now = Date()
        // Importes construidos con enteros para evitar conversiones desde Double.
        let netflix = Decimal(1799) / Decimal(100)   // 17.99
        let spotify = Decimal(1099) / Decimal(100)   // 10.99
        let icloud = Decimal(299) / Decimal(100)     // 2.99
        let installment = Decimal(4150) / Decimal(100) // 41.50
        let total = Decimal(7347) / Decimal(100)     // 73.47

        return WidgetSnapshot(
            generatedAt: now,
            monthlyTotal: total,
            currencyCode: "EUR",
            activeSubscriptions: 3,
            activeFinancings: 1,
            isPremium: false,
            nextPayments: [
                UpcomingPayment(
                    name: "Netflix",
                    amount: netflix,
                    currencyCode: "EUR",
                    date: now.addingTimeInterval(2 * 86_400),
                    kindRaw: "subscription"
                ),
                UpcomingPayment(
                    name: "Spotify",
                    amount: spotify,
                    currencyCode: "EUR",
                    date: now.addingTimeInterval(5 * 86_400),
                    kindRaw: "subscription"
                ),
                UpcomingPayment(
                    name: "iCloud+",
                    amount: icloud,
                    currencyCode: "EUR",
                    date: now.addingTimeInterval(9 * 86_400),
                    kindRaw: "subscription"
                ),
                UpcomingPayment(
                    name: "MediaMarkt",
                    amount: installment,
                    currencyCode: "EUR",
                    date: now.addingTimeInterval(12 * 86_400),
                    kindRaw: "financing"
                )
            ],
            categoryBreakdown: [
                SpendingCalculator.CategorySlice(category: .streaming, monthlyAmount: netflix),
                SpendingCalculator.CategorySlice(category: .music, monthlyAmount: spotify),
                SpendingCalculator.CategorySlice(category: .productivity, monthlyAmount: icloud)
            ]
        )
    }()

    /// Serializa la instantánea como JSON con fechas ISO 8601.
    public func encoded() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(self)
    }

    /// Reconstruye una instantánea desde JSON con fechas ISO 8601.
    public static func decode(from data: Data) -> WidgetSnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }
}
