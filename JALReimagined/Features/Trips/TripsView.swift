import SwiftUI

struct TripsView: View {
    @Environment(FlightStatusStore.self) private var store
    @State private var filter: Filter = .upcoming
    @State private var showAddFlight = false

    enum Filter: String, CaseIterable { case upcoming = "Upcoming", past = "Past" }

    private var flights: [FlightLiveStatus] {
        switch filter {
        case .upcoming: return store.tracked.filter { $0.actualArrival == nil }
        case .past:     return store.tracked.filter { $0.actualArrival != nil }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("", selection: $filter) {
                        ForEach(Filter.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    if flights.isEmpty {
                        emptyState
                            .padding(.top, 40)
                    } else {
                        ForEach(flights, id: \.flightNumber) { flight in
                            NavigationLink {
                                TrackedFlightDetailView(flightNumber: flight.flightNumber)
                            } label: {
                                TripRow(status: flight)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }

                    Button { showAddFlight = true } label: {
                        Label("Track another flight", systemImage: "plus.circle.fill")
                            .font(.jal(14, .semibold))
                            .foregroundStyle(JALTheme.crane)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(JALTheme.crane.opacity(0.4),
                                                  style: .init(lineWidth: 1.2, dash: [4, 4]))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
            .background(JALTheme.mist.ignoresSafeArea())
            .navigationTitle("My Trips")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddFlight) {
                AddFlightSheet()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(JALTheme.inkSoft)
            Text(filter == .upcoming ? "No upcoming flights" : "No past flights")
                .font(.jal(17, .bold))
                .foregroundStyle(JALTheme.ink)
            Text("Add a flight to keep its status cached and tracked.")
                .font(.jal(13))
                .foregroundStyle(JALTheme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 20)
    }
}

private struct TripRow: View {
    let status: FlightLiveStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Pill(text: status.flightNumber, icon: "number", tint: JALTheme.ink)
                Spacer()
                Pill(text: status.status.rawValue,
                     icon: "circle.fill",
                     tint: tintFor(status.status), filled: false)
            }

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.originIATA)
                        .font(.jal(28, .heavy))
                        .foregroundStyle(JALTheme.ink)
                    Text(status.originCity)
                        .font(.jal(11, .semibold))
                        .foregroundStyle(JALTheme.inkSoft)
                }
                Spacer()
                Image(systemName: "airplane")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(JALTheme.crane)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(status.destinationIATA)
                        .font(.jal(28, .heavy))
                        .foregroundStyle(JALTheme.ink)
                    Text(status.destinationCity)
                        .font(.jal(11, .semibold))
                        .foregroundStyle(JALTheme.inkSoft)
                }
            }

            DashedDivider()

            HStack {
                Label {
                    Text(status.scheduledDeparture
                            .formatted(in: status.originTimezone, "MMM d · HH:mm"))
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.jal(12, .medium))
                .foregroundStyle(JALTheme.inkSoft)

                Spacer()

                if let gate = status.departureGate {
                    Label("Gate \(gate)", systemImage: "mappin.and.ellipse")
                        .font(.jal(12, .medium))
                        .foregroundStyle(JALTheme.inkSoft)
                }
            }
        }
        .jalCard()
    }

    private func tintFor(_ s: LiveStatus) -> Color {
        switch s {
        case .delayed, .cancelled, .diverted: return JALTheme.warning
        case .boarding, .enRoute, .landed, .arrived: return JALTheme.success
        default: return JALTheme.inkSoft
        }
    }
}

#Preview {
    TripsView()
        .environment(FlightStatusStore(service: MockFlightStatusService()))
}
