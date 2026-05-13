import Foundation

/// Item condition values used across `items.condition` and listing flow.
/// Mirrors `shared/types/item.schema.json` and the DB CHECK constraint in
/// `supabase/migrations/20260513000001_initial_schema.sql`.
public enum ItemCondition: String, Codable, CaseIterable, Sendable {
    case newWithTags = "new_with_tags"
    case newWithoutTags = "new_without_tags"
    case veryGood = "very_good"
    case good = "good"
    case satisfactory = "satisfactory"

    /// Human-readable label for UI rendering.
    public var displayName: String {
        switch self {
        case .newWithTags: return "New with tags"
        case .newWithoutTags: return "New without tags"
        case .veryGood: return "Very good"
        case .good: return "Good"
        case .satisfactory: return "Satisfactory"
        }
    }
}
