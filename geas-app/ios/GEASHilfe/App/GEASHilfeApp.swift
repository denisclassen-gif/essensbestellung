import SwiftUI

@main
struct GEASHilfeApp: App {
    @StateObject private var progress = ProgressStore()
    @AppStorage("geas.onboarding.v1") private var onboardingFertig = false
    private let content = AppContent.loadFromBundle()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(progress)
                .environment(\.appContent, content)
                .fullScreenCover(isPresented: Binding(get: { !onboardingFertig }, set: { _ in })) {
                    OnboardingView(seiten: content.onboarding) { onboardingFertig = true }
                }
        }
    }
}

private struct AppContentKey: EnvironmentKey {
    static let defaultValue = AppContent.empty
}

extension EnvironmentValues {
    var appContent: AppContent {
        get { self[AppContentKey.self] }
        set { self[AppContentKey.self] = newValue }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            ScreeningView()
                .tabItem { Label("Screening", systemImage: "checkmark.shield") }
            WissenView()
                .tabItem { Label("Wissen", systemImage: "books.vertical") }
            EinsatzView()
                .tabItem { Label("Einsatz", systemImage: "shield.lefthalf.filled") }
            LernenView()
                .tabItem { Label("Lernen", systemImage: "graduationcap") }
            MehrView()
                .tabItem { Label("Mehr", systemImage: "ellipsis.circle") }
        }
    }
}
