//
//  DebuggerToolbarView.swift
//  Wick
//
//  Created by Mark Alldritt on 2026-04-05.
//

import SwiftUI
import LanternKit

struct ToolbarPauseContinueButton: View {
    @Binding var isPaused: Bool
    let action: () -> Void

    var body: some View {
        if isPaused {
            Button {
                action()
            } label: {
                Image(systemName: "play.fill")
                    .font(Font.system(size: 15))
            }
        }
        else {
            Button {
                action()
            } label: {
                Image(systemName: "pause.fill")
                    .font(Font.system(size: 15))
            }
        }
        ToolbarToggleButton(symbol: "play.fill", symbol2: "pause.fill", isOn: $isPaused)
    }
}

struct ToolbarToggleButton: View {
    let symbol: String
    var symbol2: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            if let symbol2 {
                Image(systemName: isOn ? symbol : symbol2)
                    .font(Font.system(size: 15))
            }
            else {
                Image(systemName: symbol)
                    .font(Font.system(size: 15))
            }
        }
        .toggleStyle(.button)
        .buttonStyle(.borderless)
        .padding(.horizontal, 3)
    }
}


struct ToolbarSymbolButton: View {
    let symbol: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: symbol)
                .font(Font.system(size: 11))
        }
        .buttonStyle(.borderless)
        .disabled(isDisabled)
        .padding(.horizontal, 3)
    }
}


struct ToolbarButton: View {
    let symbol: Image
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            symbol
        }
        .buttonStyle(.borderless)
        .disabled(isDisabled)
        .padding(.horizontal, 3)
    }
}


struct ToolbarDivider: View {
    var body: some View {
        Divider()
            .frame(height: 12)
    }
}


struct StackFramePicker: View {
    let session: SessionController

    var body: some View {
        let dbg = session.debugSession
        let frames = dbg.callStack

        if !frames.isEmpty {
            Menu {
                ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                    Button {
                        dbg.selectFrame(index)
                    } label: {
                        HStack {
                            Text(frame.functionName)
                            if index == dbg.selectedFrame {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(frames.indices.contains(dbg.selectedFrame)
                     ? frames[dbg.selectedFrame].functionName
                     : "No Frame")
                    .font(.system(size: 11))
            }
            .menuStyle(.borderlessButton)
        }
    }
}

struct DebuggerToolbarView: View {
    @Binding var showDebugger: Bool
    let session: SessionController

    @State var breakpointsEnabled = true

    private var isRunning: Bool { session.state == .running }
    private var isPaused: Bool { session.state == .paused }
    private var isIdle: Bool { session.state == .idle || session.state == .finished || session.state == .error }

    var body: some View {
        HStack {
            Spacer()
                .frame(width: 8)
            // Enable/disable breakpoints
            ToolbarToggleButton(symbol: "arrow.right.square.fill", isOn: $breakpointsEnabled)
            ToolbarDivider()

            // Run / Stop
            ToolbarSymbolButton(symbol: isRunning || isPaused ? "stop.fill" : "play.fill") {
                if isRunning || isPaused {
                    session.stop()
                } else {
                    // Run is handled by RunToolbar in the window toolbar
                }
            }

            // Pause / Resume
            ToolbarSymbolButton(symbol: isPaused ? "play.fill" : "pause.fill",
                                isDisabled: isIdle) {
                if isPaused {
                    session.resume()
                } else {
                    session.pauseExecution()
                }
            }

            // Step controls
            ToolbarButton(symbol: Image("StepOver"), isDisabled: !isPaused) {
                session.debugSession.stepOver()
            }
            .help("Step over the next statement")

            ToolbarButton(symbol: Image("StepInto"), isDisabled: !isPaused) {
                session.debugSession.stepInto()
            }
            .help("Step into function")

            ToolbarButton(symbol: Image("StepOut"), isDisabled: !isPaused) {
                session.debugSession.stepOut()
            }
            .help("Step out of function")

            ToolbarDivider()

            // Stack frame picker
            StackFramePicker(session: session)

            Spacer()
            ToolbarToggleButton(symbol: "inset.filled.bottomthird.square", isOn: $showDebugger)
        }
    }
}
