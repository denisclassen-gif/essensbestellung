import SwiftUI
import UIKit

// MARK: - Startseite

struct StartView: View {
    @Environment(\.appContent) private var content
    @EnvironmentObject private var fall: FallStore
    @Namespace private var zoom

    private var fallbeispiele: [QuizFrage] { content.quiz.filter { $0.kapitel == "screening" } }
    private let spalten = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ParallaxHero(hoehe: 330) {
                        VStack(alignment: .leading, spacing: 12) {
                            Emblem(groesse: 62)
                            Text("GEAS Hilfe")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Screening · Asyl · Rückführung")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.9))
                            Text("Polizei Sachsen · PD Leipzig · Stand \(content.meta.stand)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        NavigationLink {
                            ScreeningWizardView()
                                .zoomZiel("pruefung", in: zoom)
                        } label: {
                            HauptKarte(
                                icon: "checkmark.shield.fill",
                                farbe: Stil.farbe(0),
                                titel: "Screening-Prüfung",
                                text: "Ist ein Screening durchzuführen? Frage für Frage zum eindeutigen Ergebnis.",
                                knopf: "Prüfung starten"
                            )
                        }
                        .buttonStyle(DrueckStil())
                        .zoomQuelle("pruefung", in: zoom)
                        .scrollEinblenden()

                        NavigationLink {
                            FallUebersichtView()
                                .zoomZiel("fall", in: zoom)
                        } label: {
                            FallKarte()
                        }
                        .buttonStyle(DrueckStil())
                        .zoomQuelle("fall", in: zoom)
                        .scrollEinblenden()

                        Abschnittstitel(text: "Werkzeuge")
                        LazyVGrid(columns: spalten, spacing: 14) {
                            kachel("fristen", "Fristenrechner", "Aufgriffszeit eingeben", "clock.badge.exclamationmark", 3) {
                                ScrollView { FristenrechnerView().padding(20) }
                                    .seitenHintergrund()
                                    .navigationTitle("Fristenrechner")
                            }
                            kachel("checklisten", "Checklisten", "\(content.checklisten.count) Abläufe zum Abhaken", "checklist", 1) {
                                ChecklistenUebersichtView()
                            }
                            kachel("faelle", "Fallbeispiele", "\(fallbeispiele.count) Fälle üben", "person.fill.questionmark", 2) {
                                QuizView(fragen: fallbeispiele, titel: "Fallbeispiele")
                            }
                            kachel("paragraphen", "Paragraphen", "Schnellzugriff", "text.book.closed.fill", 4) {
                                NormenView()
                            }
                            kachel("fristenliste", "Fristen", "Alle Höchstdauern", "hourglass", 5) {
                                FristenView()
                            }
                            if let kapitel = content.kapitel(id: "screening") {
                                kachel("kapitel", "Hintergrund", "Kapitel Screening", "book.fill", 6) {
                                    KapitelDetailView(kapitel: kapitel)
                                }
                            }
                        }

                        Abschnittstitel(text: "So gehst du vor", zusatz: "\(content.screening.kurzanleitung.count) Schritte")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(Array(content.screening.kurzanleitung.enumerated()), id: \.offset) { i, schritt in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("\(i + 1)")
                                            .font(.system(size: 34, weight: .bold, design: .rounded))
                                            .foregroundStyle(Stil.farbe(i))
                                        Text(schritt)
                                            .font(.callout)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(18)
                                    .frame(width: 230, height: 180, alignment: .topLeading)
                                    .glas(24)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, -20)

                        Abschnittstitel(text: "Grundsätze")
                        VStack(spacing: 10) {
                            ForEach(content.screening.grundsaetze, id: \.self) { satz in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(Stil.bernstein)
                                    Text(satz).font(.callout)
                                    Spacer(minLength: 0)
                                }
                                .padding(14)
                                .glas(18)
                                .scrollEinblenden()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -30)
                    .padding(.bottom, 30)
                }
            }
            .coordinateSpace(name: "scroll")
            .ignoresSafeArea(edges: .top)
            .seitenHintergrund()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func kachel<Ziel: View>(_ id: String, _ titel: String, _ untertitel: String, _ icon: String, _ farbe: Int,
                                    @ViewBuilder ziel: @escaping () -> Ziel) -> some View {
        NavigationLink {
            ziel().zoomZiel(id, in: zoom)
        } label: {
            Kachel(titel: titel, untertitel: untertitel, icon: icon, farbe: Stil.farbe(farbe))
        }
        .buttonStyle(DrueckStil())
        .zoomQuelle(id, in: zoom)
        .scrollEinblenden()
    }
}

