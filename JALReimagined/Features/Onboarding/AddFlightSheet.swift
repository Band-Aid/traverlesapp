import SwiftUI

/// Modal for adding another flight after onboarding. Shares the same track
/// logic but fits inside a sheet instead of taking over the whole screen.
struct AddFlightSheet: View {
    @Environment(FlightStatusStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var input: String = ""
    @FocusState private var focused: Bool
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Track a flight")
                        .font(.jal(24, .bold))
                        .foregroundStyle(JALTheme.ink)
                    Text("Enter a flight number — we'll cache the gate, terminal, and status so it works offline.")
                        .font(.jal(13))
                        .foregroundStyle(JALTheme.inkSoft)
                }

                HStack(spacing: 10) {
                    Image(systemName: "airplane")
                        .foregroundStyle(JALTheme.crane)
                    TextField("e.g. JL2", text: $input)
                        .font(.jal(18, .semibold))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .submitLabel(.go)
                        .onSubmit(submit)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(JALTheme.mist)
                )

                if let errorText {
                    Text(errorText)
                        .font(.jal(12, .semibold))
                        .foregroundStyle(JALTheme.warning)
                }

                PrimaryButton(title: "Track", icon: "plus.circle.fill") {
                    submit()
                }
                .disabled(input.isEmpty || store.isLoading)
                .opacity(input.isEmpty ? 0.5 : 1)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Add flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { focused = true }
        }
    }

    private func submit() {
        errorText = nil
        focused = false
        let query = input
        Task {
            await store.lookup(query)
            if store.current?.flightNumber ==
                FlightNumberParser.normalize(query) {
                dismiss()
            } else if let err = store.lastError {
                errorText = err
            }
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        AddFlightSheet()
            .environment(FlightStatusStore(service: MockFlightStatusService()))
    }
}
