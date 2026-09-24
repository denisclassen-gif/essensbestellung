import SwiftUI

@main
struct GEASHilfeApp: App {
    @StateObject private var progress = ProgressStore()
    @AppStorage("geas.hinweisBestaetigt") private var hinweisBestaetigt = false
    private let content = AppContent.loadFromBundle()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(progress)
                .environment(\.appContent, content)
                .sheet(isPresented: Binding(get: { !hinweisBestaetigt }, set: { _ in })) {
                    HinweisSheet(meta: content.meta) { hinweisBestaetigt = true }
                        .interactiveDismissDisabled()
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
            WissenView()
                .tabItem { Label("Wissen", systemImage: "books.vertical") }
            EinsatzView()
                .tabItem { Label("Einsatz", systemImage: "shield.lefthalf.filled") }
            LernenView()
                .tabItem { Label("Lernen", systemImage: "graduationcap") }
            SucheView()
                .tabItem { Label("Suche", systemImage: "magnifyingglass") }
            MehrView()
                .tabItem { Label("Mehr", systemImage: "ellipsis.circle") }
        }
    }
}

struct HinweisSheet: View {
    let meta: Meta
    let bestaetigen: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "exclamationmark.shield")
                        .font(.system(size: 48))
                        .foregroundStyle(.tint)
                    Text(meta.titel).font(.largeTitle.bold())
                    Text(meta.untertitel).font(.headline).foregroundStyle(.secondary)
                    Text(meta.hinweis)
                    Text("Stand: \(meta.stand)").font(.footnote).foregroundStyle(.secondary)
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: bestaetigen) {
                    Text("Verstanden").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                .background(.bar)
            }
        }
    }
}
