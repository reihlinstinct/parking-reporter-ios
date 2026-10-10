import SwiftUI
import UIKit

enum ReviewLanguage: String { case hebrew = "he", english = "en"
    func text(_ hebrew: String, _ english: String) -> String { self == .hebrew ? hebrew : english }
    var direction: LayoutDirection { self == .hebrew ? .rightToLeft : .leftToRight }
}
struct PlateRecognition: Equatable {
    let candidates: [String]
    let confidence: Float
    var needsCorrection: Bool { candidates.count != 1 || confidence < 0.85 }
    // Confidence is a presentation hint, never proof of plate identity or user approval.
    static func from(_ lines: [(String, Float)]) -> PlateRecognition {
        let candidates = PlateCandidates.parse(lines.map { $0.0 })
        let confidence = lines.filter { !PlateCandidates.parse([$0.0]).isEmpty }.map { $0.1 }.min() ?? 0
        return PlateRecognition(candidates: candidates, confidence: confidence)
    }
}
struct ReviewPreview {
    let uncertain: Bool
    static func image() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 420))
        return renderer.image { ctx in
            UIColor(red: 0.86, green: 0.91, blue: 0.93, alpha: 1).setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 800, height: 420))
            UIColor(red: 0.72, green: 0.79, blue: 0.78, alpha: 1).setFill(); ctx.fill(CGRect(x: 0, y: 270, width: 800, height: 150))
            UIColor(red: 0.22, green: 0.35, blue: 0.40, alpha: 1).setFill(); UIBezierPath(roundedRect: CGRect(x: 180, y: 110, width: 440, height: 220), cornerRadius: 28).fill()
            UIColor(red: 0.72, green: 0.84, blue: 0.88, alpha: 1).setFill(); UIBezierPath(roundedRect: CGRect(x: 210, y: 135, width: 380, height: 95), cornerRadius: 15).fill()
            UIColor.systemYellow.setFill(); UIBezierPath(roundedRect: CGRect(x: 285, y: 250, width: 230, height: 48), cornerRadius: 6).fill()
            ("12-345-67" as NSString).draw(at: CGPoint(x: 305, y: 256), withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 32, weight: .bold), .foregroundColor: UIColor.black])
            ("SYNTHETIC PREVIEW" as NSString).draw(at: CGPoint(x: 24, y: 24), withAttributes: [.font: UIFont.systemFont(ofSize: 25, weight: .medium), .foregroundColor: UIColor.darkGray])
        }
    }
}
