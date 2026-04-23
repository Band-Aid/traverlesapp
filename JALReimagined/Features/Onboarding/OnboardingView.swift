import SwiftUI

/// First-run experience. Two steps:
///   1. Flight number — tracked through `FlightStatusStore`.
///   2. JMB profile — written to `JMBStore`, backs the Profile tab.
/// Both are independently skippable.
struct OnboardingView: View {
    @Environment(FlightStatusStore.self) private var flightStore
    @Environment(JMBStore.self) private var jmbStore

    enum Step: Hashable { case flight, jmb }

    @State private var step: Step = .flight

    // Flight step state
    @State private var flightInput: String = ""
    @FocusState private var flightFocused: Bool
    @State private var flightError: String?
    @State private var tracked: FlightLiveStatus?

    // JMB step state
    @State private var jmbName: String = ""
    @State private var jmbNumber: String = ""
    @State private var jmbTier: String = "Sapphire"
    @State private var jmbMiles: String = ""
    @State private var jmbFOP: String = ""
    @State private var jmbFlightsYTD: String = ""
    @FocusState private var jmbFocused: Field?
    enum Field: Hashable { case name, number, miles, fop, flightsYTD }

    @State private var showScan = false
    @State private var showLogin = false

    var onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                stepIndicator
                Group {
                    switch step {
                    case .flight: flightStepBody
                    case .jmb:    jmbStepBody
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                cta
                skipRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 48)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(background)
        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: step)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if step == .flight { flightFocused = true }
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [JALTheme.crane, JALTheme.craneDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            CraneMark(size: 44, tint: JALTheme.crane, background: .white)
            Text(step == .flight ? "Welcome aboard." : "One more thing.")
                .font(.jal(30, .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(step == .flight
                 ? "Add your flight to start tracking. We'll keep the gate, terminal, and countdown live — even offline."
                 : "Your JAL Mileage Bank lives here. Add it once and we'll track miles, tier progress, and FOP every flight.")
                .font(.jal(14))
                .foregroundStyle(.white.opacity(0.88))
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach([Step.flight, Step.jmb], id: \.self) { s in
                Capsule()
                    .fill(s == step ? .white : .white.opacity(0.25))
                    .frame(width: s == step ? 28 : 16, height: 4)
                    .animation(.easeInOut(duration: 0.25), value: step)
            }
            Spacer()
            Text(step == .flight ? "1 / 2" : "2 / 2")
                .font(.jalMono(11, .bold))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Step 1: Flight

    private var flightStepBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let tracked {
                confirmCard(tracked)
            } else {
                flightInputCard
            }
        }
    }

    private var flightInputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("FLIGHT NUMBER")
                .font(.jal(11, .heavy))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 10) {
                Image(systemName: "airplane")
                    .foregroundStyle(JALTheme.crane)
                TextField("e.g. JL2", text: $flightInput)
                    .font(.jal(20, .bold))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($flightFocused)
                    .submitLabel(.go)
                    .onSubmit(submitFlight)
                if !flightInput.isEmpty {
                    Button { flightInput = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(JALTheme.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white)
            )

            if let flightError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(flightError).lineLimit(2)
                }
                .font(.jal(12, .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.18))
                )
            }

            suggestionChips
        }
    }

    private var suggestionChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("POPULAR RIGHT NOW")
                .font(.jal(10, .heavy))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 6)
            FlowLayout(spacing: 8) {
                ForEach(["JL2", "JL5", "JL60", "JL505", "JL107"], id: \.self) { num in
                    Button {
                        flightInput = num
                        submitFlight()
                    } label: {
                        Text(num)
                            .font(.jalMono(13, .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Capsule().fill(.white.opacity(0.18)))
                            .overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func confirmCard(_ flight: FlightLiveStatus) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TRACKING")
                    .font(.jal(10, .heavy))
                    .tracking(1.4)
                    .foregroundStyle(JALTheme.inkSoft)
                Spacer()
                Text(flight.flightNumber)
                    .font(.jalMono(13, .bold))
                    .foregroundStyle(JALTheme.crane)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(flight.originIATA)
                    .font(.jal(40, .heavy))
                    .foregroundStyle(JALTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Image(systemName: "airplane")
                    .foregroundStyle(JALTheme.crane)
                Spacer()
                Text(flight.destinationIATA)
                    .font(.jal(40, .heavy))
                    .foregroundStyle(JALTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            HStack(spacing: 14) {
                labeled("GATE", flight.departureGate ?? "—")
                labeled("TERMINAL", flight.departureTerminal ?? "—")
                labeled("DEPARTS",
                        flight.scheduledDeparture.formatted(in: flight.originTimezone, "HH:mm"))
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white)
        )
    }

    private func labeled(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.jal(9, .heavy))
                .tracking(1.2)
                .foregroundStyle(JALTheme.inkSoft)
            Text(value)
                .font(.jalMono(16, .bold))
                .foregroundStyle(JALTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Step 2: JMB

    private var jmbStepBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            quickFillRow

            jmbField(title: "NAME ON CARD", text: $jmbName,
                     placeholder: "Daichi Yamashita",
                     autocap: .words, keyboard: .default, field: .name)

            jmbField(title: "JMB MEMBER NUMBER", text: $jmbNumber,
                     placeholder: "JL 1 003 4567",
                     autocap: .characters, keyboard: .numbersAndPunctuation, field: .number)

            tierPicker

            HStack(spacing: 10) {
                jmbField(title: "MILES", text: $jmbMiles,
                         placeholder: "184,320",
                         autocap: .never, keyboard: .numberPad, field: .miles)
                jmbField(title: "FLY ON PTS", text: $jmbFOP,
                         placeholder: "50,000",
                         autocap: .never, keyboard: .numberPad, field: .fop)
                jmbField(title: "FLIGHTS", text: $jmbFlightsYTD,
                         placeholder: "42",
                         autocap: .never, keyboard: .numberPad, field: .flightsYTD)
            }

            Text("Stored on-device only. You can edit this anytime from the JMB tab.")
                .font(.jal(11))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 4)
        }
    }

    private var quickFillRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK FILL")
                .font(.jal(10, .heavy))
                .tracking(1.3)
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 10) {
                quickFillButton(title: "Scan screenshot",
                                icon: "doc.viewfinder.fill") {
                    showScan = true
                }
                quickFillButton(title: "Sign in to JAL",
                                icon: "globe") {
                    showLogin = true
                }
            }
        }
        .sheet(isPresented: $showScan) {
            JMBScanSheet { draft in apply(draft) }
        }
        .sheet(isPresented: $showLogin) {
            JMBLoginSheet { draft in apply(draft) }
        }
    }

    private func quickFillButton(title: String,
                                 icon: String,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(JALTheme.crane)
                Text(title)
                    .font(.jal(12, .bold))
                    .foregroundStyle(JALTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white)
            )
        }
        .buttonStyle(.plain)
    }

    private func apply(_ draft: JMBDraft) {
        if let n = draft.name, !n.isEmpty { jmbName = n }
        if let num = draft.memberNumber, !num.isEmpty { jmbNumber = num }
        if let t = draft.tier, JMBProfile.tiers.contains(t) { jmbTier = t }
        if let m = draft.miles { jmbMiles = String(m) }
        if let p = draft.flyOnPoints { jmbFOP = String(p) }
        if let f = draft.flightsYTD { jmbFlightsYTD = String(f) }
    }

    private func jmbField(title: String,
                          text: Binding<String>,
                          placeholder: String,
                          autocap: TextInputAutocapitalization,
                          keyboard: UIKeyboardType,
                          field: Field) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.jal(10, .heavy))
                .tracking(1.3)
                .foregroundStyle(.white.opacity(0.7))
            TextField(placeholder, text: text)
                .font(.jal(16, .bold))
                .foregroundStyle(JALTheme.ink)
                .textInputAutocapitalization(autocap)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .focused($jmbFocused, equals: field)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white)
                )
        }
    }

    private var tierPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TIER")
                .font(.jal(10, .heavy))
                .tracking(1.3)
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 6) {
                ForEach(JMBProfile.tiers, id: \.self) { tier in
                    Button {
                        jmbTier = tier
                    } label: {
                        Text(tier)
                            .font(.jal(12, .bold))
                            .foregroundStyle(jmbTier == tier ? JALTheme.crane : .white)
                            .padding(.horizontal, 10).padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(jmbTier == tier ? .white : .white.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(.white.opacity(jmbTier == tier ? 0 : 0.3),
                                                  lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - CTA

    private var cta: some View {
        Button(action: primaryAction) {
            HStack(spacing: 10) {
                if flightStore.isLoading {
                    ProgressView().tint(JALTheme.crane)
                }
                Text(ctaTitle)
                    .font(.jal(16, .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundStyle(JALTheme.crane)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: JALTheme.ink.opacity(0.2), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(ctaDisabled)
        .opacity(ctaDisabled ? 0.5 : 1)
    }

    private var ctaTitle: String {
        switch step {
        case .flight: return tracked == nil ? "Track this flight" : "Next — add JMB"
        case .jmb:    return "Save and continue"
        }
    }

    private var ctaDisabled: Bool {
        switch step {
        case .flight: return tracked == nil && (flightInput.isEmpty || flightStore.isLoading)
        case .jmb:    return jmbName.isEmpty && jmbNumber.isEmpty && jmbMiles.isEmpty && jmbFOP.isEmpty
        }
    }

    private var skipRow: some View {
        HStack {
            Spacer()
            Button(skipTitle) { skip() }
                .font(.jal(13, .semibold))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
        .padding(.top, 4)
    }

    private var skipTitle: String {
        switch step {
        case .flight: return "Skip for now"
        case .jmb:    return "I'll add this later"
        }
    }

    // MARK: - Actions

    private func primaryAction() {
        switch step {
        case .flight:
            if tracked != nil {
                advanceToJMB()
            } else {
                submitFlight()
            }
        case .jmb:
            saveJMB()
            onComplete()
        }
    }

    private func skip() {
        switch step {
        case .flight: advanceToJMB()
        case .jmb:    onComplete()
        }
    }

    private func advanceToJMB() {
        flightFocused = false
        withAnimation { step = .jmb }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            jmbFocused = .name
        }
    }

    private func submitFlight() {
        flightError = nil
        flightFocused = false
        let query = flightInput
        Task {
            await flightStore.lookup(query)
            if let found = flightStore.current {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    tracked = found
                }
            } else if let err = flightStore.lastError {
                flightError = err
            }
        }
    }

    private func saveJMB() {
        let trimmedName = jmbName.trimmingCharacters(in: .whitespaces)
        let trimmedNumber = jmbNumber.trimmingCharacters(in: .whitespaces)
        let miles = Int(jmbMiles.filter(\.isNumber)) ?? 0
        let fop = Int(jmbFOP.filter(\.isNumber))
        let flights = Int(jmbFlightsYTD.filter(\.isNumber)) ?? 0
        // If the user typed nothing useful, don't persist a ghost record.
        guard !(trimmedName.isEmpty && trimmedNumber.isEmpty && miles == 0 && (fop ?? 0) == 0) else { return }

        let profile = JMBProfile(
            name: trimmedName.isEmpty ? "JAL Member" : trimmedName,
            memberNumber: trimmedNumber.isEmpty ? "JL — — ————" : trimmedNumber,
            tier: "JMB \(jmbTier)",
            miles: miles,
            flyOnPoints: fop,
            flightsYTD: flights,
            segmentsYTD: flights,
            nextTier: nil,
            milesToNextTier: nil
        )
        jmbStore.save(profile)
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environment(FlightStatusStore(service: MockFlightStatusService()))
        .environment(JMBStore())
}
