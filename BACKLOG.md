# 📋 Stinky Toss – Feature-Backlog

200 offene Features für die Weiterentwicklung von **Stinky Toss**.
Jedes Feature hat eine ID (`F001`–`F200`), eine Kurzbeschreibung und Aufwands-Tags.

**Aufwand:** 🟢 klein · 🟡 mittel · 🔴 groß
**Status:** `[ ]` offen · `[~]` in Arbeit · `[x]` erledigt

> Reihenfolge = grobe Empfehlung. Querverweise in Klammern.

---

## 🎯 1. Wurf- & Kernmechanik (F001–F020)

- [x] **F001** 🟢 Wurf-Kraftanzeige (Ladebalken) während des Ziehens – Drag-Distanz limitiert
- [x] **F002** 🟢 Mindest-/Höchstkraft visuell am Gummiband markieren – Trajectory-Vorschau
- [ ] **F003** 🟡 Mehrere Geschosse gleichzeitig in der Luft erlauben (Limit konfigurierbar)
- [ ] **F004** 🟡 Geschoss-Vorrat/Munition pro Runde (begrenzte Würfe)
- [x] **F005** 🟢 Nachlade-Animation des Kackhaufens am Anker
- [ ] **F006** 🟡 Abprall-Physik an Wänden mit Restitution
- [ ] **F007** 🟡 Wind-Einfluss auf die Flugbahn (seitliche Kraft)
- [ ] **F008** 🔴 Zerlegbare Geschosse (Split-Shot in 3 kleinere Haufen)
- [ ] **F009** 🟡 Klebrige Geschosse, die an Männchen haften bleiben
- [ ] **F010** 🟡 Sprengradius/Flächenschaden bei Aufprall (AoE)
- [x] **F011** 🟢 Drehmoment/Spin durch Wischrichtung beim Loslassen – Kreuzprodukt für Spin
- [ ] **F012** 🟡 Zeitlupe (Bullet-Time) während des Zielens
- [x] **F013** 🟢 Doppeltipp zum schnellen Wiederholen des letzten Wurfs – 0.4s Fenster
- [ ] **F014** 🟡 Zwei-Finger-Zoom der Wurf-Vorschau
- [ ] **F015** 🟡 Aufprall hinterlässt Schmierfleck-Decals am Boden
- [x] **F016** 🟢 Trefferzonen (Kopf = Bonus, Körper = normal)
- [ ] **F017** 🔴 Ricochet-Combo (ein Wurf trifft mehrere Männchen)
- [ ] **F018** 🟡 Magnet-Geschoss, das leicht zum nächsten Ziel zieht
- [ ] **F019** 🟡 Geschoss-Gewicht beeinflusst Reichweite/Bogen
- [x] **F020** 🟢 Konfetti-/Partikel-Schweif hinter dem fliegenden Haufen – Particle Trail

## 🧍 2. Strichmännchen-Varianten (F021–F040)

- [x] **F021** 🟢 Schnelles Männchen (höheres Lauftempo, mehr Punkte) – 150 px/s, 2x Punkte
- [x] **F022** 🟡 Springendes Männchen (hüpft periodisch) – Jump-Phase Sinus-Animation
- [ ] **F023** 🟡 Schild-Männchen (braucht 2 Treffer)
- [ ] **F024** 🔴 Boss-Männchen mit Lebensbalken
- [x] **F025** 🟢 Mini-Männchen (kleines, schwer zu treffendes Ziel) – 0.55x Größe, 3x Punkte
- [ ] **F026** 🟡 Regenschirm-Männchen (blockt Treffer von oben)
- [ ] **F027** 🟡 Ausweichendes Männchen (springt bei Annäherung zur Seite)
- [x] **F028** 🟡 Gold-Männchen (selten, hoher Punktewert) – Gelb, 5x Punkte
- [ ] **F029** 🔴 Bomben-Männchen (Minuspunkte bei Treffer)
- [ ] **F030** 🟡 Gruppen-Männchen, die in Formation laufen
- [ ] **F031** 🟡 Fliegendes Männchen (Jetpack, bewegt sich in der Luft)
- [x] **F032** 🟢 Schlafendes Männchen (steht still, Bonus für Wecken) – Stationär, 4x Punkte, Zzz-Effekt
- [ ] **F033** 🟡 Verkleidetes Männchen (tarnt sich vor Hintergrund)
- [ ] **F034** 🔴 Männchen mit Konter (wirft zurück)
- [x] **F035** 🟢 Variations-Farben/Outfits rein kosmetisch – Farben per Variante (blau, gold, grün)
- [ ] **F036** 🟡 Männchen-Spawnwellen mit ansteigender Schwierigkeit
- [ ] **F037** 🟡 Geh-Richtungs-KI mit Wegpunkten
- [x] **F038** 🟢 Reaktions-Emotes über dem Kopf (Schreck, Wut) – Zzz beim Schlafen
- [ ] **F039** 🔴 Ragdoll-Physik statt Tween beim Umfallen
- [ ] **F040** 🟡 Männchen halten Schilder mit Punktwerten hoch

