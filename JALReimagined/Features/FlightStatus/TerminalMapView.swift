import SwiftUI
import MapKit
import CoreLocation

/// Zooms Apple Maps to the origin airport. At HND/NRT/SFO/LAX and several
/// others, Apple Maps will render the indoor terminal automatically when the
/// user zooms in. The user's blue dot appears when location permission is
/// granted.
struct TerminalMapView: View {
    let status: FlightLiveStatus
    @StateObject private var location = LocationProvider()
    @State private var camera: MapCameraPosition
    @Environment(\.dismiss) private var dismiss

    init(status: FlightLiveStatus) {
        self.status = status
        let coord = CLLocationCoordinate2D(latitude: status.originLat,
                                           longitude: status.originLon)
        _camera = State(initialValue: .region(
            MKCoordinateRegion(center: coord,
                               span: MKCoordinateSpan(latitudeDelta: 0.012,
                                                      longitudeDelta: 0.012))
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $camera) {
                UserAnnotation()
                Annotation(status.originIATA, coordinate: airportCoord) {
                    VStack(spacing: 2) {
                        Image(systemName: "airplane.departure")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Circle().fill(JALTheme.crane))
                        Text("Gate \(status.departureGate ?? "—")")
                            .font(.jalMono(11, .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(JALTheme.ink))
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .bottom)

            overlay
        }
        .navigationTitle("\(status.originIATA) · Terminal \(status.departureTerminal ?? "—")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }.fontWeight(.semibold)
            }
        }
        .onAppear { location.request() }
    }

    private var airportCoord: CLLocationCoordinate2D {
        .init(latitude: status.originLat, longitude: status.originLon)
    }

    @ViewBuilder
    private var overlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            if location.authorizationDenied {
                HStack(spacing: 10) {
                    Image(systemName: "location.slash.fill")
                        .foregroundStyle(JALTheme.warning)
                    Text("Enable location in Settings to see where you are in the terminal.")
                        .font(.jal(12, .medium))
                        .foregroundStyle(JALTheme.ink)
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white)
                )
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gate \(status.departureGate ?? "—")")
                        .font(.jal(22, .heavy))
                        .foregroundStyle(JALTheme.ink)
                    Text("\(status.flightNumber) · \(status.destinationIATA)")
                        .font(.jal(12))
                        .foregroundStyle(JALTheme.inkSoft)
                }
                Spacer()
                Button {
                    UberLink.open(to: status)
                } label: {
                    Label("Uber", systemImage: "car.fill")
                        .font(.jal(13, .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Capsule().fill(.black))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Location provider

@MainActor
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationDenied = false
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            authorizationDenied = true
        default:
            authorizationDenied = false
            manager.startUpdatingLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .denied, .restricted: self.authorizationDenied = true
            case .authorizedAlways, .authorizedWhenInUse:
                self.authorizationDenied = false
                manager.startUpdatingLocation()
            default: break
            }
        }
    }
}
