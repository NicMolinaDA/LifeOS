import SwiftUI
import Combine

@main
struct ProfessionalApp: App {
    @StateObject private var framework = ProfessionalFramework.shared
    @StateObject private var purchaseManager = PurchaseManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(framework)
                .environmentObject(purchaseManager)
                .task {
                    await framework.initializeFramework()
                    await purchaseManager.start()
                }
        }
    }
}

