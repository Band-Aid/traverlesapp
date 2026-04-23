import Foundation
import Observation

/// Persistent store for the user's JAL Mileage Bank profile. Backed by
/// UserDefaults JSON — enough for a demo, and the call sites don't need to
/// know whether the source is local entry, OCR, or a future scrape.
@Observable
final class JMBStore {
    private let key = "jmb.profile.v1"

    private(set) var profile: JMBProfile?

    var hasProfile: Bool { profile != nil }

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(JMBProfile.self, from: data) {
            self.profile = decoded
        }
    }

    func save(_ profile: JMBProfile) {
        self.profile = profile
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
        let hasOnboarded = UserDefaults.standard.bool(forKey: "hasOnboarded")
        PendoIntegration.identifyVisitor(profile, hasOnboarded: hasOnboarded)
    }

    func clear() {
        profile = nil
        UserDefaults.standard.removeObject(forKey: key)
        PendoIntegration.clearVisitor()
    }
}

extension JMBProfile {
    /// Current JAL FLY ON Program tiers, in ascending status order.
    /// JAL retired the old "JGC Premier" name when the Global Club side was
    /// moved into the Life Status Program — Crystal/Sapphire/Diamond is the
    /// canonical list for annual status.
    static let tiers: [String] = ["Crystal", "Sapphire", "Diamond"]

    /// FOP thresholds published by JAL for each tier.
    static let fopThresholds: [String: Int] = [
        "Crystal":  30_000,
        "Sapphire": 50_000,
        "Diamond":  100_000
    ]

    var bareTier: String {
        tier.replacingOccurrences(of: "JMB ", with: "")
    }

    /// Next tier up from the user's current one, or Crystal if they have no
    /// status yet.
    var nextTierUp: String? {
        if let idx = Self.tiers.firstIndex(of: bareTier) {
            return idx < Self.tiers.count - 1 ? Self.tiers[idx + 1] : nil
        }
        return Self.tiers.first
    }

    /// FOP remaining to reach `nextTierUp`. Uses the explicit field if
    /// supplied, otherwise computes from `flyOnPoints`.
    var fopToNextTier: Int? {
        if let explicit = milesToNextTier { return explicit }
        guard let next = nextTierUp,
              let threshold = Self.fopThresholds[next] else { return nil }
        let current = flyOnPoints ?? 0
        return max(0, threshold - current)
    }
}
