// zsh 側で選んだ画像を macOS の PDFKit で1ファイルにまとめる。
import AppKit
import Foundation
import PDFKit

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("images-to-pdf: \(message)\n".utf8))
    exit(1)
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 2 else {
    fail("Expected an output path and at least one image.")
}

let output = URL(fileURLWithPath: arguments[0])
let imagePaths = Array(arguments.dropFirst())
let document = PDFDocument()

for path in imagePaths {
    guard let image = NSImage(contentsOfFile: path),
          let page = PDFPage(image: image) else {
        fail("Cannot read image: \(path)")
    }
    document.insert(page, at: document.pageCount)
}

// 同じディレクトリに一時生成して検証し、ハードリンクで原子的に公開する。
// 既存ファイルとの競合があっても上書きせず、一時ファイルは必ず片付ける。
let temporary = output.deletingLastPathComponent()
    .appendingPathComponent(".\(output.lastPathComponent).\(UUID().uuidString).tmp")
let fileManager = FileManager.default
defer { try? fileManager.removeItem(at: temporary) }

guard document.write(to: temporary) else {
    fail("Failed to write temporary PDF: \(temporary.path)")
}
guard let verified = PDFDocument(url: temporary),
      verified.pageCount == imagePaths.count else {
    fail("Generated PDF failed validation.")
}

do {
    try fileManager.linkItem(at: temporary, to: output)
} catch {
    fail("Failed to create output (already exists or unavailable): \(output.path): \(error.localizedDescription)")
}
