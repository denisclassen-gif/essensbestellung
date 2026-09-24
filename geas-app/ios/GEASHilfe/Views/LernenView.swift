import SwiftUI

struct LernenView: View {
    @Environment(\.appContent) private var content
    @EnvironmentObject private var progress: ProgressStore
    @State private var resetFragen = false

    private var falsche: [QuizFrage] { progress.falschBeantwortet(content.quiz) }

    private let spalten = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ParallaxHero(hoehe: 250, verlauf: LinearGradient(
                        colors: [Stil.farbe(2), Color(red: 0.55, green: 0.16, blue: 0.24)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )) {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Lernen")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Quiz, Fallbeispiele, Prüfung, Karteikarten")
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        FortschrittKarte(
                            beherrscht: progress.beherrscht(content.quiz),
                            gesamt: content.quiz.count,
                            karten: progress.anzahlGewussteKarten,
                            kartenGesamt: content.glossar.count + content.normen.count
                        )
                        .padding(18)
                        .glas(26)

                        Abschnittstitel(text: "Trainieren")
                        LazyVGrid(columns: spalten, spacing: 14) {
                            NavigationLink {
                                QuizView(fragen: content.quiz, titel: "Alle Fragen")
                            } label: {
                                Kachel(titel: "Quiz", untertitel: "Alle \(content.quiz.count) Fragen mit Erklärung", icon: "questionmark.circle.fill", farbe: Stil.farbe(0))
                            }
                            .buttonStyle(DrueckStil())
                            NavigationLink {
                                QuizView(fragen: Array(content.quiz.shuffled().prefix(20)), titel: "Prüfung", pruefungsModus: true)
                            } label: {
                                Kachel(titel: "Prüfung", untertitel: "20 zufällige Fragen", icon: "timer", farbe: Stil.farbe(2))
                            }
                            .buttonStyle(DrueckStil())
                            NavigationLink {
                                KarteikartenView()
                            } label: {
                                Kachel(titel: "Karteikarten", untertitel: "Begriffe & Paragraphen", icon: "rectangle.on.rectangle.angled", farbe: Stil.farbe(1))
                            }
                            .buttonStyle(DrueckStil())
                            NavigationLink {
                                QuizView(fragen: falsche.isEmpty ? content.quiz.filter { $0.kapitel == "screening" } : falsche,
                                         titel: falsche.isEmpty ? "Fallbeispiele" : "Wiederholen")
                            } label: {
                                Kachel(titel: falsche.isEmpty ? "Fallbeispiele" : "Wiederholen",
                                       untertitel: falsche.isEmpty ? "Screening-Fälle" : "Falsch beantwortete",
                                       icon: falsche.isEmpty ? "person.fill.questionmark" : "arrow.counterclockwise",
                                       farbe: Stil.farbe(3),
                                       plakette: falsche.isEmpty ? nil : "\(falsche.count)")
                            }
                            .buttonStyle(DrueckStil())
                        }

                        Abschnittstitel(text: "Nach Kapitel")
                        VStack(spacing: 10) {
                            ForEach(Array(content.kapitel.enumerated()), id: \.element.id) { index, kapitel in
                                let fragen = content.quiz.filter { $0.kapitel == kapitel.id }
                                if !fragen.isEmpty {
                                    NavigationLink {
                                        QuizView(fragen: fragen, titel: kapitel.titel)
                                    } label: {
                                        ZeilenKachel(titel: kapitel.titel, icon: kapitel.icon, farbe: Stil.farbe(index),
                                                     rechts: "\(progress.beherrscht(fragen))/\(fragen.count)")
                                    }
                                    .buttonStyle(DrueckStil())
                                    .scrollEinblenden()
                                }
                            }
                        }

                        Button(role: .destructive) { resetFragen = true } label: {
                            Label("Lernfortschritt zurücksetzen", systemImage: "arrow.counterclockwise")
                                .foregroundStyle(Stil.koralle)
                        }
                        .buttonStyle(GlasKnopfStil())
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -28)
                    .padding(.bottom, 30)
                }
            }
            .coordinateSpace(name: "scroll")
            .ignoresSafeArea(edges: .top)
            .seitenHintergrund()
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("Gesamten Lernfortschritt löschen?", isPresented: $resetFragen, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) { progress.allesZuruecksetzen() }
            }
        }
    }
}

