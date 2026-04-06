import SwiftUI

@main
struct WickApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: LanternDocument()) { config in
            ProjectView(document: config.$document)
        }
    }
}
