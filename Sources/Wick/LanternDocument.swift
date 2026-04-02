import SwiftUI
import UniformTypeIdentifiers

/// A Lantern source file (.lantern).
struct LanternDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.lanternSource] }

    var source: String

    init(source: String = defaultSource) {
        self.source = source
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.source = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = source.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }

    private static let defaultSource = """
    // Welcome to Wick!
    // Write Lantern code here and tap Run.

    print("Hello, Wick!")
    """
}

extension UTType {
    /// Lantern source file type.
    static let lanternSource = UTType(
        exportedAs: "com.latenightsw.lantern-source",
        conformingTo: .plainText
    )
}
