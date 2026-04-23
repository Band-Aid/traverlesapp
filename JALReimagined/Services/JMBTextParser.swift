import Foundation

/// Draft extracted from raw text. Every field is optional — the caller decides
/// which fields to trust and which to ask the user to fill in by hand.
struct JMBDraft: Equatable {
    var name: String?
    var memberNumber: String?
    var tier: String?       // matches one of `JMBProfile.tiers`
    var miles: Int?
    var flyOnPoints: Int?
    var flightsYTD: Int?
}

/// Heuristic extractor that runs against OCR text or HTML-stripped page text.
/// Both JAL's web portal and the native iOS app print these fields in the
/// same shapes (JL 1 003 4567, "Diamond", comma-grouped miles), so a shared
/// parser is enough for both scrape paths.
enum JMBTextParser {
    static func parse(_ lines: [String]) -> JMBDraft {
        let cleaned = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let joined = cleaned.joined(separator: "\n")

        var draft = JMBDraft()
        draft.tier = extractTier(from: joined)
        draft.memberNumber = extractMemberNumber(from: joined)
        draft.flyOnPoints = extractFOP(from: cleaned)
        draft.miles = extractMiles(from: joined, excluding: draft.flyOnPoints)
        draft.flightsYTD = extractFlightsYTD(from: cleaned)
        draft.name = extractName(from: cleaned, memberNumber: draft.memberNumber)
        return draft
    }

    // MARK: - Tier

    /// Search in descending status order — if multiple tier keywords appear
    /// (e.g. marketing copy listing all tiers), prefer the highest.
    private static func extractTier(from text: String) -> String? {
        let candidates: [(String, String)] = [
            ("Diamond", "Diamond"),
            ("ダイヤモンド", "Diamond"),
            ("Sapphire", "Sapphire"),
            ("サファイア", "Sapphire"),
            ("Crystal", "Crystal"),
            ("クリスタル", "Crystal")
        ]
        for (needle, tier) in candidates
        where text.localizedCaseInsensitiveContains(needle) {
            return tier
        }
        return nil
    }

    // MARK: - Member number

    /// Matches "JL 1 003 4567", "JL1 003 4567", "JL10034567", or a bare 9-digit
    /// run. Normalises to the canonical "JL 1 003 4567" spacing.
    private static func extractMemberNumber(from text: String) -> String? {
        // "JL" + optional space + 9 digits with optional spaces between them.
        let patterns = [
            #"JL[ \u3000]*\d[ \u3000]*\d{3}[ \u3000]*\d{4}"#,
            #"JL[ \u3000]*\d{9}"#
        ]
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                return normalizeMemberNumber(String(text[range]))
            }
        }
        // Fallback: a bare 9-digit run that's not part of a larger number.
        if let range = text.range(of: #"(?<!\d)\d{9}(?!\d)"#, options: .regularExpression) {
            return normalizeMemberNumber("JL" + text[range])
        }
        return nil
    }

    private static func normalizeMemberNumber(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard digits.count == 9 else { return raw }
        let d = Array(digits)
        return "JL \(d[0]) \(String(d[1...3])) \(String(d[4...8]))"
    }

    // MARK: - Miles

    /// Largest plausible comma/space-grouped integer in the text, optionally
    /// excluding an already-identified FOP value so we don't double-claim it.
    /// JMB screens typically have one big number (lifetime miles) and a
    /// medium one (FOP), so max() works after excluding FOP.
    private static func extractMiles(from text: String, excluding fop: Int? = nil) -> Int? {
        let numbers = allNumbers(in: text)
        let filtered = fop.map { f in numbers.filter { $0 != f } } ?? numbers
        return filtered.max()
    }

    private static func allNumbers(in text: String) -> [Int] {
        let pattern = #"\b\d{1,3}(?:[,，]\d{3})+\b|\b\d{4,8}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        var out: [Int] = []
        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let m = match?.range,
                  let swiftRange = Range(m, in: text) else { return }
            let stripped = text[swiftRange]
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: "，", with: "")
            if let n = Int(stripped), (1_000...10_000_000).contains(n) {
                out.append(n)
            }
        }
        return out
    }

    // MARK: - FLY ON Points

    /// FOP is the annual status currency. JAL labels it "FLY ON Points",
    /// "FOP", or "FLY ONポイント" depending on locale.
    private static func extractFOP(from lines: [String]) -> Int? {
        let keywords = ["fly on", "fop", "flyon", "fly onポイント", "fly on points",
                        "fly on point"]
        for (idx, line) in lines.enumerated() {
            let lower = line.lowercased()
            guard keywords.contains(where: lower.contains) else { continue }
            // Same line
            if let n = firstBigNumber(in: line) { return n }
            // Adjacent lines — labels often sit above values in dashboards
            if idx + 1 < lines.count, let n = firstBigNumber(in: lines[idx + 1]) { return n }
            if idx > 0, let n = firstBigNumber(in: lines[idx - 1]) { return n }
        }
        return nil
    }

    private static func firstBigNumber(in line: String) -> Int? {
        allNumbers(in: line).first
    }

    // MARK: - Flights YTD

    /// Looks for small integers (1–999) adjacent to a flight-count keyword.
    /// Much less reliable than miles, so it's OK to return nil.
    private static func extractFlightsYTD(from lines: [String]) -> Int? {
        let keywords = ["flights", "segments", "搭乗回数", "フライト"]
        for (idx, line) in lines.enumerated() {
            let lower = line.lowercased()
            guard keywords.contains(where: lower.contains) else { continue }
            // Same line first
            if let n = firstSmallInt(in: line) { return n }
            // Adjacent lines (some layouts put label above value)
            if idx + 1 < lines.count, let n = firstSmallInt(in: lines[idx + 1]) { return n }
            if idx > 0, let n = firstSmallInt(in: lines[idx - 1]) { return n }
        }
        return nil
    }

    private static func firstSmallInt(in line: String) -> Int? {
        guard let range = line.range(of: #"\b\d{1,3}\b"#, options: .regularExpression),
              let n = Int(line[range]),
              (1...999).contains(n) else { return nil }
        return n
    }

    // MARK: - Name

    /// Best-effort: an ALL-CAPS line that sits adjacent to the member number.
    /// JAL prints names as "YAMASHITA/DAICHI MR" or "DAICHI YAMASHITA".
    private static func extractName(from lines: [String], memberNumber: String?) -> String? {
        guard let memberNumber else { return firstAllCapsName(in: lines) }
        for (idx, line) in lines.enumerated() where line.contains(memberNumber.prefix(4)) {
            for offset in [-1, 1, -2, 2] {
                let i = idx + offset
                guard lines.indices.contains(i) else { continue }
                if let name = asName(lines[i]) { return name }
            }
        }
        return firstAllCapsName(in: lines)
    }

    private static func firstAllCapsName(in lines: [String]) -> String? {
        for line in lines {
            if let name = asName(line) { return name }
        }
        return nil
    }

    private static func asName(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 5, trimmed.count <= 40 else { return nil }
        let letters = trimmed.filter { $0.isLetter }
        guard letters.count >= 4 else { return nil }
        let uppers = letters.filter { $0.isUppercase }
        guard Double(uppers.count) / Double(letters.count) >= 0.8 else { return nil }
        // Reject strings that look like member numbers or tier labels.
        if trimmed.contains("JL") || trimmed.range(of: #"\d{4,}"#, options: .regularExpression) != nil {
            return nil
        }
        return trimmed.capitalized
    }
}
