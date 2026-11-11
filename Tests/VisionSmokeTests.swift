import XCTest
import UIKit
import Vision
@testable import ParkingReporter
final class VisionSmokeTests: XCTestCase {
    func testSyntheticPlateAndBlank() throws {
        for (value, expected) in [("12-345-67", ["1234567"]), ("", [])] {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1000, height: 220))
            let image = renderer.image { context in
                UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 1000, height: 220))
                (value as NSString).draw(at: CGPoint(x: 50, y: 50), withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 100, weight: .bold), .foregroundColor: UIColor.black])
            }
            let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false; request.recognitionLanguages = ["en-US"]
            try VNImageRequestHandler(cgImage: try XCTUnwrap(image.cgImage)).perform([request])
            XCTAssertEqual(PlateCandidates.parse((request.results ?? []).compactMap { $0.topCandidates(1).first?.string }), expected)
        }
    }
}
