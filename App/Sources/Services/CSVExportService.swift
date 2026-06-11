import Foundation
import SubscriptionGuardianCore

/// Exportación de datos a CSV (separado por punto y coma, fechas en ISO 8601).
enum CSVExportService {
    /// Genera el contenido CSV con dos secciones: suscripciones y financiaciones.
    static func export(
        subscriptions: [SubscriptionSummary],
        financings: [FinancingSummary]
    ) -> String {
        var lines: [String] = []

        // Sección de suscripciones.
        lines.append("SUSCRIPCIONES")
        lines.append("Nombre;Categoria;Importe;Divisa;Frecuencia;Proxima renovacion;Fecha de alta;Estado")
        for subscription in subscriptions {
            lines.append(
                [
                    escape(subscription.name),
                    subscription.category.rawValue,
                    decimalText(subscription.amount),
                    subscription.currencyCode,
                    subscription.frequency.rawValue,
                    isoDate(subscription.nextRenewal),
                    isoDate(subscription.startDate),
                    subscription.status.rawValue
                ].joined(separator: ";")
            )
        }

        lines.append("")

        // Sección de financiaciones.
        lines.append("FINANCIACIONES")
        lines.append("Comercio;Proveedor;Importe total;Cuota mensual;Cuotas totales;Cuotas pagadas;Primera cuota;Interes;Estado")
        for financing in financings {
            lines.append(
                [
                    escape(financing.merchant),
                    financing.provider.displayName,
                    decimalText(financing.totalAmount),
                    decimalText(financing.monthlyAmount),
                    String(financing.totalInstallments),
                    String(financing.paidInstallments),
                    isoDate(financing.firstInstallmentDate),
                    decimalText(financing.interestRate),
                    financing.status.rawValue
                ].joined(separator: ";")
            )
        }

        return lines.joined(separator: "\n")
    }

    /// Escribe el contenido en un fichero temporal y devuelve su URL.
    static func writeTemporaryFile(content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SubscriptionGuardian-export.csv")
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Privado

    /// Fecha en formato ISO 8601 (solo fecha), o cadena vacía si es `nil`.
    private static func isoDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return date.formatted(.iso8601.year().month().day())
    }

    /// Representación neutra del importe (punto decimal, sin separadores de miles).
    private static func decimalText(_ value: Decimal) -> String {
        "\(value)"
    }

    /// Protege un campo que pueda contener el separador o comillas.
    private static func escape(_ field: String) -> String {
        if field.contains(";") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
