import Foundation

/// A single eBay sold-comp record passed into the price-guidance prompt
/// alongside an `Item`. Mirrors `EbayComp` in `web/lib/types.ts` and the
/// per-row shape of `price_scans.comp_data` jsonb.
///
/// Source can be official Marketplace Insights (when approved) or Apify
/// (ADR-005, temporary). The shape is the same.
public struct EbayComp: Codable, Hashable, Identifiable, Sendable {
    public let title: String
    public let priceGbp: Decimal
    public let condition: String?
    public let soldAt: Date?
    public let itemWebUrl: URL?

    /// Synthetic ID for SwiftUI list rendering. eBay item IDs aren't always
    /// returned by every source; the URL + price combo is unique enough.
    public var id: String {
        "\(itemWebUrl?.absoluteString ?? title)|\(priceGbp)"
    }

    public init(
        title: String,
        priceGbp: Decimal,
        condition: String? = nil,
        soldAt: Date? = nil,
        itemWebUrl: URL? = nil
    ) {
        self.title = title
        self.priceGbp = priceGbp
        self.condition = condition
        self.soldAt = soldAt
        self.itemWebUrl = itemWebUrl
    }
}
