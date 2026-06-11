import XCTest
@testable import SubscriptionGuardianCore

/// Pruebas del planificador de recordatorios.
final class ReminderPlannerTests: XCTestCase {
    /// Calendario gregoriano fijado a Europe/Madrid para resultados deterministas.
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    func testSubscriptionRemindersIdentifiersAndFireTime() {
        let now = date(2026, 6, 1, hour: 8)
        let id = UUID()
        let subscription = SubscriptionSummary(
            id: id,
            name: "Netflix",
            category: .streaming,
            amount: Decimal(string: "17.99")!,
            frequency: .monthly,
            nextRenewal: date(2026, 6, 20),
            createdAt: now
        )

        let reminders = ReminderPlanner.plan(
            subscriptions: [subscription],
            reminderDays: [id: 7],
            financings: [],
            now: now,
            calendar: calendar
        )

        // Antelación máxima 7 → offsets 1, 3 y 7.
        XCTAssertEqual(reminders.count, 3)
        XCTAssertEqual(
            Set(reminders.map(\.identifier)),
            Set([1, 3, 7].map { "sub-\(id.uuidString)-\($0)" })
        )
        // Ordenados por fecha de disparo, todos a las 09:00 locales.
        XCTAssertEqual(
            reminders.map(\.fireDate),
            [date(2026, 6, 13, hour: 9), date(2026, 6, 17, hour: 9), date(2026, 6, 19, hour: 9)]
        )
        XCTAssertEqual(reminders.map(\.offsetDays), [7, 3, 1])
        XCTAssertTrue(reminders.allSatisfy { $0.kind == .subscriptionRenewal })
        XCTAssertTrue(reminders.allSatisfy { $0.eventDate == date(2026, 6, 20) })
    }

    func testDefaultReminderDaysCapsOffsetsToThree() {
        let now = date(2026, 6, 1, hour: 8)
        let subscription = SubscriptionSummary(
            name: "Spotify",
            category: .music,
            amount: Decimal(string: "10.99")!,
            frequency: .monthly,
            nextRenewal: date(2026, 6, 20),
            createdAt: now
        )

        // Sin preferencia: antelación por defecto 3 → solo offsets 1 y 3.
        let reminders = ReminderPlanner.plan(
            subscriptions: [subscription],
            reminderDays: [:],
            financings: [],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(Set(reminders.map(\.offsetDays)), Set([1, 3]))
    }

    func testSkipsFireDatesInThePast() {
        // Renovación anual mañana: ambos disparos (1 y 3 días antes) ya pasaron.
        let now = date(2026, 6, 1, hour: 10)
        let subscription = SubscriptionSummary(
            name: "Amazon Prime",
            category: .membership,
            amount: Decimal(string: "49.90")!,
            frequency: .annual,
            nextRenewal: date(2026, 6, 2),
            createdAt: now
        )

        let reminders = ReminderPlanner.plan(
            subscriptions: [subscription],
            reminderDays: [:],
            financings: [],
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(reminders.isEmpty)
    }

    func testFinancingRemindersAndMaxRequestsPrefix() {
        let now = date(2026, 6, 1, hour: 8)
        let id = UUID()
        let financing = FinancingSummary(
            id: id,
            merchant: "MediaMarkt",
            provider: .klarna,
            totalAmount: Decimal(600),
            monthlyAmount: Decimal(50),
            totalInstallments: 12,
            paidInstallments: 0,
            firstInstallmentDate: date(2026, 6, 5)
        )

        let reminders = ReminderPlanner.plan(
            subscriptions: [],
            reminderDays: [:],
            financings: [financing],
            now: now,
            maxRequests: 2,
            calendar: calendar
        )

        // Cuotas del 5 de junio y 5 de julio dentro de la ventana, pero
        // limitado a las 2 primeras por fecha de disparo.
        XCTAssertEqual(reminders.count, 2)
        XCTAssertEqual(
            reminders.map(\.fireDate),
            [date(2026, 6, 2, hour: 9), date(2026, 6, 4, hour: 9)]
        )
        XCTAssertEqual(
            reminders.map(\.identifier),
            ["fin-\(id.uuidString)-3", "fin-\(id.uuidString)-1"]
        )
        XCTAssertTrue(reminders.allSatisfy { $0.kind == .financingInstallment })
        XCTAssertTrue(reminders.allSatisfy { $0.amount == Decimal(50) })
    }
}
