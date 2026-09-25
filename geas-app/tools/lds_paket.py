#!/usr/bin/env python3
"""Bereitet das LDS-Vorlagenpaket (entpackte ZIPs) für die interne Ausgabe auf.

Aufruf (im Ordner geas-app):
  python3 tools/lds_paket.py <Ordner mit den entpackten Paketen>

Ergebnis (nur lokal, per .gitignore ausgeschlossen):
  content/intern/sprachen/<art>/<sprache>.docx   Sprachfassungen der Formulare
  content/intern/vorlagen/beilagen/*.pdf          EUAA-Merkblätter
  content/intern/sprachen/index.json              Übersicht für build_web.py

Eingebettete Bildschirmfotos, von denen das Formular nur einen Ausschnitt zeigt,
werden auf den sichtbaren Ausschnitt zugeschnitten. Das Aussehen des Formulars
bleibt gleich, die Datei wird aber deutlich kleiner.
"""
import hashlib
import io
import json
import os
import pathlib
import re
import sys
import zipfile

from PIL import Image

root = pathlib.Path(__file__).resolve().parent.parent
ziel = root / "content" / "intern" / "sprachen"
beilagen = root / "content" / "intern" / "vorlagen" / "beilagen"

# Ordnername (Teil) → Formularart der App
ARTEN = [
    ("Belehrungen nach", "belehrung15"),
    ("Belehrung 48", "belehrung48"),
    ("Anlaufbescheinigung", "anlauf"),
    ("Inverwahr. Pass", "inverwahrung"),
    ("Inverwahr. § 50", "inverwahrung50"),
    ("Fragebogen AMMVO", "fragebogen"),
    ("Fragebogen umA", "fragebogen_uma"),
]
# Schreibweisen in den Dateinamen vereinheitlichen
SPRACHE = {"franzöisch": "französisch", "kurd-kurmanji": "kurd-kurmanci", "kurd-kurmandschi": "kurd-kurmanci"}


def dekodiere(s):
    return re.sub(r"#U([0-9a-fA-F]{4})", lambda m: chr(int(m.group(1), 16)), s)


def sprache_aus(name):
    m = re.search(r"_([^_]+?)(?: \(\d+\))?\.(docx|pdf)$", name)
    s = m.group(1).lower() if m else "deutsch"
    return SPRACHE.get(s, s)


def zuschneiden(daten):
    """Bilder mit Ausschnitt (a:srcRect) auf den sichtbaren Teil zuschneiden."""
    z = zipfile.ZipFile(io.BytesIO(daten))
    dateien = {i.filename: z.read(i.filename) for i in z.infolist()}
    doc = dateien["word/document.xml"].decode("utf-8")
    rels = dateien["word/_rels/document.xml.rels"].decode("utf-8")
    ziele = dict(re.findall(r'Id="(rId\d+)"[^>]*Target="([^"]+)"', rels))
    geaendert = False
    for m in list(re.finditer(r'<a:blip r:embed="(rId\d+)"', doc)):
        rid = m.group(1)
        if doc.count(f'r:embed="{rid}"') != 1 or rid not in ziele:
            continue
        pfad = "word/" + ziele[rid]
        if not pfad.lower().endswith(".png") or pfad not in dateien:
            continue
        ende = doc.find("</pic:blipFill>", m.start())
        block = doc[m.start():ende]
        sr = re.search(r'<a:srcRect( [^>]*)?/>', block)
        if not sr or not sr.group(1):
            continue
        werte = {k: int(v) for k, v in re.findall(r'(\w)="(-?\d+)"', sr.group(1))}
        if any(v < 0 for v in werte.values()):
            continue
        bild = Image.open(io.BytesIO(dateien[pfad]))
        b, h = bild.size
        box = (round(werte.get("l", 0) * b / 100000), round(werte.get("t", 0) * h / 100000),
               round(b - werte.get("r", 0) * b / 100000), round(h - werte.get("b", 0) * h / 100000))
        if box[2] - box[0] < 4 or box[3] - box[1] < 4:
            continue
        aus = io.BytesIO()
        bild.crop(box).save(aus, "PNG", optimize=True)
        dateien[pfad] = aus.getvalue()
        neu = block.replace(sr.group(0), "<a:srcRect/>")
        # Die HD-Photo-Ebene (Bildbearbeitung in Word) bezieht sich auf das ganze Bild – entfernen
        neu = re.sub(r'<a:ext uri="\{BEBA8EAE-BF5A-486C-A8C5-ECC9F3942E4B\}">.*?</a:ext>', "", neu, flags=re.S)
        doc = doc[:m.start()] + neu + doc[ende:]
        geaendert = True
    if not geaendert:
        return daten
    # Nicht mehr verwendete Bildebenen (z. B. hdphoto*.wdp) samt Verweis entfernen
    for rid, pfad in ziele.items():
        if pfad.startswith("media/") and f'"{rid}"' not in doc:
            dateien.pop("word/" + pfad, None)
            rels = re.sub(r'<Relationship [^>]*Id="%s"[^>]*/>' % rid, "", rels)
    dateien["word/_rels/document.xml.rels"] = rels.encode("utf-8")
    dateien["word/document.xml"] = doc.encode("utf-8")
    aus = io.BytesIO()
    with zipfile.ZipFile(aus, "w", zipfile.ZIP_DEFLATED) as neu:
        for name, inhalt in dateien.items():
            neu.writestr(name, inhalt)
    return aus.getvalue()


