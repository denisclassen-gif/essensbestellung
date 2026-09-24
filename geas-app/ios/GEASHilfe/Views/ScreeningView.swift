import SwiftUI
import UIKit

// MARK: - Startseite des Reiters „Screening“

struct ScreeningView: View {
    @Environment(\.appContent) private var content

    private var fallbeispiele: [QuizFrage] { content.quiz.filter { $0.kapitel == "screening" } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Ist ein Screening durchzuführen?", systemImage: "checkmark.shield.fill")
                            .font(.title3.bold())
                            .foregroundStyle(.tint)
                        Text("Beantworte einfach eine Frage nach der anderen. Am Ende steht eindeutig, ob du ein Screening durchführen musst – und was du jetzt tun musst.")
                            .font(.callout)
                        NavigationLink {
                            ScreeningWizardView()
                        } label: {
                            Label("Prüfung starten", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.vertical, 6)
                }

                Section("So gehst du vor") {
                    ForEach(Array(content.screening.kurzanleitung.enumerated()), id: \.offset) { i, schritt in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("\(i + 1)")
                                .font(.headline.monospacedDigit())
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.accentColor.opacity(0.15)))
                                .foregroundStyle(.tint)
                            Text(schritt)
                        }
                    }
                }

                Section("Werkzeuge") {
                    NavigationLink {
                        ScrollView { FristenrechnerView().padding() }
                            .navigationTitle("Fristenrechner")
                    } label: {
                        Label("Fristenrechner (Aufgriffszeit eingeben)", systemImage: "clock.badge.exclamationmark")
                    }
                    if let liste = content.checklisten.first(where: { $0.id == "screening-inland" }) {
                        NavigationLink {
                            ChecklistenView(liste: liste)
                        } label: {
                            Label("Checkliste: Screening durchführen", systemImage: "checklist")
                        }
                    }
                    if !fallbeispiele.isEmpty {
                        NavigationLink {
                            QuizView(fragen: fallbeispiele, titel: "Fallbeispiele Screening")
                        } label: {
                            Label("\(fallbeispiele.count) Fallbeispiele üben", systemImage: "person.fill.questionmark")
                        }
                    }
                    if let kapitel = content.kapitel(id: "screening") {
                        NavigationLink {
                            KapitelDetailView(kapitel: kapitel)
                        } label: {
                            Label("Hintergrund: Kapitel Screening", systemImage: "book")
                        }
                    }
                }

                Section("Grundsätze") {
                    ForEach(content.screening.grundsaetze, id: \.self) { satz in
                        Label(satz, systemImage: "exclamationmark.circle")
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Screening")
        }
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

    private var pruefung: ScreeningPruefung { content.screening }
    private var knotenID: String { aktuell ?? pruefung.start }

    var body: some View {
        Group {
            if let knoten = pruefung.knoten[knotenID] {
                if knoten.istFrage {
                    frageAnsicht(knoten)
                } else {
                    ScreeningErgebnisView(knoten: knoten, protokoll: protokoll(ergebnis: knoten), neuStarten: neuStarten)
                        .id(knotenID)
                }
            } else {
                Text("Prüfung nicht verfügbar.").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Screening-Prüfung")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !verlauf.isEmpty {
                HStack {
                    Button {
                        zurueck()
                    } label: {
                        Label("Vorherige Frage", systemImage: "chevron.backward")
                    }
                    Spacer()
                    Button(role: .destructive) {
                        neuStarten()
                    } label: {
                        Label("Neu starten", systemImage: "arrow.counterclockwise")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }
        }
    }

    private func frageAnsicht(_ knoten: ScreeningKnoten) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Frage \(verlauf.count + 1)")
                    if let schritt = knoten.schritt {
                        Text("·")
                        Text(schritt)
                    }
                }
                .font(.subheadline.bold())
                .foregroundStyle(.tint)

                Text(knoten.frage ?? "")
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)

                if let hilfe = knoten.hilfe {
                    Label {
                        Text(RichText.markdown(hilfe))
                    } icon: {
                        Image(systemName: "info.circle.fill")
                    }
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }

                if let beispiele = knoten.beispiele, !beispiele.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Beispiele").font(.caption.bold()).foregroundStyle(.secondary)
                        ForEach(beispiele, id: \.self) { beispiel in
                            Text("• " + beispiel).font(.callout).foregroundStyle(.secondary)
                        }
                    }
                }

                VStack(spacing: 12) {
                    ForEach(Array((knoten.antworten ?? []).enumerated()), id: \.offset) { index, antwort in
                        Button {
                            waehle(index, antwort: antwort)
                        } label: {
                            HStack {
                                Text(antwort.text)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right")
                            }
                            .padding(.vertical, 18)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                            .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentColor.opacity(0.5)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            .padding()
        }
    }

    private func waehle(_ index: Int, antwort: ScreeningKnoten.Antwort) {
        verlauf.append(Schritt(knotenID: knotenID, antwort: index))
        withAnimation { aktuell = antwort.ziel }
    }

    private func zurueck() {
        guard let letzter = verlauf.popLast() else { return }
        withAnimation { aktuell = letzter.knotenID }
    }

    private func neuStarten() {
        verlauf = []
        withAnimation { aktuell = nil }
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

    private var farbe: Color {
        switch knoten.ergebnis {
        case .screening: return .orange
        case .kein: return .green
        default: return .blue
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
                VStack(alignment: .leading, spacing: 10) {
                    Label(knoten.titel ?? "", systemImage: symbol)
                        .font(.title.bold())
                        .foregroundStyle(farbe)
                    Text(knoten.kurz ?? "")
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(farbe.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(farbe.opacity(0.6), lineWidth: 2))

                if let schritte = knoten.schritte, !schritte.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Das musst du jetzt tun").font(.title3.bold())
                        Text("Punkt für Punkt abhaken.").font(.caption).foregroundStyle(.secondary)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(schritte.enumerated()), id: \.offset) { i, schritt in
                            Button {
                                if erledigt.contains(i) { erledigt.remove(i) } else { erledigt.insert(i) }
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: erledigt.contains(i) ? "checkmark.square.fill" : "\(i + 1).square")
                                        .font(.title2)
                                        .foregroundStyle(erledigt.contains(i) ? Color.green : Color.accentColor)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(schritt.text)
                                            .foregroundStyle(.primary)
                                            .strikethrough(erledigt.contains(i), color: .secondary)
                                            .multilineTextAlignment(.leading)
                                        if let hinweis = schritt.hinweis {
                                            Text(hinweis).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                }

                if knoten.fristen == true {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fristen").font(.title3.bold())
                        FristenrechnerView()
                    }
                }

                if let rg = knoten.rechtsgrundlage {
                    Label(rg, systemImage: "text.book.closed")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Prüfprotokoll").font(.title3.bold())
                    Text("Für die Vorgangsdokumentation kopieren oder teilen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(protokoll)
                        .font(.footnote.monospaced())
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        .textSelection(.enabled)
                    HStack {
                        Button {
                            UIPasteboard.general.string = protokoll
                            kopiert = true
                        } label: {
                            Label(kopiert ? "Kopiert" : "Kopieren", systemImage: kopiert ? "checkmark" : "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        ShareLink(item: protokoll) {
                            Label("Teilen", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if knoten.ergebnis == .screening,
                   let liste = content.checklisten.first(where: { $0.id == "screening-inland" }) {
                    NavigationLink {
                        ChecklistenView(liste: liste)
                    } label: {
                        Label("Zur Checkliste „Screening durchführen“", systemImage: "checklist")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button(action: neuStarten) {
                    Label("Neue Prüfung starten", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .padding(.bottom, 40)
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

    /// Ende des Tages nach dem Ergreifen (23:59 Uhr des Folgetages).
    private var richterBis: Date {
        let cal = Calendar(identifier: .gregorian)
        let tagesbeginn = cal.startOfDay(for: aufgriff)
        let uebermorgen = cal.date(byAdding: .day, value: 2, to: tagesbeginn) ?? aufgriff
        return uebermorgen.addingTimeInterval(-60)
    }

    private var screeningBis: Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: 3, to: aufgriff) ?? aufgriff
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DatePicker("Aufgriff", selection: $aufgriff)
                .environment(\.locale, Locale(identifier: "de_DE"))
                .font(.headline)

            fristZeile(
                titel: "Richterliche Entscheidung spätestens",
                datum: richterBis,
                erklaerung: "Nur wenn die Person festgehalten wird. Ohne Entscheidung bis dahin: freilassen.",
                farbe: .red
            )
            fristZeile(
                titel: "Screening abgeschlossen spätestens",
                datum: screeningBis,
                erklaerung: "Höchstdauer des Screenings im Inland: 3 Tage.",
                farbe: .orange
            )
            Text("Hilfsrechnung ohne Gewähr. Im Zweifel gilt die frühere Frist; mit der Dienstgruppenleitung abstimmen.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func fristZeile(titel: String, datum: Date, erklaerung: String, farbe: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel).font(.subheadline.bold())
            Text(Self.format.string(from: datum))
                .font(.title3.bold())
                .foregroundStyle(farbe)
            Text(erklaerung).font(.caption).foregroundStyle(.secondary)
        }
    }
}
