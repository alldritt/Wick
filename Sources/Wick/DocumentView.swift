import SwiftUI
import LanternKit
import LanternDebugger
import CodeEditorView
import LanguageSupport

/// Root view for a single Lantern document.
///
/// Creates a per-document `SessionController` and adapts layout
/// based on horizontal size class: split view on macOS/iPad,
/// tabs on iPhone. The debugger is always active.
struct DocumentView: View {
    @Binding var document: LanternDocument
    @State private var session = SessionController()
    @State private var messages: Set<TextLocated<Message>> = []
    @State private var position = CodeEditor.Position()
    @State private var showPreview = true
    @State private var bottomPanel: BottomPanel = .console
    @Environment(\.horizontalSizeClass) private var sizeClass

    enum BottomPanel: String, CaseIterable {
        case console = "Console"
        case variables = "Variables"
        case callStack = "Call Stack"
        case canvas = "Canvas"
        case repl = "REPL"
    }

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
            previewToggle
        }
        .onChange(of: session.state) {
            updateMessages()
        }
        .onChange(of: session.debugSession.pausedLocation?.line) {
            updateMessages()
        }
        .onChange(of: document.source) {
            session.scheduleRecompile(source: document.source)
        }
    }

    // MARK: - Layouts

    /// macOS / iPad: editor left with bottom panels, preview right.
    private var regularLayout: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                editor
                    .frame(minHeight: 200)
                Divider()
                bottomPanelView
                    .frame(minHeight: 80, idealHeight: 150)
            }
            .frame(minWidth: 300)

            if showPreview {
                Divider()
                preview
                    .frame(minWidth: 250, idealWidth: 350)
            }
        }
    }

    /// iPhone: tabs for editor, preview, console, and debug.
    private var compactLayout: some View {
        TabView {
            Tab("Editor", systemImage: "doc.text") {
                editor
            }
            Tab("Preview", systemImage: "rectangle.dashed") {
                preview
            }
            Tab("Console", systemImage: "terminal") {
                console
            }
            Tab("Debug", systemImage: "ant") {
                debugPanelsCompact
            }
        }
    }

    // MARK: - Bottom Panel (Regular Layout)

    private var bottomPanelView: some View {
        VStack(spacing: 0) {
            Picker("Panel", selection: $bottomPanel) {
                ForEach(BottomPanel.allCases, id: \.self) { panel in
                    Text(panel.rawValue).tag(panel)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Group {
                switch bottomPanel {
                case .console:
                    console
                case .variables:
                    VariablesPanel(
                        locals: session.debugSession.currentLocals,
                        captures: session.debugSession.currentCaptures,
                        globals: session.debugSession.currentGlobals
                    )
                case .callStack:
                    CallStackPanel(
                        frames: session.debugSession.callStack,
                        selectedFrame: session.debugSession.selectedFrame,
                        onSelectFrame: { session.debugSession.selectFrame($0) }
                    )
                case .canvas:
                    DebugCanvasView(
                        canvas: session.debugSession.canvasModel,
                        onSelectBubble: { session.debugSession.selectFrame($0.frameIndex) }
                    )
                case .repl:
                    DebugREPLView(
                        isPaused: session.debugSession.isPaused,
                        onEvaluate: { session.debugSession.evaluate(expression: $0) }
                    )
                }
            }
        }
    }

    // MARK: - Compact Debug Panels

    private var debugPanelsCompact: some View {
        VStack(spacing: 0) {
            let dbg = session.debugSession
            Picker("Panel", selection: $bottomPanel) {
                Text("Variables").tag(BottomPanel.variables)
                Text("Call Stack").tag(BottomPanel.callStack)
                Text("Canvas").tag(BottomPanel.canvas)
                Text("REPL").tag(BottomPanel.repl)
            }
            .pickerStyle(.segmented)
            .padding(8)

            switch bottomPanel {
            case .variables:
                VariablesPanel(locals: dbg.currentLocals, captures: dbg.currentCaptures)
            case .callStack:
                CallStackPanel(
                    frames: dbg.callStack,
                    selectedFrame: dbg.selectedFrame,
                    onSelectFrame: { dbg.selectFrame($0) }
                )
            case .canvas:
                DebugCanvasView(
                    canvas: dbg.canvasModel,
                    onSelectBubble: { dbg.selectFrame($0.frameIndex) }
                )
            case .repl:
                DebugREPLView(
                    isPaused: dbg.isPaused,
                    onEvaluate: { dbg.evaluate(expression: $0) }
                )
            default:
                console
            }
        }
    }

    // MARK: - Message Updates

    private func updateMessages() {
        var msgs: Set<TextLocated<Message>> = []

        // Compiler diagnostics
        if let diags = session.diagnostics {
            msgs = DiagnosticMapper.map(diags)
        }

        // Current execution line indicator (when paused)
        if let loc = session.debugSession.pausedLocation {
            let lineMsg = Message(
                category: .live,
                length: 1,
                summary: "\u{25B6} Paused here",
                description: nil
            )
            let textLoc = TextLocation(oneBasedLine: Int(loc.line), column: 1)
            msgs.insert(TextLocated(location: textLoc, entity: lineMsg))
        }

        messages = msgs
    }

    // MARK: - Subviews

    private var editor: some View {
        let dbg = session.debugSession
        return LanternEditorView(
            source: $document.source,
            messages: $messages,
            position: $position,
            breakpoints: BreakpointMapper.mapBreakpoints(dbg.breakpoints),
            stackFrames: BreakpointMapper.mapPausedState(
                pausedLocation: dbg.pausedLocation,
                callStack: dbg.callStack
            ),
            breakpointActions: makeBreakpointActions()
        )
    }

    private func makeBreakpointActions() -> GutterBreakpointActions {
        let dbg = session.debugSession
        return GutterBreakpointActions(
            onToggle: { line in
                dbg.toggleBreakpoint(file: "", line: line)
            },
            onMove: { id, newLine in
                dbg.removeBreakpoint(id)
                dbg.addBreakpoint(file: "", line: newLine)
            },
            onDelete: { id in
                dbg.removeBreakpoint(id)
            },
            onEdit: { _ in
                // TODO: Present breakpoint editor sheet
            },
            contextMenuItems: { id in
                let bp = dbg.breakpoints.first { $0.id == id }
                var items: [GutterContextMenuItem] = []
                if let bp {
                    items.append(GutterContextMenuItem(
                        title: bp.isEnabled ? "Disable Breakpoint" : "Enable Breakpoint"
                    ) {
                        dbg.enableBreakpoint(id, enabled: !bp.isEnabled)
                    })
                }
                items.append(GutterContextMenuItem(
                    title: "Delete Breakpoint",
                    isDestructive: true
                ) {
                    dbg.removeBreakpoint(id)
                })
                return items
            }
        )
    }

    private var console: some View {
        LanternConsoleView(output: session.consoleOutput)
    }

    private var preview: some View {
        PreviewCanvasView(
            result: session.previewValue,
            error: session.state == .error ? session.diagnostics?.description : nil
        )
    }

    private var previewToggle: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Toggle(isOn: $showPreview) {
                Label("Preview", systemImage: "rectangle.dashed")
            }
            .toggleStyle(.button)
            .help("Toggle preview panel")
        }
    }
}
