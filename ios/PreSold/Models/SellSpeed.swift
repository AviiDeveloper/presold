import Foundation

/// Estimated time-to-sale from the price-guidance prompt (Prompt 3).
/// Mirrors `shared/types/price-guidance.schema.json`.
public enum SellSpeed: String, Codable, CaseIterable, Sendable {
    case fast
    case medium
    case slow
    case uncertain

    public var displayName: String {
        switch self {
        case .fast: return "Fast (days)"
        case .medium: return "Medium (1–2 weeks)"
        case .slow: return "Slow (a month or more)"
        case .uncertain: return "Uncertain"
        }
    }
}
