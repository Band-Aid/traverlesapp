import Foundation
import Pendo

/// Centralizes all Pendo SDK interactions. Call `setup()` once at app launch,
/// then `identifyVisitor(_:hasOnboarded:)` whenever the JMB profile changes.
enum PendoIntegration {

    /// The Pendo app key provisioned for this application.
    private static let appKey = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhY2VudGVyIjoidXMiLCJrZXkiOiIyZmY2MmFkNWZhMWQ0M2FmMTAxZjEzYmU3OWVlNzVjZGFhN2FhMWM3N2VhYjg5MTdhZjY1Mjg3YjkzZjlkZDA0MmMwZGY5MWJkNzUxZmE4ZGU2MGUyMWUyMTc1MWFmYTNkN2MxZDA4MDVjOWNhN2NkMjRjYzM3ZjIyYjc0YTc3MDcxZmQxMGZhMTIwZDNhZTdmMmRlYWMzZmI4NGE4NWJmMGJhNGJiZWJlMTFjMTc3OTViODQ4NGU0NmZiOTgxZjkuOWZiMWJhZDc4OTEwMmIxOGUwNTAyODkzOGU5Y2IxZjQuOGU3ZThmYTg0ZTM1ZWQyNmQ4NzE3ZGNkODljNWU5ZTc2MTg3OTIxZWVlYWE5NzI3ZjBlNTM5ZTMwZDkzZTc4ZiJ9.D3aFtq_upCnPXIO7s-6vXhL5zVW8hJyMv2djKQmCBzIKpD-ai2fYcKi-E0WaTGYZiMiQRUKUOPEe_VXzB8ydgpmHz1Ja8-haA7xD6IEWkV5WVZlWXIwfPu9JhFH0sYX5U3-WN1klUhOzjqjQ-YfzjFtVqoeFGqWIuKd7E6pgATA"

    /// Call once from the `App` initializer to load the Pendo agent.
    /// Starts an anonymous session so Pendo begins collecting analytics
    /// immediately, even before the user signs in.
    static func setup() {
        PendoManager.shared().setup(appKey)
        PendoManager.shared().startSession("", accountId: "", visitorData: [:], accountData: [:])
    }

    /// Call whenever the user's JMB profile becomes available or changes.
    /// Maps all 8 detected metadata fields into the Pendo visitor object.
    ///
    /// - Parameters:
    ///   - profile: The user's JMB profile.
    ///   - hasOnboarded: Whether the user has completed onboarding.
    static func identifyVisitor(_ profile: JMBProfile, hasOnboarded: Bool) {
        let visitorData: [String: Any] = [
            "full_name": profile.name,
            "tier": profile.tier,
            "miles": profile.miles,
            "flyOnPoints": profile.flyOnPoints ?? 0,
            "flightsYTD": profile.flightsYTD,
            "segmentsYTD": profile.segmentsYTD,
            "hasOnboarded": hasOnboarded
        ]

        PendoManager.shared().startSession(
            profile.memberNumber,
            accountId: "",
            visitorData: visitorData,
            accountData: [:]
        )
    }

    /// Call when the user clears their profile (sign out equivalent).
    /// Reverts to an anonymous session.
    static func clearVisitor() {
        PendoManager.shared().startSession("", accountId: "", visitorData: [:], accountData: [:])
    }

    static func handleOpenURL(_ url: URL) -> Bool {
        guard url.scheme?.hasPrefix("pendo") == true else { return false }
        PendoManager.shared().initWith(url)
        return true
    }
}
