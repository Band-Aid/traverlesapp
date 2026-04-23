import SwiftUI

struct RootView: View {
    @Environment(FlightStatusStore.self) private var store
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var tab: Tab = .home

    enum Tab: Hashable { case home, trips, checkin, status, profile }

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            TripsView()
                .tabItem { Label("Trips", systemImage: "airplane.circle.fill") }
                .tag(Tab.trips)

            CheckInView()
                .tabItem { Label("Check-in", systemImage: "checkmark.seal.fill") }
                .tag(Tab.checkin)

            FlightStatusView()
                .tabItem { Label("Status", systemImage: "dot.radiowaves.left.and.right") }
                .tag(Tab.status)

            ProfileView()
                .tabItem { Label("JMB", systemImage: "person.crop.circle.fill") }
                .tag(Tab.profile)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasOnboarded = true
                showOnboarding = false
            }
            .interactiveDismissDisabled()
        }
        .onAppear {
            if !hasOnboarded { showOnboarding = true }
        }
    }
}

#Preview {
    RootView()
        .environment(FlightStatusStore(service: MockFlightStatusService()))
}
