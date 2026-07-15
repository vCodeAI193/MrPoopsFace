# 💩 Stinky Toss

Ein lustiges 2D-Casual-Physik-Spiel für **Android-Tablets**, gebaut mit **Godot 4.x**.
Wirf Kackhaufen auf Strichmännchen und sammle in 60 Sekunden so viele Punkte wie möglich!

## 🎮 Spielprinzip

- **Ziehen & Loslassen** (wie Angry Birds): Finger aufsetzen, zurückziehen, loslassen – der Kackhaufen fliegt in einer Parabel los.
- **Treffer** lassen die Strichmännchen umfallen und einen Furz von sich geben.
- **Combo-Multiplikator**: Schnelle Treffer hintereinander geben mehr Punkte.
- **60-Sekunden-Runde**, danach Endbildschirm mit „Nochmal werfen!".

## 🧩 Projektstruktur

```
project.godot            # Projektkonfiguration (Landscape, Touch, 1920x1200)
export_presets.cfg       # Android-Export (com.yourname.stinkytoss, minSDK 21)
icon.svg                 # App-Icon
scenes/
  MainMenu.tscn          # Startbildschirm (Spielen/Beenden, Highscore)
  Main.tscn              # Spielschleife, HUD, Countdown, Kamera-Shake
  Player.tscn            # Schleuder-/Wurfmechanik mit Touch-Eingabe
  Maennchen.tscn         # Strichmännchen mit Treffer-Animation + Furzsound
  Projectile.tscn        # Kackhaufen (RigidBody2D)
  PauseMenu.tscn         # Pause-Overlay (Fortsetzen/Neustart/Hauptmenü)
  GameOver.tscn          # Endbildschirm (Score, Rekord, Wiederholen/Menü)
  FloatingText.tscn      # Aufsteigender "+Punkte"-Text
  HitEffect.tscn         # Partikel-Spritzer beim Treffer
scripts/
  GameManager.gd         # Autoload: Score, Combo, Timer, Highscore, Speichern
  SoundGen.gd            # Prozedurale Soundeffekte (Furz/Whoosh/Splat)
  MainMenu.gd            # Startbildschirm-Logik
  Main.gd                # Spawner, Varianten, HUD, Countdown, Screen-Shake
  Player.gd              # Touch-Steuerung, Wurfberechnung, Combo-Aura
  Maennchen.gd           # Treffer-Erkennung, Animation, Effekte, Varianten
  MaennchenBody.gd       # Zeichnet das Strichmännchen
  Projectile.gd          # Zeichnet den Kackhaufen, Aufprall-Sound
  PauseMenu.gd           # Pause-Logik
  GameOver.gd            # Endbildschirm-Logik
  FloatingText.gd        # Animation des Punkte-Texts
  HitEffect.gd           # Selbstaufräumende Partikel
```

## 🎯 Männchen-Varianten

| Variante | Größe | Tempo | Punktebonus | Häufigkeit |
|----------|-------|-------|-------------|-----------|
| Normal   | 100 % | mittel | x1 | häufig |
| Schnell (blau) | 90 % | hoch | x2 | gelegentlich |
| Mini     | 55 % | mittel | x3 | selten |
| Gold     | 100 % | langsam | x5 | sehr selten |

## 🛠️ Anpassbare Werte (`@export`)

| Skript          | Variable           | Bedeutung                          |
|-----------------|--------------------|------------------------------------|
| GameManager.gd  | `round_duration`   | Rundenlänge in Sekunden            |
| GameManager.gd  | `base_hit_points`  | Grundpunkte pro Treffer            |
| Player.gd       | `throw_power`      | Wurfstärke                         |
| Player.gd       | `max_drag_distance`| Maximale Ziehweite                 |
| Main.gd         | `spawn_rate`       | Sekunden zwischen zwei Spawns      |
| Main.gd         | `max_maennchen`    | Max. gleichzeitige Männchen        |

## ▶️ Starten

1. Projekt in **Godot 4.x** öffnen (`project.godot`).
2. Mit **F5** starten (Maus erzeugt im Editor automatisch Touch-Events).

## 📦 Android-Export

1. In Godot: **Editor → Verwalte Export-Vorlagen** installieren.
2. Unter **Editor → Editor-Einstellungen → Export → Android** die Pfade zum Android SDK
   und zu einem Debug-Keystore setzen (für Release-Builds eigenen Keystore anlegen).
3. **Projekt → Exportieren → Android** (Vorlage liegt bereits als `export_presets.cfg` vor).
4. Paketname: `com.vcodeai.stinkytoss`, Min-SDK 21, nur Landscape,
   Vibrations-Berechtigung ist gesetzt (für haptisches Feedback).
5. Optional: Launcher-Icons (PNG, 192×192 und adaptiv 432×432) aus `icon.svg`
   exportieren und im Preset unter `launcher_icons/` eintragen.

## 📱 Verhalten auf dem Gerät

- **Zurück-Taste**: öffnet im Spiel das Pause-Menü, im Hauptmenü einen Beenden-Dialog.
- **Fokusverlust** (Anruf, Home-Button): laufende Runden pausieren automatisch.
- **Erster Start**: kurzes Tutorial erklärt die Schleuder-Steuerung (einmalig).

Alle Grafiken und der Furzsound werden **prozedural im Code erzeugt** – es sind keine externen Assets nötig.
