import SwiftUI

/// Volltextsuche über Kapitel, Paragraphen und Glossar. Wird aus dem Reiter „Wissen“ geöffnet.
struct SucheView: View {
    @Environment(\.appContent) private var content
    @EnvironmentObject private var progress: ProgressStore
    @State private var suche = ""

    private func passt(_ s: String) -> Bool { s.localizedCaseInsensitiveContains(suche) }

    private var kapitelTreffer: [Kapitel] {
        content.kapitel.filter { k in
            passt(k.titel) || passt(k.kurz) || k.abschnitte.contains { passt($0.titel) || passt($0.text) } || k.merke.contains(where: passt)
        }
    }

    private var normTreffer: [Norm] {
        content.normen.filter { passt($0.norm) || passt($0.titel) || passt($0.inhalt) || passt($0.praxis) }
    }

    private var glossarTreffer: [GlossarEintrag] {
        suche.isEmpty ? content.glossar : content.glossar.filter { passt($0.begriff) || passt($0.erklaerung) }
    }

    var body: some View {
        List {
            if !suche.isEmpty {
                if !kapitelTreffer.isEmpty {
                    Section("Kapitel") {
                        ForEach(kapitelTreffer) { k in
                            NavigationLink(value: k) {
                                KapitelZeile(kapitel: k, gelesen: progress.istGelesen(k))
                            }
                        }
                    }
                }
                if !normTreffer.isEmpty {
                    Section("Paragraphen") {
                        ForEach(normTreffer) { NormZeile(norm: $0) }
                    }
                }
            }
            Section(suche.isEmpty ? "Glossar A–Z" : "Glossar") {
                ForEach(glossarTreffer) { eintrag in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(eintrag.begriff).font(.headline)
                        Text(eintrag.erklaerung).font(.callout).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            if !suche.isEmpty && kapitelTreffer.isEmpty && normTreffer.isEmpty && glossarTreffer.isEmpty {
                Text("Keine Treffer für „\(suche)“.").foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .seitenHintergrund()
        .searchable(text: $suche, placement: .navigationBarDrawer(displayMode: .always), prompt: "Begriff, Paragraph, Thema …")
        .navigationTitle("Suche & Glossar")
    }
}
