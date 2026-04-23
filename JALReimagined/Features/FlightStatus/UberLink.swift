import Foundation
import UIKit

/// Deep-links into Uber with the destination airport pre-filled. Falls back
/// to Uber's universal link if the app isn't installed.
enum UberLink {
    static func open(to status: FlightLiveStatus) {
        let lat = status.originLat
        let lon = status.originLon
        let label = "\(status.originIATA) · Terminal \(status.departureTerminal ?? "")"
        let encoded = label.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed) ?? label

        let native = "uber://?action=setPickup&pickup=my_location" +
            "&dropoff[latitude]=\(lat)&dropoff[longitude]=\(lon)" +
            "&dropoff[formatted_address]=\(encoded)"
        let universal = "https://m.uber.com/ul/?action=setPickup&pickup=my_location" +
            "&dropoff[latitude]=\(lat)&dropoff[longitude]=\(lon)" +
            "&dropoff[formatted_address]=\(encoded)"

        if let url = URL(string: native), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: universal) {
            UIApplication.shared.open(url)
        }
    }
}
