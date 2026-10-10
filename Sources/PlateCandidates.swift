import Foundation

enum PlateCandidates {
    // A candidate, never an assertion that a plate or offence was detected.
    static func parse(_ lines: [String]) -> [String] {
        let pattern = #"(?<![A-Za-z0-9])(?:[0-9]{7,8}|[0-9]{2}-[0-9]{3}-[0-9]{2}|[0-9]{3}-[0-9]{2}-[0-9]{3})(?![A-Za-z0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        var result: [String] = []
        for line in lines {
            let text = line as NSString
            for match in regex.matches(in: line, range: NSRange(location: 0, length: text.length)) {
                let value = text.substring(with: match.range).replacingOccurrences(of: "-", with: "")
                if !result.contains(value) { result.append(value) }
            }
        }
        return result
    }
}
