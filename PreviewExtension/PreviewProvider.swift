import ImageIO
import QuickLookUI
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    /// Upper bound for the initial preview window size in points.
    private let maxContentSize: CGFloat = 1600

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let jpeg = try VWXPreview.jpegData(from: request.fileURL)

        var size = CGSize(width: 800, height: 600)
        if let source = CGImageSourceCreateWithData(jpeg as CFData, nil),
           let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let w = props[kCGImagePropertyPixelWidth] as? CGFloat,
           let h = props[kCGImagePropertyPixelHeight] as? CGFloat, w > 0, h > 0 {
            let factor = min(1, maxContentSize / max(w, h))
            size = CGSize(width: w * factor, height: h * factor)
        }

        return QLPreviewReply(dataOfContentType: .jpeg, contentSize: size) { _ in jpeg }
    }
}
