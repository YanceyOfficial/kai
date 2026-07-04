import SwiftUI
import UniformTypeIdentifiers

/// A JSON document wrapper so the deck backup can be written out through `.fileExporter`
/// (to the Files app, iCloud Drive, AirDrop, …) and read back via `.fileImporter`.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