def main(quelle):
    index = {"formulare": {}, "beilagen": []}
    gesehen = set()
    for pfad, _, namen in os.walk(quelle):
        ordner = dekodiere(pfad)
        for n in sorted(namen):
            name = dekodiere(n)
            if name.startswith("~$"):
                continue
            daten = pathlib.Path(pfad, n).read_bytes()
            if name.lower().endswith(".pdf") and "EUAA" in ordner:
                typ = "eurodac" if "EURODAC" in name.upper() else "typD" if "TypD" in name else "typA" if "TypA" in name else "typB" if "TypB" in name else None
                if not typ:
                    continue
                sprache = sprache_aus(name)
                datei = f"EUAA_{typ}_{sprache}.pdf"
                if datei in gesehen:
                    continue
                gesehen.add(datei)
                beilagen.mkdir(parents=True, exist_ok=True)
                (beilagen / datei).write_bytes(daten)
                index["beilagen"].append({"typ": typ, "sprache": sprache, "datei": datei})
                continue
            if not name.lower().endswith(".docx"):
                continue
            art = next((a for teil, a in ARTEN if teil in ordner), None)
            if not art:
                continue
            sprache = sprache_aus(name)
            if sprache == "deutsch" or "noch nicht verfügbar" in name:
                continue   # die deutschen Fassungen sind bereits als Hauptvorlagen eingebaut
            schluessel = (art, sprache)
            if schluessel in gesehen:
                continue
            gesehen.add(schluessel)
            (ziel / art).mkdir(parents=True, exist_ok=True)
            (ziel / art / f"{sprache}.docx").write_bytes(zuschneiden(daten))
            index["formulare"].setdefault(art, []).append(sprache)
    for liste in index["formulare"].values():
        liste.sort()
    ziel.mkdir(parents=True, exist_ok=True)
    (ziel / "index.json").write_text(json.dumps(index, ensure_ascii=False, indent=1), encoding="utf-8")
    groesse = sum(f.stat().st_size for f in ziel.rglob("*.docx"))
    print(f"{sum(len(v) for v in index['formulare'].values())} Sprachfassungen ({groesse / 1e6:.1f} MB), {len(index['beilagen'])} Merkblätter")
    for art, liste in index["formulare"].items():
        print(f"  {art}: {len(liste)} Sprachen")
    for b in index["beilagen"]:
        print(f"  Merkblatt {b['typ']} {b['sprache']}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1])
