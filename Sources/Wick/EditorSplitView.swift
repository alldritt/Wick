//
//  EditorSplitView.swift
//  Wick
//
//  Created by Mark Alldritt on 2026-04-06.
//

import SwiftUI
import SplitView
import LanternKit
import LanternDebugger
import CodeEditorView
import LanguageSupport


struct EditorSplitView: View {
    @Binding var document: LanternDocument
    let session: SessionController
    @Binding var messages: Set<TextLocated<Message>>
    @Binding var position: CodeEditor.Position

    var body: some View {
        HSplit {
            editorPane
        } right: {
            previewPane
        }
        .splitter { Splitter.line(color: .secondary) }
    }

    private var editorPane: some View {
        LanternEditorView(
            source: $document.source,
            messages: $messages,
            position: $position,
            breakpoints: BreakpointMapper.mapBreakpoints(session.debugSession.breakpoints),
            stackFrames: BreakpointMapper.mapPausedState(
                pausedLocation: session.debugSession.pausedLocation,
                callStack: session.debugSession.callStack
            ),
            breakpointActions: makeBreakpointActions()
        )
    }

    private var previewPane: some View {
        PreviewCanvasView(
            result: session.previewValue,
            error: session.state == .error ? session.diagnostics?.description : nil,
            session: session
        )
    }

    private func makeBreakpointActions() -> GutterBreakpointActions {
        let dbg = session.debugSession
        return GutterBreakpointActions(
            onToggle: { line in
                dbg.addBreakpoint(file: "", line: line)
            },
            onToggleEnabled: { id in
                if let bp = dbg.breakpoints.first(where: { $0.id == id }) {
                    dbg.enableBreakpoint(id, enabled: !bp.isEnabled)
                }
            },
            onMove: { id, newLine in
                dbg.removeBreakpoint(id)
                dbg.addBreakpoint(file: "", line: newLine)
            },
            onDelete: { id in
                dbg.removeBreakpoint(id)
            },
            onEdit: { _ in },
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
}
