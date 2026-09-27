# TauschRevier – Werbeclip

`tauschrevier-clip.mp4`: 22 s, 1080×1920 (Hochformat für WhatsApp-Status, Reels, Stories), 30 fps, H.264 + AAC.

- `clip.html`: die Animation. Jedes Bild ist eine reine Funktion der Zeit (`seek(t)`), mit Apple-Federn.
- `music.py`: komponiert den Soundtrack (eigene Komposition, 120 BPM, D-Dur, lizenzfrei) samt UI-Sounds → `soundtrack.wav`.
- `render.js`: rendert die Einzelbilder mit Playwright (`node render.js frames 30`, Kontaktbogen: `node render.js sheet`).

Neu erstellen:

```
python3 music.py
node render.js frames 30
ffmpeg -framerate 30 -i frames/f%05d.png -i soundtrack.wav -c:v libx264 -preset slow -crf 18 \
  -pix_fmt yuv420p -c:a aac -b:a 192k -shortest -movflags +faststart tauschrevier-clip.mp4
```
