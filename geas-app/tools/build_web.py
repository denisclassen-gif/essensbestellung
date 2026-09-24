#!/usr/bin/env python3
"""Erzeugt web/index.html aus web/template.html und content/content.json.

Aufruf (im Ordner geas-app):  python3 tools/build_web.py
Nach jeder Änderung an content.json erneut ausführen – die iOS-App liest content.json direkt.
"""
import json
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
content = json.loads((root / "content" / "content.json").read_text(encoding="utf-8"))
payload = json.dumps(content, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
template = (root / "web" / "template.html").read_text(encoding="utf-8")
assert "__CONTENT__" in template
(root / "web" / "index.html").write_text(template.replace("__CONTENT__", payload), encoding="utf-8")

version = content["meta"]["version"]
sw = (root / "web" / "sw.template.js").read_text(encoding="utf-8").replace("__VERSION__", version)
(root / "web" / "sw.js").write_text(sw, encoding="utf-8")
print(f"web/index.html erzeugt (Inhalt v{version}, {len(content['kapitel'])} Kapitel, {len(content['quiz'])} Quizfragen)")
