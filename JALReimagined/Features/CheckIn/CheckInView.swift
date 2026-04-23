import SwiftUI

struct CheckInView: View {
    @State private var step: Int = 0
    @State private var showPass = false
    private let flight = MockData.nextFlight

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard
                    stepsCard
                    documentsCard
                    PrimaryButton(title: step >= 3 ? "View boarding pass" : "Complete check-in",
                                  icon: step >= 3 ? "qrcode" : "checkmark.circle.fill") {
                        if step >= 3 {
                            showPass = true
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                step = min(step + 1, 3)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(JALTheme.mist.ignoresSafeArea())
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPass) {
                BoardingPassView(pass: MockData.boardingPass)
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Pill(text: "Check-in open",
                     icon: "checkmark.circle.fill",
                     tint: JALTheme.success, filled: true)
                Spacer()
                Text("Closes in 22h 40m")
                    .font(.jal(12, .semibold))
                    .foregroundStyle(JALTheme.inkSoft)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(flight.origin.code) → \(flight.destination.code)")
                    .font(.jal(28, .heavy))
                    .foregroundStyle(JALTheme.ink)
                Spacer()
                Text(flight.number)
                    .font(.jalMono(14, .semibold))
                    .foregroundStyle(JALTheme.inkSoft)
            }
            Text(flight.scheduledDeparture
                    .formatted(in: flight.origin.timezone, "EEE, MMM d · HH:mm"))
                .font(.jal(13))
                .foregroundStyle(JALTheme.inkSoft)
        }
        .jalCard()
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Your check-in")
            stepRow(index: 0, icon: "person.text.rectangle.fill",
                    title: "Confirm identity",
                    sub: "Passport ending •••7891")
            stepRow(index: 1, icon: "chair.fill",
                    title: "Seat 7K selected",
                    sub: "SKY SUITE · Window")
            stepRow(index: 2, icon: "suitcase.fill",
                    title: "2 bags checked",
                    sub: "Business allowance · 64 kg total")
            stepRow(index: 3, icon: "qrcode",
                    title: "Boarding pass",
                    sub: step >= 3 ? "Ready" : "Almost there", isLast: true)
        }
        .jalCard()
    }

    private func stepRow(index: Int, icon: String, title: String, sub: String,
                         isLast: Bool = false) -> some View {
        let done = step > index
        let current = step == index
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(done ? JALTheme.success : (current ? JALTheme.crane : JALTheme.mist))
                        .frame(width: 36, height: 36)
                    Image(systemName: done ? "checkmark" : icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(done || current ? .white : JALTheme.inkSoft)
                }
                if !isLast {
                    Rectangle().fill(JALTheme.line).frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.jal(14, .semibold))
                    .foregroundStyle(JALTheme.ink)
                Text(sub)
                    .font(.jal(12))
                    .foregroundStyle(JALTheme.inkSoft)
            }
            Spacer()
        }
        .padding(.bottom, isLast ? 0 : 16)
    }

    private var documentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Travel documents")
            HStack(spacing: 12) {
                docChip(icon: "checkmark.seal.fill", title: "Passport", sub: "Verified", ok: true)
                docChip(icon: "globe.americas.fill", title: "ESTA", sub: "Valid until 2027", ok: true)
            }
        }
        .jalCard()
    }

    private func docChip(icon: String, title: String, sub: String, ok: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ok ? JALTheme.success : JALTheme.warning)
                .frame(width: 40, height: 40)
                .background(
                    (ok ? JALTheme.success : JALTheme.warning).opacity(0.12)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.jal(14, .semibold)).foregroundStyle(JALTheme.ink)
                Text(sub).font(.jal(11)).foregroundStyle(JALTheme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(JALTheme.mist)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview { CheckInView() }