struct FortschrittKarte: View {
    let beherrscht: Int
    let gesamt: Int
    let karten: Int
    let kartenGesamt: Int

    var body: some View {
        HStack(spacing: 20) {
            Ring(wert: Double(beherrscht) / Double(max(gesamt, 1)))
                .frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(beherrscht) von \(gesamt) Fragen sicher").font(.headline)
                Text("\(karten) von \(kartenGesamt) Karteikarten gewusst")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct Ring: View {
    let wert: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: wert)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((wert * 100).rounded())) %").font(.caption.bold().monospacedDigit())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fortschritt \(Int((wert * 100).rounded())) Prozent")
    }
}

// MARK: - Quiz

struct QuizView: View {
    let titel: String
    let pruefungsModus: Bool
    @EnvironmentObject private var progress: ProgressStore

    @State private var fragen: [QuizFrage]
    @State private var index = 0
    @State private var gewaehlt: Int?
    @State private var punkte = 0
    @State private var fertig = false

    init(fragen: [QuizFrage], titel: String, pruefungsModus: Bool = false) {
        self.titel = titel
        self.pruefungsModus = pruefungsModus
        _fragen = State(initialValue: fragen.shuffled())
    }

    var body: some View {
        Group {
            if fragen.isEmpty {
                Text("Keine Fragen vorhanden.").foregroundStyle(.secondary)
            } else if fertig {
                ergebnis
            } else {
                frageAnsicht(fragen[index])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .seitenHintergrund()
        .navigationTitle(titel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func frageAnsicht(_ frage: QuizFrage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProgressView(value: Double(index), total: Double(fragen.count))
                Text("Frage \(index + 1) von \(fragen.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(frage.frage).font(.title3.bold())

                ForEach(Array(frage.antworten.enumerated()), id: \.offset) { i, antwort in
                    Button {
                        guard gewaehlt == nil else { return }
                        gewaehlt = i
                        let richtig = i == frage.richtig
                        if richtig { punkte += 1 }
                        progress.beantwortet(frage, richtig: richtig)
                    } label: {
                        HStack(alignment: .top) {
                            Text(antwort).multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            if let symbol = symbol(fuer: i, frage: frage) {
                                Image(systemName: symbol)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(hintergrund(fuer: i, frage: frage), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .glas(18, interaktiv: true)
                    }
                    .buttonStyle(DrueckStil())
                    .disabled(gewaehlt != nil)
                }

                if let gewaehlt {
                    if !pruefungsModus {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(gewaehlt == frage.richtig ? "Richtig" : "Leider falsch",
                                  systemImage: gewaehlt == frage.richtig ? "checkmark.seal.fill" : "xmark.octagon.fill")
                                .font(.headline)
                                .foregroundStyle(gewaehlt == frage.richtig ? Color.green : Color.red)
                            Text(frage.erklaerung)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glas(18)
                    }

                    Button {
                        weiter()
                    } label: {
                        Text(index + 1 < fragen.count ? "Weiter" : "Auswertung")
                    }
                    .buttonStyle(PrimaerStil())
                }
            }
            .padding()
        }
    }

    private func symbol(fuer i: Int, frage: QuizFrage) -> String? {
        guard let gewaehlt, !pruefungsModus else { return nil }
        if i == frage.richtig { return "checkmark.circle.fill" }
        if i == gewaehlt { return "xmark.circle.fill" }
        return nil
    }

    private func hintergrund(fuer i: Int, frage: QuizFrage) -> Color {
        guard let gewaehlt else { return Color.clear }
        if pruefungsModus { return i == gewaehlt ? Color.accentColor.opacity(0.18) : .clear }
        if i == frage.richtig { return Color.green.opacity(0.18) }
        if i == gewaehlt { return Color.red.opacity(0.18) }
        return .clear
    }

    private func weiter() {
        if index + 1 < fragen.count {
            index += 1
            gewaehlt = nil
        } else {
            fertig = true
        }
    }

    private var ergebnis: some View {
        let quote = Double(punkte) / Double(max(fragen.count, 1))
        return VStack(spacing: 20) {
            Ring(wert: quote).frame(width: 140, height: 140)
            Text("\(punkte) von \(fragen.count) richtig").font(.title2.bold())
            Text(quote >= 0.8 ? "Sehr gut – bestanden." : quote >= 0.6 ? "Bestanden – einzelne Themen wiederholen." : "Nicht bestanden – Kapitel noch einmal durcharbeiten.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Noch einmal") {
                fragen.shuffle()
                index = 0
                gewaehlt = nil
                punkte = 0
                fertig = false
            }
            .buttonStyle(PrimaerStil())
        }
        .padding()
    }
}

// MARK: - Karteikarten

struct KarteikartenView: View {
    struct Karte: Identifiable, Hashable {
        let id: String
        let vorne: String
        let hinten: String
    }

    @Environment(\.appContent) private var content
    @EnvironmentObject private var progress: ProgressStore
    @State private var stapel: [Karte] = []
    @State private var index = 0
    @State private var umgedreht = false
    @State private var nurUnbekannte = true

    private func baueStapel() {
        let alle = content.glossar.map { Karte(id: "g:" + $0.begriff, vorne: $0.begriff, hinten: $0.erklaerung) }
            + content.normen.map { Karte(id: "n:" + $0.norm, vorne: "\($0.norm)\n\($0.titel)", hinten: "\($0.inhalt)\n\nPraxis: \($0.praxis)") }
        let auswahl = nurUnbekannte ? alle.filter { !progress.gewusst($0.id) } : alle
        stapel = auswahl.shuffled()
        index = 0
        umgedreht = false
    }

    var body: some View {
        VStack(spacing: 16) {
            Toggle("Nur noch nicht gewusste Karten", isOn: $nurUnbekannte)
                .onChange(of: nurUnbekannte) { _ in baueStapel() }

            if stapel.isEmpty {
                Spacer()
                Label("Alle Karten gewusst!", systemImage: "star.fill").font(.title2)
                Button("Alle Karten erneut üben") { nurUnbekannte = false }
                Spacer()
            } else {
                Text("Karte \(index + 1) von \(stapel.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let karte = stapel[index]
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(umgedreht ? Stil.gruen.opacity(0.14) : Color.clear)
                        .glas(28)
                    ScrollView {
                        Text(umgedreht ? karte.hinten : karte.vorne)
                            .font(umgedreht ? Font.body : Font.title2.bold())
                            .multilineTextAlignment(.center)
                            .padding(24)
                            .frame(maxWidth: .infinity)
                    }
                    // Rückseite nicht spiegelverkehrt anzeigen
                    .scaleEffect(x: umgedreht ? -1 : 1, y: 1)
                }
                .frame(maxHeight: .infinity)
                .rotation3DEffect(.degrees(umgedreht ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .onTapGesture {
                    Haptik.tippen()
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { umgedreht.toggle() }
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Tippen zum Umdrehen")

                Text(umgedreht ? "" : "Tippen zum Umdrehen").font(.caption).foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button {
                        progress.setGewusst(karte.id, false)
                        naechste()
                    } label: {
                        Label("Nochmal", systemImage: "arrow.uturn.left")
                            .foregroundStyle(Stil.farbe(3))
                    }
                    .buttonStyle(GlasKnopfStil())

                    Button {
                        progress.setGewusst(karte.id, true)
                        naechste()
                    } label: {
                        Label("Gewusst", systemImage: "checkmark")
                    }
                    .buttonStyle(PrimaerStil())
                }
            }
        }
        .padding()
        .seitenHintergrund()
        .navigationTitle("Karteikarten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if stapel.isEmpty { baueStapel() } }
    }

    private func naechste() {
        umgedreht = false
        if index + 1 < stapel.count {
            index += 1
        } else {
            baueStapel()
        }
    }
}
