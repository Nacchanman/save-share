import SwiftUI

@main
struct SaveShareApp: App {
    @StateObject private var store = SaveShareStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
