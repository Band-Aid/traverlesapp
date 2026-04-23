import SwiftUI
import CoreImage.CIFilterBuiltins

struct BoardingPassView: View {
    let pass: BoardingPass
    @Environment(\.dismiss) private var dismiss

    private var flight: Flight { pass.flight }

    var body: some View {
        ZStack {
            JALTheme.nightGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    card
                    addToWallet
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .toolbar { ToolbarItem(placement: .topBarLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
            }
        }}
    }

    private var header: some View {
        HStack {
            CraneMark(size: 28, tint: JALTheme.crane, background: .white)
            Text("BOARDING PASS")
                .font(.jal(12, .heavy))
                .tracking(2.0)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Text(flight.number)
                .font(.jalMono(14, .bold))
                .foregroundStyle(.white)
        }
        .padding(.top, 8)
    }

    private var card: some View {
        VStack(spacing: 0) {
            // Top: route
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flight.origin.city.uppercased())
                            .font(.jal(11, .semibold))
                            .foregroundStyle(JALTheme.inkSoft)
                            .tracking(1.0)
                        Text(flight.origin.code)
                            .font(.jal(48, .heavy))
                            .foregroundStyle(JALTheme.ink)
                            .kerning(-1)
                        Text(flight.scheduledDeparture
                                .formatted(in: flight.origin.timezone, "HH:mm"))
                            .font(.jalMono(18, .bold))
                            .foregroundStyle(JALTheme.crane)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "airplane")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(JALTheme.crane)
                            .padding(.top, 20)
                        Text(flight.scheduledDeparture
                                .formatted(in: flight.origin.timezone, "MMM d"))
                            .font(.jal(11, .semibold))
                            .foregroundStyle(JALTheme.inkSoft)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(flight.destination.city.uppercased())
                            .font(.jal(11, .semibold))
                            .foregroundStyle(JALTheme.inkSoft)
                            .tracking(1.0)
                        Text(flight.destination.code)
                            .font(.jal(48, .heavy))
                            .foregroundStyle(JALTheme.ink)
                            .kerning(-1)
                        Text(flight.scheduledArrival
                                .formatted(in: flight.destination.timezone, "HH:mm"))
                            .font(.jalMono(18, .bold))
                            .foregroundStyle(JALTheme.crane)
                    }
                }

                DashedDivider()

                // Passenger
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PASSENGER")
                            .font(.jal(9, .semibold))
                            .tracking(1.0)
                            .foregroundStyle(JALTheme.inkSoft)
                        Text(pass.passengerName)
                            .font(.jal(14, .bold))
                            .foregroundStyle(JALTheme.ink)
                    }
                    Spacer()
                    if let tsa = pass.tsa {
                        Text(tsa)
                            .font(.jal(11, .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(JALTheme.success))
                    }
                }

                // Data row
                HStack(alignment: .top, spacing: 0) {
                    dataCell("GATE", flight.gate ?? "—", big: true)
                    dataCell("SEAT", flight.seat, big: true)
                    dataCell("GROUP", pass.group)
                    dataCell("SEQ", pass.sequence)
                }

                HStack(alignment: .top, spacing: 0) {
                    dataCell("TERMINAL", flight.terminal ?? "—")
                    dataCell("CABIN", flight.bookingClass)
                    dataCell("BOARDING", flight.scheduledDeparture
                                .addingTimeInterval(-40 * 60)
                                .formatted(in: flight.origin.timezone, "HH:mm"))
                    dataCell("FF", pass.ffNumber ?? "—")
                }
            }
            .padding(22)
            .background(Color.white)

            // Perforation
            ZStack {
                Rectangle().fill(JALTheme.mist).frame(height: 22)
                HStack {
                    Circle().fill(JALTheme.nightGradient).frame(width: 22, height: 22)
                        .offset(x: -11)
                    Spacer()
                    Circle().fill(JALTheme.nightGradient).frame(width: 22, height: 22)
                        .offset(x: 11)
                }
                DashedDivider().padding(.horizontal, 20)
            }

            // QR
            VStack(spacing: 12) {
                QRCodeView(payload: pass.qrPayload)
                    .frame(width: 180, height: 180)
                Text(pass.qrPayload)
                    .font(.jalMono(9))
                    .foregroundStyle(JALTheme.inkSoft)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 30, x: 0, y: 18)
    }

    private func dataCell(_ label: String, _ value: String, big: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.jal(9, .semibold))
                .tracking(1.0)
                .foregroundStyle(JALTheme.inkSoft)
            Text(value)
                .font(big ? .jalMono(22, .bold) : .jalMono(14, .semibold))
                .foregroundStyle(JALTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addToWallet: some View {
        Button {} label: {
            HStack(spacing: 10) {
                Image(systemName: "wallet.pass.fill")
                Text("Add to Apple Wallet")
                    .font(.jal(15, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - QR

struct QRCodeView: View {
    let payload: String

    var body: some View {
        if let image = generate(payload: payload) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
        }
    }

    private func generate(payload: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cg = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

#Preview {
    BoardingPassView(pass: MockData.boardingPass)
}
