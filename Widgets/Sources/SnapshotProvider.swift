import Foundation
import WidgetKit
import SubscriptionGuardianCore

/// Entrada de la línea de tiempo del widget: fecha más snapshot de datos.
struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

/// Proveedor de línea de tiempo compartido por todos los widgets.
/// Lee el `WidgetSnapshot` que la app escribe en el App Group.
struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        // Carga los datos reales; si no hay, usa el placeholder.
        completion(SnapshotEntry(date: Date(), snapshot: Self.loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: Date(), snapshot: Self.loadSnapshot())
        // Una única entrada; se pide refresco en la próxima medianoche.
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: startOfToday)
            ?? Date().addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    /// Lee y decodifica el snapshot del UserDefaults compartido.
    /// Devuelve el placeholder si no hay datos o no se pueden decodificar.
    static func loadSnapshot() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: WidgetConfig.appGroupID),
              let data = defaults.data(forKey: WidgetConfig.widgetSnapshotKey),
              let snapshot = WidgetSnapshot.decode(from: data) else {
            return .placeholder
        }
        return snapshot
    }
}
