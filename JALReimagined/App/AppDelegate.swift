import Foundation
import UIKit
import Pendo

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PendoManager.shared().setup("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhY2VudGVyIjoidXMiLCJrZXkiOiIyZmY2MmFkNWZhMWQ0M2FmMTAxZjEzYmU3OWVlNzVjZGFhN2FhMWM3N2VhYjg5MTdhZjY1Mjg3YjkzZjlkZDA0MmMwZGY5MWJkNzUxZmE4ZGU2MGUyMWUyMTc1MWFmYTNkN2MxZDA4MDVjOWNhN2NkMjRjYzM3ZjIyYjc0YTc3MDcxZmQxMGZhMTIwZDNhZTdmMmRlYWMzZmI4NGE4NWJmMGJhNGJiZWJlMTFjMTc3OTViODQ4NGU0NmZiOTgxZjkuOWZiMWJhZDc4OTEwMmIxOGUwNTAyODkzOGU5Y2IxZjQuOGU3ZThmYTg0ZTM1ZWQyNmQ4NzE3ZGNkODljNWU5ZTc2MTg3OTIxZWVlYWE5NzI3ZjBlNTM5ZTMwZDkzZTc4ZiJ9.D3aFtq_upCnPXIO7s-6vXhL5zVW8hJyMv2djKQmCBzIKpD-ai2fYcKi-E0WaTGYZiMiQRUKUOPEe_VXzB8ydgpmHz1Ja8-haA7xD6IEWkV5WVZlWXIwfPu9JhFH0sYX5U3-WN1klUhOzjqjQ-YfzjFtVqoeFGqWIuKd7E6pgATA")

        let jmbStore = JMBStore()
        let profile = jmbStore.profile

        PendoManager.shared().startSession(
            profile?.memberNumber ?? "",
            accountId: "",
            visitorData: [
                "memberNumber": profile?.memberNumber ?? "",
                "name": profile?.name ?? "",
                "tier": profile?.tier ?? "",
                "miles": profile?.miles ?? 0,
                "flyOnPoints": profile?.flyOnPoints ?? 0,
                "flightsYTD": profile?.flightsYTD ?? 0,
                "segmentsYTD": profile?.segmentsYTD ?? 0
            ],
            accountData: [:]
        )

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme?.range(of: "pendo") != nil {
            PendoManager.shared().initWith(url)
            return true
        }
        return false
    }
}
