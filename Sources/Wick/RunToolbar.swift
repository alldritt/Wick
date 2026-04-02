import SwiftUI
import LanternKit

/// Toolbar content with Run and Stop controls.
struct RunToolbar: ToolbarContent {
    let session: SessionController
    let source: String

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                session.run(source: source)
            } label: {
                Label("Run", systemImage: "play.fill")
            }
            .disabled(session.state == .running || session.state == .compiling)
            .keyboardShortcut("r", modifiers: .command)

            Button {
                session.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .disabled(session.state != .running && session.state != .paused)

            Button {
                session.clearConsole()
            } label: {
                Label("Clear", systemImage: "trash")
            }
        }

        ToolbarItem(placement: .status) {
            statusView
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch session.state {
        case .idle:
            Text("Ready")
                .foregroundStyle(.secondary)
        case .compiling:
            Label("Compiling...", systemImage: "gear")
                .foregroundStyle(.secondary)
        case .running:
            Label("Running...", systemImage: "bolt.fill")
                .foregroundStyle(.green)
        case .paused:
            Label("Paused", systemImage: "pause.fill")
                .foregroundStyle(.yellow)
        case .finished:
            Label("Finished", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Label("Error", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}
