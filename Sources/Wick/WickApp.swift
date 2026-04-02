import SwiftUI

@main
struct WickApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: LanternDocument()) { config in
            DocumentView(document: config.$document)
        }
    }
}
