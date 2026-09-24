import Foundation
import SwiftUI

/// Hält die Daten des aktuellen Screening-Falls.
///
/// Datenschutz: Die Datei liegt im Application-Support-Verzeichnis mit `completeFileProtection`
/// (nur bei entsperrtem Gerät lesbar), ist vom Backup ausgeschlossen und wird nach 7 Tagen
/// automatisch gelöscht.
@MainActor
final class FallStore: ObservableObject {
    static let aufbewahrung: TimeInterval = 7 * 24 * 60 * 60
    static let trenner = "; "

    private struct Datei: Codable {
        var angelegt: Date
        var werte: [String: String]
    }

    @Published private(set) var angelegt: Date?
    @Published private(set) var werte: [String: String] = [:]

    var aktiv: Bool { angelegt != nil }

    private let url: URL = {
        let ordner = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return ordner.appendingPathComponent("fall.json")
    }()

    init() {
        laden()
    }

    // MARK: Lebenszyklus

    func neuerFall() {
        angelegt = Date()
        werte = ["aufgriff_zeit": Self.isoString(Date())]
        speichern()
    }

    func loeschen() {
        angelegt = nil
        werte = [:]
        try? FileManager.default.removeItem(at: url)
        DokumentExport.aufraeumen()
    }

    var loeschtAm: Date? { angelegt?.addingTimeInterval(Self.aufbewahrung) }

    private func laden() {
        guard let data = try? Data(contentsOf: url),
              let datei = try? JSONDecoder().decode(Datei.self, from: data) else { return }
        if Date().timeIntervalSince(datei.angelegt) > Self.aufbewahrung {
            loeschen()
            return
        }
        angelegt = datei.angelegt
        werte = datei.werte
    }

    private func speichern() {
        guard let angelegt else { return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Datei(angelegt: angelegt, werte: werte))
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            var ressource = URLResourceValues()
            ressource.isExcludedFromBackup = true
            var ziel = url
            try? ziel.setResourceValues(ressource)
        } catch {
            assertionFailure("Fall konnte nicht gespeichert werden: \(error)")
        }
    }

    // MARK: Werte

    func wert(_ id: String) -> String { werte[id] ?? "" }

    func setze(_ id: String, _ neu: String) {
        let bereinigt = neu
        if bereinigt.isEmpty { werte.removeValue(forKey: id) } else { werte[id] = bereinigt }
        speichern()
    }

    func binding(_ id: String) -> Binding<String> {
        Binding(get: { self.wert(id) }, set: { self.setze(id, $0) })
    }

    func auswahl(_ id: String) -> [String] {
        wert(id).components(separatedBy: Self.trenner).filter { !$0.isEmpty }
    }

    /// Mehrfachauswahl umschalten. „Kein…“-Optionen schließen alle anderen aus.
    func umschalten(_ id: String, _ option: String) {
        var liste = auswahl(id)
        if let i = liste.firstIndex(of: option) {
            liste.remove(at: i)
        } else if option.hasPrefix("Kein") {
            liste = [option]
        } else {
            liste.removeAll { $0.hasPrefix("Kein") }
            liste.append(option)
        }
        setze(id, liste.joined(separator: Self.trenner))
    }

    // MARK: Logik

    func erfuellt(_ bedingung: Bedingung?) -> Bool {
        guard let bedingung else { return true }
        let werteListe = auswahl(bedingung.feld)
        if bedingung.wert.hasPrefix("!") {
            let ausgeschlossen = String(bedingung.wert.dropFirst())
            return !werteListe.isEmpty && !werteListe.contains(ausgeschlossen)
        }
        return werteListe.contains(bedingung.wert)
    }

    func sichtbar(_ feld: FallFeld) -> Bool { erfuellt(feld.bedingung) }

    func offenePflichtfelder(in schritt: FallSchritt) -> [FallFeld] {
        schritt.felder.filter { $0.istPflicht && sichtbar($0) && wert($0.id).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func offenePflichtfelder(fuer dokument: DokumentVorlage, vorlage: FallVorlage) -> [FallFeld] {
        dokument.pflichtfelder.compactMap { vorlage.feld($0) }
            .filter { sichtbar($0) && wert($0.id).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func relevant(_ dokument: DokumentVorlage) -> Bool { erfuellt(dokument.bedingung) }

    // MARK: Fristen

    var aufgriff: Date? { Self.datum(aus: wert("aufgriff_zeit")) }

    /// Ende des Tages nach dem Ergreifen (23:59 Uhr des Folgetages).
    static func richterFrist(ab aufgriff: Date) -> Date {
        let cal = Calendar(identifier: .gregorian)
        let beginn = cal.startOfDay(for: aufgriff)
        return (cal.date(byAdding: .day, value: 2, to: beginn) ?? aufgriff).addingTimeInterval(-60)
    }

    static func screeningFrist(ab aufgriff: Date) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: 3, to: aufgriff) ?? aufgriff
    }

    // MARK: Datumsformat

    private static let iso: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return f
    }()

    static let anzeige: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEE, dd.MM.yyyy, HH:mm 'Uhr'"
        return f
    }()

    static func isoString(_ d: Date) -> String { iso.string(from: d) }
    static func datum(aus s: String) -> Date? { s.isEmpty ? nil : iso.date(from: s) }
}
