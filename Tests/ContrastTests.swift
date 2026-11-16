import XCTest
import UIKit
import SwiftUI
@testable import ParkingReporter

final class ContrastTests: XCTestCase {
    private func resolved(_ color: Color, _ style: UIUserInterfaceStyle) -> UIColor {
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }
    func testWhiteTextOnButtonFillMeetsAAInBothModes() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let fill = resolved(AppTheme.buttonFill, style)
            XCTAssertGreaterThanOrEqual(Contrast.ratio(.white, fill), 4.5, "button text contrast in \(style.rawValue)")
        }
    }
    func testAccentIsReadableOnItsSurfaceInBothModes() {
        let darkSurface = UIColor(red: 0x1A / 255, green: 0x1C / 255, blue: 0x1E / 255, alpha: 1)
        XCTAssertGreaterThanOrEqual(Contrast.ratio(resolved(AppTheme.accent, .dark), darkSurface), 4.5)
        XCTAssertGreaterThanOrEqual(Contrast.ratio(resolved(AppTheme.accent, .light), .white), 4.5)
    }
    func testOldDarkAccentWithWhiteTextWasTooLow() {
        // Documents the regression: white on the light dark-mode accent.
        XCTAssertLessThan(Contrast.ratio(.white, resolved(AppTheme.accent, .dark)), 3.0)
    }
    func testKnownRatios() {
        XCTAssertEqual(Contrast.ratio(.black, .white), 21, accuracy: 0.01)
    }
}
