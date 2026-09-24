import SwiftUI

struct EinsatzView: View {
    @Environment(\.appContent) private var content
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Die Entscheidung über den Fortgang einer Abschiebung trifft die Ausländerbehörde (ZAB/LDS). Im Zweifel: Rücksprache halten und dokumentieren.", systemImage: "phone.arrow.up.right")
                        .font(.callout)
                }

                Section("Checklisten") {
                    ForEach(content.checklisten) { liste in
                        NavigationLink {
                            ChecklistenView(liste: liste)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: liste.icon).foregroundStyle(.tint).frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(liste.titel).font(.headline)
                                    Text(liste.kontext).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                                Text("\(progress.anzahlAbgehakt(liste))/\(liste.punkte.count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Nachschlagen") {
                    NavigationLink {
                        FristenView()
                    } label: {
                        Label("Fristen & Höchstdauern", systemImage: "clock.badge.exclamationmark")
                    }
                    NavigationLink {
                        NormenView()
                    } label: {
                        Label("Paragraphen-Schnellzugriff", systemImage: "text.book.closed")
                    }
                }
            }
            .navigationTitle("Einsatz")
        }
    }
}

struct ChecklistenView: View {
    let liste: Checkliste
    @EnvironmentObject private var progress: ProgressStore
    @State private var zuruecksetzenFragen = false

    var body: some View {
        List {
            Section {
                Text(liste.kontext).font(.callout).foregroundStyle(.secondary)
            }
            Section {
                ForEach(Array(liste.punkte.enumerated()), id: \.offset) { index, punkt in
                    Button {
                        progress.toggle(liste, index)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: progress.istAbgehakt(liste, index) ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundStyle(progress.istAbgehakt(liste, index) ? Color.green : Color.secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(punkt.text)
                                    .foregroundStyle(.primary)
                                    .strikethrough(progress.istAbgehakt(liste, index), color: .secondary)
                                if let hinweis = punkt.hinweis {
                                    Text(hinweis).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .accessibilityAddTraits(progress.istAbgehakt(liste, index) ? .isSelected : [])
                }
            } footer: {
                Text("Abgehakte Punkte werden nur lokal gespeichert. Keine Personendaten eintragen.")
            }
        }
        .navigationTitle(liste.titel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Zurücksetzen") { zuruecksetzenFragen = true }
        }
        .confirmationDialog("Alle Haken entfernen?", isPresented: $zuruecksetzenFragen, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) { progress.reset(liste) }
        }
    }
}

struct FristenView: View {
    @Environment(\.appContent) private var content

    var body: some View {
        List(content.fristen, id: \.self) { frist in
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(frist.was).font(.headline)
                    Spacer()
                    Text(frist.frist)
                        .font(.subheadline.bold())
                        .foregroundStyle(.tint)
                        .multilineTextAlignment(.trailing)
                }
                Text(frist.grundlage).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
        .navigationTitle("Fristen")
    }
}

struct NormenView: View {
    @Environment(\.appContent) private var content
    @State private var suche = ""

    private var treffer: [Norm] {
        guard !suche.isEmpty else { return content.normen }
        return content.normen.filter {
            $0.norm.localizedCaseInsensitiveContains(suche)
                || $0.titel.localizedCaseInsensitiveContains(suche)
                || $0.inhalt.localizedCaseInsensitiveContains(suche)
        }
    }

    var body: some View {
        List(treffer) { norm in
            NormZeile(norm: norm)
        }
        .searchable(text: $suche, prompt: "z. B. 62 oder Duldung")
        .navigationTitle("Paragraphen")
    }
}

struct NormZeile: View {
    let norm: Norm

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(norm.norm).font(.headline).foregroundStyle(.tint)
                Text(norm.titel).font(.subheadline.bold())
            }
            Text(norm.inhalt).font(.callout)
            Label(norm.praxis, systemImage: "hand.point.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
