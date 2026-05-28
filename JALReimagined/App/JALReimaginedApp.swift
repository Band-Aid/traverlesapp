import SwiftUI
import BackgroundTasks

@main
struct JALReimaginedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var flightStore = FlightStatusStore.makeDefault()
    @State private var jmbStore = JMBStore()

    static let refreshTaskID = "com.jalhack.refresh"

    init() {
        PendoIntegration.setup()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(flightStore)
                .environment(jmbStore)
                .preferredColorScheme(.light)
                .tint(JALTheme.crane)
                .onAppear {
                    scheduleNextRefresh()
                    if let profile = jmbStore.profile {
                        let hasOnboarded = UserDefaults.standard.bool(forKey: "hasOnboarded")
                        PendoIntegration.identifyVisitor(profile, hasOnboarded: hasOnboarded)
                    }
                }
                .onOpenURL { url in
                    let handled = appDelegate.application(UIApplication.shared, open: url, options: [:])
                    if !handled {
                        NSLog("Unhandled URL: %@", url.absoluteString)
                    }
                }
        }
        .backgroundTask(.appRefresh(Self.refreshTaskID)) {
            await flightStore.backgroundRefresh()
            scheduleNextRefresh()
        }
    }

}

/// Asks iOS to wake us up ~15 minutes from now. The OS ultimately decides
/// when to fire — on iOS, background refresh is opportunistic.
private func scheduleNextRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: JALReimaginedApp.refreshTaskID)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    try? BGTaskScheduler.shared.submit(request)
}
