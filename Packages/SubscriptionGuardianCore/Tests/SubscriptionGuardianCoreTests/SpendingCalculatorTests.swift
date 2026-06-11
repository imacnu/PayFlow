import XCTest
@testable import SubscriptionGuardianCore

/// Pruebas de los cálculos de gasto.
final class SpendingCalculatorTests: XCTestCase {
    func testMonthlyEquivalentForAllFrequencies() {
        XCTAssertEqual(
            SpendingCalculator.monthlyEquivalent(amount: Decimal(10), frequency: .weekly),
            Decimal(string: "43.33")
        )
        XCTAssertEqual(
            SpendingCalculator.monthlyEquivalent(amount: Decimal(10), frequency: .monthly),
            Decimal(10)
        )
        XCTAssertEqual(
            SpendingCalculator.monthlyEquivalent(amount: Decimal(30), frequency: .quarterly),
            Decimal(10)
        )
        XCTAssertEqual(
            SpendingCalculator.monthlyEquivalent(amount: Decimal(60), frequency: .semiannual),
            Decimal(10)
        )
        XCTAssertEqual(
            SpendingCalculator.monthlyEquivalent(amount: Decimal(120), frequency: .annual),
            Decimal(10)
        )
    }

    func testMonthlyTotalIgnoresCancelledAndPaused() {
        let subscriptions = [
            SubscriptionSummary(name: "Netflix", category: .streaming, amount: Decimal(string: "17.99")!),
            SubscriptionSummary(name: "HBO Max", category: .streaming, amount: Decimal(string: "9.99")!, status: .cancelled),
            SubscriptionSummary(name: "Gym", category: .fitness, amount: Decimal(string: "25.00")!, status: .paused)
        ]

        XCTAssertEqual(
            SpendingCalculator.monthlyTotal(subscriptions: subscriptions),
            Decimal(string: "17.99")
        )
    }

    func testMonthlyTotalIncludesActiveFinancingsWithPendingInstallments() {
        let subscriptions = [
            SubscriptionSummary(name: "Netflix", category: .streaming, amount: Decimal(10))
        ]
        let financings = [
            FinancingSummary(merchant: "MediaMarkt", totalAmount: Decimal(600), monthlyAmount: Decimal(50), totalInstallments: 12, paidInstallments: 4),
            // Completada: no debe sumar.
            FinancingSummary(merchant: "Ikea", totalAmount: Decimal(300), monthlyAmount: Decimal(100), totalInstallments: 3, paidInstallments: 3, status: .completed)
        ]

        XCTAssertEqual(
            SpendingCalculator.monthlyTotal(subscriptions: subscriptions, financings: financings),
            Decimal(60)
        )
    }

    func testCategoryBreakdownSortedDescending() {
        let subscriptions = [
            SubscriptionSummary(name: "iCloud+", category: .productivity, amount: Decimal(string: "2.99")!),
            SubscriptionSummary(name: "Netflix", category: .streaming, amount: Decimal(string: "17.99")!),
            SubscriptionSummary(name: "Spotify", category: .music, amount: Decimal(string: "10.99")!)
        ]

        let breakdown = SpendingCalculator.categoryBreakdown(subscriptions: subscriptions)

        XCTAssertEqual(breakdown.map(\.category), [.streaming, .music, .productivity])
        XCTAssertEqual(breakdown.first?.monthlyAmount, Decimal(string: "17.99"))
    }

    func testMonthOverMonthVariation() {
        let reference = Date(timeIntervalSince1970: 1_750_000_000)
        let evolution = [
            SpendingCalculator.MonthPoint(monthStart: reference, total: Decimal(100)),
            SpendingCalculator.MonthPoint(monthStart: reference.addingTimeInterval(2_592_000), total: Decimal(110))
        ]

        XCTAssertEqual(
            SpendingCalculator.monthOverMonthVariation(evolution: evolution),
            Decimal(10)
        )
    }

    func testMonthOverMonthVariationNilCases() {
        let reference = Date(timeIntervalSince1970: 1_750_000_000)

        // Menos de dos puntos.
        XCTAssertNil(SpendingCalculator.monthOverMonthVariation(evolution: [
            SpendingCalculator.MonthPoint(monthStart: reference, total: Decimal(100))
        ]))

        // Mes anterior a cero.
        XCTAssertNil(SpendingCalculator.monthOverMonthVariation(evolution: [
            SpendingCalculator.MonthPoint(monthStart: reference, total: Decimal(0)),
            SpendingCalculator.MonthPoint(monthStart: reference.addingTimeInterval(2_592_000), total: Decimal(50))
        ]))
    }
}
