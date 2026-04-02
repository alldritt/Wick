import SwiftUI
import LanternKit
import LanternDebugger
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
            if session.isDebugging, let dbg = session.debugSession {
                ToolbarItem(placement: .primaryAction) {
                    DebugToolbar(
                        isPaused: dbg.isPaused,
                        isDebugging: session.isDebugging,
                        onContinue: { session.resume() },
                        onPause: { session.pauseExecution() },
                        onStepOver: { session.stepOver() },
                        onStepInto: { session.stepInto() },
                        onStepOut: { session.stepOut() }
                    )
                }
            }
            previewToggle
        }
        .onChange(of: session.state) {
            if let diags = session.diagnostics {
                messages = DiagnosticMapper.map(diags)
            } else {
                messages = []
            }
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
            if session.isDebugging {
                Tab("Debug", systemImage: "ant") {
                    debugPanelsCompact
                }
            }
        }
    }

    // MARK: - Bottom Panel (Regular Layout)

    private var bottomPanelView: some View {
        VStack(spacing: 0) {
            // Panel selector
            if session.isDebugging {
                Picker("Panel", selection: $bottomPanel) {
                    ForEach(BottomPanel.allCases, id: \.self) { panel in
                        Text(panel.rawValue).tag(panel)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            // Panel content
            Group {
                switch bottomPanel {
                case .console:
                    console
                case .variables:
                    if let dbg = session.debugSession {
                        VariablesPanel(
                            locals: dbg.currentLocals,
                            captures: dbg.currentCaptures
                        )
                    }
                case .callStack:
                    if let dbg = session.debugSession {
                        CallStackPanel(
                            frames: dbg.callStack,
                            selectedFrame: dbg.selectedFrame,
                            onSelectFrame: { dbg.selectFrame($0) }
                        )
                    }
                case .canvas:
                    if let dbg = session.debugSession {
                        DebugCanvasView(
                            canvas: dbg.canvasModel,
                            onSelectBubble: { dbg.selectFrame($0.frameIndex) }
                        )
                    }
                case .repl:
                    if let dbg = session.debugSession {
                        DebugREPLView(
                            isPaused: dbg.isPaused,
                            onEvaluate: { dbg.evaluate(expression: $0) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Compact Debug Panels

    private var debugPanelsCompact: some View {
        VStack(spacing: 0) {
            if let dbg = session.debugSession {
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
                    VariablesPanel(
                        locals: dbg.currentLocals,
                        captures: dbg.currentCaptures
                    )
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

    private var preview: some View {
        PreviewCanvasView(
            previewView: session.previewView,
            detectedTypeName: session.detectedViewTypeName,
            hasError: session.diagnostics != nil
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
