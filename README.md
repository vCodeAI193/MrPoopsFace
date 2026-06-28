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
  Main.tscn              # Spielschleife, HUD (Punkte, Timer, Combo)
  Player.tscn            # Schleuder-/Wurfmechanik mit Touch-Eingabe
  Maennchen.tscn         # Strichmännchen mit Treffer-Animation + Furzsound
  Projectile.tscn        # Kackhaufen (RigidBody2D)
  GameOver.tscn          # Endbildschirm mit Wiederholen-Knopf
scripts/
  GameManager.gd         # Autoload: Score-, Combo- und Timer-Status
  Main.gd                # Spawner & HUD-Logik
  Player.gd              # Touch-Steuerung & Wurfberechnung
  Maennchen.gd           # Treffer-Erkennung, Animation, prozeduraler Furz
  MaennchenBody.gd       # Zeichnet das Strichmännchen
  Projectile.gd          # Zeichnet den Kackhaufen
  GameOver.gd            # Endbildschirm-Logik
```

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
2. **Projekt → Exportieren → Android** (Vorlage liegt bereits als `export_presets.cfg` vor).
3. Paketname: `com.yourname.stinkytoss`, Min-SDK 21, nur Landscape.

Alle Grafiken und der Furzsound werden **prozedural im Code erzeugt** – es sind keine externen Assets nötig.
