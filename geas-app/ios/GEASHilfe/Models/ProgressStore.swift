import Foundation
import SwiftUI

/// Lernfortschritt, abgehakte Checklistenpunkte und eigene Kontakte.
/// Alles bleibt lokal auf dem Gerät (UserDefaults) – keine personenbezogenen Einsatzdaten speichern.
@MainActor
final class ProgressStore: ObservableObject {
    struct QuizStat: Codable, Equatable {
        var richtig = 0
        var falsch = 0
        var zuletztRichtig = false
    }

    struct EigenerKontakt: Codable, Identifiable, Equatable {
        var id = UUID()
        var name: String
        var rolle: String
        var telefon: String
    }

    private struct Snapshot: Codable {
        var gelesen: Set<String> = []
        var quiz: [String: QuizStat] = [:]
        var checklisten: [String: Set<Int>] = [:]
        var kontakte: [EigenerKontakt]? = nil
        var gewussteKarten: Set<String> = []
    }

    @Published private var state: Snapshot {
        didSet { save() }
    }

    private let key = "geas.progress.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            state = decoded
        } else {
            state = Snapshot()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: Kapitel

    func istGelesen(_ kapitel: Kapitel) -> Bool { state.gelesen.contains(kapitel.id) }

    func setGelesen(_ kapitel: Kapitel, _ value: Bool) {
        if value { state.gelesen.insert(kapitel.id) } else { state.gelesen.remove(kapitel.id) }
    }

    var anzahlGelesen: Int { state.gelesen.count }

    // MARK: Quiz

    func stat(_ frage: QuizFrage) -> QuizStat { state.quiz[frage.id] ?? QuizStat() }

    func beantwortet(_ frage: QuizFrage, richtig: Bool) {
        var s = stat(frage)
        if richtig { s.richtig += 1 } else { s.falsch += 1 }
        s.zuletztRichtig = richtig
        state.quiz[frage.id] = s
    }

    /// Anteil der Fragen, deren letzte Antwort richtig war.
    func beherrscht(_ fragen: [QuizFrage]) -> Int {
        fragen.filter { state.quiz[$0.id]?.zuletztRichtig == true }.count
    }

    func falschBeantwortet(_ fragen: [QuizFrage]) -> [QuizFrage] {
        fragen.filter { if let s = state.quiz[$0.id] { return !s.zuletztRichtig } else { return false } }
    }

    // MARK: Karteikarten

    func gewusst(_ id: String) -> Bool { state.gewussteKarten.contains(id) }

    func setGewusst(_ id: String, _ value: Bool) {
        if value { state.gewussteKarten.insert(id) } else { state.gewussteKarten.remove(id) }
    }

    var anzahlGewussteKarten: Int { state.gewussteKarten.count }

    // MARK: Checklisten

    func istAbgehakt(_ liste: Checkliste, _ index: Int) -> Bool {
        state.checklisten[liste.id]?.contains(index) ?? false
    }

    func toggle(_ liste: Checkliste, _ index: Int) {
        var set = state.checklisten[liste.id] ?? []
        if set.contains(index) { set.remove(index) } else { set.insert(index) }
        state.checklisten[liste.id] = set
    }

    func anzahlAbgehakt(_ liste: Checkliste) -> Int { state.checklisten[liste.id]?.count ?? 0 }

    func reset(_ liste: Checkliste) { state.checklisten[liste.id] = [] }

    // MARK: Kontakte

    func kontakte(vorlage: [Kontakt]) -> [EigenerKontakt] {
        state.kontakte ?? vorlage.map { EigenerKontakt(name: $0.name, rolle: $0.rolle, telefon: $0.telefon) }
    }

    func speichereKontakte(_ kontakte: [EigenerKontakt]) { state.kontakte = kontakte }

    // MARK: Alles

    func allesZuruecksetzen() {
        let kontakte = state.kontakte
        state = Snapshot()
        state.kontakte = kontakte
    }
}
