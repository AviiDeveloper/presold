import XCTest
@testable import PreSold

/// Money-math tests. Per `CLAUDE.md` and `ios/CLAUDE.md`, `PricingService`
/// is the only place that calculates fees / profit and it MUST be tested.
/// Tests use `Decimal` throughout (never `Double`) to mirror production.
final class PricingServiceTests: XCTestCase {

    private var service: PricingService!

    override func setUp() {
        super.setUp()
        service = PricingService()
    }

    // MARK: - Fee constants (PLAN.md §7)

    func testVintedHasNoFee() {
        let fee = service.fee(for: .vinted)
        XCTAssertEqual(fee.rate, 0)
        XCTAssertEqual(fee.fixed, 0)
    }

    func testDepopFeeIsTenPercent() {
        let fee = service.fee(for: .depop)
        XCTAssertEqual(fee.rate, Decimal(string: "0.10"))
        XCTAssertEqual(fee.fixed, 0)
    }

    func testEbayFeeIs12point8PercentPlus30p() {
        let fee = service.fee(for: .ebay)
        XCTAssertEqual(fee.rate, Decimal(string: "0.128"))
        XCTAssertEqual(fee.fixed, Decimal(string: "0.30"))
    }

    // MARK: - platformFee

    func testVintedPlatformFeeIsAlwaysZero() {
        XCTAssertEqual(service.platformFee(salePrice: 0, platform: .vinted), 0)
        XCTAssertEqual(service.platformFee(salePrice: 100, platform: .vinted), 0)
        XCTAssertEqual(service.platformFee(salePrice: Decimal(string: "12.50")!, platform: .vinted), 0)
    }

    func testDepopPlatformFeeAtTenPercent() {
        XCTAssertEqual(
            service.platformFee(salePrice: Decimal(string: "30.00")!, platform: .depop),
            Decimal(string: "3.00")
        )
        XCTAssertEqual(
            service.platformFee(salePrice: Decimal(string: "12.50")!, platform: .depop),
            Decimal(string: "1.25")
        )
    }

    func testEbayPlatformFeeIncludesBothRateAndFixed() {
        // £20 * 0.128 + £0.30 = £2.56 + £0.30 = £2.86
        XCTAssertEqual(
            service.platformFee(salePrice: Decimal(string: "20.00")!, platform: .ebay),
            Decimal(string: "2.86")
        )
        // £100 * 0.128 + £0.30 = £12.80 + £0.30 = £13.10
        XCTAssertEqual(
            service.platformFee(salePrice: Decimal(string: "100.00")!, platform: .ebay),
            Decimal(string: "13.10")
        )
    }

    func testEbayFeeOnZeroSaleIsJustTheFixedComponent() {
        // £0 * 0.128 + £0.30 = £0.30
        XCTAssertEqual(
            service.platformFee(salePrice: 0, platform: .ebay),
            Decimal(string: "0.30")
        )
    }

    // MARK: - breakdown — happy paths

    func testVintedHealthyProfit() {
        // Picked up at a charity shop for £4, listed at £25, free shipping
        // pre-paid by Vinted buyer (so shippingCost = 0 to us).
        let b = service.breakdown(
            salePrice: Decimal(string: "25.00")!,
            shippingCost: 0,
            costBasis: Decimal(string: "4.00")!,
            platform: .vinted
        )
        XCTAssertEqual(b.platformFee, 0)
        XCTAssertEqual(b.netProceeds, Decimal(string: "25.00"))
        XCTAssertEqual(b.profit, Decimal(string: "21.00"))
        XCTAssertEqual(b.marginPercent, Decimal(string: "84"))
        XCTAssertEqual(b.platform, .vinted)
    }

    func testDepopWithFee() {
        // Sold at £20, cost £5, no separate shipping recorded.
        // Fee: £2. Profit: £20 - £2 - £5 = £13.
        let b = service.breakdown(
            salePrice: Decimal(string: "20.00")!,
            shippingCost: 0,
            costBasis: Decimal(string: "5.00")!,
            platform: .depop
        )
        XCTAssertEqual(b.platformFee, Decimal(string: "2.00"))
        XCTAssertEqual(b.netProceeds, Decimal(string: "18.00"))
        XCTAssertEqual(b.profit, Decimal(string: "13.00"))
        XCTAssertEqual(b.marginPercent, Decimal(string: "65"))
    }

