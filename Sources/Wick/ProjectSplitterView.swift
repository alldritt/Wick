//
//  ProjectSplitterView.swift
//  Wick
//
//  Created by Mark Alldritt on 2026-04-05.
//

import SwiftUI
import SplitView
import LanternKit


struct DebuggerSplitterView: SplitDivider {
    @ObservedObject var layout: LayoutHolder
    @ObservedObject var hide: SideHolder
    @ObservedObject var styling: SplitStyling
    @Binding var showDebugger: Bool
    let session: SessionController

    var body: some View {
        DebuggerToolbarView(showDebugger: $showDebugger, session: session)
            .contentShape(Rectangle())
    }
}
