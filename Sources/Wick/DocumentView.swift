import SwiftUI
import LanternKit
import CodeEditorView
import LanguageSupport

/// Root view for a single Lantern document.
///
/// Creates a per-document `SessionController` and adapts layout
/// based on horizontal size class: split view on macOS/iPad,
/// tabs on iPhone.
struct DocumentView: View {
    @Binding var document: LanternDocument
    @State private var session = SessionController()
    @State private var messages: Set<TextLocated<Message>> = []
    @State private var position = CodeEditor.Position()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if sizeClass == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .toolbar {
            RunToolbar(session: session, source: document.source)
        }
        .onChange(of: session.state) {
            if let diags = session.diagnostics {
                messages = DiagnosticMapper.map(diags)
            } else {
                messages = []
            }
        }
    }

    // MARK: - Layouts

    /// macOS / iPad: editor on top, console below.
    private var regularLayout: some View {
        VStack(spacing: 0) {
            editor
                .frame(minHeight: 200)
            Divider()
            console
                .frame(minHeight: 100, idealHeight: 150)
        }
    }

    /// iPhone: tabs for editor and console.
    private var compactLayout: some View {
        TabView {
            Tab("Editor", systemImage: "doc.text") {
                editor
            }
            Tab("Console", systemImage: "terminal") {
                console
            }
        }
    }

    // MARK: - Subviews

    private var editor: some View {
        LanternEditorView(
            source: $document.source,
            messages: $messages,
            position: $position
        )
    }

    private var console: some View {
        LanternConsoleView(output: session.consoleOutput)
    }
}
