import SwiftUI

@main
struct VlessBoxApp: App {
    @StateObject private var proxyManager = ProxyManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(proxyManager)
        }
    }
}