## 🎁 3. Power-Ups & Items (F041–F058)

- [x] **F041** 🟡 Zeit-Bonus-Pickup (+5 Sekunden)
- [ ] **F042** 🟡 Punkte-Verdopplung für 10 Sekunden
- [ ] **F043** 🟡 Mehrfach-Wurf (3 Geschosse auf einmal)
- [x] **F044** 🟢 Größeres Geschoss temporär
- [ ] **F045** 🟡 Einfrieren – alle Männchen stehen still
- [ ] **F046** 🔴 Regen-Modus: Kackhaufen fallen automatisch vom Himmel
- [ ] **F047** 🟡 Magnet-Power-Up (alle Treffer ziehen an)
- [ ] **F048** 🟡 Schild gegen Bomben-Männchen-Strafe
- [x] **F049** 🟢 Combo-Schutz (Combo läuft kurz nicht ab) – Shield Timer beim Schlafen-Wecken
- [ ] **F050** 🔴 Power-Up-Inventar mit aktivierbaren Slots
- [ ] **F051** 🟡 Zufalls-Würfel-Power-Up (Glücksspiel-Effekt)
- [x] **F052** 🟢 Power-Up-Drop-Animation und Aufsammel-Touch
- [ ] **F053** 🟡 Negativ-Item meiden (Stinkbombe = Punktabzug)
- [ ] **F054** 🟡 Kettenblitz-Geschoss (springt zwischen Zielen)
- [x] **F055** 🟢 Power-Up-Timer-Anzeige im HUD
- [ ] **F056** 🟡 Seltenheitsstufen für Power-Ups (Common→Legendary)
- [ ] **F057** 🔴 Power-Up-Kombinationen (Synergie-Effekte)
- [ ] **F058** 🟡 Boden-Power-Up-Spawner mit Cooldown

## 🗺️ 4. Level & Umgebungen (F059–F076)

- [ ] **F059** 🟡 Mehrere Hintergrund-Themes (Stadt, Strand, Weltraum)
- [ ] **F060** 🟡 Parallax-Scrolling-Hintergrund
- [ ] **F061** 🟡 Hindernisse im Level (Kisten, Mauern)
- [ ] **F062** 🔴 Bewegliche Plattformen, auf denen Männchen laufen
- [ ] **F063** 🟡 Tag-/Nacht-Wechsel mit Beleuchtung
- [ ] **F064** 🟡 Wetter-Effekte (Regen, Schnee, Nebel)
- [ ] **F065** 🟢 Bodentextur-Varianten pro Theme
- [ ] **F066** 🔴 Zerstörbare Umgebungsobjekte
- [ ] **F067** 🟡 Trampoline, die Geschosse abfedern
- [ ] **F068** 🟡 Wasser-/Lava-Zonen mit Spezialeffekt
- [ ] **F069** 🔴 Level-Editor für eigene Anordnungen
- [ ] **F070** 🟡 Scrollendes Level (Kamera folgt)
- [ ] **F071** 🟢 Vordergrund-Deko-Schicht (Büsche, Zäune)
- [ ] **F072** 🟡 Interaktive Schalter, die Fallen auslösen
- [ ] **F073** 🟡 Windzonen-Bereiche im Level
- [ ] **F074** 🔴 Prozedural generierte Level-Layouts
- [x] **F075** 🟢 Animierte Wolken am Himmel – Procedurales Scrolling
- [ ] **F076** 🟡 Verschiedene Bodenhöhen/Hügel

## 🎮 5. Spielmodi (F077–F094)

