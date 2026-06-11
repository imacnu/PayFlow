import Foundation

/// Utilidades mínimas para aritmética monetaria con `Decimal`.
public enum Money {
    /// Redondea un valor decimal a la escala indicada (redondeo "plain").
    public static func rounded(_ value: Decimal, scale: Int = 2) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .plain)
        return result
    }

    /// Multiplica dos valores decimales.
    public static func multiply(_ lhs: Decimal, _ rhs: Decimal) -> Decimal {
        lhs * rhs
    }

    /// División segura: devuelve 0 cuando el divisor es 0.
    public static func divide(_ value: Decimal, by divisor: Decimal) -> Decimal {
        guard divisor != 0 else { return 0 }
        return value / divisor
    }
}
