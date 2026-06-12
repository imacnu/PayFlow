import XCTest
@testable import SubscriptionGuardianCore

/// Pruebas de los cálculos sobre financiaciones BNPL.
final class FinancingCalculatorTests: XCTestCase {
    /// Calendario gregoriano fijado a Europe/Madrid para resultados deterministas.
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makeFinancing(
        total: Int,
        paid: Int,
        monthly: Decimal = Decimal(50),
        firstDate: Date? = nil,
        status: FinancingStatus = .active
    ) -> FinancingSummary {
        FinancingSummary(
            merchant: "MediaMarkt",
            provider: .klarna,
            totalAmount: monthly * Decimal(total),
            monthlyAmount: monthly,
            totalInstallments: total,
            paidInstallments: paid,
            firstInstallmentDate: firstDate,
            status: status
        )
    }

    func testPendingCapital() {
        let financing = makeFinancing(total: 12, paid: 4)
        XCTAssertEqual(FinancingCalculator.pendingInstallments(financing), 8)
        XCTAssertEqual(FinancingCalculator.pendingCapital(financing), Decimal(400))
    }

    func testNextInstallmentDateAdvancesByPaidInstallments() {
        let financing = makeFinancing(total: 12, paid: 3, firstDate: date(2026, 1, 5))
        XCTAssertEqual(
            FinancingCalculator.nextInstallmentDate(financing, calendar: calendar),
            date(2026, 4, 5)
        )
    }

    func testNextInstallmentDateNilWhenCompletedOrNoDate() {
        // Sin fecha de primera cuota.
        XCTAssertNil(FinancingCalculator.nextInstallmentDate(makeFinancing(total: 12, paid: 3), calendar: calendar))
        // Completada.
        XCTAssertNil(FinancingCalculator.nextInstallmentDate(
            makeFinancing(total: 12, paid: 12, firstDate: date(2026, 1, 5), status: .completed),
            calendar: calendar
        ))
        // Sin cuotas pendientes aunque siga activa.
        XCTAssertNil(FinancingCalculator.nextInstallmentDate(
            makeFinancing(total: 12, paid: 12, firstDate: date(2026, 1, 5)),
            calendar: calendar
        ))
    }

    func testEndDate() {
        let financing = makeFinancing(total: 12, paid: 0, firstDate: date(2026, 1, 5))
        XCTAssertEqual(
            FinancingCalculator.endDate(financing, calendar: calendar),
            date(2026, 12, 5)
        )
    }

    func testProgressClamping() {
        XCTAssertEqual(FinancingCalculator.progress(makeFinancing(total: 12, paid: 6)), 0.5, accuracy: 0.0001)
        // Pagadas de más: se recorta a 1.
        XCTAssertEqual(FinancingCalculator.progress(makeFinancing(total: 12, paid: 15)), 1.0, accuracy: 0.0001)
        // Sin cuotas: 0.
        XCTAssertEqual(FinancingCalculator.progress(makeFinancing(total: 0, paid: 0)), 0.0, accuracy: 0.0001)
    }

    func testAccruedInstallments() {
        // La primera cuota vence el mismo día: cuenta como devengada.
        XCTAssertEqual(
            FinancingCalculator.accruedInstallments(
                firstInstallmentDate: date(2026, 6, 12), totalInstallments: 12,
                asOf: date(2026, 6, 12), calendar: calendar
            ),
            1
        )
        // Tres meses transcurridos: cuatro cuotas devengadas (meses 0..3).
        XCTAssertEqual(
            FinancingCalculator.accruedInstallments(
                firstInstallmentDate: date(2026, 3, 5), totalInstallments: 12,
                asOf: date(2026, 6, 12), calendar: calendar
            ),
            4
        )
        // Primera cuota en el futuro: ninguna devengada.
        XCTAssertEqual(
            FinancingCalculator.accruedInstallments(
                firstInstallmentDate: date(2026, 7, 1), totalInstallments: 12,
                asOf: date(2026, 6, 12), calendar: calendar
            ),
            0
        )
        // Financiación antigua: se recorta al total de cuotas.
        XCTAssertEqual(
            FinancingCalculator.accruedInstallments(
                firstInstallmentDate: date(2020, 1, 1), totalInstallments: 12,
                asOf: date(2026, 6, 12), calendar: calendar
            ),
            12
        )
    }

    func testIsAlmostFinishedBoundaries() {
        XCTAssertTrue(FinancingCalculator.isAlmostFinished(makeFinancing(total: 12, paid: 10)))  // quedan 2
        XCTAssertTrue(FinancingCalculator.isAlmostFinished(makeFinancing(total: 12, paid: 11)))  // queda 1
        XCTAssertFalse(FinancingCalculator.isAlmostFinished(makeFinancing(total: 12, paid: 9)))  // quedan 3
        XCTAssertFalse(FinancingCalculator.isAlmostFinished(makeFinancing(total: 12, paid: 12))) // quedan 0
        XCTAssertFalse(FinancingCalculator.isAlmostFinished(
            makeFinancing(total: 12, paid: 10, status: .completed)
        ))
    }
}
