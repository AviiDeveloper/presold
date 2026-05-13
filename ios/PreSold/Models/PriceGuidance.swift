import Foundation

/// Output of the price-guidance prompt (Prompt 3). Mirrors
/// `shared/types/price-guidance.schema.json` and `web/lib/types.ts`.
///
/// Price fields are nullable when the item couldn't be identified or comps
/// were too sparse to anchor a recommendation — the UI shows an explanation
/// instead of `£NaN` tiles.
public struct PriceGuidance: Codable, Hashable, Sendable {
    public let priceLow: Decimal?
    public let priceRecommended: Decimal?
    public let priceHigh: Decimal?
    public let sellSpeedEstimate: SellSpeed
    public let reasoning: String
    public let compCount: Int
    public let confidence: Decimal

    public init(
        priceLow: Decimal?,
        priceRecommended: Decimal?,
        priceHigh: Decimal?,
        sellSpeedEstimate: SellSpeed,
        reasoning: String,
        compCount: Int,
        confidence: Decimal
    ) {
        self.priceLow = priceLow
        self.priceRecommended = priceRecommended
        self.priceHigh = priceHigh
        self.sellSpeedEstimate = sellSpeedEstimate
        self.reasoning = reasoning
        self.compCount = compCount
        self.confidence = confidence
    }
}
