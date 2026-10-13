import ImageIO
import QuickLookThumbnailing

final class ThumbnailProvider: QLThumbnailProvider {

    override func provideThumbnail(for request: QLFileThumbnailRequest,
                                   _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        do {
            let jpeg = try VWXPreview.jpegData(from: request.fileURL)
            let maxSize = request.maximumSize
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: max(maxSize.width, maxSize.height) * request.scale,
            ]
            guard let source = CGImageSourceCreateWithData(jpeg as CFData, nil),
                  let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
            else { throw VWXPreview.Failure.corrupt }

            let factor = min(maxSize.width / CGFloat(image.width), maxSize.height / CGFloat(image.height))
            let size = CGSize(width: CGFloat(image.width) * factor, height: CGFloat(image.height) * factor)

            handler(QLThumbnailReply(contextSize: size) { context in
                context.interpolationQuality = .high
                context.draw(image, in: CGRect(origin: .zero, size: size))
                return true
            }, nil)
        } catch {
            handler(nil, error)
        }
    }
}