- [ ] **F077** 🟡 Endlos-Modus ohne Timer (bis 3 Fehlwürfe)
- [ ] **F078** 🟡 Zeitrennen: möglichst schnell X Männchen treffen
- [ ] **F079** 🟡 Präzisions-Modus mit begrenzter Munition
- [ ] **F080** 🔴 Story-/Kampagnen-Modus mit Leveln
- [ ] **F081** 🟡 Herausforderungs-Modus mit Tagesaufgaben
- [ ] **F082** 🔴 Lokaler 2-Spieler-Wettkampf (geteilter Bildschirm)
- [ ] **F083** 🟡 Überlebens-Modus mit Männchen-Wellen
- [ ] **F084** 🟡 Bonus-Runde (Goldregen)
- [x] **F085** 🟢 Übungsmodus ohne Zeitdruck – practice mode mit 999s Timer
- [ ] **F086** 🔴 Boss-Rush-Modus
- [ ] **F087** 🟡 Modifikator-Modus (Mutatoren wählbar)
- [ ] **F088** 🟡 Hardcore-Modus (ein Fehlwurf = Ende)
- [x] **F089** 🟢 Schwierigkeitsgrade (leicht/mittel/schwer) – easy/normal/hard mit unterschiedlichen Einstellungen
- [ ] **F090** 🔴 Wöchentliche Sonder-Events
- [ ] **F091** 🟡 Ziel-Quoten-Modus (genau X treffen, nicht mehr)
- [ ] **F092** 🟡 Combo-Jagd-Modus (höchste Combo zählt)
- [ ] **F093** 🟢 Zen-Modus (entspannt, keine Wertung)
- [ ] **F094** 🔴 Modus-Auswahl-Menü mit Vorschau

## 📈 6. Progression & Wirtschaft (F095–F112)

- [ ] **F095** 🟡 Münzwährung für Treffer sammeln
- [ ] **F096** 🟡 Shop zum Kauf von Skins/Power-Ups
- [ ] **F097** 🔴 XP- und Spielerlevel-System
- [ ] **F098** 🟡 Freischaltbare Geschoss-Skins (Mais, Wurst …)
- [ ] **F099** 🟡 Freischaltbare Schleuder-Designs
- [ ] **F100** 🔴 Skill-Tree für permanente Boni
- [ ] **F101** 🟢 Tägliche Login-Belohnung
- [ ] **F102** 🟡 Sammelkarten/Sticker für getroffene Männchen-Typen
- [ ] **F103** 🔴 Battle-Pass-/Season-System
- [ ] **F104** 🟡 Münz-Verdopplung nach Runde (Werbung optional)
- [ ] **F105** 🟢 Sternebewertung pro Level (1–3 Sterne)
- [ ] **F106** 🟡 Meilenstein-Belohnungen (Gesamttreffer)
- [ ] **F107** 🔴 Prestige-/Neustart-System mit Bonus
- [ ] **F108** 🟡 Truhen/Lootboxen mit Zufallsinhalt
- [ ] **F109** 🟢 Geschenk-Code-Einlösung
- [ ] **F110** 🟡 Upgrade-Stufen für Wurfkraft kaufbar
- [ ] **F111** 🟡 Sammel-Album/Kompendium der Männchen
- [ ] **F112** 🔴 Währungs-Persistenz mit Cloud-Sync (→F151)

## 🖥️ 7. UI / UX & HUD (F113–F130)

