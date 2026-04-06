//
//  ProjectView.swift
//  Wick
//
//  Created by Mark Alldritt on 2026-04-05.
//

import SwiftUI
import SplitView
import LanternKit
import LanternDebugger
import CodeEditorView
import LanguageSupport


struct ProjectView: View {
    @Binding var document: LanternDocument
    @State private var session = SessionController()
    @State private var messages: Set<TextLocated<Message>> = []
    @State private var position = CodeEditor.Position()

    let layout = LayoutHolder(.vertical)
    let hide = SideHolder()
    let styling = SplitStyling(visibleThickness: 22)
    @State var showDebugger = true

    var body: some View {
        Split {
            EditorSplitView(
                document: $document,
                session: session,
                messages: $messages,
                position: $position
            )
        } secondary: {
            DebuggerSplitView(session: session)
        }
        .layout(layout)
        .hide(hide)
        .styling(hideSplitter: false)
        .constraints(minPFraction: 0.2, minSFraction: 0.2, dragToHideS: true)
        .splitter { DebuggerSplitterView(layout: layout, hide: hide, styling: styling, showDebugger: $showDebugger, session: session) }
        .toolbar {
            RunToolbar(session: session, source: document.source)
        }
        .onChange(of: showDebugger) {
            hide.toggle(.bottom)
        }
        .onChange(of: session.state) {
            updateMessages()
        }
        .onChange(of: session.debugSession.pausedLocation?.line) {
            updateMessages()
            scrollToPausedLine()
        }
        .onChange(of: document.source) {
            session.scheduleRecompile(source: document.source)
        }
    }

    // MARK: - Message Updates

    private func updateMessages() {
        var msgs: Set<TextLocated<Message>> = []

        if let diags = session.diagnostics {
            msgs = DiagnosticMapper.map(diags)
        }

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

    private func scrollToPausedLine() {
        guard let loc = session.debugSession.pausedLocation, loc.line > 0 else { return }
        let line = Int(loc.line)
        var offset = 0
        var currentLine = 1
        for char in document.source {
            if currentLine >= line { break }
            offset += 1
            if char == "\n" { currentLine += 1 }
        }
        position.selections = [NSRange(location: offset, length: 0)]
    }
}
