import Foundation

/// The only place in the app that calculates platform fees, net proceeds,
/// profit, and margin. Per `ios/CLAUDE.md` and PLAN.md §11 DoD — money math
/// is centralised here and unit-tested.
///
/// Pure synchronous math. No I/O, no state. Exposed as a singleton
/// (`PricingService.shared`) only to honour the convention in
/// `ios/CLAUDE.md` — the type itself holds no state.
public final class PricingService {
    public static let shared = PricingService()

    public init() {}

    // MARK: - Fee constants (PLAN.md §7)

    /// A platform's seller-side fee structure.
    public struct Fee: Equatable, Sendable {
        /// Percentage charge expressed as a decimal fraction (e.g. `0.128` = 12.8%).
        public let rate: Decimal
        /// Fixed pence-denominated charge per sale (e.g. `0.30` = 30p).
        public let fixed: Decimal

        public init(rate: Decimal, fixed: Decimal) {
            self.rate = rate
            self.fixed = fixed
        }
    }

    /// Returns the fee structure for a platform. PLAN.md §7 is the source of
    /// truth — when fees change, update both this method and the plan.
    public func fee(for platform: Platform) -> Fee {
        switch platform {
        case .vinted:
            return Fee(rate: 0, fixed: 0)
        case .depop:
            // 10% + £0
            return Fee(rate: Decimal(string: "0.10")!, fixed: 0)
        case .ebay:
            // 12.8% + £0.30
            return Fee(rate: Decimal(string: "0.128")!, fixed: Decimal(string: "0.30")!)
        }
    }

    // MARK: - Calculations

    /// Calculate the platform fee for a sale at `salePrice` on `platform`.
    /// Formula: `salePrice * rate + fixed`. Never negative.
    public func platformFee(salePrice: Decimal, platform: Platform) -> Decimal {
        let f = fee(for: platform)
        return (salePrice * f.rate) + f.fixed
    }

    /// Full profit breakdown for a completed sale. PLAN.md §7 formula:
    /// ```
    /// gross_proceeds = sale_price
    /// platform_fee   = sale_price * rate + fixed
    /// net_proceeds   = gross_proceeds - platform_fee - shipping_cost
    /// profit         = net_proceeds - cost_basis
    /// margin_percent = profit / gross_proceeds * 100
    /// ```
    ///
    /// `marginPercent` is `nil` when `salePrice` is zero (avoids division
    /// by zero; "100% loss on a £0 sale" is meaningless to render).
    public func breakdown(
        salePrice: Decimal,
        shippingCost: Decimal,
        costBasis: Decimal,
        platform: Platform
    ) -> ProfitBreakdown {
        let platformFee = self.platformFee(salePrice: salePrice, platform: platform)
        let netProceeds = salePrice - platformFee - shippingCost
        let profit = netProceeds - costBasis
        let marginPercent: Decimal? = salePrice == 0 ? nil : (profit / salePrice * 100)

        return ProfitBreakdown(
            salePrice: salePrice,
            platformFee: platformFee,
            shippingCost: shippingCost,
            netProceeds: netProceeds,
            profit: profit,
            marginPercent: marginPercent,
            platform: platform
        )
    }
}

/// Result of `PricingService.breakdown(...)`. Persisted to the `sales` table
/// after the user marks an item sold or the email-forward parser confirms.
public struct ProfitBreakdown: Equatable, Sendable {
    public let salePrice: Decimal
    public let platformFee: Decimal
    public let shippingCost: Decimal
    public let netProceeds: Decimal
    public let profit: Decimal
    /// `nil` when `salePrice == 0`. Otherwise a percentage value (e.g.
    /// `25` means 25%, not 0.25). Can be negative for a loss.
    public let marginPercent: Decimal?
    public let platform: Platform

    public init(
        salePrice: Decimal,
        platformFee: Decimal,
        shippingCost: Decimal,
        netProceeds: Decimal,
        profit: Decimal,
        marginPercent: Decimal?,
        platform: Platform
    ) {
        self.salePrice = salePrice
        self.platformFee = platformFee
        self.shippingCost = shippingCost
        self.netProceeds = netProceeds
        self.profit = profit
        self.marginPercent = marginPercent
        self.platform = platform
    }
}
