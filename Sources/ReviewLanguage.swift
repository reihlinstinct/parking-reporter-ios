import SwiftUI
import UIKit

enum ReviewLanguage: String, CaseIterable, Identifiable { case hebrew = "he", english = "en", arabic = "ar", russian = "ru", amharic = "am", french = "fr"
    var id: String { rawValue }
    // Hebrew and English come from the call site. Other languages look up the English text in
    // the UI catalog (Resources/i18n/ui_strings.json); a missing entry shows English, and the
    // scripts/check_ios_strings.py gate keeps that from happening for shipped screens.
    func text(_ hebrew: String, _ english: String) -> String {
        switch self {
        case .hebrew: return hebrew
        case .english: return english
        default: return Localizer.shared.ui(english, self) ?? english
        }
    }
    /// fr, ar, ru and am are machine drafts until a native speaker reviews them.
    var isMachineTranslated: Bool { self != .hebrew && self != .english }
    var isRightToLeft: Bool { self == .hebrew || self == .arabic }
    var direction: LayoutDirection { isRightToLeft ? .rightToLeft : .leftToRight }
    var nativeName: String {
        switch self { case .hebrew: return "עברית"; case .english: return "English"; case .arabic: return "العربية"; case .russian: return "Русский"; case .amharic: return "አማርኛ"; case .french: return "Français" }
    }
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

extension ReviewLanguage {
    // Preview flags win, then the user's saved choice, then the system language.
    static func resolve(arguments: [String], preferred: [String], saved: ReviewLanguage? = nil) -> ReviewLanguage {
        for language in ReviewLanguage.allCases where arguments.contains("--preview-\(language.rawValue)") { return language }
        if let saved = saved { return saved }
        let code = preferred.first.map { String($0.prefix(2)) } ?? ""
        if code == "iw" { return .hebrew }
        return ReviewLanguage(rawValue: code) ?? .english
    }
}

enum AppTheme {
    // Android palette (Palette.kt): NAVY 0x2C537E, GOLD 0xD8A038, dark-mode primary 0xA3C9F5.
    static let accent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0xA3 / 255, green: 0xC9 / 255, blue: 0xF5 / 255, alpha: 1)
            : UIColor(red: 0x2C / 255, green: 0x53 / 255, blue: 0x7E / 255, alpha: 1)
    })
    // Fill behind white button text. Navy in both modes, because the dark-mode accent is light
    // (it suits text and icons on dark surfaces, but white text on it measures about 1.7:1).
    static let buttonFillUI = UIColor(red: 0x2C / 255, green: 0x53 / 255, blue: 0x7E / 255, alpha: 1)
    static let buttonFill = Color(buttonFillUI)
}

enum Contrast {
    // WCAG 2.x contrast ratio between two sRGB colours.
    static func ratio(_ a: UIColor, _ b: UIColor) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }
    static func luminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0, al: CGFloat = 0
        color.getRed(&r, green: &g, blue: &bl, alpha: &al)
        func lin(_ c: CGFloat) -> Double { let v = Double(c); return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(bl)
    }
}

enum ReportTimeFormat {
    // Readable 24-hour local time, never a timezone-stamped value.
    static func string(from date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}
