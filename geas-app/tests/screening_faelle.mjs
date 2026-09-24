// Prüft typische Fälle gegen den Entscheidungsbaum in content.json.
// Aufruf: node tests/screening_faelle.mjs
import { readFileSync } from "node:fs";
const C = JSON.parse(readFileSync(new URL("../content/content.json", import.meta.url), "utf8"));
const K = C.screening.knoten;

// Antworten werden über einen eindeutigen Textanfang ausgewählt.
function pruefe(name, antworten, erwartet) {
  let id = C.screening.start;
  for (const anfang of antworten) {
    const k = K[id];
    if (k.typ !== "frage") throw new Error(`${name}: Ergebnis ${id} erreicht, aber noch Antworten übrig`);
    const treffer = k.antworten.filter(a => a.text.startsWith(anfang));
    if (treffer.length !== 1) throw new Error(`${name}: Antwort „${anfang}“ bei ${id} nicht eindeutig (${treffer.length})`);
    id = treffer[0].ziel;
  }
  const ok = id === erwartet;
  console.log(`${ok ? "✔" : "✘"} ${name} → ${K[id].titel || id}`);
  if (!ok) { console.log(`   erwartet: ${erwartet}, erhalten: ${id}`); process.exitCode = 1; }
}

const dritt = ["Nein / unklar", "Nein / nicht"];
pruefe("Rumänische Staatsangehörige", ["Ja – nachgewiesen"], "e_eu");
pruefe("Vietnamesin, Visum abgelaufen (Pass vorhanden)", [...dritt, "Nur ein ABGELAUFENES"], "e_overstay");
pruefe("Vietnamesin ohne Pass, VIS-Treffer", [...dritt, "Nein – gar nichts", "VIS/EES-Treffer"], "e_overstay");
pruefe("Kolumbianer, visumfrei, 90 Tage überschritten", [...dritt, "Nur ein ABGELAUFENES"], "e_overstay");
pruefe("Georgier mit italienischem Titel, 1 Jahr in DE", [...dritt, "Titel eines anderen Schengen"], "e_anderer_staat");
pruefe("Geduldeter aus dem Landkreis Leipzig", [...dritt, "Ja – gültiges"], "e_status");
pruefe("Asylbewerber mit laufendem Verfahren, ohne Papiere", [...dritt, "Nein – gar nichts", "Bekannt in Deutschland"], "e_bekannt");
pruefe("Syrer, abgeschoben, ohne Kontrolle zurück", [...dritt, "Nein – gar nichts", "Frühere Abschiebung", "Ja – Ausreise", "Ohne Kontrolle"], "e_wiedereinreise");
pruefe("Abgeschobener, mit neuem Visum eingereist", [...dritt, "Nein – gar nichts", "Frühere Abschiebung", "Ja – Ausreise", "Mit Grenzkontrolle"], "e_wieder_kontrolliert");
pruefe("Afghane, nach Italien überstellt, zurück", [...dritt, "Nein – gar nichts", "Frühere Abschiebung", "Nein – nur innerhalb"], "e_bekannt");
pruefe("Frühere Ausreise ungeklärt", [...dritt, "Nein – gar nichts", "Frühere Abschiebung", "Unklar"], "e_ausreise_unklar");
pruefe("In Leipzig geborenes Kind", [...dritt, "Nein – gar nichts", "Kein Treffer", "Ja – Geburt"], "e_geboren");
pruefe("Unbekannter ohne Papiere, keine Treffer", [...dritt, "Nein – gar nichts", "Kein Treffer", "Nein / unklar", "Nein / kein", "Nein (Regelfall)"], "e_screening");
pruefe("Systemausfall, Einreisestempel im Pass", [...dritt, "Nein – gar nichts", "Abfrage gerade", "Nein / unklar", "Ja – belegbarer"], "e_overstay");
pruefe("Grenznaher Aufgriff, Rücküberstellung Bundespolizei", [...dritt, "Nein – gar nichts", "Kein Treffer", "Nein / unklar", "Nein / kein", "Ja – mit Bundespolizei"], "e_rueck");
