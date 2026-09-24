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
| **Wissen** | 11 Kapitel: GEAS-Überblick, Screening, Eurodac, Asylverfahren, Zuständigkeit/Überstellung (AMM-VO), Ausreisepflicht & Abschiebung, Festnahme & Haft, besondere Personengruppen, Straf-/Bußgeldrecht, Zuständigkeiten in Sachsen, Einsatzpraxis |
| **Einsatz** | 6 abhakbare Checklisten (Aufgriff, Asylgesuch, Abschiebung Vorbereitung/Durchführung, Festnahme/Haftantrag, UMA), Fristen-Übersicht, Paragraphen-Schnellzugriff |
| **Lernen** | 46 Quizfragen mit Erklärungen, Prüfungssimulation (20 Fragen), Wiederholung falscher Antworten, 53 Karteikarten, Fortschrittsanzeige |
| **Suche** | Volltextsuche über Kapitel, Paragraphen und Glossar (28 Begriffe) |
| **Mehr** | Selbst pflegbare Erreichbarkeiten (ZAB-Bereitschaft, Ausländerbehörden, Jugendamt, Bereitschaftsgericht …), Hinweise, Quellen |

Alle Daten (Lernfortschritt, Haken, Telefonnummern) bleiben lokal auf dem Gerät. Es gibt keinen Server und kein Tracking.

## Aufbau

```
geas-app/
├── content/content.json   ← alle Inhalte (eine Quelle für iOS und Web)
├── ios/                   ← native iOS-App (SwiftUI, ab iOS 16)
├── web/                   ← Web-App/PWA (läuft auf jedem iPhone über Safari)
└── tools/                 ← build_web.py, Icon
```

**Inhalte ändern:** nur `content/content.json` bearbeiten, danach `python3 tools/build_web.py`
ausführen (erzeugt `web/index.html`). Die iOS-App liest `content.json` direkt.

## Variante 1: Web-App (sofort nutzbar, kein App Store nötig)

`web/` auf einen beliebigen HTTPS-Webserver legen (z. B. Intranet oder GitHub Pages).
Auf dem iPhone in Safari öffnen → Teilen → **„Zum Home-Bildschirm“**. Danach startet sie wie eine App
und funktioniert offline. `web/index.html` ist auch allein lauffähig (alle Inhalte eingebettet).

## Variante 2: Native iOS-App

Voraussetzungen: Mac mit Xcode 15 oder neuer, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

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
