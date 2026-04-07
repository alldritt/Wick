//
//  DebuggerSplitView.swift
//  Wick
//
//  Created by Mark Alldritt on 2026-04-05.
//

import SwiftUI
import SplitView
import LanternKit


struct FilterView: View {

    @Binding var filter: String

    var body: some View {
        TextField("Filter", text: $filter)
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
    }
}

struct ConsoleBottomBarView: View {
    @Binding var showDebugger: Bool
    @Binding var showConsole: Bool
    let onClear: () -> Void
    @State var filter = ""

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            FilterView(filter: $filter)
            ToolbarSymbolButton(symbol: "trash") {
                onClear()
            }
            ToolbarDivider()
            ToolbarToggleButton(symbol: "inset.filled.leftthird.square", isOn: $showDebugger)
            ToolbarToggleButton(symbol: "inset.filled.rightthird.square", isOn: $showConsole)
        }
        .frame(height: 22)
    }
}


struct DebuggerBottomBarView: View {
    @Binding var showDebugger: Bool
    @Binding var showConsole: Bool

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            if !showConsole {
                ToolbarToggleButton(symbol: "inset.filled.leftthird.square", isOn: $showDebugger)
                ToolbarToggleButton(symbol: "inset.filled.rightthird.square", isOn: $showConsole)
            }
        }
        .frame(height: 22)
    }
}


struct DebuggerSplitView: View {
    let session: SessionController

    @StateObject private var layout = LayoutHolder(.horizontal)
    @StateObject private var hide = SideHolder()
    @State var showDebugger: Bool = true
    @State var showConsole: Bool = true

    private func updateControls(side: SplitSide?) {
        if let side = hide.side {
            if side == .left {
                showDebugger = false
                showConsole = true
            }
            else {
                showDebugger = true
                showConsole = false
            }
        }
        else {
            showDebugger = true
            showConsole = true
        }
    }

    var body: some View {
        Split {
            // Left: Variables panel
            VStack(spacing: 0) {
                VariablesPanel(
                    locals: session.debugSession.currentLocals,
                    captures: session.debugSession.currentCaptures,
                    globals: session.debugSession.currentGlobals
                )
                DebuggerBottomBarView(showDebugger: $showDebugger, showConsole: $showConsole)
            }
        } secondary: {
            // Right: Unified Console + REPL
            VStack(spacing: 0) {
                UnifiedConsoleView(
                    entries: session.consoleEntries,
                    canEvaluate: session.state == .paused || session.state == .finished,
                    onEvaluate: { session.evaluateREPL(expression: $0) },
                    onClear: { session.clearConsole() }
                )
                ConsoleBottomBarView(
                    showDebugger: $showDebugger,
                    showConsole: $showConsole,
                    onClear: { session.clearConsole() }
                )
            }
        }
        .layout(layout)
        .hide(hide)
        .styling(invisibleThickness: 4, hideSplitter: true)
        .constraints(minPFraction: 0.2, minSFraction: 0.2, dragToHideP: true, dragToHideS: true)
        .splitter { Splitter.line(color: .secondary) }
        .onChange(of: showDebugger) {
            withAnimation {
                hide.toggle(.left)
            }
        }
        .onChange(of: showConsole) {
            withAnimation {
                hide.toggle(.right)
            }
        }
        .onChange(of: hide.side) {
            updateControls(side: hide.side)
        }
    }
}
