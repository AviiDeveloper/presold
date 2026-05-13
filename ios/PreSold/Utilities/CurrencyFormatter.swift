import Foundation

/// Single source of truth for currency rendering. Per `ios/CLAUDE.md`,
/// all monetary values pass through `CurrencyFormatter.gbp` so the app
/// shows the same number the same way everywhere.
///
/// Behaviour: GBP, en_GB locale, always two fraction digits. Predictable
/// for users ("£12.50", "£100.00") even at the cost of an extra ".00" on
/// whole numbers — resellers expect to see pence on every figure.
public enum CurrencyFormatter {
    /// Pre-built formatter, cached so we don't re-allocate per render.
    /// Half-up rounding to match high-street retail display ("£12.345"
    /// → "£12.35"), not banker's rounding — the audience is consumers,
    /// not accountants.
    public static let gbp: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "GBP"
        f.locale = Locale(identifier: "en_GB")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.roundingMode = .halfUp
        return f
    }()

    /// Format a `Decimal` as GBP. Returns the locale-specific currency
    /// fallback string when formatting fails (extremely rare in practice).
    public static func format(_ value: Decimal) -> String {
        let nsValue = value as NSDecimalNumber
        return gbp.string(from: nsValue) ?? "£\(nsValue.stringValue)"
    }
}
