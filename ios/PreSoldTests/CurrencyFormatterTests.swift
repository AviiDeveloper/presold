import XCTest
@testable import PreSold

/// Tests for `CurrencyFormatter.gbp`. Locks down rendering so prices
/// never drift in subtle ways across the app.
final class CurrencyFormatterTests: XCTestCase {

    func testWholeAmountShowsTwoDecimals() {
        XCTAssertEqual(CurrencyFormatter.format(100), "£100.00")
        XCTAssertEqual(CurrencyFormatter.format(0), "£0.00")
    }

    func testTypicalRetailPrice() {
        XCTAssertEqual(
            CurrencyFormatter.format(Decimal(string: "12.50")!),
            "£12.50"
        )
        XCTAssertEqual(
            CurrencyFormatter.format(Decimal(string: "7.99")!),
            "£7.99"
        )
    }

    func testPennies() {
        XCTAssertEqual(
            CurrencyFormatter.format(Decimal(string: "0.01")!),
            "£0.01"
        )
        XCTAssertEqual(
            CurrencyFormatter.format(Decimal(string: "0.99")!),
            "£0.99"
        )
    }

    func testNegativeForLosses() {
        // en_GB locale renders negatives with a leading minus.
        XCTAssertEqual(
            CurrencyFormatter.format(Decimal(string: "-2.58")!),
            "-£2.58"
        )
    }

    func testThousandsSeparatorRenders() {
        XCTAssertEqual(
            CurrencyFormatter.format(Decimal(string: "1234.56")!),
            "£1,234.56"
        )
    }

    func testHalfUpRoundingFromThreeDecimalPlaces() {
        // 4.56624 → £4.57 (half-up). Confirms PricingService outputs
        // can be rendered without surprise rounding.
        XCTAssertEqual(
            CurrencyFormatter.format(Decimal(string: "4.56624")!),
            "£4.57"
        )
        // Boundary case: half-up rounds 0.345 → 0.35.
        XCTAssertEqual(
            CurrencyFormatter.format(Decimal(string: "12.345")!),
            "£12.35"
        )
    }
}
