import SwiftUI

struct ProfileView: View {
    @Environment(JMBStore.self) private var jmbStore
    @State private var showEditor = false

    private var profile: JMBProfile {
        jmbStore.profile ?? MockData.profile
    }

    private var isPlaceholder: Bool { jmbStore.profile == nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isPlaceholder { demoBanner }
                    memberCard
                    statsGrid
                    actionsCard
                    historyCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(JALTheme.mist.ignoresSafeArea())
            .navigationTitle("JMB")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEditor = true } label: {
                        Image(systemName: isPlaceholder ? "plus.circle.fill" : "pencil.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(JALTheme.ink)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                JMBEditorSheet(initial: jmbStore.profile) { updated in
                    jmbStore.save(updated)
                }
            }
        }
    }

    private var demoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(JALTheme.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Demo data")
                    .font(.jal(13, .bold))
                    .foregroundStyle(JALTheme.ink)
                Text("Tap the + above to enter your real JMB.")
                    .font(.jal(11))
                    .foregroundStyle(JALTheme.inkSoft)
            }
            Spacer()
            Button("Add") { showEditor = true }
                .font(.jal(12, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(JALTheme.crane))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(JALTheme.gold.opacity(0.4), lineWidth: 1)
        )
    }

    private var memberCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                CraneMark(size: 40, tint: JALTheme.crane, background: .white)
                Spacer()
                Text(profile.tier.uppercased())
                    .font(.jal(11, .heavy))
                    .tracking(1.6)
                    .foregroundStyle(JALTheme.gold)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().stroke(JALTheme.gold, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.jal(22, .bold))
                    .foregroundStyle(.white)
                Text(profile.memberNumber)
                    .font(.jalMono(13))
                    .foregroundStyle(.white.opacity(0.75))
                    .tracking(1.0)
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AVAILABLE MILES")
                        .font(.jal(10, .heavy))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(profile.miles.formatted())
                        .font(.jal(36, .heavy))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
                Spacer()
                Image(systemName: "bird.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.1))
                    .rotationEffect(.degrees(-12))
            }
            if let remaining = profile.fopToNextTier, remaining > 0,
               let nextTier = profile.nextTierUp {
                nextTierProgress(remaining: remaining, nextTier: nextTier)
            }
        }
        .padding(22)
        .background(
            ZStack {
                JALTheme.nightGradient
                LinearGradient(colors: [JALTheme.gold.opacity(0.25), .clear],
                               startPoint: .topTrailing, endPoint: .bottomLeading)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(JALTheme.gold.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: JALTheme.ink.opacity(0.25), radius: 22, x: 0, y: 12)
    }

    private func nextTierProgress(remaining: Int, nextTier: String) -> some View {
        let current = profile.flyOnPoints ?? 0
        let threshold = current + remaining
        let fraction = threshold > 0 ? min(1, max(0.05, Double(current) / Double(threshold))) : 0
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TO \(nextTier.uppercased())")
                    .font(.jal(9, .heavy))
                    .tracking(1.3)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("\(remaining.formatted()) FOP to go")
                    .font(.jalMono(11, .bold))
                    .foregroundStyle(JALTheme.gold)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.15))
                    Capsule().fill(JALTheme.gold)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
        }
        .padding(.top, 4)
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "This year")
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 12) {
                StatBlock(value: "\(profile.flightsYTD)", label: "Flights")
                StatBlock(value: "\(profile.segmentsYTD)", label: "Segments")
                StatBlock(value: fopStatValue, label: "FLY ON pts")
            }
        }
        .jalCard()
    }

    private var fopStatValue: String {
        guard let fop = profile.flyOnPoints, fop > 0 else { return "—" }
        if fop >= 10_000 {
            return "\(fop / 1000)K"
        }
        return fop.formatted()
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {
            actionRow(icon: "ticket.fill", title: "Use miles",
                      sub: "Award tickets, upgrades, shopping")
            Divider().background(JALTheme.line)
            actionRow(icon: "creditcard.fill", title: "JAL Card",
                      sub: "Earn 2× miles on every flight")
            Divider().background(JALTheme.line)
            actionRow(icon: "star.fill", title: "Status benefits",
                      sub: "oneworld Emerald · priority everything")
            Divider().background(JALTheme.line)
            actionRow(icon: "building.columns.fill", title: "Partners",
                      sub: "Book with American, BA, Qatar, Qantas")
        }
        .jalCard(padding: 0)
    }

    private func actionRow(icon: String, title: String, sub: String) -> some View {
        Button {} label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JALTheme.crane)
                    .frame(width: 36, height: 36)
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
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(JALTheme.inkSoft)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recent activity", action: "See all")
            historyRow(date: "Feb 16", route: "JFK → HND", miles: "+ 6,761 mi")
            Divider().background(JALTheme.line)
            historyRow(date: "Feb 08", route: "HND → JFK", miles: "+ 6,761 mi")
            Divider().background(JALTheme.line)
            historyRow(date: "Jan 22", route: "HND → CTS", miles: "+   821 mi")
        }
        .jalCard()
    }

    private func historyRow(date: String, route: String, miles: String) -> some View {
        HStack {
            Text(date)
                .font(.jal(12, .semibold))
                .foregroundStyle(JALTheme.inkSoft)
                .frame(width: 52, alignment: .leading)
            Text(route)
                .font(.jal(14, .semibold))
                .foregroundStyle(JALTheme.ink)
            Spacer()
            Text(miles)
                .font(.jalMono(12, .semibold))
                .foregroundStyle(JALTheme.crane)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Editor sheet

private struct JMBEditorSheet: View {
    let initial: JMBProfile?
    let onSave: (JMBProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var number: String = ""
    @State private var tier: String = "Sapphire"
    @State private var miles: String = ""
    @State private var flyOnPoints: String = ""
    @State private var flightsYTD: String = ""

    @State private var showScan = false
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showScan = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scan screenshot").font(.jal(14, .bold))
                                Text("Pick a JMB dashboard image, we'll read it on-device")
                                    .font(.jal(11))
                                    .foregroundStyle(JALTheme.inkSoft)
                            }
                        } icon: {
                            Image(systemName: "doc.viewfinder.fill")
                                .foregroundStyle(JALTheme.crane)
                        }
                    }
                    Button {
                        showLogin = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sign in to JAL").font(.jal(14, .bold))
                                Text("Log into jal.co.jp in-app and pull your data")
                                    .font(.jal(11))
                                    .foregroundStyle(JALTheme.inkSoft)
                            }
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(JALTheme.crane)
                        }
                    }
                } header: {
                    Text("Quick fill")
                } footer: {
                    Text("Both paths only touch your device — nothing is sent to us.")
                }

                Section("Card holder") {
                    TextField("Name on card", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Member number", text: $number)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                Section("Status") {
                    Picker("Tier", selection: $tier) {
                        ForEach(JMBProfile.tiers, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                }
                Section {
                    TextField("Lifetime miles", text: $miles)
                        .keyboardType(.numberPad)
                    TextField("FLY ON Points (this year)", text: $flyOnPoints)
                        .keyboardType(.numberPad)
                    TextField("Flights YTD", text: $flightsYTD)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Balances")
                } footer: {
                    Text("FLY ON Points reset each January and drive your tier. Lifetime miles are your redeemable balance.")
                }
            }
            .sheet(isPresented: $showScan) {
                JMBScanSheet { draft in apply(draft) }
            }
            .sheet(isPresented: $showLogin) {
                JMBLoginSheet { draft in apply(draft) }
            }
            .navigationTitle(initial == nil ? "Add JMB" : "Edit JMB")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private func prefill() {
        guard let initial else { return }
        name = initial.name
        number = initial.memberNumber
        tier = initial.bareTier
        miles = String(initial.miles)
        flyOnPoints = initial.flyOnPoints.map(String.init) ?? ""
        flightsYTD = String(initial.flightsYTD)
    }

    private func apply(_ draft: JMBDraft) {
        if let n = draft.name, !n.isEmpty { name = n }
        if let num = draft.memberNumber, !num.isEmpty { number = num }
        if let t = draft.tier, JMBProfile.tiers.contains(t) { tier = t }
        if let m = draft.miles { miles = String(m) }
        if let p = draft.flyOnPoints { flyOnPoints = String(p) }
        if let f = draft.flightsYTD { flightsYTD = String(f) }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedNumber = number.trimmingCharacters(in: .whitespaces)
        let milesInt = Int(miles.filter(\.isNumber)) ?? 0
        let fopInt = Int(flyOnPoints.filter(\.isNumber))
        let flightsInt = Int(flightsYTD.filter(\.isNumber)) ?? 0
        let profile = JMBProfile(
            name: trimmedName.isEmpty ? "JAL Member" : trimmedName,
            memberNumber: trimmedNumber.isEmpty ? "JL — — ————" : trimmedNumber,
            tier: "JMB \(tier)",
            miles: milesInt,
            flyOnPoints: fopInt,
            flightsYTD: flightsInt,
            segmentsYTD: flightsInt,
            nextTier: nil,
            milesToNextTier: nil
        )
        onSave(profile)
        dismiss()
    }
}

#Preview {
    ProfileView()
        .environment(JMBStore())
}
