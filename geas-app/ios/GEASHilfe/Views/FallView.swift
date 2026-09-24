import PDFKit
import SwiftUI
import UIKit

/// Reiter „Unterlagen“.
struct FallView: View {
    var body: some View {
        NavigationStack {
            FallUebersichtView()
        }
    }
}

// MARK: - Übersicht

struct FallUebersichtView: View {
    @Environment(\.appContent) private var content
    @EnvironmentObject private var fall: FallStore
    @Namespace private var zoom
    @State private var loeschenFragen = false
    @State private var erfassung: Int?
    @State private var alle: Bool = false

    private var vorlage: FallVorlage { content.fall }
    private var relevanteDokumente: [DokumentVorlage] { content.dokumente.filter { fall.relevant($0) } }
    private let spalten = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            if fall.aktiv {
                aktiverFall
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                leererZustand
                    .transition(.opacity)
            }
        }
        .seitenHintergrund()
        .navigationTitle("Unterlagen")
        .toolbar {
            if fall.aktiv {
                Menu {
                    Button(role: .destructive) { loeschenFragen = true } label: {
                        Label("Fall löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Weitere Aktionen")
            }
        }
        .confirmationDialog("Fall und alle Daten endgültig löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                Haptik.warnung()
                withAnimation(.spring()) { fall.loeschen() }
            }
        } message: {
            Text("Vorher die Unterlagen in das Vorgangsbearbeitungssystem übernehmen.")
        }
        .navigationDestination(isPresented: Binding(get: { erfassung != nil }, set: { if !$0 { erfassung = nil } })) {
            FallErfassungView(start: erfassung ?? 0)
        }
        .navigationDestination(isPresented: $alle) {
            DokumentVorschauView(dokumente: relevanteDokumente, titel: "Alle Unterlagen")
        }
    }

    // MARK: Kein Fall

    private var leererZustand: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 14) {
                IconPlakette(icon: "doc.richtext.fill", farbe: Stil.farbe(2), groesse: 64)
                Text("Unterlagen-Assistent")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Die App führt dich durch alle Angaben des Screenings und erstellt daraus automatisch die Unterlagen – fertig zum Drucken oder Teilen.")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                schrittErklaerung(1, "Fall anlegen", "Die Aufgriffszeit wird automatisch gesetzt.", "plus.circle.fill")
                schrittErklaerung(2, "Schritt für Schritt erfassen", "\(vorlage.schritte.count) kurze Schritte, Pflichtfelder sind markiert.", "list.bullet.rectangle.portrait.fill")
                schrittErklaerung(3, "Unterlagen erzeugen", "\(content.dokumente.count) Dokumente als PDF – nur die, die im Fall nötig sind.", "doc.on.doc.fill")
            }

            Button {
                Haptik.erfolg()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { fall.neuerFall() }
                erfassung = 0
            } label: {
                Label("Neuen Fall anlegen", systemImage: "plus")
            }
            .buttonStyle(PrimaerStil())

            datenschutz
        }
        .padding(20)
    }

    private func schrittErklaerung(_ nr: Int, _ titel: String, _ text: String, _ icon: String) -> some View {
        HStack(spacing: 14) {
            IconPlakette(icon: icon, farbe: Stil.farbe(nr), groesse: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.headline)
                Text(text).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .glas(20)
        .scrollEinblenden()
    }

    private var datenschutz: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill").foregroundStyle(Stil.gruen).font(.title3)
            Text(vorlage.hinweis).font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .glas(20)
    }

    // MARK: Aktiver Fall

    private var aktiverFall: some View {
        let schritte = vorlage.schritte
        let fertig = schritte.filter { fall.offenePflichtfelder(in: $0).isEmpty }.count
        return VStack(alignment: .leading, spacing: 18) {
            kopfkarte(fertig: fertig, gesamt: schritte.count)
            if let aufgriff = fall.aufgriff { fristenKarte(aufgriff) }

            Abschnittstitel(text: "Erfassung", zusatz: "\(fertig)/\(schritte.count) vollständig")
            VStack(spacing: 10) {
                ForEach(Array(schritte.enumerated()), id: \.element.id) { index, schritt in
                    let offen = fall.offenePflichtfelder(in: schritt).count
                    Button {
                        Haptik.tippen()
                        erfassung = index
                    } label: {
                        ZeilenKachel(
                            titel: "\(index + 1). \(schritt.titel)",
                            untertitel: offen == 0 ? "Vollständig" : "\(offen) Pflichtangabe\(offen == 1 ? "" : "n") offen",
                            icon: offen == 0 ? "checkmark" : schritt.icon,
                            farbe: offen == 0 ? Stil.farbe(0) : Stil.farbe(index + 1)
                        )
                    }
                    .buttonStyle(DrueckStil())
                    .scrollEinblenden()
                }
            }

            Abschnittstitel(text: "Unterlagen", zusatz: "\(relevanteDokumente.count) Dokumente")
            LazyVGrid(columns: spalten, spacing: 14) {
                ForEach(Array(relevanteDokumente.enumerated()), id: \.element.id) { index, dok in
                    let offen = fall.offenePflichtfelder(fuer: dok, vorlage: vorlage).count
                    NavigationLink {
                        DokumentVorschauView(dokumente: [dok], titel: dok.titel)
                            .zoomZiel(dok.id, in: zoom)
                    } label: {
                        Kachel(
                            titel: dok.titel,
                            untertitel: dok.untertitel,
                            icon: dok.icon,
                            farbe: Stil.farbe(index + 2),
                            plakette: offen == 0 ? "Bereit" : "\(offen) offen",
                            hoehe: 150
                        )
                    }
                    .buttonStyle(DrueckStil())
                    .zoomQuelle(dok.id, in: zoom)
                    .scrollEinblenden()
                }
            }

            Button {
                Haptik.tippen()
                alle = true
            } label: {
                Label("Alle Unterlagen als ein PDF", systemImage: "doc.on.doc.fill")
            }
            .buttonStyle(PrimaerStil(farbe: Stil.farbe(2)))

            Button(role: .destructive) {
                loeschenFragen = true
            } label: {
                Label("Fall abschließen und löschen", systemImage: "trash")
                    .foregroundStyle(Stil.koralle)
            }
            .buttonStyle(GlasKnopfStil())

            datenschutz
        }
        .padding(20)
    }

    private func kopfkarte(fertig: Int, gesamt: Int) -> some View {
        let name = [fall.wert("name"), fall.wert("vorname")].filter { !$0.isEmpty }.joined(separator: ", ")
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Neuer Fall" : name)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Text(fall.wert("vorgang").isEmpty ? "Vorgangsnummer noch offen" : "Vorgang \(fall.wert("vorgang"))")
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Emblem(groesse: 40)
            }
            ProgressView(value: Double(fertig), total: Double(max(gesamt, 1)))
                .tint(.white)
            HStack {
                Text("\(fertig) von \(gesamt) Schritten vollständig")
                Spacer()
                if let loescht = fall.loeschtAm {
                    Label(loescht.formatted(.dateTime.day().month().hour().minute()), systemImage: "trash.circle")
                        .accessibilityLabel("Automatische Löschung am \(loescht.formatted())")
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.85))

            Button {
                Haptik.tippen()
                erfassung = vorlage.schritte.firstIndex { !fall.offenePflichtfelder(in: $0).isEmpty } ?? 0
            } label: {
                Label(fertig == gesamt ? "Angaben prüfen" : "Weiter erfassen", systemImage: "square.and.pencil")
                    .font(.headline)
                    .foregroundStyle(Stil.tiefgruen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
            }
            .buttonStyle(DrueckStil())
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Stil.heroVerlauf))
        .shadow(color: Stil.tiefgruen.opacity(0.35), radius: 18, y: 10)
    }

    private func fristenKarte(_ aufgriff: Date) -> some View {
        let richter = FallStore.richterFrist(ab: aufgriff)
        let ende = FallStore.screeningFrist(ab: aufgriff)
        let festgehalten = fall.wert("festgehalten") == "Ja"
        return HStack(spacing: 12) {
            fristBlock("Richter bis", festgehalten ? richter : nil, festgehalten ? "" : "nur bei Festhalten", Stil.koralle)
            fristBlock("Screening bis", ende, "", Stil.farbe(3))
        }
    }

    private func fristBlock(_ titel: String, _ datum: Date?, _ ersatz: String, _ farbe: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            if let datum {
                Text(datum.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute()))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(farbe)
                Text(datum, style: .relative).font(.caption2).foregroundStyle(.secondary)
            } else {
                Text(ersatz).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glas(20)
    }
}

