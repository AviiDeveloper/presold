import Foundation

/// Supported reselling platforms. Mirrors `shared/types/platform.schema.json`
/// and the DB CHECK constraint on `listings.platform` / `sales.platform`.
public enum Platform: String, Codable, CaseIterable, Identifiable, Sendable {
    case vinted
    case depop
    case ebay

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vinted: return "Vinted"
        case .depop: return "Depop"
        case .ebay: return "eBay"
        }
    }

    /// Per-platform listing-copy constraints from PLAN.md §6.
    /// Source of truth for the AI listing-reformat prompt (Prompt 2).
    public var titleMaxLength: Int {
        switch self {
        case .vinted: return 50
        case .depop: return 65
        case .ebay: return 80
        }
    }
}
