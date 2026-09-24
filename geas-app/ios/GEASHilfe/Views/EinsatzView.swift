import SwiftUI

/// Übersicht aller Checklisten (von der Startseite aus erreichbar).
struct ChecklistenUebersichtView: View {
    @Environment(\.appContent) private var content
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "phone.arrow.up.right.fill").foregroundStyle(Stil.gruen)
                    Text("Die Entscheidung über den Fortgang einer Abschiebung trifft die Ausländerbehörde (ZAB/LDS). Im Zweifel: Rücksprache halten und dokumentieren.")
                        .font(.callout)
                }
                .padding(16)
                .glas(20)

                ForEach(Array(content.checklisten.enumerated()), id: \.element.id) { index, liste in
                    NavigationLink {
                        ChecklistenView(liste: liste)
                    } label: {
                        ZeilenKachel(
                            titel: liste.titel,
                            untertitel: liste.kontext,
                            icon: liste.icon,
                            farbe: Stil.farbe(index),
                            rechts: "\(progress.anzahlAbgehakt(liste))/\(liste.punkte.count)"
                        )
                    }
                    .buttonStyle(DrueckStil())
                    .scrollEinblenden()
                }
            }
            .padding(20)
        }
        .seitenHintergrund()
        .navigationTitle("Checklisten")
    }
}

struct ChecklistenView: View {
    let liste: Checkliste
    @EnvironmentObject private var progress: ProgressStore
    @State private var zuruecksetzenFragen = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(liste.kontext).font(.callout).foregroundStyle(.secondary)
                    Fortschrittsbalken(wert: Double(progress.anzahlAbgehakt(liste)) / Double(max(liste.punkte.count, 1)))
                }
                .padding(.bottom, 4)

                ForEach(Array(liste.punkte.enumerated()), id: \.offset) { index, punkt in
                    let an = progress.istAbgehakt(liste, index)
                    Button {
                        Haptik.tippen()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { progress.toggle(liste, index) }
                    } label: {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(an ? AnyShapeStyle(Stil.akzentVerlauf) : AnyShapeStyle(Color.primary.opacity(0.07)))
                                    .frame(width: 28, height: 28)
                                if an {
                                    Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(.white)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(punkt.text)
                                    .foregroundStyle(an ? .secondary : .primary)
                                    .strikethrough(an, color: .secondary)
                                    .multilineTextAlignment(.leading)
                                if let hinweis = punkt.hinweis {
                                    Text(hinweis).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .glas(18, interaktiv: true)
                    }
                    .buttonStyle(DrueckStil())
                    .accessibilityAddTraits(an ? .isSelected : [])
                }

                Text("Abgehakte Punkte werden nur lokal gespeichert. Keine Personendaten eintragen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .seitenHintergrund()
        .navigationTitle(liste.titel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Zurücksetzen") { zuruecksetzenFragen = true }
        }
        .confirmationDialog("Alle Haken entfernen?", isPresented: $zuruecksetzenFragen, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) { withAnimation { progress.reset(liste) } }
        }
    }
}

struct FristenView: View {
    @Environment(\.appContent) private var content

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(Array(content.fristen.enumerated()), id: \.offset) { index, frist in
                    HStack(alignment: .center, spacing: 14) {
                        IconPlakette(icon: "hourglass", farbe: Stil.farbe(index), groesse: 36)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(frist.was).font(.headline)
                            Text(frist.grundlage).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Text(frist.frist)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(Stil.farbe(index))
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(14)
                    .glas(18)
                    .scrollEinblenden()
                }
            }
            .padding(20)
        }
        .seitenHintergrund()
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
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(treffer) { norm in
                    NormZeile(norm: norm)
                        .scrollEinblenden()
                }
            }
            .padding(20)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: suche)
        }
        .seitenHintergrund()
        .searchable(text: $suche, prompt: "z. B. 62 oder Duldung")
        .navigationTitle("Paragraphen")
    }
}

struct NormZeile: View {
    let norm: Norm

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(norm.norm)
                    .font(.system(.headline, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Stil.gruen.opacity(0.14)))
                    .foregroundStyle(Stil.gruen)
                Text(norm.titel).font(.subheadline.bold())
            }
            Text(norm.inhalt).font(.callout)
            Label(norm.praxis, systemImage: "hand.point.right.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glas(20)
    }
}
