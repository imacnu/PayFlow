import WidgetKit
import SwiftUI

/// Paquete de widgets de Subscription Guardian.
@main
struct SubscriptionGuardianWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NextPaymentWidget()
        MonthlySpendWidget()
        MiniDashboardWidget()
        LockScreenNextPaymentWidget()
    }
}