- [x] **F113** 🟢 Hauptmenü-Szene mit Start/Optionen/Beenden – MainMenu.tscn
- [x] **F114** 🟢 Pause-Menü mit Fortsetzen/Neustart/Beenden – PauseMenu.tscn
- [x] **F115** 🟡 Animierter Combo-Zähler mit Skalierung – ComboLabel mit Update
- [x] **F116** 🟢 Treffer-Punktzahl als aufsteigender Text (Floating Text) – FloatingText.tscn
- [x] **F117** 🟡 Countdown „3-2-1-Los!" zum Rundenstart – _run_countdown()
- [x] **F118** 🟢 Timer wird in letzten 10 Sekunden rot/pulsiert – _timer_warning Flag
- [x] **F119** 🟡 Fortschrittsbalken zum nächsten Combo-Level – _combo_bar ProgressBar
- [x] **F120** 🟢 Bestätigungsdialog beim Verlassen – ConfirmationDialog
- [ ] **F121** 🟡 Responsives HUD-Layout für Notch/Safe-Area
- [x] **F122** 🟢 Highscore-Anzeige im Hauptmenü – Im MainMenu implementiert
- [ ] **F123** 🟡 Toast-Benachrichtigungen (z. B. „Neuer Rekord!")
- [ ] **F124** 🟢 Einstellungs-Button im HUD
- [ ] **F125** 🟡 Anim. Szenenübergänge (Fade/Wipe)
- [x] **F126** 🟢 Treffer-Streak-Anzeige – 🔥 Icon mit Zähler ab 3
- [ ] **F127** 🟡 Mini-Map/Übersicht bei scrollenden Leveln (→F070)
- [ ] **F128** 🟢 Theme-fähige UI (heller/dunkler Stil)
- [ ] **F129** 🟡 On-Screen-Tooltips für Power-Ups
- [ ] **F130** 🟢 GameOver-Screen zeigt Statistiken (Treffer, beste Combo)

## 🔊 8. Audio (F131–F142)

- [x] **F131** 🟢 Mehrere Furz-Varianten (zufällig) – SoundGen.fart() mit 5 Varianten
- [x] **F132** 🟢 Wurf-Soundeffekt (Schwung/Whoosh) – SoundGen.whoosh() prozedural
- [x] **F133** 🟢 Aufprall-Platsch-Sound – SoundGen.impact() beim Treffer
- [ ] **F134** 🟡 Hintergrundmusik-Loop pro Theme
- [x] **F135** 🟢 Combo-Jingle bei Steigerung – SoundGen.combo_jingle() Arpeggio
- [x] **F136** 🟢 UI-Klick-Sounds – SoundGen.click() in Menüs
- [ ] **F137** 🟡 Lautstärkeregler für Musik/SFX getrennt
- [x] **F138** 🟢 Countdown-Tick-Sound – SoundGen.countdown_tick() bei "3-2-1"
- [ ] **F139** 🟡 Dynamische Musik (intensiver bei hoher Combo)
- [x] **F140** 🟢 Stummschalt-Button – 🔊/🔇 Icon Toggle
- [ ] **F141** 🟡 Sprach-Samples/Jubel bei Highscore
- [ ] **F142** 🟡 Audio-Bus-Setup mit Effekten (Reverb)

## ✨ 9. Visuelle Effekte & Polish (F143–F156)

- [x] **F143** 🟢 Treffer-Partikel (braune Spritzer) – HitEffect.tscn
- [x] **F144** 🟢 Screen-Shake bei Treffer – shake_strength mit decay
- [ ] **F145** 🟡 Slow-Motion-Effekt beim letzten Treffer der Runde
- [x] **F146** 🟢 Combo-Aura/Glow um den Spieler – _aura_phase Sine-Animation
- [ ] **F147** 🟡 Geschoss-Trail mit Verblass-Effekt
- [ ] **F148** 🟡 Stink-Wölkchen über getroffenen Männchen
- [ ] **F149** 🟢 Aufblitzen des Bildschirms bei Mega-Combo
- [ ] **F150** 🟡 Animierter Wackel-Effekt der Schleuder beim Spannen
- [ ] **F151** 🔴 Beleuchtung/Schatten via CanvasModulate + Light2D
- [ ] **F152** 🟢 Sterne/Konfetti beim Rundensieg
- [ ] **F153** 🟡 Umgebungs-Animationen (schwankende Bäume)
- [x] **F154** 🟢 Treffer-Hitstop (kurzer Freeze-Frame) – Queue Delete mit Delay
- [ ] **F155** 🟡 Anpassbare Geschoss-Spuren (Skins)
- [ ] **F156** 🟡 Shader-basierter Hitze-/Stink-Verzerrungseffekt

## 🕹️ 10. Steuerung & Eingabe (F157–F166)

- [ ] **F157** 🟢 Haptisches Feedback (Vibration) bei Treffer
- [ ] **F158** 🟡 Links-/Rechtshänder-Modus (Schleuder spiegeln)
- [ ] **F159** 🟡 Multi-Touch: zwei Schleudern gleichzeitig
- [x] **F160** 🟢 Empfindlichkeit der Zugweite einstellbar – max_drag_distance Export (350 px default)
- [ ] **F161** 🟡 Alternative Tipp-zum-Zielen-Steuerung
- [ ] **F162** 🟢 Touch-Bereich-Visualisierung im Tutorial
- [ ] **F163** 🟡 Gamepad-Unterstützung (optional)
- [x] **F164** 🟢 Abbruch des Wurfs durch Zurückziehen in den Anker – 30px proximity check
- [ ] **F165** 🟡 Geste zum schnellen Power-Up-Einsatz
- [ ] **F166** 🟢 Konfigurierbare Vibrationsstärke

## 🌐 11. Soziales & Online (F167–F178)

- [ ] **F167** 🔴 Online-Bestenliste (Leaderboard)
- [x] **F168** 🟡 Lokale Highscore-Tabelle (Top 10) – ConfigFile in GameManager
- [ ] **F169** 🔴 Google Play Games Services Integration
- [ ] **F170** 🟡 Erfolge mit Play-Games synchronisieren
- [ ] **F171** 🟡 Screenshot-/Score-Teilen-Button
- [ ] **F172** 🔴 Freundes-Challenges (asynchron)
- [ ] **F173** 🟡 Wöchentliche Online-Turniere
- [ ] **F174** 🟢 „Schlag deinen Highscore"-Aufforderung
- [ ] **F175** 🔴 Cloud-Speicherstand (→F112)
- [ ] **F176** 🟡 Geister-Replay des Bestlaufs
- [ ] **F177** 🟡 Regionale/globale Ranglisten-Filter
- [ ] **F178** 🟢 Teilen-Text mit Deep-Link zum Spiel

## ⚙️ 12. Einstellungen & Barrierefreiheit (F179–F188)

- [ ] **F179** 🟢 Einstellungs-Szene mit persistenten Optionen
- [ ] **F180** 🟡 Farbenblind-Modus / hoher Kontrast
- [ ] **F181** 🟢 Bildschirm-Erschütterung abschaltbar
- [ ] **F182** 🟡 Schriftgröße skalierbar
- [ ] **F183** 🟢 Reduzierte-Bewegung-Option
- [ ] **F184** 🟡 Eingabe-Hilfe (größere Trefferzonen)
- [ ] **F185** 🟢 Untertitel/Text für Audio-Hinweise
- [ ] **F186** 🟡 Linkshänder-UI-Spiegelung (→F158)
- [ ] **F187** 🟢 Reset-auf-Standard-Button in Optionen
- [ ] **F188** 🟡 Datenschutz-/Werbe-Einwilligung (Consent) – GDPR

## 🌍 13. Lokalisierung (F189–F194)

- [ ] **F189** 🟡 i18n-System mit Übersetzungs-CSV
- [ ] **F190** 🟢 Englische Übersetzung
- [ ] **F191** 🟢 Spanische Übersetzung
- [ ] **F192** 🟢 Französische Übersetzung
- [ ] **F193** 🟡 Sprachauswahl in den Optionen
- [ ] **F194** 🟢 Automatische Erkennung der Systemsprache

## 🛠️ 14. Technik, Test & Monetarisierung (F195–F200)

- [x] **F195** 🟡 Speicher-/Lade-System (ConfigFile) für Fortschritt – _save_game() / _load_game()
- [ ] **F196** 🔴 Belohnungs-Werbung (Rewarded Ads) Integration
- [ ] **F197** 🟡 Banner-/Interstitial-Werbung (optional, abschaltbar)
- [ ] **F198** 🟡 Performance-Optimierung: Objekt-Pooling für Geschosse/Männchen
- [ ] **F199** 🟡 Unit-Tests für GameManager (Score/Combo/Timer) via GUT
- [ ] **F200** 🟢 Analytics-Events (Rundenstart, Score, Modus) – datenschutzkonform

---

## 📊 Übersicht

| Kategorie | Features | IDs |
|-----------|---------:|-----|
| Wurf- & Kernmechanik | 20 | F001–F020 |
| Strichmännchen-Varianten | 20 | F021–F040 |
| Power-Ups & Items | 18 | F041–F058 |
| Level & Umgebungen | 18 | F059–F076 |
| Spielmodi | 18 | F077–F094 |
| Progression & Wirtschaft | 18 | F095–F112 |
| UI / UX & HUD | 18 | F113–F130 |
| Audio | 12 | F131–F142 |
| Visuelle Effekte & Polish | 14 | F143–F156 |
| Steuerung & Eingabe | 10 | F157–F166 |
| Soziales & Online | 12 | F167–F178 |
| Einstellungen & Barrierefreiheit | 10 | F179–F188 |
| Lokalisierung | 6 | F189–F194 |
| Technik, Test & Monetarisierung | 6 | F195–F200 |
| **Gesamt** | **200** | **F001–F200** |

> 💡 **Nächste empfohlene Schritte (schnelle Wins):**
> F113 (Hauptmenü), F114 (Pause), F116 (Floating Score), F131–F133 (Audio),
> F143/F144 (Partikel + Screen-Shake), F168 (lokaler Highscore), F195 (Speichern).
