import SwiftUI

/// The flight plan — the core experience JAL's current app is missing.
struct TripDetailView: View {
    let trip: Trip
    @State private var selectedFlightIndex: Int = 0
    @State private var showBoardingPass = false

    private var flight: Flight { trip.flights[selectedFlightIndex] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FlightRouteHeader(flight: flight)

                if trip.flights.count > 1 {
                    legPicker
                }

                flightPlanSection
                timelineSection
                aircraftSection
                if !flight.mealService.isEmpty { mealSection }
                detailsGrid
                baggageSection
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(JALTheme.mist.ignoresSafeArea())
        .navigationTitle("Flight plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(JALTheme.ink)
                }
            }
        }
        .sheet(isPresented: $showBoardingPass) {
            BoardingPassView(pass: MockData.boardingPass)
        }
    }

    private var legPicker: some View {
        HStack(spacing: 8) {
            ForEach(Array(trip.flights.enumerated()), id: \.offset) { idx, f in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedFlightIndex = idx
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(f.origin.code) → \(f.destination.code)")
                            .font(.jal(13, .semibold))
                        Text(f.scheduledDeparture
                                .formatted(in: f.origin.timezone, "MMM d"))
                            .font(.jal(11))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .foregroundStyle(selectedFlightIndex == idx ? .white : JALTheme.ink)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selectedFlightIndex == idx ? JALTheme.crane : JALTheme.card)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Plan summary

    private var flightPlanSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Flight plan")
                Spacer()
                Pill(text: "On-time \(Int(flight.onTimeProbability * 100))%",
                     icon: "chart.line.uptrend.xyaxis",
                     tint: JALTheme.success)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEPART")
                        .font(.jal(10, .semibold)).tracking(1.0)
                        .foregroundStyle(JALTheme.inkSoft)
                    Text(flight.scheduledDeparture
                            .formatted(in: flight.origin.timezone, "HH:mm"))
                        .font(.jalMono(26, .bold))
                        .foregroundStyle(JALTheme.ink)
                    Text(flight.scheduledDeparture
                            .formatted(in: flight.origin.timezone, "EEE, MMM d"))
                        .font(.jal(12)).foregroundStyle(JALTheme.inkSoft)
                    Text("\(flight.origin.name) · Terminal \(flight.terminal ?? "—")")
                        .font(.jal(12, .medium))
                        .foregroundStyle(JALTheme.ink)
                        .padding(.top, 2)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("\(flight.durationMinutes / 60)h \(flight.durationMinutes % 60)m")
                        .font(.jal(12, .semibold))
                        .foregroundStyle(JALTheme.inkSoft)
                    Image(systemName: "airplane")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(JALTheme.crane)
                    Text("\(flight.distanceKm.formatted()) km")
                        .font(.jal(11)).foregroundStyle(JALTheme.inkSoft)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("ARRIVE")
                        .font(.jal(10, .semibold)).tracking(1.0)
                        .foregroundStyle(JALTheme.inkSoft)
                    Text(flight.scheduledArrival
                            .formatted(in: flight.destination.timezone, "HH:mm"))
                        .font(.jalMono(26, .bold))
                        .foregroundStyle(JALTheme.ink)
                    Text(flight.scheduledArrival
                            .formatted(in: flight.destination.timezone, "EEE, MMM d"))
                        .font(.jal(12)).foregroundStyle(JALTheme.inkSoft)
                    Text(flight.destination.name)
                        .font(.jal(12, .medium))
                        .foregroundStyle(JALTheme.ink)
                        .padding(.top, 2)
                }
            }
        }
        .jalCard()
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Your day")

            VStack(alignment: .leading, spacing: 0) {
                TimelineRow(icon: "figure.walk", time: "19:30",
                            title: "Leave home", sub: "Est. 45 min to Haneda T3")
                TimelineRow(icon: "checkmark.seal.fill", time: "20:15",
                            title: "Arrive at airport", sub: "Drop bags at JAL counter")
                TimelineRow(icon: "cup.and.saucer.fill", time: "20:45",
                            title: "Sakura Lounge", sub: "Champagne, sushi bar, showers",
                            highlight: true)
                TimelineRow(icon: "dot.radiowaves.left.and.right", time: "23:25",
                            title: "Boarding", sub: "Gate \(flight.gate ?? "—"), Group \(MockData.boardingPass.group)")
                TimelineRow(icon: "airplane.departure", time: "00:05",
                            title: "Departure", sub: "Pushback", highlight: true)
                TimelineRow(icon: "airplane.arrival", time: "17:25",
                            title: "Arrival in \(flight.destination.city)",
                            sub: "Local time",
                            isLast: true, highlight: true)
            }
        }
        .jalCard()
    }

    // MARK: - Aircraft

    private var aircraftSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Aircraft")
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(JALTheme.nightGradient)
                        .frame(width: 96, height: 96)
                    Image(systemName: "airplane")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-20))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(flight.aircraft)
                        .font(.jal(16, .bold))
                        .foregroundStyle(JALTheme.ink)
                    Text("Registration · \(flight.aircraftReg)")
                        .font(.jal(12)).foregroundStyle(JALTheme.inkSoft)
                    HStack(spacing: 6) {
                        Pill(text: flight.cabin, icon: "sparkles", tint: JALTheme.gold)
                    }
                    .padding(.top, 2)
                }
                Spacer()
            }
        }
        .jalCard()
    }

    // MARK: - Meal

    private var mealSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Onboard dining")
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(flight.mealService.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "fork.knife.circle.fill")
                            .foregroundStyle(JALTheme.crane)
                        Text(item)
                            .font(.jal(13))
                            .foregroundStyle(JALTheme.ink)
                    }
                }
            }
            HStack(spacing: 8) {
                Pill(text: "\(flight.entertainmentHours) hrs Magic",
                     icon: "play.rectangle.fill", tint: JALTheme.ink)
                Pill(text: "Wi-Fi onboard", icon: "wifi", tint: JALTheme.ink)
            }
        }
        .jalCard()
    }

    // MARK: - Details grid

    private var detailsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Details")
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 16) {
                StatBlock(value: "Seat \(flight.seat)", label: "Your seat",
                          sub: flight.cabin)
                StatBlock(value: flight.gate ?? "—", label: "Gate",
                          sub: "Terminal \(flight.terminal ?? "—")")
                StatBlock(value: flight.number, label: "Flight")
                StatBlock(value: trip.confirmationCode, label: "Confirmation")
            }
        }
        .jalCard()
    }

    // MARK: - Baggage

    private var baggageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Baggage")
            HStack(spacing: 14) {
                baggageChip(icon: "suitcase.fill", title: "2 × 32kg",
                            sub: "Checked (Business)")
                baggageChip(icon: "bag.fill", title: "2 × 10kg",
                            sub: "Cabin")
            }
            if let claim = flight.baggageClaim {
                Text("Baggage claim \(claim)")
                    .font(.jal(12, .semibold))
                    .foregroundStyle(JALTheme.success)
            }
        }
        .jalCard()
    }

    private func baggageChip(icon: String, title: String, sub: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JALTheme.crane)
                .frame(width: 40, height: 40)
                .background(JALTheme.craneSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.jal(14, .semibold))
                    .foregroundStyle(JALTheme.ink)
                Text(sub)
                    .font(.jal(11))
                    .foregroundStyle(JALTheme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(JALTheme.mist)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "View boarding pass", icon: "qrcode") {
                showBoardingPass = true
            }
            HStack(spacing: 10) {
                secondary("Change seat", icon: "chair.fill")
                secondary("Add bags", icon: "suitcase.fill")
            }
        }
    }

    private func secondary(_ title: String, icon: String) -> some View {
        Button {} label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title).font(.jal(14, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(JALTheme.ink)
            .background(JALTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(JALTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timeline row

private struct TimelineRow: View {
    let icon: String
    let time: String
    let title: String
    let sub: String
    var isLast: Bool = false
    var highlight: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(highlight ? JALTheme.crane : JALTheme.mist)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(highlight ? .white : JALTheme.ink)
                }
                if !isLast {
                    Rectangle()
                        .fill(JALTheme.line)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title)
                        .font(.jal(14, .semibold))
                        .foregroundStyle(JALTheme.ink)
                    Spacer()
                    Text(time)
                        .font(.jalMono(13, .semibold))
                        .foregroundStyle(JALTheme.inkSoft)
                }
                Text(sub)
                    .font(.jal(12))
                    .foregroundStyle(JALTheme.inkSoft)
            }
            .padding(.bottom, isLast ? 0 : 18)
        }
    }
}

#Preview {
    NavigationStack {
        TripDetailView(trip: MockData.trips[0])
    }
}
