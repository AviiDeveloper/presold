import Foundation

/// A completed sale of an item. Mirrors the `sales` table in
/// `docs/data-model.md` and PLAN.md §7 profit math.
///
/// All money fields use `Decimal`. The `PricingService` is the only place
/// that calculates these from raw inputs; this struct is the persisted
/// result. Do not recompute from this struct's fields — read what's stored.
public struct Sale: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let itemId: UUID
    public let listingId: UUID?
    public let platform: Platform
    public let salePrice: Decimal
    public let platformFee: Decimal
    public let shippingCost: Decimal
    public let netProceeds: Decimal
    public let profit: Decimal
    public let soldAt: Date
    public let source: SaleSource

    public init(
        id: UUID,
        itemId: UUID,
        listingId: UUID? = nil,
        platform: Platform,
        salePrice: Decimal,
        platformFee: Decimal,
        shippingCost: Decimal,
        netProceeds: Decimal,
        profit: Decimal,
        soldAt: Date,
        source: SaleSource
    ) {
        self.id = id
        self.itemId = itemId
        self.listingId = listingId
        self.platform = platform
        self.salePrice = salePrice
        self.platformFee = platformFee
        self.shippingCost = shippingCost
        self.netProceeds = netProceeds
        self.profit = profit
        self.soldAt = soldAt
        self.source = source
    }
}

/// How the sale was recorded.
public enum SaleSource: String, Codable, CaseIterable, Sendable {
    /// Detected by parsing a forwarded marketplace sale email
    /// (`<token>@sales.presold.app`).
    case email
    /// User tapped "mark sold" inside the app.
    case manual
}
