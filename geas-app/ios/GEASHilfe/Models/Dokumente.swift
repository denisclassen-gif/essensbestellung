import Foundation
import UIKit

/// Setzt die Falldaten in die Dokumentvorlagen ein und erzeugt druckfertiges HTML bzw. PDF (A4).
@MainActor
enum DokumentRenderer {
    /// Ersetzt `{{feld}}` durch den formatierten Wert, leere Werte durch „—“.
    static func einsetzen(_ text: String, fall: FallStore, vorlage: FallVorlage) -> String {
        var ergebnis = ""
        var rest = Substring(text)
        while let start = rest.range(of: "{{"), let ende = rest[start.upperBound...].range(of: "}}") {
            ergebnis += rest[..<start.lowerBound]
            let id = String(rest[start.upperBound..<ende.lowerBound])
            ergebnis += wert(id, fall: fall, vorlage: vorlage)
            rest = rest[ende.upperBound...]
        }
        return ergebnis + rest
    }

    private static func wert(_ id: String, fall: FallStore, vorlage: FallVorlage) -> String {
        switch id {
        case "heute":
            return FallStore.anzeige.string(from: Date())
        case "frist_richter":
            if fall.wert("festgehalten") == "Nein" { return "entfällt – kein Festhalten" }
            guard let a = fall.aufgriff else { return "—" }
            return FallStore.anzeige.string(from: FallStore.richterFrist(ab: a))
        case "frist_screening":
            guard let a = fall.aufgriff else { return "—" }
            return FallStore.anzeige.string(from: FallStore.screeningFrist(ab: a))
        default:
            let roh = fall.wert(id).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !roh.isEmpty else { return "—" }
            if vorlage.feld(id)?.typ == .datumzeit, let d = FallStore.datum(aus: roh) {
                return FallStore.anzeige.string(from: d)
            }
            return roh
        }
    }

    // MARK: HTML

    static func html(_ dokumente: [DokumentVorlage], fall: FallStore, vorlage: FallVorlage) -> String {
        let seiten = dokumente.enumerated().map { index, dok -> String in
            var teile = ["<section class=\"dok\(index > 0 ? " neu" : "")\">",
                         "<header><div class=\"marke\">GEAS Hilfe · Screening</div><span class=\"entwurf\">ENTWURF</span></header>",
                         "<h1>\(escape(dok.titel))</h1><p class=\"unter\">\(escape(dok.untertitel))</p>"]
            for abschnitt in dok.abschnitte {
                if !abschnitt.titel.isEmpty { teile.append("<h2>\(escape(abschnitt.titel))</h2>") }
                teile.append(block(einsetzen(abschnitt.text, fall: fall, vorlage: vorlage)))
            }
            teile.append("<footer>Erstellt am \(escape(FallStore.anzeige.string(from: Date()))) mit GEAS Hilfe (inoffizielle Arbeitshilfe). Entwurf – maßgeblich sind die amtlichen Vordrucke.</footer></section>")
            return teile.joined()
        }
        return """
        <!doctype html><html lang="de"><head><meta charset="utf-8"><style>
        body { font: 10.5pt -apple-system, Helvetica, Arial, sans-serif; color: #1c1c1e; margin: 0; }
        .dok.neu { page-break-before: always; }
        header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #00584a; padding-bottom: 6px; margin-bottom: 14px; }
        .marke { color: #00584a; font-weight: 700; letter-spacing: .04em; font-size: 9pt; }
        .entwurf { border: 1.5px solid #b26200; color: #b26200; font-weight: 700; font-size: 8pt; padding: 2px 8px; border-radius: 10px; }
        h1 { font-size: 17pt; margin: 0; }
        .unter { color: #6c6c70; margin: 2px 0 12px; }
        h2 { font-size: 11.5pt; color: #00584a; margin: 16px 0 6px; }
        table { width: 100%; border-collapse: collapse; margin: 4px 0 8px; }
        td { border: 0.5pt solid #c7c7cc; padding: 4px 6px; vertical-align: top; }
        td.l { width: 34%; background: #f2f2f7; font-weight: 600; }
        p { margin: 0 0 6px; white-space: pre-wrap; }
        ul { margin: 0 0 6px; padding-left: 18px; }
        footer { margin-top: 18px; border-top: 0.5pt solid #c7c7cc; padding-top: 6px; color: #8e8e93; font-size: 8pt; }
        </style></head><body>\(seiten.joined())</body></html>
        """
    }

