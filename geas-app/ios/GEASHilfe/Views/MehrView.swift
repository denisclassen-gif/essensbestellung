import SwiftUI

struct MehrView: View {
    @Environment(\.appContent) private var content
    @State private var einfuehrung = false

    var body: some View {
        NavigationStack {
            List {
                Section("Einsatz") {
                    NavigationLink {
                        KontakteView()
                    } label: {
                        Label("Wichtige Erreichbarkeiten", systemImage: "phone")
                    }
                }
                Section("Hilfe") {
                    Button {
                        einfuehrung = true
                    } label: {
                        Label("Einführung erneut ansehen", systemImage: "play.rectangle")
                    }
                }
                Section("Über diese App") {
                    NavigationLink {
                        TextSeite(titel: "Wichtiger Hinweis", text: content.meta.hinweis)
                    } label: {
                        Label("Hinweis & Haftung", systemImage: "exclamationmark.shield")
                    }
                    NavigationLink {
                        TextSeite(titel: "Quellen", text: content.quellen.map { "• " + $0 }.joined(separator: "\n"))
                    } label: {
                        Label("Quellen & Rechtsstand", systemImage: "books.vertical")
                    }
                    LabeledContent("Version", value: content.meta.version)
                    LabeledContent("Inhaltsstand", value: content.meta.stand)
                }
            }
            .navigationTitle("Mehr")
            .fullScreenCover(isPresented: $einfuehrung) {
                OnboardingView(seiten: content.onboarding) { einfuehrung = false }
            }
        }
    }
}

struct TextSeite: View {
    let titel: String
    let text: String

    var body: some View {
        ScrollView {
            RichText(text: text).padding()
        }
        .navigationTitle(titel)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Erreichbarkeiten werden von jeder Dienststelle selbst gepflegt und nur lokal gespeichert.
struct KontakteView: View {
    @Environment(\.appContent) private var content
    @EnvironmentObject private var progress: ProgressStore
    @State private var kontakte: [ProgressStore.EigenerKontakt] = []
    @State private var bearbeiten: ProgressStore.EigenerKontakt?

    var body: some View {
        List {
            Section {
                ForEach(kontakte) { kontakt in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kontakt.name).font(.headline)
                            Text(kontakt.rolle).font(.caption).foregroundStyle(.secondary)
                            Text(kontakt.telefon.isEmpty ? "Nummer noch nicht hinterlegt" : kontakt.telefon)
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(kontakt.telefon.isEmpty ? Color.orange : Color.primary)
                        }
                        Spacer()
                        if let url = telURL(kontakt.telefon) {
                            Link(destination: url) {
                                Image(systemName: "phone.fill").padding(10)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("\(kontakt.name) anrufen")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { bearbeiten = kontakt }
                }
                .onDelete { kontakte.remove(atOffsets: $0); progress.speichereKontakte(kontakte) }
                .onMove { kontakte.move(fromOffsets: $0, toOffset: $1); progress.speichereKontakte(kontakte) }
            } footer: {
                Text("Bitte die dienstlich gültigen Nummern der PD Leipzig selbst eintragen. Die Daten bleiben ausschließlich auf diesem Gerät.")
            }
        }
        .navigationTitle("Erreichbarkeiten")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { EditButton() }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    bearbeiten = ProgressStore.EigenerKontakt(name: "", rolle: "", telefon: "")
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Kontakt hinzufügen")
            }
        }
        .onAppear { kontakte = progress.kontakte(vorlage: content.kontakte) }
        .sheet(item: $bearbeiten) { kontakt in
            KontaktEditor(kontakt: kontakt) { neu in
                if let i = kontakte.firstIndex(where: { $0.id == neu.id }) {
                    kontakte[i] = neu
                } else {
                    kontakte.append(neu)
                }
                progress.speichereKontakte(kontakte)
            }
        }
    }

    private func telURL(_ nummer: String) -> URL? {
        let erlaubt = nummer.filter { $0.isNumber || $0 == "+" }
        guard !erlaubt.isEmpty else { return nil }
        return URL(string: "tel:\(erlaubt)")
    }
}

struct KontaktEditor: View {
    @State var kontakt: ProgressStore.EigenerKontakt
    let speichern: (ProgressStore.EigenerKontakt) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name / Stelle", text: $kontakt.name)
                TextField("Zuständigkeit", text: $kontakt.rolle)
                TextField("Telefon", text: $kontakt.telefon)
                    .keyboardType(.phonePad)
            }
            .navigationTitle(kontakt.name.isEmpty ? "Neuer Kontakt" : kontakt.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        speichern(kontakt)
                        dismiss()
                    }
                    .disabled(kontakt.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
