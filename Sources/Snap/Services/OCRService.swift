import Foundation
import CoreGraphics
import Vision

/// OCR 服务。基于 Apple Vision Framework。
/// 完全本地,无任何网络请求。
final class OCRService {

    enum OCRError: Error {
        case emptyImage
        case visionFailed(String)
    }

    struct Result: Sendable {
        let text: String
        let blocks: [TextBlock]
        let language: String?
    }

    struct TextBlock: Sendable {
        let text: String
        let bbox: CGRect          // 归一化坐标 (0...1)
        let confidence: Float
    }

    /// 默认识别中英文,准确优先。
    var recognitionLanguages: [String] = ["zh-Hans", "zh-Hant", "en-US"]
    var recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    var usesLanguageCorrection = true

    /// 识别图像中的所有文字 — W4 任务。
    func recognize(image: CGImage) async throws -> Result {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Result, Error>) in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    cont.resume(throwing: OCRError.visionFailed(error.localizedDescription))
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    cont.resume(returning: Result(text: "", blocks: [], language: nil))
                    return
                }

                var fullText = ""
                var blocks: [TextBlock] = []
                for obs in observations {
                    guard let candidate = obs.topCandidates(1).first else { continue }
                    fullText += candidate.string + "\n"
                    blocks.append(TextBlock(
                        text: candidate.string,
                        bbox: obs.boundingBox,
                        confidence: candidate.confidence
                    ))
                }
                cont.resume(returning: Result(
                    text: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
                    blocks: blocks,
                    language: nil
                ))
            }
            request.recognitionLevel = self.recognitionLevel
            request.recognitionLanguages = self.recognitionLanguages
            request.usesLanguageCorrection = self.usesLanguageCorrection

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                cont.resume(throwing: OCRError.visionFailed(error.localizedDescription))
            }
        }
    }
}
