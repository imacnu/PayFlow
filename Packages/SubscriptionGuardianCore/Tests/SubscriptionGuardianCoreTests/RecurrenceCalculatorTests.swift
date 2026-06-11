import XCTest
@testable import SubscriptionGuardianCore

/// Pruebas del cálculo de renovaciones con fechas fijas y zona horaria explícita.
final class RecurrenceCalculatorTests: XCTestCase {
    /// Calendario gregoriano fijado a Europe/Madrid para resultados deterministas.
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }()

    /// Construye una fecha fija en el calendario de prueba.
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testNextRenewalRollsForwardMonthly() {
        let anchor = date(2026, 1, 15)
        let reference = date(2026, 3, 20)

        let next = RecurrenceCalculator.nextRenewal(
            anchor: anchor,
            frequency: .monthly,
            after: reference,
            calendar: calendar
        )

        XCTAssertEqual(next, date(2026, 4, 15))
    }

    func testNextRenewalRollsForwardAnnual() {
        let anchor = date(2024, 6, 1)
        let reference = date(2026, 1, 1)

        let next = RecurrenceCalculator.nextRenewal(
            anchor: anchor,
            frequency: .annual,
            after: reference,
            calendar: calendar
        )

        XCTAssertEqual(next, date(2026, 6, 1))
    }

    func testNextRenewalReturnsFutureAnchorAsIs() {
        let anchor = date(2026, 7, 1)
        let reference = date(2026, 6, 11)

        let next = RecurrenceCalculator.nextRenewal(
            anchor: anchor,
            frequency: .monthly,
            after: reference,
            calendar: calendar
        )

        XCTAssertEqual(next, anchor)
    }

    func testRenewalsWithinQuarterCountsMonthlyOccurrences() {
        let anchor = date(2026, 1, 10)
        let interval = DateInterval(start: date(2026, 1, 1), end: date(2026, 3, 31))

        let renewals = RecurrenceCalculator.renewals(
            anchor: anchor,
            frequency: .monthly,
            in: interval,
            calendar: calendar
        )

        XCTAssertEqual(renewals, [date(2026, 1, 10), date(2026, 2, 10), date(2026, 3, 10)])
    }

    func testRenewalsRollsPastAnchorIntoInterval() {
        // Ancla muy anterior al intervalo: solo deben aparecer las ocurrencias dentro.
        let anchor = date(2025, 1, 5)
        let interval = DateInterval(start: date(2026, 6, 1), end: date(2026, 7, 31))

        let renewals = RecurrenceCalculator.renewals(
            anchor: anchor,
            frequency: .monthly,
            in: interval,
            calendar: calendar
        )

        XCTAssertEqual(renewals, [date(2026, 6, 5), date(2026, 7, 5)])
    }
}
