import XCTest
@testable import SubscriptionGuardianCore

/// Pruebas de las heurísticas del motor de hallazgos.
final class InsightsEngineTests: XCTestCase {
    /// Calendario gregoriano fijado a Europe/Madrid para resultados deterministas.
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func generate(
        subscriptions: [SubscriptionSummary] = [],
        financings: [FinancingSummary] = [],
        now: Date
    ) -> [Insight] {
        InsightsEngine.generate(
            subscriptions: subscriptions,
            financings: financings,
            now: now,
            calendar: calendar
        )
    }

    func testDuplicateStreamingDetectionWithCheapestAnnualizedSaving() {
        let now = date(2026, 6, 11)
        let subscriptions = [
            SubscriptionSummary(name: "HBO Max", category: .streaming, amount: Decimal(string: "9.99")!, createdAt: now),
            SubscriptionSummary(name: "Netflix", category: .streaming, amount: Decimal(string: "17.99")!, createdAt: now)
        ]

        let insights = generate(subscriptions: subscriptions, now: now)
        let duplicates = insights.filter { $0.kind == .duplicateCategory }

        XCTAssertEqual(duplicates.count, 1)
        let insight = duplicates[0]
        XCTAssertEqual(insight.id, "duplicateCategory-streaming")
        XCTAssertEqual(insight.category, .streaming)
        // Nombres ordenados por coste mensual descendente.
        XCTAssertEqual(insight.subscriptionNames, ["Netflix", "HBO Max"])
        // Ahorro: el más barato anualizado (9.99 × 12).
        XCTAssertEqual(insight.estimatedAnnualSaving, Decimal(string: "119.88"))
    }

    func testUnusedSubscriptionSixtyDayRule() {
        let now = date(2026, 6, 11)
        let oldDate = date(2026, 1, 10)   // > 60 días antes
        let recentDate = date(2026, 6, 1) // < 60 días antes

        let unused = SubscriptionSummary(
            name: "Gym",
            category: .fitness,
            amount: Decimal(30),
            lastUsedAt: nil,
            createdAt: oldDate
        )
        let stillUsed = SubscriptionSummary(
            name: "Netflix",
            category: .streaming,
            amount: Decimal(string: "17.99")!,
            lastUsedAt: recentDate,
            createdAt: oldDate
        )
        let tooNew = SubscriptionSummary(
            name: "ChatGPT",
            category: .ai,
            amount: Decimal(20),
            lastUsedAt: nil,
            createdAt: recentDate
        )

        let insights = generate(subscriptions: [unused, stillUsed, tooNew], now: now)
        let unusedInsights = insights.filter { $0.kind == .unusedSubscription }

        XCTAssertEqual(unusedInsights.count, 1)
        XCTAssertEqual(unusedInsights[0].subscriptionNames, ["Gym"])
        // Ahorro: equivalente mensual anualizado (30 × 12).
        XCTAssertEqual(unusedInsights[0].estimatedAnnualSaving, Decimal(360))
    }

    func testPriceIncreaseAnnualizedDelta() {
        let now = date(2026, 6, 11)
        let subscription = SubscriptionSummary(
            name: "Netflix",
            category: .streaming,
            amount: Decimal(string: "12.99")!,
            previousAmount: Decimal(string: "9.99")!,
            createdAt: now
        )

        let insights = generate(subscriptions: [subscription], now: now)
        let increases = insights.filter { $0.kind == .priceIncrease }

        XCTAssertEqual(increases.count, 1)
        // Subida anualizada: 3.00 × 12 = 36.00.
        XCTAssertEqual(increases[0].amount, Decimal(36))
        XCTAssertNil(increases[0].estimatedAnnualSaving)
    }

    func testFinancingAlmostDone() {
        let now = date(2026, 6, 11)
        let financing = FinancingSummary(
            merchant: "MediaMarkt",
            provider: .klarna,
            totalAmount: Decimal(600),
            monthlyAmount: Decimal(50),
            totalInstallments: 12,
            paidInstallments: 10,
            firstInstallmentDate: date(2025, 9, 5)
        )

        let insights = generate(financings: [financing], now: now)
        let almostDone = insights.filter { $0.kind == .financingAlmostDone }

        XCTAssertEqual(almostDone.count, 1)
        XCTAssertEqual(almostDone[0].subscriptionNames, ["MediaMarkt"])
        XCTAssertEqual(almostDone[0].amount, Decimal(50))
        XCTAssertEqual(almostDone[0].referenceDate, date(2026, 8, 5))
    }

    func testDominantCategoryThreshold() {
        let now = date(2026, 6, 11)
        // streaming 50 de 60 → 83.33 % (> 40 %).
        let dominant = [
            SubscriptionSummary(name: "Netflix", category: .streaming, amount: Decimal(50), createdAt: now),
            SubscriptionSummary(name: "iCloud+", category: .productivity, amount: Decimal(10), createdAt: now)
        ]
        let dominantInsights = generate(subscriptions: dominant, now: now)
            .filter { $0.kind == .dominantCategory }

        XCTAssertEqual(dominantInsights.count, 1)
        XCTAssertEqual(dominantInsights[0].category, .streaming)
        XCTAssertEqual(dominantInsights[0].amount, Decimal(string: "83.33"))

        // Reparto equilibrado por debajo del umbral: sin hallazgo.
        let balanced = [
            SubscriptionSummary(name: "Netflix", category: .streaming, amount: Decimal(10), createdAt: now),
            SubscriptionSummary(name: "iCloud+", category: .productivity, amount: Decimal(10), createdAt: now),
            SubscriptionSummary(name: "Spotify", category: .music, amount: Decimal(10), createdAt: now)
        ]
        let balancedInsights = generate(subscriptions: balanced, now: now)
            .filter { $0.kind == .dominantCategory }

        XCTAssertTrue(balancedInsights.isEmpty)
    }

    func testTotalPotentialAnnualSavingSumsOnlySavings() {
        let insights = [
            Insight(id: "a", kind: .unusedSubscription, estimatedAnnualSaving: Decimal(100)),
            Insight(id: "b", kind: .duplicateCategory, estimatedAnnualSaving: Decimal(string: "119.88")),
            Insight(id: "c", kind: .priceIncrease, amount: Decimal(36))
        ]

        XCTAssertEqual(
            InsightsEngine.totalPotentialAnnualSaving(insights),
            Decimal(string: "219.88")
        )
    }
}