// MARK: - Erfassung

struct FallErfassungView: View {
    let start: Int

    @Environment(\.appContent) private var content
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var fall: FallStore
    @State private var index = 0
    @State private var vorwaerts = true
    @State private var gestartet = false

    private var schritte: [FallSchritt] { content.fall.schritte }

    var body: some View {
        VStack(spacing: 0) {
            // Schrittanzeige
            VStack(spacing: 10) {
                Fortschrittsbalken(wert: Double(index + 1) / Double(max(schritte.count, 1)))
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(schritte.enumerated()), id: \.element.id) { i, s in
                                let fertig = fall.offenePflichtfelder(in: s).isEmpty
                                Button {
                                    gehe(zu: i)
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: fertig ? "checkmark.circle.fill" : s.icon)
                                        Text(s.titel)
                                    }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(i == index ? Color.white : (fertig ? Stil.gruen : Color.primary))
                                    .background(
                                        Capsule().fill(i == index ? AnyShapeStyle(Stil.akzentVerlauf) : AnyShapeStyle(.ultraThinMaterial))
                                    )
                                }
                                .buttonStyle(DrueckStil())
                                .id(i)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .onChange(of: index) { neu in
                        withAnimation { proxy.scrollTo(neu, anchor: .center) }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 10)

            ZStack {
                if schritte.indices.contains(index) {
                    schrittAnsicht(schritte[index])
                        .id(index)
                        .transition(.asymmetric(
                            insertion: .move(edge: vorwaerts ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: vorwaerts ? .leading : .trailing).combined(with: .opacity)
                        ))
                }
            }
            .frame(maxHeight: .infinity)
        }
        .seitenHintergrund()
        .navigationTitle("Schritt \(index + 1) von \(schritte.count)")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                if index > 0 {
                    Button { gehe(zu: index - 1) } label: {
                        Label("Zurück", systemImage: "chevron.backward")
                    }
                    .buttonStyle(GlasKnopfStil())
                    .frame(maxWidth: 140)
                }
                if index < schritte.count - 1 {
                    Button { gehe(zu: index + 1) } label: {
                        Label("Weiter", systemImage: "chevron.forward")
                    }
                    .buttonStyle(PrimaerStil())
                } else {
                    Button {
                        Haptik.erfolg()
                        dismiss()
                    } label: {
                        Label("Fertig – zu den Unterlagen", systemImage: "doc.richtext")
                    }
                    .buttonStyle(PrimaerStil(farbe: Stil.farbe(2)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .onAppear {
            if !gestartet {
                index = min(start, max(schritte.count - 1, 0))
                gestartet = true
            }
        }
    }

    private func gehe(zu ziel: Int) {
        guard ziel != index, schritte.indices.contains(ziel) else { return }
        Haptik.tippen()
        vorwaerts = ziel > index
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) { index = ziel }
    }

    private func schrittAnsicht(_ schritt: FallSchritt) -> some View {
        let offen = fall.offenePflichtfelder(in: schritt).count
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    IconPlakette(icon: schritt.icon, farbe: Stil.farbe(index + 1), groesse: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(schritt.titel).font(.system(.title, design: .rounded).weight(.bold))
                        Text(offen == 0 ? "Alle Pflichtangaben erfasst" : "\(offen) Pflichtangabe\(offen == 1 ? "" : "n") offen")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(offen == 0 ? Stil.gruen : Stil.koralle)
                            .contentTransition(.opacity)
                    }
                }
                Text(schritt.beschreibung).font(.callout).foregroundStyle(.secondary)

                ForEach(schritt.felder) { feld in
                    if fall.sichtbar(feld) {
                        FeldEingabe(feld: feld)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: fall.werte)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

/// Eingabe für ein einzelnes Feld – je nach Typ Textfeld, Datum oder Auswahl-Chips.
struct FeldEingabe: View {
    let feld: FallFeld
    @EnvironmentObject private var fall: FallStore

    var body: some View {
        switch feld.typ {
        case .text, .mehrzeilig:
            SchwebeFeld(
                label: feld.label,
                text: fall.binding(feld.id),
                platzhalter: feld.platzhalter,
                mehrzeilig: feld.typ == .mehrzeilig,
                pflicht: feld.istPflicht,
                hinweis: feld.hinweis
            )
        case .datumzeit:
            datumFeld
        case .auswahl, .mehrfach:
            auswahlFeld
        }
    }

    private var kopf: some View {
        HStack(spacing: 6) {
            Text(feld.label).font(.subheadline.weight(.semibold))
            if feld.istPflicht {
                let leer = fall.wert(feld.id).isEmpty
                Text("Pflicht")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill((leer ? Stil.koralle : Stil.gruen).opacity(0.15)))
                    .foregroundStyle(leer ? Stil.koralle : Stil.gruen)
            }
            if feld.typ == .mehrfach {
                Text("Mehrfachauswahl").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var datumFeld: some View {
        let gesetzt = FallStore.datum(aus: fall.wert(feld.id))
        return VStack(alignment: .leading, spacing: 10) {
            kopf
            if let gesetzt {
                HStack {
                    DatePicker("", selection: Binding(
                        get: { gesetzt },
                        set: { fall.setze(feld.id, FallStore.isoString($0)) }
                    ))
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "de_DE"))
                    Spacer()
                    Button {
                        Haptik.tippen()
                        withAnimation { fall.setze(feld.id, "") }
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Zeit entfernen")
                }
            } else {
                Button {
                    Haptik.tippen()
                    withAnimation(.spring()) { fall.setze(feld.id, FallStore.isoString(Date())) }
                } label: {
                    Label("Jetzt eintragen", systemImage: "clock.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Stil.gruen.opacity(0.14)))
                        .foregroundStyle(Stil.gruen)
                }
                .buttonStyle(DrueckStil())
            }
            if let hinweis = feld.hinweis {
                Label(hinweis, systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glas(18)
    }

    private var auswahlFeld: some View {
        let gewaehlt = fall.auswahl(feld.id)
        return VStack(alignment: .leading, spacing: 10) {
            kopf
            FlussLayout(abstand: 8) {
                ForEach(feld.optionen ?? [], id: \.self) { option in
                    Chip(text: option, gewaehlt: gewaehlt.contains(option)) {
                        if feld.typ == .mehrfach {
                            fall.umschalten(feld.id, option)
                        } else {
                            fall.setze(feld.id, gewaehlt.contains(option) ? "" : option)
                        }
                    }
                }
            }
            if let hinweis = feld.hinweis {
                Label(hinweis, systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glas(18)
    }
}

// MARK: - Dokumentvorschau

struct DokumentVorschauView: View {
    let dokumente: [DokumentVorlage]
    let titel: String

    @Environment(\.appContent) private var content
    @EnvironmentObject private var fall: FallStore
    @State private var pdf: Data?
    @State private var datei: URL?

    private var offene: [FallFeld] {
        var gesehen = Set<String>()
        return dokumente.flatMap { fall.offenePflichtfelder(fuer: $0, vorlage: content.fall) }
            .filter { gesehen.insert($0.id).inserted }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !offene.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Stil.bernstein)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(offene.count) Pflichtangabe\(offene.count == 1 ? "" : "n") fehlen noch").font(.subheadline.weight(.semibold))
                        Text(offene.prefix(4).map(\.label).joined(separator: " · ") + (offene.count > 4 ? " …" : ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .glas(18)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            if let pdf {
                PDFAnsicht(daten: pdf)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                Spacer()
                ProgressView("Dokument wird erstellt …")
                Spacer()
            }
        }
        .seitenHintergrund()
        .navigationTitle(titel)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let datei {
                ShareLink(item: datei) {
                    Label("Drucken, sichern oder teilen", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaerStil())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .task { erzeugen() }
    }

    private func erzeugen() {
        let html = DokumentRenderer.html(dokumente, fall: fall, vorlage: content.fall)
        let daten = DokumentRenderer.pdf(html: html)
        let vorgang = fall.wert("vorgang").isEmpty ? "Fall" : fall.wert("vorgang")
        let name = "Screening_\(vorgang)_\(dokumente.count == 1 ? dokumente[0].id : "Unterlagen")"
        datei = try? DokumentExport.speichern(daten, name: name)
        withAnimation(.easeOut(duration: 0.35)) { pdf = daten }
    }
}

struct PDFAnsicht: UIViewRepresentable {
    let daten: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.backgroundColor = .clear
        view.document = PDFDocument(data: daten)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {}
}
