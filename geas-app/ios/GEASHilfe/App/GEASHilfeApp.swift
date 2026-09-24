import SwiftUI

@main
struct GEASHilfeApp: App {
    @StateObject private var progress = ProgressStore()
    @StateObject private var fall = FallStore()
    @AppStorage("geas.onboarding.v2") private var onboardingFertig = false
    private let content = AppContent.loadFromBundle()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(progress)
                .environmentObject(fall)
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
            StartView()
                .tabItem { Label("Start", systemImage: "shield.lefthalf.filled") }
            FallView()
                .tabItem { Label("Unterlagen", systemImage: "doc.richtext") }
            WissenView()
                .tabItem { Label("Wissen", systemImage: "books.vertical") }
            LernenView()
                .tabItem { Label("Lernen", systemImage: "graduationcap") }
            MehrView()
                .tabItem { Label("Mehr", systemImage: "ellipsis.circle") }
        }
    }
}
