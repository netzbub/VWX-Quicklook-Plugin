import Foundation

// Command-line test tool: extracts the embedded preview of each given file
// as <name>.jpg into the current directory.

let paths = CommandLine.arguments.dropFirst()
guard !paths.isEmpty else {
    FileHandle.standardError.write("usage: vwxextract FILE.vwx ...\n".data(using: .utf8)!)
    exit(2)
}

var failed = false
for path in paths {
    let url = URL(fileURLWithPath: path)
    do {
        let jpeg = try VWXPreview.jpegData(from: url)
        let out = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".jpg")
        try jpeg.write(to: out)
        print("\(path): \(jpeg.count) bytes -> \(out.path)")
    } catch {
        print("\(path): \(error)")
        failed = true
    }
}
exit(failed ? 1 : 0)
