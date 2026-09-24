# GEAS Hilfe – Einsatz- und Lernhilfe GEAS, Asyl & Rückführung

Inoffizielle Arbeits- und Lernhilfe für Beamtinnen und Beamte der Polizei Sachsen
(Zuschnitt PD Leipzig) zum Gemeinsamen Europäischen Asylsystem (GEAS) und zur Rückführung.
Rechtsstand: GEAS-Reform und GEAS-Anpassungsgesetz, **in Kraft seit 12.06.2026**, Inhaltsstand September 2026.

> Die App ersetzt weder Gesetzestext noch Erlasse, Dienstanweisungen oder die Weisung der
> zuständigen Ausländerbehörde. Vor dienstlichem Einsatz fachlich prüfen lassen (z. B. durch die
> Fachdienststelle/Rechtsstelle der PD Leipzig).

## Inhalt

| Bereich | Umfang |
|---|---|
| **Unterlagen-Assistent** | Fall anlegen, in 9 Schritten erfassen (Einsatz, Person, Reiseweg, Abfragen, Biometrie, Gesundheit & Vulnerabilität, Schutzersuchen, Festhalten, Abschluss). Erzeugt automatisch bis zu 8 Unterlagen als A4-PDF bzw. Druck: Überprüfungsformular (Art. 17 Screening-VO, Entwurf), Belehrung DE/EN, Festhalten & Antrag an das Gericht, Vermerk Schutzersuchen, Mitteilung Gesundheitsbehörde, Vermerk Schutzbedürftigkeit, Abschluss-/Übergabevermerk, Fristenblatt. Nur die im Fall nötigen Dokumente werden angeboten; fehlende Pflichtangaben werden angezeigt. |
| **Screening-Prüfung** | Geführte Prüfung „Ist ein Screening durchzuführen?“: eine Frage pro Bildschirm, eindeutiges Ergebnis mit Handlungsschritten zum Abhaken, Fristenrechner (Richtervorbehalt / 3-Tage-Frist), Prüfprotokoll zum Kopieren, Kurzanleitung, Checkliste, 10 Fallbeispiele |
| **Einführung** | Beim ersten Start geführte Einführung (5 Schritte), die bestätigt werden muss; jederzeit unter „Mehr“ erneut aufrufbar |
| **Wissen** | 11 Kapitel: GEAS-Überblick, Screening, Eurodac, Asylverfahren, Zuständigkeit/Überstellung (AMM-VO), Ausreisepflicht & Abschiebung, Festnahme & Haft, besondere Personengruppen, Straf-/Bußgeldrecht, Zuständigkeiten in Sachsen, Einsatzpraxis |
| **Einsatz** | 7 abhakbare Checklisten (Screening im Inland, Aufgriff, Asylgesuch, Abschiebung Vorbereitung/Durchführung, Festnahme/Haftantrag, UMA), Fristen-Übersicht, Paragraphen-Schnellzugriff |
| **Lernen** | 56 Quizfragen (davon 10 Screening-Fallbeispiele) mit Erklärungen, Prüfungssimulation (20 Fragen), Wiederholung falscher Antworten, 53 Karteikarten, Fortschrittsanzeige |
| **Suche** | Im Reiter „Wissen“: Volltextsuche über Kapitel, Paragraphen und Glossar (28 Begriffe) |
| **Mehr** | Selbst pflegbare Erreichbarkeiten (ZAB-Bereitschaft, Ausländerbehörden, Jugendamt, Bereitschaftsgericht …), Hinweise, Quellen |

Alle Daten bleiben lokal auf dem Gerät. Es gibt keinen Server und kein Tracking.

**Datenschutz im Unterlagen-Assistenten:** Falldaten enthalten personenbezogene Daten. iOS speichert sie mit
`completeFileProtection` (nur bei entsperrtem Gerät lesbar), ohne iCloud-/iTunes-Backup, und löscht sie nach 7 Tagen
automatisch. Die Web-Version speichert im lokalen Browser-Speicher und löscht ebenfalls nach 7 Tagen. Nur auf dienstlich
zugelassenen Geräten verwenden; nach Übernahme in das Vorgangsbearbeitungssystem den Fall löschen. Erzeugte Unterlagen sind
Entwürfe – maßgeblich sind die amtlichen Vordrucke.

## Design

Apple-/Airbnb-Stil: Glasflächen (echtes **Liquid Glass** ab iOS 26, darunter Material-Effekte), Kacheln,
Parallax-Kopfbereiche, Zoom-Übergänge (iOS 18), gleitende Schrittwechsel, animierte Eingabefelder mit schwebender
Beschriftung, Auswahl-Chips mit Feder-Animation, 3D-Karteikarten, haptisches Feedback. Eigenes gezeichnetes Emblem
(Schild, Sternenkreis, Paragraph) statt generischer Symbole. Unterstützt Hell/Dunkel und „Bewegung reduzieren“.

## Aufbau

```
geas-app/
├── content/content.json   ← alle Inhalte (eine Quelle für iOS und Web)
├── ios/                   ← native iOS-App (SwiftUI, ab iOS 16)
├── web/                   ← Web-App/PWA (läuft auf jedem iPhone über Safari)
└── tools/                 ← build_web.py, Icon
```

**Screening-Entscheidungsbaum ändern:** in `content.json` unter `screening.knoten`. Jede Frage verweist
mit `antworten[].ziel` auf die nächste Frage oder ein Ergebnis (`typ: "ergebnis"`).

**Inhalte ändern:** nur `content/content.json` bearbeiten, danach `python3 tools/build_web.py`
ausführen (erzeugt `web/index.html`). Die iOS-App liest `content.json` direkt.

## Variante 1: Web-App (sofort nutzbar, kein App Store nötig)

`web/` auf einen beliebigen HTTPS-Webserver legen (z. B. Intranet oder GitHub Pages).
Auf dem iPhone in Safari öffnen → Teilen → **„Zum Home-Bildschirm“**. Danach startet sie wie eine App
und funktioniert offline. `web/index.html` ist auch allein lauffähig (alle Inhalte eingebettet).

## Variante 2: Native iOS-App

Voraussetzungen: Mac mit Xcode 16 oder neuer (für Liquid Glass Xcode 26), [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
cd geas-app/ios
xcodegen generate
open GEASHilfe.xcodeproj
```

In Xcode unter *Signing & Capabilities* das eigene Team wählen und auf dem iPhone oder im Simulator starten.
Jeder Push baut die App zusätzlich per GitHub Actions (`.github/workflows/geas-ios.yml`).

**Verteilung an alle Beamten:** Für dienstliche iPhones läuft das üblicherweise über das
Mobile-Device-Management der Polizei Sachsen (Apple Developer Enterprise Program oder
Apple Business Manager/Custom Apps). Das muss die zuständige IT-Stelle freigeben.
Für einen Test reichen TestFlight oder die Web-Variante.

## Quellen

- EU-Verordnungen 2024/1346–1359 (GEAS-Reform)
- GEAS-Anpassungsgesetz und GEAS-Anpassungsfolgegesetz (BGBl. 2026)
- AufenthG, AsylG in aktueller Fassung
- Landesdirektion Sachsen: Sekundärmigrationszentrum Dresden (seit 01.07.2026), Einrichtung Abschiebungshaft Dresden
- SächsPVDG (Novelle vom 24.06.2026)
