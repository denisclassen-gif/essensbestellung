import Foundation

struct AppContent: Decodable {
    let meta: Meta
    let kapitel: [Kapitel]
    let checklisten: [Checkliste]
    let fristen: [Frist]
    let normen: [Norm]
    let glossar: [GlossarEintrag]
    let quiz: [QuizFrage]
    let kontakte: [Kontakt]
    let quellen: [String]
    let onboarding: [OnboardingSeite]
    let screening: ScreeningPruefung
    let fall: FallVorlage
    let dokumente: [DokumentVorlage]

    static let empty = AppContent(
        meta: Meta(titel: "GEAS & Rückführung", untertitel: "", version: "", stand: "", hinweis: ""),
        kapitel: [], checklisten: [], fristen: [], normen: [], glossar: [], quiz: [], kontakte: [], quellen: [],
        onboarding: [],
        screening: ScreeningPruefung(start: "", kurzanleitung: [], grundsaetze: [], knoten: [:]),
        fall: FallVorlage(hinweis: "", schritte: []),
        dokumente: []
    )

    static func loadFromBundle() -> AppContent {
        guard let url = Bundle.main.url(forResource: "content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let content = try? JSONDecoder().decode(AppContent.self, from: data)
        else {
            assertionFailure("content.json fehlt oder ist ungültig")
            return .empty
        }
        return content
    }

    func kapitel(id: String) -> Kapitel? {
        kapitel.first { $0.id == id }
    }
}

struct Meta: Decodable {
    let titel: String
    let untertitel: String
    let version: String
    let stand: String
    let hinweis: String
}

struct Kapitel: Decodable, Identifiable, Hashable {
    let id: String
    let titel: String
    let icon: String
    let kurz: String
    let abschnitte: [Abschnitt]
    let merke: [String]
}

struct Abschnitt: Decodable, Hashable {
    let titel: String
    let text: String
}

struct Checkliste: Decodable, Identifiable, Hashable {
    let id: String
    let titel: String
    let icon: String
    let kontext: String
    let punkte: [ChecklistPunkt]
}

struct ChecklistPunkt: Decodable, Hashable {
    let text: String
    let hinweis: String?
}

struct Frist: Decodable, Hashable {
    let was: String
    let frist: String
    let grundlage: String
}

struct Norm: Decodable, Hashable, Identifiable {
    var id: String { norm }
    let norm: String
    let titel: String
    let inhalt: String
    let praxis: String
}

struct GlossarEintrag: Decodable, Hashable, Identifiable {
    var id: String { begriff }
    let begriff: String
    let erklaerung: String
}

struct QuizFrage: Decodable, Hashable, Identifiable {
    var id: String { frage }
    let kapitel: String
    let frage: String
    let antworten: [String]
    let richtig: Int
    let erklaerung: String
}

struct Kontakt: Decodable, Hashable {
    let name: String
    let rolle: String
    let telefon: String
}

struct OnboardingSeite: Decodable, Hashable {
    let icon: String
    let titel: String
    let text: String
}

/// Entscheidungsbaum „Ist ein Screening durchzuführen?“ – Fragen führen über `antworten[].ziel` zu Ergebnissen.
struct ScreeningPruefung: Decodable {
    let start: String
    let kurzanleitung: [String]
    let grundsaetze: [String]
    let knoten: [String: ScreeningKnoten]
}

struct ScreeningKnoten: Decodable, Hashable {
    enum Ergebnis: String, Decodable {
        case screening, kein, sonder
    }

    struct Antwort: Decodable, Hashable {
        let text: String
        let ziel: String
    }

    let typ: String
    // Frage
    let schritt: String?
    let frage: String?
    let hilfe: String?
    let beispiele: [String]?
    let antworten: [Antwort]?
    // Ergebnis
    let ergebnis: Ergebnis?
    let titel: String?
    let kurz: String?
    let fristen: Bool?
    let schritte: [ChecklistPunkt]?
    let rechtsgrundlage: String?

    var istFrage: Bool { typ == "frage" }
}

// MARK: - Unterlagen-Assistent

struct Bedingung: Decodable, Hashable {
    let feld: String
    /// Erwarteter Wert. Beginnt er mit „!“, muss das Feld ausgefüllt sein und darf den Wert NICHT enthalten.
    let wert: String
}

struct FallVorlage: Decodable {
    let hinweis: String
    let schritte: [FallSchritt]

    var alleFelder: [FallFeld] { schritte.flatMap(\.felder) }

    func feld(_ id: String) -> FallFeld? { alleFelder.first { $0.id == id } }
}

struct FallSchritt: Decodable, Identifiable, Hashable {
    let id: String
    let titel: String
    let icon: String
    let beschreibung: String
    let felder: [FallFeld]
}

struct FallFeld: Decodable, Identifiable, Hashable {
    enum Typ: String, Decodable {
        case text, mehrzeilig, datumzeit, auswahl, mehrfach
    }

    let id: String
    let label: String
    let typ: Typ
    let pflicht: Bool?
    let optionen: [String]?
    let hinweis: String?
    let platzhalter: String?
    let bedingung: Bedingung?

    var istPflicht: Bool { pflicht ?? false }
}

struct DokumentVorlage: Decodable, Identifiable, Hashable {
    struct Abschnitt: Decodable, Hashable {
        let titel: String
        let text: String
    }

    let id: String
    let titel: String
    let untertitel: String
    let icon: String
    let beschreibung: String
    let bedingung: Bedingung?
    let pflichtfelder: [String]
    let abschnitte: [Abschnitt]
}
