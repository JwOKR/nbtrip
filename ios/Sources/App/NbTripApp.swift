import SwiftUI

@main
struct NbTripApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .tint(.nbAccent)
                .task { await model.load() }
        }
    }
}
