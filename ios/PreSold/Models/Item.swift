import Foundation

/// Universal item record. The Identify prompt (Prompt 1) returns this shape;
/// the iOS app stores it locally and uses it to drive listing generation.
///
/// Mirrors `shared/types/item.schema.json` and `web/lib/types.ts`. All
/// identifiable fields are nullable because Haiku/Sonnet returns nulls and
/// `confidence: 0` when the photo contains no identifiable item (see
/// Prompt 1 v1.3 in `docs/ai-prompts.md`).
///
/// Money fields use `Decimal` per `ios/CLAUDE.md` — never `Double`.
public struct Item: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let createdAt: Date
    public let updatedAt: Date

    // AI-identified fields (all nullable; null when not visible / unknown)
    public var title: String?
    public var description: String?
    public var category: String?
    public var brand: String?
    public var size: String?
    public var color: String?
    public var condition: ItemCondition?
    public var weightGramsEstimate: Int?
    public var aiConfidence: Decimal?
    public var aiPromptVersion: String?

    // User-provided fields
    public var costBasis: Decimal?
    public var targetPrice: Decimal?
    public var weightGrams: Int?
    public var status: ItemStatus
    public var notes: String?

    public init(
        id: UUID,
        userId: UUID,
        createdAt: Date,
        updatedAt: Date,
        title: String? = nil,
        description: String? = nil,
        category: String? = nil,
        brand: String? = nil,
        size: String? = nil,
        color: String? = nil,
        condition: ItemCondition? = nil,
        weightGramsEstimate: Int? = nil,
        aiConfidence: Decimal? = nil,
        aiPromptVersion: String? = nil,
        costBasis: Decimal? = nil,
        targetPrice: Decimal? = nil,
        weightGrams: Int? = nil,
        status: ItemStatus = .draft,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.description = description
        self.category = category
        self.brand = brand
        self.size = size
        self.color = color
        self.condition = condition
        self.weightGramsEstimate = weightGramsEstimate
        self.aiConfidence = aiConfidence
        self.aiPromptVersion = aiPromptVersion
        self.costBasis = costBasis
        self.targetPrice = targetPrice
        self.weightGrams = weightGrams
        self.status = status
        self.notes = notes
    }
}

/// Inventory-tracking status for an item. Mirrors the DB CHECK constraint on
/// `items.status` (`supabase/migrations/20260513000001_initial_schema.sql`).
public enum ItemStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case listed
    case sold
    case archived

    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .listed: return "Listed"
        case .sold: return "Sold"
        case .archived: return "Archived"
        }
    }
}
