#!/usr/bin/env python3
"""Erzeugt die Web-App aus web/template.html und content/content.json.

Aufruf (im Ordner geas-app):
  python3 tools/build_web.py           → web/index.html (öffentliche Ausgabe)
  python3 tools/build_web.py --intern  → zusätzlich web/intern/GEAS-Hilfe-intern.html

Die interne Ausgabe mischt content/intern.json (dienstinterne Inhalte) hinzu.
intern.json und web/intern/ sind per .gitignore vom Repository ausgeschlossen
und dürfen NIEMALS veröffentlicht werden.
"""
import base64
import copy
import json
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
basis = json.loads((root / "content" / "content.json").read_text(encoding="utf-8"))
template = (root / "web" / "template.html").read_text(encoding="utf-8")
assert "__CONTENT__" in template


def schreibe(inhalt, ziel, vendor=False):
    inhalt = dict(inhalt)
    daten = inhalt.pop("_daten", {})
    payload = json.dumps(inhalt, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    html = template.replace("__CONTENT__", payload)
    if daten:
        bloecke = "".join(f'<script type="text/plain" id="d:{k}">{base64.b64encode(p.read_bytes()).decode()}</script>\n' for k, p in daten.items())
        html = html.replace('<script id="content"', bloecke + '<script id="content"', 1)
    if vendor:
        # Offline-Bibliotheken für Word-Vorschau und PDF (JSZip: MIT, docx-preview: Apache 2.0, html2canvas: MIT) – Lizenzen in tools/vendor/
        skripte = "".join(f"<script>{(root / 'tools' / 'vendor' / n).read_text(encoding='utf-8')}</script>\n" for n in ("jszip.min.js", "docx-preview.min.js", "html2canvas.min.js"))
        html = html.replace('<script id="content"', skripte + '<script id="content"', 1)
    urheber = inhalt.get("meta", {}).get("copyright")
    if urheber:
        html = html.replace("<!doctype html>", f"<!doctype html>\n<!-- {urheber} -->", 1)
    ziel.parent.mkdir(parents=True, exist_ok=True)
    ziel.write_text(html, encoding="utf-8")


def mische_intern(c, i):
    c = copy.deepcopy(c)
    c["intern"] = True
    c["meta"].update(i.get("meta", {}))
    schritte = {s["id"]: s for s in c["fall"]["schritte"]}
    for zusatz in i.get("fall_felder", []):
        felder = schritte[zusatz["schritt"]]["felder"]
        pos = next(k for k, f in enumerate(felder) if f["id"] == zusatz["nach"]) + 1
        felder.insert(pos, zusatz["feld"])
    # Schritte, die die Polizei nicht ausfüllt (z. B. Gesundheit – macht die Gesundheitsbehörde/LDS)
    c["fall"]["schritte"] = [s for s in c["fall"]["schritte"] if s["id"] not in i.get("schritte_entfernen", [])]
    for s in c["fall"]["schritte"]:
        for f in s["felder"]:
            f.update(i.get("felder_patch", {}).get(f["id"], {}))
    for knoten, aenderung in i.get("screening_patch", {}).items():
        c["screening"]["knoten"][knoten].update(aenderung)
    c["kontakte"] = i.get("kontakte", c["kontakte"])
    c["kapitel"] += i.get("kapitel_zusatz", [])
    for schluessel in ("ablauf", "dokumentauswahl", "vorlagen", "uma_hilfe", "sidas", "einsatz"):
        if schluessel in i:
            c[schluessel] = i[schluessel]
    # Eingebaute Word-Vorlagen und Merkblätter (nur interne Ausgabe, Ordner content/intern/vorlagen/ ist ignoriert)
    ordner = root / "content" / "intern" / "vorlagen"
    if ordner.exists():
        c["vorlagen_eingebaut"] = [{"name": f.name, "daten": base64.b64encode(f.read_bytes()).decode()} for f in sorted(ordner.glob("*.docx"))]
        c["vorlagen_stand"] = i.get("vorlagen_stand", "")
    # Sprachfassungen und EUAA-Merkblätter (tools/lds_paket.py) – als eigene Datenblöcke, die die App erst bei Bedarf liest
    sp = root / "content" / "intern" / "sprachen"
    c["_daten"] = {}
    if (sp / "index.json").exists():
        idx = json.loads((sp / "index.json").read_text(encoding="utf-8"))
        c["sprachen_formulare"] = idx["formulare"]
        for art, liste in idx["formulare"].items():
            for spr in liste:
                c["_daten"][f"sp/{art}/{spr}"] = sp / art / f"{spr}.docx"
        c["beilagen_liste"] = []
        for b in idx["beilagen"]:
            regel = next((r for r in i.get("beilagen_regeln", []) if r["typ"] == b["typ"]), None)
            if not regel:
                continue
            c["beilagen_liste"].append(dict(regel, sprache=b["sprache"], name=b["datei"]))
            c["_daten"]["bl/" + b["datei"]] = ordner / "beilagen" / b["datei"]
        sprachen = sorted({s for l in idx["formulare"].values() for s in l} | {"deutsch"}, key=lambda x: (x != "deutsch", x))
        for st in c["fall"]["schritte"]:
            for f in st["felder"]:
                if f["id"] == "formularsprache":
                    f["optionen"] = [x[0].upper() + x[1:] for x in sprachen]
    # Dienstlogo nur in der internen Ausgabe (Dateien liegen im ignorierten Ordner content/intern/)
    for schluessel, datei in (("logo", "logo_pdl.png"), ("stern", "stern.png")):
        bild = root / "content" / "intern" / datei
        if bild.exists():
            c[schluessel] = "data:image/png;base64," + base64.b64encode(bild.read_bytes()).decode()
    return c


schreibe(basis, root / "web" / "index.html")
version = basis["meta"]["version"]
sw = (root / "web" / "sw.template.js").read_text(encoding="utf-8").replace("__VERSION__", version)
(root / "web" / "sw.js").write_text(sw, encoding="utf-8")
print(f"web/index.html erzeugt (Inhalt v{version}, {len(basis['kapitel'])} Kapitel, {len(basis['quiz'])} Quizfragen)")

if "--intern" in sys.argv:
    quelle = root / "content" / "intern.json"
    if not quelle.exists():
        sys.exit("content/intern.json fehlt – interne Ausgabe nicht erzeugt.")
    intern = mische_intern(basis, json.loads(quelle.read_text(encoding="utf-8")))
    ziel = root / "web" / "intern" / "GEAS-Hilfe-intern.html"
    schreibe(intern, ziel, vendor=True)
    print(f"{ziel.relative_to(root)} erzeugt (INTERN – nicht veröffentlichen)")
