import SwiftUI

struct HomeView: View {
    @Environment(FlightStatusStore.self) private var store
    @State private var showAddFlight = false

    private var hero: FlightLiveStatus? {
        store.nextUpcoming ?? store.tracked.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greeting
                    if let hero {
                        NavigationLink {
                            TrackedFlightDetailView(flightNumber: hero.flightNumber)
                        } label: {
                            LiveHeroCard(status: hero)
                        }
                        .buttonStyle(.plain)

                        if store.tracked.count > 1 {
                            otherFlightsStrip
                        }
                    } else {
                        emptyHero
                    }
                    quickActions
                    if hero != nil {
                        addMoreButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(JALTheme.mist.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 10) {
                        CraneMark(size: 30)
                        Text("JAL")
                            .font(.jal(18, .heavy))
                            .foregroundStyle(JALTheme.ink)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddFlight = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(JALTheme.ink)
                    }
                }
            }
            .sheet(isPresented: $showAddFlight) {
                AddFlightSheet()
            }
        }
    }

    // MARK: - Greeting

    private var greeting: some View {
        TimelineView(.periodic(from: .now, by: 60)) { ctx in
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.greetingText(at: ctx.date))
                    .font(.jal(28, .bold))
                    .foregroundStyle(JALTheme.ink)
                Text(subline(at: ctx.date))
                    .font(.jal(15))
                    .foregroundStyle(JALTheme.inkSoft)
            }
            .padding(.top, 4)
        }
    }

    private func subline(at now: Date) -> String {
        guard let hero else { return "No flights tracked yet — add one to get started." }
        let dep = hero.estimatedDeparture ?? hero.scheduledDeparture
        let seconds = dep.timeIntervalSince(now)
        if seconds > 0 {
            let h = Int(seconds / 3600)
            let m = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            if h > 0 { return "Your \(hero.flightNumber) departs in \(h)h \(m)m." }
            return "Your \(hero.flightNumber) departs in \(m)m."
        }
        if hero.actualDeparture != nil && hero.actualArrival == nil {
            return "\(hero.flightNumber) is in the air."
        }
        return "You're all set — safe travels."
    }

    private static func greetingText(at date: Date) -> String {
        let h = Calendar.current.component(.hour, from: date)
        switch h {
        case 5..<11:  return "Ohayō gozaimasu"
        case 11..<17: return "Konnichiwa"
        case 17..<22: return "Konbanwa"
        default:      return "Oyasumi"
        }
    }

    // MARK: - Empty hero

    private var emptyHero: some View {
        Button { showAddFlight = true } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    CraneMark(size: 40, tint: .white, background: JALTheme.crane)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer(minLength: 8)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add your flight")
                        .font(.jal(26, .heavy))
                        .foregroundStyle(.white)
                    Text("Enter a flight number to start tracking gate, terminal and status — even offline.")
                        .font(.jal(13))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(3)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
            .background(
                ZStack {
                    JALTheme.craneGradient
                    Image(systemName: "airplane")
                        .resizable().scaledToFit()
                        .foregroundStyle(.white.opacity(0.08))
                        .frame(width: 260)
                        .rotationEffect(.degrees(-20))
                        .offset(x: 90, y: 30)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: JALTheme.crane.opacity(0.25), radius: 22, x: 0, y: 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Other flights strip

    private var otherFlightsStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Also tracking")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.tracked.filter { $0.flightNumber != hero?.flightNumber },
                            id: \.flightNumber) { flight in
                        NavigationLink {
                            TrackedFlightDetailView(flightNumber: flight.flightNumber)
                        } label: {
                            MiniFlightCard(status: flight)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: 8) {
            QuickAction(icon: "checkmark.seal.fill", label: "Check-in", tint: JALTheme.crane)
            QuickAction(icon: "airplane", label: "Flight status")
            QuickAction(icon: "suitcase.fill", label: "Bags")
            QuickAction(icon: "fork.knife", label: "Meals")
            QuickAction(icon: "person.2.fill", label: "Lounge")
        }
        .jalCard(padding: 14)
    }

    private var addMoreButton: some View {
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
    }
}

// MARK: - Live hero card

private struct LiveHeroCard: View {
    let status: FlightLiveStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(status.flightNumber)
                        .font(.jal(14, .bold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer(minLength: 8)
                    HStack(spacing: 6) {
                        Circle().fill(.white).frame(width: 6, height: 6)
                        Text(status.status.rawValue)
                            .font(.jal(11, .heavy))
                            .tracking(0.8)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.2)))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                }
                Text("\(status.originIATA) → \(status.destinationIATA)")
                    .font(.jal(44, .heavy))
                    .foregroundStyle(.white)
                    .kerning(-1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }

            HStack(alignment: .bottom, spacing: 22) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GATE")
                        .font(.jal(10, .heavy))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.65))
                    Text(status.departureGate ?? "—")
                        .font(.jal(42, .heavy))
                        .foregroundStyle(.white)
                        .kerning(-1)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("TERMINAL")
                        .font(.jal(10, .heavy))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.65))
                    Text(status.departureTerminal ?? "—")
                        .font(.jal(28, .heavy))
                        .foregroundStyle(.white)
                }
                Spacer()
            }

            DashedDivider().overlay(Color.white.opacity(0.3))

            TimelineView(.periodic(from: .now, by: 30)) { ctx in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DEPARTS IN")
                            .font(.jal(10, .heavy))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(Self.countdown(to: status, now: ctx.date))
                            .font(.jalMono(22, .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                }
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

    private static func countdown(to status: FlightLiveStatus, now: Date) -> String {
        let dep = status.estimatedDeparture ?? status.scheduledDeparture
        let arr = status.estimatedArrival  ?? status.scheduledArrival
        if let arrived = status.actualArrival {
            return "Arrived \(FlightStatusView.relative(arrived, from: now))"
        }
        if status.actualDeparture != nil {
            let remaining = arr.timeIntervalSince(now)
            if remaining > 0 { return "Lands in \(hm(remaining))" }
            return "Landing"
        }
        let untilDep = dep.timeIntervalSince(now)
        if untilDep > 0 { return hm(untilDep) }
        return "Now boarding"
    }

    private static func hm(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

// MARK: - Mini flight card

private struct MiniFlightCard: View {
    let status: FlightLiveStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(status.flightNumber)
                .font(.jalMono(12, .bold))
                .foregroundStyle(JALTheme.crane)
            Text("\(status.originIATA) → \(status.destinationIATA)")
                .font(.jal(16, .bold))
                .foregroundStyle(JALTheme.ink)
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 10, weight: .bold))
                Text("Gate \(status.departureGate ?? "—")")
                    .font(.jal(11, .semibold))
            }
            .foregroundStyle(JALTheme.inkSoft)
        }
        .padding(14)
        .frame(width: 160, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white)
        )
        .shadow(color: JALTheme.ink.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    HomeView()
        .environment(FlightStatusStore(service: MockFlightStatusService()))
}
