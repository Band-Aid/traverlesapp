import SwiftUI
import MapKit

struct FlightStatusView: View {
    @Environment(FlightStatusStore.self) private var store
    @State private var input: String = ""
    @FocusState private var inputFocused: Bool
    @State private var showTerminalMap = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    searchField

                    if let error = store.lastError {
                        errorBanner(error)
                    }

                    if let status = store.current {
                        if store.isOffline { offlineBanner(status) }
                        GateCard(status: status)
                        LiveStatusCard(status: status)
                        TimesCard(status: status)
                        actionsRow(for: status)
                        LiveFlightMap(status: status)
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: JALTheme.ink.opacity(0.08), radius: 14, x: 0, y: 6)
                    } else if store.isLoading {
                        ProgressView().padding(40)
                    } else {
                        emptyState
                    }

                    recentCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(JALTheme.mist.ignoresSafeArea())
            .navigationTitle("Flight status")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showTerminalMap) {
                if let status = store.current {
                    NavigationStack {
                        TerminalMapView(status: status)
                    }
                }
            }
        }
        .onAppear {
            if store.current == nil, let first = store.recent.first {
                Task { await store.lookup(first) }
            }
        }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "airplane")
                .foregroundStyle(JALTheme.crane)
            TextField("Flight number (e.g. JL2)", text: $input)
                .font(.jal(17, .semibold))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($inputFocused)
                .submitLabel(.search)
                .onSubmit(submit)
            if !input.isEmpty {
                Button { input = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(JALTheme.inkSoft)
                }
                .buttonStyle(.plain)
            }
            Button(action: submit) {
                Text("Track")
                    .font(.jal(13, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(JALTheme.crane))
            }
            .buttonStyle(.plain)
            .disabled(input.isEmpty)
            .opacity(input.isEmpty ? 0.4 : 1)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(JALTheme.line, lineWidth: 1)
        )
    }

    private func submit() {
        let query = input
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        inputFocused = false
        Task { await store.lookup(query) }
    }

    // MARK: - Banners

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(JALTheme.warning)
            Text(message)
                .font(.jal(13, .medium))
                .foregroundStyle(JALTheme.ink)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(JALTheme.warning.opacity(0.12))
        )
    }

    private func offlineBanner(_ status: FlightLiveStatus) -> some View {
        TimelineView(.periodic(from: .now, by: 30)) { ctx in
            HStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(JALTheme.inkSoft)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Showing cached status")
                        .font(.jal(12, .semibold))
                        .foregroundStyle(JALTheme.ink)
                    Text("Last updated \(Self.relative(status.lastFetched, from: ctx.date))")
                        .font(.jal(11))
                        .foregroundStyle(JALTheme.inkSoft)
                }
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(JALTheme.mist)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(JALTheme.line, lineWidth: 1)
            )
        }
    }

    // MARK: - Empty / recent

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(JALTheme.inkSoft)
            Text("Track a flight")
                .font(.jal(18, .bold))
                .foregroundStyle(JALTheme.ink)
            Text("Enter a JAL flight number to see the live gate, terminal and status. Works offline too — we keep the last known state.")
                .font(.jal(13))
                .foregroundStyle(JALTheme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 40)
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: store.recent.isEmpty ? "Try" : "Recent")
            let suggestions = store.recent.isEmpty
                ? ["JL2", "JL5", "JL60", "JL505"]
                : store.recent
            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { number in
                    Button {
                        input = number
                        submit()
                    } label: {
                        Text(number)
                            .font(.jalMono(13, .bold))
                            .foregroundStyle(JALTheme.ink)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(
                                Capsule().fill(JALTheme.mist)
                            )
                            .overlay(
                                Capsule().strokeBorder(JALTheme.line, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .jalCard()
    }

    // MARK: - Actions

    private func actionsRow(for status: FlightLiveStatus) -> some View {
        HStack(spacing: 10) {
            actionButton(icon: "map.fill",
                         title: "Terminal map",
                         tint: JALTheme.crane) {
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

    // MARK: - Helpers

    static func relative(_ date: Date, from now: Date) -> String {
        let ago = now.timeIntervalSince(date)
        if ago < 45 { return "just now" }
        if ago < 3600 { return "\(Int(ago / 60)) min ago" }
        let h = Int(ago / 3600)
        let m = Int((ago.truncatingRemainder(dividingBy: 3600)) / 60)
        return m == 0 ? "\(h)h ago" : "\(h)h \(m)m ago"
    }
}

// MARK: - Gate card (headline — biggest visual)

struct GateCard: View {
    let status: FlightLiveStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.flightNumber)
                        .font(.jal(22, .heavy))
                        .foregroundStyle(.white)
                    Text("\(status.originCity) → \(status.destinationCity)")
                        .font(.jal(12))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                StatusBadge(status: status.status)
            }

            HStack(alignment: .bottom, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GATE")
                        .font(.jal(10, .heavy))
                        .tracking(1.6)
                        .foregroundStyle(.white.opacity(0.65))
                    Text(status.departureGate ?? "—")
                        .font(.jal(64, .heavy))
                        .foregroundStyle(.white)
                        .kerning(-2)
                        .contentTransition(.numericText())
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("TERMINAL")
                        .font(.jal(10, .heavy))
                        .tracking(1.6)
                        .foregroundStyle(.white.opacity(0.65))
                    Text(status.departureTerminal ?? "—")
                        .font(.jal(44, .heavy))
                        .foregroundStyle(.white)
                        .kerning(-1)
                }
                Spacer()
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                JALTheme.craneGradient
                Image(systemName: "bird.fill")
                    .resizable().scaledToFit()
                    .foregroundStyle(.white.opacity(0.08))
                    .frame(width: 220)
                    .rotationEffect(.degrees(-15))
                    .offset(x: 110, y: 10)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: JALTheme.crane.opacity(0.25), radius: 22, x: 0, y: 12)
    }
}

// MARK: - Live status card (countdown)

struct LiveStatusCard: View {
    let status: FlightLiveStatus

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let now = context.date
            let c = countdown(now: now)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: c.heading)
                    Spacer()
                    Text("Updated \(FlightStatusView.relative(status.lastFetched, from: now))")
                        .font(.jal(11))
                        .foregroundStyle(JALTheme.inkSoft)
                }
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(c.value)
                        .font(.jalMono(40, .bold))
                        .foregroundStyle(JALTheme.ink)
                        .contentTransition(.numericText())
                    Text(c.unit)
                        .font(.jal(15, .semibold))
                        .foregroundStyle(JALTheme.inkSoft)
                    Spacer()
                }
                if let detail = c.detail {
                    Text(detail)
                        .font(.jal(12))
                        .foregroundStyle(JALTheme.inkSoft)
                }
            }
            .jalCard()
        }
    }

    private struct Countdown {
        let heading: String
        let value: String
        let unit: String
        let detail: String?
    }

    private func countdown(now: Date) -> Countdown {
        let dep = status.estimatedDeparture ?? status.scheduledDeparture
        let arr = status.estimatedArrival  ?? status.scheduledArrival

        if let arrived = status.actualArrival {
            return .init(
                heading: "Arrived",
                value: FlightStatusView.relative(arrived, from: now)
                    .replacingOccurrences(of: " ago", with: ""),
                unit: "ago",
                detail: "Landed at \(arrived.formatted(in: status.destinationTimezone, "HH:mm")) local"
            )
        }
        if status.actualDeparture != nil {
            let remaining = arr.timeIntervalSince(now)
            if remaining > 0 {
                return .init(
                    heading: "En route · landing in",
                    value: Self.hm(remaining),
                    unit: "",
                    detail: "Arrives \(arr.formatted(in: status.destinationTimezone, "HH:mm")) \(status.destinationIATA)"
                )
            } else {
                return .init(heading: "Landing now", value: "—", unit: "", detail: nil)
            }
        }
        let untilDep = dep.timeIntervalSince(now)
        if untilDep > 0 {
            return .init(
                heading: "Departs in",
                value: Self.hm(untilDep),
                unit: "",
                detail: "Scheduled \(status.scheduledDeparture.formatted(in: status.originTimezone, "HH:mm")) \(status.originIATA)"
            )
        } else {
            return .init(
                heading: "Gate should be open",
                value: Self.hm(-untilDep),
                unit: "late",
                detail: nil
            )
        }
    }

    private static func hm(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

// MARK: - Times card

struct TimesCard: View {
    let status: FlightLiveStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Schedule")
            HStack {
                column(title: "DEPART \(status.originIATA)",
                       scheduled: status.scheduledDeparture,
                       estimated: status.estimatedDeparture,
                       tz: status.originTimezone)
                Spacer()
                column(title: "ARRIVE \(status.destinationIATA)",
                       scheduled: status.scheduledArrival,
                       estimated: status.estimatedArrival,
                       tz: status.destinationTimezone,
                       alignment: .trailing)
            }
            if let model = status.aircraftModel {
                Divider().background(JALTheme.line)
                HStack(spacing: 10) {
                    Image(systemName: "airplane")
                        .foregroundStyle(JALTheme.crane)
                    Text(model)
                        .font(.jal(13, .medium))
                        .foregroundStyle(JALTheme.ink)
                    if let reg = status.aircraftReg {
                        Text("·").foregroundStyle(JALTheme.inkSoft)
                        Text(reg)
                            .font(.jalMono(12))
                            .foregroundStyle(JALTheme.inkSoft)
                    }
                    Spacer()
                }
            }
        }
        .jalCard()
    }

    private func column(title: String, scheduled: Date, estimated: Date?,
                        tz: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.jal(10, .heavy))
                .tracking(1.0)
                .foregroundStyle(JALTheme.inkSoft)
            Text(scheduled.formatted(in: tz, "HH:mm"))
                .font(.jalMono(24, .bold))
                .foregroundStyle(JALTheme.ink)
            if let estimated, abs(estimated.timeIntervalSince(scheduled)) > 60 {
                Text("Est. \(estimated.formatted(in: tz, "HH:mm"))")
                    .font(.jal(11, .semibold))
                    .foregroundStyle(JALTheme.warning)
            }
            Text(scheduled.formatted(in: tz, "EEE, MMM d"))
                .font(.jal(11))
                .foregroundStyle(JALTheme.inkSoft)
        }
    }
}

// MARK: - Status badge

struct StatusBadge: View {
    let status: LiveStatus
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(.white).frame(width: 6, height: 6)
            Text(status.rawValue)
                .font(.jal(11, .heavy))
                .tracking(0.8)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Capsule().fill(.white.opacity(0.2)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - Flow layout for recent-search chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > maxWidth { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    FlightStatusView()
        .environment(FlightStatusStore(service: MockFlightStatusService()))
}