/// Große Karte mit Aufforderung (Airbnb-artige Hero-Karte).
struct HauptKarte: View {
    let icon: String
    let farbe: Color
    let titel: String
    let text: String
    let knopf: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                IconPlakette(icon: icon, farbe: farbe, groesse: 54)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .glas(20)
            }
            Text(titel).font(.title2.bold()).foregroundStyle(.primary)
            Text(text).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.leading)
            HStack {
                Text(knopf).font(.headline)
                Spacer()
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LinearGradient(colors: [farbe, farbe.opacity(0.75)], startPoint: .leading, endPoint: .trailing)))
            .shadow(color: farbe.opacity(0.35), radius: 10, y: 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glas(28, interaktiv: true)
    }
}

/// Status des aktuellen Falls auf der Startseite.
struct FallKarte: View {
    @Environment(\.appContent) private var content
    @EnvironmentObject private var fall: FallStore

    var body: some View {
        let schritte = content.fall.schritte
        let fertig = schritte.filter { fall.offenePflichtfelder(in: $0).isEmpty }.count
        HStack(spacing: 16) {
            IconPlakette(icon: "doc.richtext.fill", farbe: Stil.farbe(2), groesse: 54)
            VStack(alignment: .leading, spacing: 5) {
                Text("Unterlagen-Assistent").font(.title3.bold()).foregroundStyle(.primary)
                if fall.aktiv {
                    let name = [fall.wert("name"), fall.wert("vorname")].filter { !$0.isEmpty }.joined(separator: ", ")
                    Text(name.isEmpty ? "Aktueller Fall" : name).font(.callout).foregroundStyle(.secondary)
                    Fortschrittsbalken(wert: Double(fertig) / Double(max(schritte.count, 1)), farbe: Stil.farbe(2))
                    Text("\(fertig) von \(schritte.count) Schritten vollständig").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Fall anlegen – die App erstellt alle Unterlagen als PDF.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(20)
        .glas(28, interaktiv: true)
    }
}

// MARK: - Geführte Prüfung

struct ScreeningWizardView: View {
    private struct Schritt: Hashable {
        let knotenID: String
        let antwort: Int
    }

    @Environment(\.appContent) private var content
    @State private var verlauf: [Schritt] = []
    @State private var aktuell: String?
    @State private var vorwaerts = true

    private var pruefung: ScreeningPruefung { content.screening }
    private var knotenID: String { aktuell ?? pruefung.start }

    /// Längster möglicher Pfad – für die Fortschrittsanzeige.
    private var maxFragen: Int {
        func tiefe(_ id: String) -> Int {
            guard let k = pruefung.knoten[id], k.istFrage else { return 0 }
            return 1 + ((k.antworten ?? []).map { tiefe($0.ziel) }.max() ?? 0)
        }
        return max(tiefe(pruefung.start), 1)
    }

    private var uebergang: AnyTransition {
        .asymmetric(
            insertion: .move(edge: vorwaerts ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: vorwaerts ? .leading : .trailing).combined(with: .opacity)
        )
    }

    var body: some View {
        ZStack {
            if let knoten = pruefung.knoten[knotenID] {
                Group {
                    if knoten.istFrage {
                        frageAnsicht(knoten)
                    } else {
                        ScreeningErgebnisView(knoten: knoten, protokoll: protokoll(ergebnis: knoten), neuStarten: neuStarten)
                    }
                }
                .id(knotenID)
                .transition(uebergang)
            }
        }
        .seitenHintergrund()
        .navigationTitle("Screening-Prüfung")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !verlauf.isEmpty {
                HStack(spacing: 12) {
                    Button { zurueck() } label: {
                        Label("Zurück", systemImage: "chevron.backward")
                    }
                    .buttonStyle(GlasKnopfStil())
                    Button(role: .destructive) { neuStarten() } label: {
                        Label("Neu", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(GlasKnopfStil())
                    .foregroundStyle(Stil.koralle)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            }
        }
    }

    private func frageAnsicht(_ knoten: ScreeningKnoten) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Fortschrittsbalken(wert: Double(verlauf.count) / Double(maxFragen))
                    HStack(spacing: 8) {
                        Text("Frage \(verlauf.count + 1)")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Stil.gruen.opacity(0.15)))
                            .foregroundStyle(Stil.gruen)
                        if let schritt = knoten.schritt {
                            Text(schritt).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                        }
                    }
                }

                Text(knoten.frage ?? "")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)

                if let hilfe = knoten.hilfe {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill").foregroundStyle(Stil.farbe(4)).font(.title3)
                        Text(RichText.markdown(hilfe)).font(.callout)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glas(20)
                }

                if let beispiele = knoten.beispiele, !beispiele.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BEISPIELE").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        ForEach(beispiele, id: \.self) { beispiel in
                            Text("• " + beispiel).font(.callout).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                VStack(spacing: 12) {
                    ForEach(Array((knoten.antworten ?? []).enumerated()), id: \.offset) { index, antwort in
                        Button {
                            Haptik.tippen()
                            waehle(index, antwort: antwort)
                        } label: {
                            HStack(spacing: 14) {
                                Text(antwort.text)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Stil.gruen)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
                            .glas(22, interaktiv: true)
                        }
                        .buttonStyle(DrueckStil())
                    }
                }
            }
            .padding(20)
        }
    }

    private func waehle(_ index: Int, antwort: ScreeningKnoten.Antwort) {
        verlauf.append(Schritt(knotenID: knotenID, antwort: index))
        vorwaerts = true
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { aktuell = antwort.ziel }
        if pruefung.knoten[antwort.ziel]?.istFrage == false { Haptik.erfolg() }
    }

    private func zurueck() {
        guard let letzter = verlauf.popLast() else { return }
        vorwaerts = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { aktuell = letzter.knotenID }
    }

    private func neuStarten() {
        verlauf = []
        vorwaerts = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { aktuell = nil }
    }

    private func protokoll(ergebnis: ScreeningKnoten) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy, HH:mm 'Uhr'"
        var zeilen = ["Screening-Prüfung – Prüfprotokoll", "Erstellt: \(formatter.string(from: Date()))", ""]
        for (i, schritt) in verlauf.enumerated() {
            guard let k = pruefung.knoten[schritt.knotenID], let antworten = k.antworten,
                  antworten.indices.contains(schritt.antwort) else { continue }
            zeilen.append("\(i + 1). \(k.frage ?? "")")
            zeilen.append("   Antwort: \(antworten[schritt.antwort].text)")
        }
        zeilen.append("")
        zeilen.append("Ergebnis: \(ergebnis.titel ?? "")")
        if let rg = ergebnis.rechtsgrundlage { zeilen.append("Rechtsgrundlage: \(rg)") }
        zeilen.append("")
        zeilen.append("Erstellt mit GEAS Hilfe (inoffizielle Arbeitshilfe). Enthält keine personenbezogenen Daten.")
        return zeilen.joined(separator: "\n")
    }
}