    func testEbayFullBreakdownWithShipping() {
        // Sold £50, shipping £4.50 (we paid Royal Mail), cost basis £10.
        // Fee: £50 * 0.128 + £0.30 = £6.70.
        // Net: £50 - £6.70 - £4.50 = £38.80
        // Profit: £38.80 - £10 = £28.80
        // Margin: 28.80 / 50 * 100 = 57.6%
        let b = service.breakdown(
            salePrice: Decimal(string: "50.00")!,
            shippingCost: Decimal(string: "4.50")!,
            costBasis: Decimal(string: "10.00")!,
            platform: .ebay
        )
        XCTAssertEqual(b.platformFee, Decimal(string: "6.70"))
        XCTAssertEqual(b.netProceeds, Decimal(string: "38.80"))
        XCTAssertEqual(b.profit, Decimal(string: "28.80"))
        XCTAssertEqual(b.marginPercent, Decimal(string: "57.6"))
    }

    // MARK: - breakdown — edge cases

    func testFreeItemWithFullProfit() {
        // Found in the wild, cost £0. Sold for £10 on Vinted.
        let b = service.breakdown(
            salePrice: Decimal(string: "10.00")!,
            shippingCost: 0,
            costBasis: 0,
            platform: .vinted
        )
        XCTAssertEqual(b.profit, Decimal(string: "10.00"))
        XCTAssertEqual(b.marginPercent, Decimal(string: "100"))
    }

    func testSaleAtCostIsZeroProfit() {
        // Bought for £8, sold for £8 on Vinted (no fee), no shipping.
        let b = service.breakdown(
            salePrice: Decimal(string: "8.00")!,
            shippingCost: 0,
            costBasis: Decimal(string: "8.00")!,
            platform: .vinted
        )
        XCTAssertEqual(b.profit, 0)
        XCTAssertEqual(b.marginPercent, 0)
    }

    func testLossOnEbayAfterFeesAndShipping() {
        // Sold £10 on eBay, shipping £3, cost £8. Net = £10 - (1.28 + 0.30) - £3 = £5.42. Profit = -£2.58.
        let b = service.breakdown(
            salePrice: Decimal(string: "10.00")!,
            shippingCost: Decimal(string: "3.00")!,
            costBasis: Decimal(string: "8.00")!,
            platform: .ebay
        )
        XCTAssertEqual(b.platformFee, Decimal(string: "1.58"))
        XCTAssertEqual(b.netProceeds, Decimal(string: "5.42"))
        XCTAssertEqual(b.profit, Decimal(string: "-2.58"))
        // -2.58 / 10 * 100 = -25.8
        XCTAssertEqual(b.marginPercent, Decimal(string: "-25.8"))
    }

    func testZeroSalePriceGivesNilMargin() {
        let b = service.breakdown(
            salePrice: 0,
            shippingCost: 0,
            costBasis: 0,
            platform: .vinted
        )
        XCTAssertNil(b.marginPercent, "Margin on a £0 sale is meaningless")
        XCTAssertEqual(b.profit, 0)
    }

    func testZeroSalePriceOnEbayStillShowsTheFixedFee() {
        // eBay's 30p fixed fee applies even at £0 sale — unusual edge case
        // (e.g. promotional free listing). Net is negative by 30p plus
        // shipping.
        let b = service.breakdown(
            salePrice: 0,
            shippingCost: Decimal(string: "3.00")!,
            costBasis: Decimal(string: "5.00")!,
            platform: .ebay
        )
        XCTAssertEqual(b.platformFee, Decimal(string: "0.30"))
        XCTAssertEqual(b.netProceeds, Decimal(string: "-3.30"))
        XCTAssertEqual(b.profit, Decimal(string: "-8.30"))
        XCTAssertNil(b.marginPercent)
    }

    // MARK: - Decimal precision

    func testNoFloatingPointDriftOnRepeatingFractions() {
        // 12.8% of £33.33 = 4.26624 — verify we don't accumulate FP error.
        // (33.33 * 0.128) + 0.30 = 4.56624 exactly.
        let fee = service.platformFee(
            salePrice: Decimal(string: "33.33")!,
            platform: .ebay
        )
        XCTAssertEqual(fee, Decimal(string: "4.56624"))
    }

    // MARK: - Platform reproducibility

    func testEveryPlatformProducesAStableBreakdown() {
        for platform in Platform.allCases {
            let first = service.breakdown(
                salePrice: Decimal(string: "20.00")!,
                shippingCost: Decimal(string: "2.50")!,
                costBasis: Decimal(string: "5.00")!,
                platform: platform
            )
            let second = service.breakdown(
                salePrice: Decimal(string: "20.00")!,
                shippingCost: Decimal(string: "2.50")!,
                costBasis: Decimal(string: "5.00")!,
                platform: platform
            )
            XCTAssertEqual(first, second, "\(platform) breakdown drifted on repeat calls")
        }
    }
}
