import Foundation

/// Photo record associated with an item. Mirrors the `photos` table in
/// `docs/data-model.md`. The actual image bytes live in the `item-photos`
/// Supabase Storage bucket; this struct holds the metadata.
public struct Photo: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let itemId: UUID
    public let storagePath: String
    public var orderIndex: Int
    public var isPrimary: Bool
    public var width: Int?
    public var height: Int?
    public let createdAt: Date

    public init(
        id: UUID,
        itemId: UUID,
        storagePath: String,
        orderIndex: Int = 0,
        isPrimary: Bool = false,
        width: Int? = nil,
        height: Int? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.itemId = itemId
        self.storagePath = storagePath
        self.orderIndex = orderIndex
        self.isPrimary = isPrimary
        self.width = width
        self.height = height
        self.createdAt = createdAt
    }
}