// MARK: - Ergebnis

struct ScreeningErgebnisView: View {
    let knoten: ScreeningKnoten
    let protokoll: String
    let neuStarten: () -> Void

    @Environment(\.appContent) private var content
    @State private var erledigt: Set<Int> = []
    @State private var kopiert = false
    @State private var erschienen = false

    private var farbe: Color {
        switch knoten.ergebnis {
        case .screening: return Stil.koralle
        case .kein: return Stil.farbe(0)
        default: return Stil.farbe(4)
        }
    }

    private var symbol: String {
        switch knoten.ergebnis {
        case .screening: return "exclamationmark.shield.fill"
        case .kein: return "checkmark.shield.fill"
        default: return "info.circle.fill"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Ergebnis-Banner
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: symbol)
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(.white)
                        .scaleEffect(erschienen ? 1 : 0.4)
                        .opacity(erschienen ? 1 : 0)
                    Text(knoten.titel ?? "")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(knoten.kurz ?? "")
                        .foregroundStyle(.white.opacity(0.92))
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(colors: [farbe, farbe.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .shadow(color: farbe.opacity(0.35), radius: 18, y: 10)

                if knoten.ergebnis == .screening {
                    NavigationLink {
                        FallUebersichtView()
                    } label: {
                        Label("Unterlagen-Assistent starten", systemImage: "doc.richtext.fill")
                    }
                    .buttonStyle(PrimaerStil(farbe: Stil.gruen))
                }

                if let schritte = knoten.schritte, !schritte.isEmpty {
                    Abschnittstitel(text: "Das musst du jetzt tun", zusatz: "\(erledigt.count)/\(schritte.count)")
                    VStack(spacing: 10) {
                        ForEach(Array(schritte.enumerated()), id: \.offset) { i, schritt in
                            Button {
                                Haptik.tippen()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if erledigt.contains(i) { erledigt.remove(i) } else { erledigt.insert(i) }
                                }
                            } label: {
                                HStack(alignment: .top, spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(erledigt.contains(i) ? AnyShapeStyle(Stil.akzentVerlauf) : AnyShapeStyle(Color.primary.opacity(0.07)))
                                            .frame(width: 32, height: 32)
                                        if erledigt.contains(i) {
                                            Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(.white)
                                                .transition(.scale.combined(with: .opacity))
                                        } else {
                                            Text("\(i + 1)").font(.footnote.weight(.bold)).foregroundStyle(Stil.gruen)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(schritt.text)
                                            .foregroundStyle(erledigt.contains(i) ? .secondary : .primary)
                                            .strikethrough(erledigt.contains(i), color: .secondary)
                                            .multilineTextAlignment(.leading)
                                        if let hinweis = schritt.hinweis {
                                            Text(hinweis).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(14)
                                .glas(20, interaktiv: true)
                            }
                            .buttonStyle(DrueckStil())
                        }
                    }
                }

                if knoten.fristen == true {
                    Abschnittstitel(text: "Fristen")
                    FristenrechnerView()
                }

                if let rg = knoten.rechtsgrundlage {
                    Label(rg, systemImage: "text.book.closed")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Abschnittstitel(text: "Prüfprotokoll")
                VStack(alignment: .leading, spacing: 12) {
                    Text(protokoll)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                    HStack(spacing: 10) {
                        Button {
                            UIPasteboard.general.string = protokoll
                            Haptik.erfolg()
                            withAnimation { kopiert = true }
                        } label: {
                            Label(kopiert ? "Kopiert" : "Kopieren", systemImage: kopiert ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(GlasKnopfStil())
                        ShareLink(item: protokoll) {
                            Label("Teilen", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(GlasKnopfStil())
                    }
                }
                .padding(16)
                .glas(22)

                if knoten.ergebnis == .screening,
                   let liste = content.checklisten.first(where: { $0.id == "screening-inland" }) {
                    NavigationLink {
                        ChecklistenView(liste: liste)
                    } label: {
                        Label("Checkliste „Screening durchführen“", systemImage: "checklist")
                    }
                    .buttonStyle(GlasKnopfStil())
                }

                Button(action: neuStarten) {
                    Label("Neue Prüfung starten", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(GlasKnopfStil())
            }
            .padding(20)
            .padding(.bottom, 70)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.15)) { erschienen = true }
        }
    }
}

// MARK: - Fristenrechner

struct FristenrechnerView: View {
    @State private var aufgriff = Date()

    private static let format: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEEE, dd.MM.yyyy, HH:mm 'Uhr'"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DatePicker("Aufgriff", selection: $aufgriff)
                .environment(\.locale, Locale(identifier: "de_DE"))
                .font(.headline)

            fristZeile(
                titel: "Richterliche Entscheidung spätestens",
                datum: FallStore.richterFrist(ab: aufgriff),
                erklaerung: "Nur wenn die Person festgehalten wird. Ohne Entscheidung bis dahin: freilassen.",
                icon: "building.columns.fill",
                farbe: Stil.koralle
            )
            fristZeile(
                titel: "Screening abgeschlossen spätestens",
                datum: FallStore.screeningFrist(ab: aufgriff),
                erklaerung: "Höchstdauer des Screenings im Inland: 3 Tage.",
                icon: "hourglass",
                farbe: Stil.farbe(3)
            )
            Text("Hilfsrechnung ohne Gewähr. Im Zweifel gilt die frühere Frist; mit der Dienstgruppenleitung abstimmen.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .glas(24)
    }

    private func fristZeile(titel: String, datum: Date, erklaerung: String, icon: String, farbe: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            IconPlakette(icon: icon, farbe: farbe, groesse: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(titel).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                Text(Self.format.string(from: datum))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(farbe)
                    .contentTransition(.numericText())
                    .animation(.spring(), value: datum)
                Text(erklaerung).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
