import Foundation

/// Reads the JPEG preview image that Vectorworks embeds in its documents.
///
/// File layout (all header integers big-endian):
///   0x00  Int32  size of uncompressed header block A
///   0x08  Int32  size of uncompressed header block B
///   0x36  Int16  file format version
///   0x58  Int32  logical offset of the preview record
///   0x5C  Int32  length of the preview record
///   0x91  UInt8  bit 0 = body is snappy-compressed (format version >= 0xB7)
///
/// A compressed body starts at A + B and consists of chunks, each a
/// little-endian UInt32 length followed by a raw snappy block. Logical offsets
/// continue across the decompressed chunks, starting at A + B.
///
/// The preview record is: UInt32 (LE) = 1, the tag "gepj", then JPEG data.
enum VWXPreview {

    enum Failure: Error {
        case notVectorworks
        case noPreview
        case corrupt
    }

    static let maxPreviewBytes = 64 << 20
    static let maxChunkBytes = 64 << 20

    static func jpegData(from url: URL) throws -> Data {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }

        guard let head = try file.read(upToCount: 0x92), head.count >= 0x60 else {
            throw Failure.notVectorworks
        }
        let h = [UInt8](head)
        let headerA = int32BE(h, 0x00)
        let headerB = int32BE(h, 0x08)
        let version = int16BE(h, 0x36)
        guard version >= 0x92, headerA > 0, headerB > 0 else { throw Failure.notVectorworks }

        let offset = int32BE(h, 0x58)
        let length = int32BE(h, 0x5C)
        let bodyStart = headerA + headerB
        guard offset > bodyStart, length > 8, length <= maxPreviewBytes else { throw Failure.noPreview }

        let compressed = version >= 0xB7 && h.count > 0x91 && (h[0x91] & 1) != 0

        let record: Data
        if compressed {
            record = try readCompressed(file, bodyStart: bodyStart, offset: offset, length: length)
        } else {
            try file.seek(toOffset: UInt64(offset))
            guard let d = try file.read(upToCount: length), d.count == length else { throw Failure.corrupt }
            record = d
        }

        let r = [UInt8](record.prefix(8))
        guard r.count == 8, r == [1, 0, 0, 0] + Array("gepj".utf8) else {
            throw Failure.noPreview
        }
        return record.dropFirst(8)
    }

    private static func readCompressed(_ file: FileHandle, bodyStart: Int, offset: Int, length: Int) throws -> Data {
        try file.seek(toOffset: UInt64(bodyStart))
        var position = bodyStart
        var record = Data(capacity: length)

        while record.count < length {
            guard let lenBytes = try file.read(upToCount: 4), lenBytes.count == 4 else { throw Failure.corrupt }
            let chunkLength = Int(UInt32(lenBytes[lenBytes.startIndex])
                | UInt32(lenBytes[lenBytes.startIndex + 1]) << 8
                | UInt32(lenBytes[lenBytes.startIndex + 2]) << 16
                | UInt32(lenBytes[lenBytes.startIndex + 3]) << 24)
            guard chunkLength > 0, chunkLength <= maxChunkBytes,
                  let compressed = try file.read(upToCount: chunkLength), compressed.count == chunkLength
            else { throw Failure.corrupt }

            let chunk = try Snappy.decompress(compressed)
            guard !chunk.isEmpty else { throw Failure.corrupt }

            if offset < position + chunk.count {
                let start = max(0, offset - position)
                let take = min(length - record.count, chunk.count - start)
                record.append(chunk[chunk.startIndex + start ..< chunk.startIndex + start + take])
            }
            position += chunk.count
        }
        return record
    }

    private static func int32BE(_ b: [UInt8], _ i: Int) -> Int {
        Int(Int32(bitPattern: UInt32(b[i]) << 24 | UInt32(b[i + 1]) << 16 | UInt32(b[i + 2]) << 8 | UInt32(b[i + 3])))
    }

    private static func int16BE(_ b: [UInt8], _ i: Int) -> Int {
        Int(Int16(bitPattern: UInt16(b[i]) << 8 | UInt16(b[i + 1])))
    }
}

/// Minimal decoder for the raw snappy block format
/// (https://github.com/google/snappy/blob/main/format_description.txt).
enum Snappy {

    static func decompress(_ input: Data) throws -> Data {
        try input.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> Data in
            let src = raw.bindMemory(to: UInt8.self)
            var p = 0

            var expected = 0
            var shift = 0
            while true {
                guard p < src.count, shift <= 28 else { throw VWXPreview.Failure.corrupt }
                let c = src[p]
                p += 1
                expected |= Int(c & 0x7F) << shift
                if c < 0x80 { break }
                shift += 7
            }
            guard expected <= VWXPreview.maxChunkBytes else { throw VWXPreview.Failure.corrupt }

            var out = [UInt8](repeating: 0, count: expected)
            var o = 0
            try out.withUnsafeMutableBufferPointer { dst in
                while p < src.count {
                    let tag = src[p]
                    p += 1

                    if tag & 3 == 0 {
                        var len = Int(tag >> 2)
                        if len >= 60 {
                            let n = len - 59
                            guard p + n <= src.count else { throw VWXPreview.Failure.corrupt }
                            len = 0
                            for i in 0..<n { len |= Int(src[p + i]) << (8 * i) }
                            p += n
                        }
                        len += 1
                        guard p + len <= src.count, o + len <= expected else { throw VWXPreview.Failure.corrupt }
                        for i in 0..<len { dst[o + i] = src[p + i] }
                        p += len
                        o += len
                        continue
                    }

                    let len: Int
                    let distance: Int
                    switch tag & 3 {
                    case 1:
                        guard p < src.count else { throw VWXPreview.Failure.corrupt }
                        len = Int((tag >> 2) & 7) + 4
                        distance = Int(tag >> 5) << 8 | Int(src[p])
                        p += 1
                    case 2:
                        guard p + 2 <= src.count else { throw VWXPreview.Failure.corrupt }
                        len = Int(tag >> 2) + 1
                        distance = Int(src[p]) | Int(src[p + 1]) << 8
                        p += 2
                    default:
                        guard p + 4 <= src.count else { throw VWXPreview.Failure.corrupt }
                        len = Int(tag >> 2) + 1
                        distance = Int(src[p]) | Int(src[p + 1]) << 8 | Int(src[p + 2]) << 16 | Int(src[p + 3]) << 24
                        p += 4
                    }
                    guard distance > 0, distance <= o, o + len <= expected else { throw VWXPreview.Failure.corrupt }
                    // Byte-wise copy: source and destination may overlap.
                    for i in 0..<len { dst[o + i] = dst[o + i - distance] }
                    o += len
                }
            }
            guard o == expected else { throw VWXPreview.Failure.corrupt }
            return Data(out)
        }
    }
}
