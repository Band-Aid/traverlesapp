import SwiftUI
import MapKit

/// Map view that accepts a `FlightLiveStatus` and draws the great-circle path.
struct LiveFlightMap: View {
    let status: FlightLiveStatus
    @State private var camera: MapCameraPosition

    init(status: FlightLiveStatus) {
        self.status = status
        let mid = CLLocationCoordinate2D(
            latitude:  (status.originLat + status.destinationLat) / 2,
            longitude: (status.originLon + status.destinationLon) / 2
        )
        let latDelta  = max(abs(status.originLat - status.destinationLat) * 1.8, 15)
        let lonDelta  = max(abs(status.originLon - status.destinationLon) * 1.8, 30)
        _camera = State(initialValue: .region(
            MKCoordinateRegion(center: mid,
                               span: MKCoordinateSpan(latitudeDelta: latDelta,
                                                      longitudeDelta: lonDelta))
        ))
    }

    var body: some View {
        Map(position: $camera) {
            Annotation(status.originIATA, coordinate: originCoord) {
                AirportDot(code: status.originIATA)
            }
            Annotation(status.destinationIATA, coordinate: destCoord) {
                AirportDot(code: status.destinationIATA)
            }
            if let progress = flightProgress, progress > 0.01, progress < 0.99 {
                let coord = greatCircle[min(greatCircle.count - 1,
                                            Int(Double(greatCircle.count) * progress))]
                Annotation("", coordinate: coord) {
                    Image(systemName: "airplane")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(JALTheme.crane)
                        .rotationEffect(.degrees(70))
                        .shadow(color: .black.opacity(0.3), radius: 4)
                }
            }
            MapPolyline(coordinates: greatCircle)
                .stroke(JALTheme.crane, style: .init(lineWidth: 2.5, dash: [6, 6]))
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    private var originCoord: CLLocationCoordinate2D {
        .init(latitude: status.originLat, longitude: status.originLon)
    }
    private var destCoord: CLLocationCoordinate2D {
        .init(latitude: status.destinationLat, longitude: status.destinationLon)
    }

    /// 0..1 completion of the flight, or nil if not yet departed / already landed.
    private var flightProgress: Double? {
        guard let actualDep = status.actualDeparture else { return nil }
        if status.actualArrival != nil { return 1 }
        let arr = status.estimatedArrival ?? status.scheduledArrival
        let total = arr.timeIntervalSince(actualDep)
        guard total > 0 else { return nil }
        let elapsed = Date().timeIntervalSince(actualDep)
        return max(0, min(1, elapsed / total))
    }

    private var greatCircle: [CLLocationCoordinate2D] {
        Self.greatCirclePoints(from: originCoord, to: destCoord, count: 64)
    }

    static func greatCirclePoints(from a: CLLocationCoordinate2D,
                                  to b: CLLocationCoordinate2D,
                                  count: Int) -> [CLLocationCoordinate2D] {
        let lat1 = a.latitude * .pi / 180
        let lon1 = a.longitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let lon2 = b.longitude * .pi / 180

        let d = 2 * asin(sqrt(pow(sin((lat1 - lat2) / 2), 2) +
                              cos(lat1) * cos(lat2) * pow(sin((lon1 - lon2) / 2), 2)))
        guard d > 0 else { return [a, b] }

        return (0...count).map { i in
            let f = Double(i) / Double(count)
            let A = sin((1 - f) * d) / sin(d)
            let B = sin(f * d) / sin(d)
            let x = A * cos(lat1) * cos(lon1) + B * cos(lat2) * cos(lon2)
            let y = A * cos(lat1) * sin(lon1) + B * cos(lat2) * sin(lon2)
            let z = A * sin(lat1) + B * sin(lat2)
            let lat = atan2(z, sqrt(x * x + y * y))
            let lon = atan2(y, x)
            return CLLocationCoordinate2D(latitude: lat * 180 / .pi,
                                          longitude: lon * 180 / .pi)
        }
    }
}

struct AirportDot: View {
    let code: String
    var body: some View {
        VStack(spacing: 2) {
            Text(code)
                .font(.jalMono(11, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Capsule().fill(JALTheme.ink))
            Circle().fill(JALTheme.crane).frame(width: 10, height: 10)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
        }
    }
}
