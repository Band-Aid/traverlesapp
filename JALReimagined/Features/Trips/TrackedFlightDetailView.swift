import SwiftUI

/// Detail view for a single tracked flight. Reads its live status from the
/// store by flight number so it re-renders automatically when background /
/// 15-min refresh updates the cache.
struct TrackedFlightDetailView: View {
    let flightNumber: String
    @Environment(FlightStatusStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showTerminalMap = false
    @State private var confirmUntrack = false

    private var status: FlightLiveStatus? {
        store.status(for: flightNumber)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let status {
                    if store.isOffline {
                        offlineBanner(status)
                    }
                    GateCard(status: status)
                    LiveStatusCard(status: status)
                    TimesCard(status: status)
                    actionsRow(for: status)
                    LiveFlightMap(status: status)
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: JALTheme.ink.opacity(0.08), radius: 14, x: 0, y: 6)
                    untrackButton
                } else {
                    ContentUnavailableView(
                        "Flight not found",
                        systemImage: "airplane.circle",
                        description: Text("This flight may have been removed.")
                    )
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(JALTheme.mist.ignoresSafeArea())
        .navigationTitle(flightNumber)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTerminalMap) {
            if let status {
                NavigationStack { TerminalMapView(status: status) }
            }
        }
        .alert("Stop tracking \(flightNumber)?", isPresented: $confirmUntrack) {
            Button("Stop tracking", role: .destructive) {
                store.untrack(flightNumber)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We'll drop the cached status. You can add it back anytime.")
        }
    }

    private func offlineBanner(_ status: FlightLiveStatus) -> some View {
        TimelineView(.periodic(from: .now, by: 30)) { ctx in
            HStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(JALTheme.inkSoft)
                Text("Cached · updated \(FlightStatusView.relative(status.lastFetched, from: ctx.date))")
                    .font(.jal(12, .semibold))
                    .foregroundStyle(JALTheme.inkSoft)
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(JALTheme.line, lineWidth: 1)
            )
        }
    }

    private func actionsRow(for status: FlightLiveStatus) -> some View {
        HStack(spacing: 10) {
            actionButton(icon: "map.fill", title: "Terminal map", tint: JALTheme.crane) {
                showTerminalMap = true
            }
            actionButton(icon: "car.fill",
                         title: "Uber to \(status.originIATA)",
                         tint: .black) {
                UberLink.open(to: status)
            }
        }
    }

    private func actionButton(icon: String, title: String, tint: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title).font(.jal(13, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var untrackButton: some View {
        Button(role: .destructive) {
            confirmUntrack = true
        } label: {
            Label("Stop tracking", systemImage: "minus.circle")
                .font(.jal(14, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(JALTheme.crane)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(JALTheme.craneSoft)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }
}
