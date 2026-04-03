import SwiftUI
import LanternKit

/// Unified toolbar: Run/Pause, Stop, Step Over, Step Into, Step Out.
///
/// The debugger is always active. Run executes to completion (honouring
/// breakpoints). Step Over/Into compile if needed and pause after one statement.
struct RunToolbar: ToolbarContent {
    let session: SessionController
    let source: String

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // Run / Pause toggle
            if session.state == .running {
                Button {
                    session.pauseExecution()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .keyboardShortcut("r", modifiers: .command)
            } else if session.state == .paused {
                Button {
                    session.resume()
                } label: {
                    Label("Continue", systemImage: "play.fill")
                }
                .keyboardShortcut("r", modifiers: .command)
            } else {
                Button {
                    session.run(source: source)
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .disabled(session.state == .compiling)
                .keyboardShortcut("r", modifiers: .command)
            }

            // Stop
            Button {
                session.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .disabled(session.state == .idle || session.state == .finished || session.state == .error)

            Divider()

            // Step Over
            Button {
                session.stepOver(source: source)
            } label: {
                Label("Step Over", systemImage: "arrow.right")
            }
            .disabled(session.state == .running || session.state == .compiling)
            .keyboardShortcut("o", modifiers: [.command, .shift])

            // Step Into
            Button {
                session.stepInto(source: source)
            } label: {
                Label("Step Into", systemImage: "arrow.down.right")
            }
            .disabled(session.state == .running || session.state == .compiling)
            .keyboardShortcut("i", modifiers: [.command, .shift])

            // Step Out
            Button {
                session.stepOut()
            } label: {
                Label("Step Out", systemImage: "arrow.up.left")
            }
            .disabled(session.state != .paused)
            .keyboardShortcut("u", modifiers: [.command, .shift])
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