    /// Wandelt die leichte Auszeichnung (Absätze, „• “, „| a | b“, **fett**) in HTML um.
    private static func block(_ text: String) -> String {
        var html = ""
        var tabelle: [String] = []
        var liste: [String] = []
        var absatz: [String] = []

        func abschliessen() {
            if !tabelle.isEmpty { html += "<table>\(tabelle.joined())</table>"; tabelle = [] }
            if !liste.isEmpty { html += "<ul>\(liste.joined())</ul>"; liste = [] }
            if !absatz.isEmpty { html += "<p>\(absatz.joined(separator: "\n"))</p>"; absatz = [] }
        }

        for zeile in text.components(separatedBy: "\n") {
            if zeile.hasPrefix("| ") {
                if !liste.isEmpty || !absatz.isEmpty { abschliessen() }
                let teile = zeile.dropFirst(2).components(separatedBy: " | ")
                let links = inline(teile.first ?? "")
                let rechts = inline(teile.dropFirst().joined(separator: " | "))
                tabelle.append("<tr><td class=\"l\">\(links)</td><td>\(rechts)</td></tr>")
            } else if zeile.hasPrefix("• ") {
                if !tabelle.isEmpty || !absatz.isEmpty { abschliessen() }
                liste.append("<li>\(inline(String(zeile.dropFirst(2))))</li>")
            } else if zeile.trimmingCharacters(in: .whitespaces).isEmpty {
                if absatz.isEmpty { abschliessen(); html += "<p>&nbsp;</p>" } else { abschliessen() }
            } else {
                if !tabelle.isEmpty || !liste.isEmpty { abschliessen() }
                absatz.append(inline(zeile))
            }
        }
        abschliessen()
        return html
    }

    private static func inline(_ s: String) -> String {
        var e = escape(s)
        while let a = e.range(of: "**"), let b = e[a.upperBound...].range(of: "**") {
            let ersatz = "<b>" + String(e[a.upperBound..<b.lowerBound]) + "</b>"
            e.replaceSubrange(a.lowerBound..<b.upperBound, with: ersatz)
        }
        return e
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    // MARK: PDF

    private final class A4Renderer: UIPrintPageRenderer {
        override var paperRect: CGRect { CGRect(x: 0, y: 0, width: 595.2, height: 841.8) }
        override var printableRect: CGRect { paperRect.insetBy(dx: 44, dy: 48) }
    }

    static func pdf(html: String) -> Data {
        let renderer = A4Renderer()
        renderer.addPrintFormatter(UIMarkupTextPrintFormatter(markupText: html), startingAtPageAt: 0)
        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, renderer.paperRect, nil)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: renderer.numberOfPages))
        for seite in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: seite, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        return data as Data
    }
}

/// Legt erzeugte PDFs geschützt im temporären Verzeichnis ab (zum Teilen) und räumt sie wieder auf.
enum DokumentExport {
    private static var ordner: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Unterlagen", isDirectory: true)
    }

    static func speichern(_ data: Data, name: String) throws -> URL {
        try FileManager.default.createDirectory(at: ordner, withIntermediateDirectories: true)
        let erlaubt = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sicher = String(name.unicodeScalars.map { erlaubt.contains($0) ? Character($0) : "_" })
        let url = ordner.appendingPathComponent(sicher).appendingPathExtension("pdf")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    static func aufraeumen() {
        try? FileManager.default.removeItem(at: ordner)
    }
}
