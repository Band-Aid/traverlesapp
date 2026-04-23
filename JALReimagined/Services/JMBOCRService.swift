import Foundation
import UIKit
import Vision

enum JMBOCRError: LocalizedError {
    case noImage
    case visionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noImage:           return "Couldn't read that image."
        case .visionFailed(let e): return "Scan failed: \(e.localizedDescription)"
        }
    }
}

/// On-device text recognition over a JMB dashboard screenshot. Returns the
/// raw text lines so the caller can feed them through `JMBTextParser`.
enum JMBOCRService {
    static func recognize(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { throw JMBOCRError.noImage }

        return try await withCheckedThrowingContinuation { cont in
            let request = VNRecognizeTextRequest { req, err in
                if let err {
                    cont.resume(throwing: JMBOCRError.visionFailed(err))
                    return
                }
                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                cont.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "ja-JP"]

            let handler = VNImageRequestHandler(cgImage: cgImage,
                                                orientation: image.cgImageOrientation,
                                                options: [:])
            do {
                try handler.perform([request])
            } catch {
                cont.resume(throwing: JMBOCRError.visionFailed(error))
            }
        }
    }
}

private extension UIImage {
    /// Vision needs the CG orientation hint when the UIImage came from the
    /// camera roll with non-identity imageOrientation, otherwise upside-down
    /// screenshots scan as garbage.
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:            return .up
        case .down:          return .down
        case .left:          return .left
        case .right:         return .right
        case .upMirrored:    return .upMirrored
        case .downMirrored:  return .downMirrored
        case .leftMirrored:  return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default:    return .up
        }
    }
}
