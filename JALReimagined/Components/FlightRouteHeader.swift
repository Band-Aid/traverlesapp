import SwiftUI

/// The signature header — big airport codes, plane between them, gradient sky.
struct FlightRouteHeader: View {
    let flight: Flight
    var compact: Bool = false

    @State private var planeOffset: CGFloat = -1

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.origin.code)
                        .font(.jal(compact ? 36 : 56, .heavy))
                        .foregroundStyle(.white)
                        .kerning(-1)
                    Text(flight.origin.city)
                        .font(.jal(compact ? 12 : 14, .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(flight.destination.code)
                        .font(.jal(compact ? 36 : 56, .heavy))
                        .foregroundStyle(.white)
                        .kerning(-1)
                    Text(flight.destination.city)
                        .font(.jal(compact ? 12 : 14, .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            // Path with plane
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Path { p in
                        let y = geo.size.height / 2
                        p.move(to: .init(x: 0, y: y))
                        p.addLine(to: .init(x: geo.size.width, y: y))
                    }
                    .stroke(.white.opacity(0.45),
                            style: .init(lineWidth: 1.5, dash: [3, 4]))

                    Circle().fill(.white).frame(width: 8, height: 8)
                    Circle().fill(.white).frame(width: 8, height: 8)
                        .offset(x: geo.size.width - 8)

                    Image(systemName: "airplane")
                        .font(.system(size: compact ? 18 : 22, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: max(0, (geo.size.width - 24) * planeProgress))
                }
            }
            .frame(height: compact ? 22 : 28)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).delay(0.1)) {
                    planeOffset = 1
                }
            }

            HStack(spacing: 16) {
                Label(flight.number, systemImage: "barcode")
                Label("\(flight.distanceKm.formatted()) km", systemImage: "map")
                Label("\(flight.durationMinutes / 60)h \(flight.durationMinutes % 60)m",
                      systemImage: "clock")
            }
            .font(.jal(12, .semibold))
            .foregroundStyle(.white.opacity(0.92))
        }
        .padding(compact ? 18 : 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                JALTheme.dawnGradient
                // crane silhouette wash
                Image(systemName: "bird.fill")
                    .resizable().scaledToFit()
                    .foregroundStyle(.white.opacity(0.06))
                    .frame(width: 220)
                    .rotationEffect(.degrees(-12))
                    .offset(x: 90, y: -10)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: JALTheme.crane.opacity(0.2), radius: 22, x: 0, y: 12)
    }

    private var planeProgress: CGFloat {
        // animate from 0 → 1
        planeOffset < 0 ? 0 : 1
    }
}

#Preview {
    FlightRouteHeader(flight: MockData.nextFlight)
        .padding()
        .background(JALTheme.mist)
}
