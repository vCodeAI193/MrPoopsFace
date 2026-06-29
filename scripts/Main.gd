extends Node2D
## Main – Spielschleife: Countdown, Spawnen der Strichmännchen
## und Aktualisierung der HUD (Punkte, Timer, Combo).

@export var maennchen_scene: PackedScene        ## Szene des Strichmännchens
@export var spawn_rate: float = 1.4             ## Sekunden zwischen zwei Spawns
@export var max_maennchen: int = 8              ## Maximale gleichzeitige Männchen
@export var ground_y: float = 1050.0            ## Höhe der Bodenlinie (Y in Pixel)
@export var spawn_x_min: float = 500.0          ## Linker Spawn-Rand
@export var spawn_x_max: float = 1820.0         ## Rechter Spawn-Rand

# --- Screen-Shake (F144) ---
@export var shake_per_hit: float = 7.0          ## Stärkezuwachs pro Treffer
@export var shake_max: float = 26.0             ## Maximale Erschütterung
@export var shake_decay: float = 45.0           ## Abklinggeschwindigkeit

# --- Männchen-Varianten (F021/F025/F028) ---
## Jede Variante: scale, speed, color, mult, weight; optional jump_height, sleeping, has_shield (F022/F032/F023)
const VARIANTS: Array = [
	{"scale": 1.0, "speed": 60.0, "color": Color(0.1, 0.1, 0.1), "mult": 1, "weight": 70, "jump_height": 0.0, "sleeping": false, "has_shield": false},
	{"scale": 0.9, "speed": 150.0, "color": Color(0.15, 0.35, 0.8), "mult": 2, "weight": 22, "jump_height": 0.0, "sleeping": false, "has_shield": false},   # schnell
	{"scale": 0.55, "speed": 85.0, "color": Color(0.1, 0.1, 0.1), "mult": 3, "weight": 14, "jump_height": 0.0, "sleeping": false, "has_shield": false},     # mini
	{"scale": 1.0, "speed": 45.0, "color": Color(0.95, 0.75, 0.05), "mult": 5, "weight": 5, "jump_height": 0.0, "sleeping": false, "has_shield": false},    # gold
	{"scale": 0.88, "speed": 75.0, "color": Color(0.1, 0.55, 0.15), "mult": 2, "weight": 18, "jump_height": 110.0, "sleeping": false, "has_shield": false}, # springend (F022)
	{"scale": 1.05, "speed": 0.0, "color": Color(0.2, 0.22, 0.32), "mult": 4, "weight": 8, "jump_height": 0.0, "sleeping": true, "has_shield": false},     # schlafend (F032)
	{"scale": 1.15, "speed": 50.0, "color": Color(0.35, 0.35, 0.35), "mult": 2, "weight": 8, "jump_height": 0.0, "sleeping": false, "has_shield": true},   # Schild (F023)
]

@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _score_label: Label = $HUD/TopBar/ScoreLabel
@onready var _time_label: Label = $HUD/TopBar/TimeLabel
@onready var _combo_label: Label = $HUD/TopBar/ComboLabel
@onready var _combo_bar: ProgressBar = $HUD/ComboBar
@onready var _powerup_label: Label = $HUD/PowerUpLabel
@onready var _pause_button: Button = $HUD/PauseButton
@onready var _mute_button: Button = $HUD/MuteButton
@onready var _countdown_label: Label = $HUD/CountdownLabel
@onready var _streak_label: Label = $HUD/TopBar/StreakLabel
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _camera: Camera2D = $Camera2D

# Audio Players (F135, F136, F138, F140)
var _combo_jingle_player: AudioStreamPlayer
var _ui_click_player: AudioStreamPlayer
var _countdown_tick_player: AudioStreamPlayer
var _muted: bool = false

var _shake_strength: float = 0.0
var _timer_warning: bool = false               ## Läuft der rote Timer-Warnmodus? (F118)
var _last_shown_second: int = -1

# F075 – Animierte Wolken
var _clouds: Array = []


func _ready() -> void:
	randomize()

	# Schwierigkeitsmultiplikatoren anwenden (F089)
	match GameManager.difficulty:
		"easy":
			max_maennchen = 5
			spawn_rate = 2.0
		"hard":
			max_maennchen = 12
			spawn_rate = 0.9

	# HUD mit den GameManager-Signalen verbinden
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.streak_changed.connect(_on_streak_changed)
	GameManager.hit_registered.connect(_on_hit_registered)

	# Pause-Knopf verbinden (F114)
	_pause_button.pressed.connect(_on_pause_pressed)
	# Stummschalt-Knopf verbinden (F140)
	_mute_button.pressed.connect(_on_mute_pressed)

	# Audio-Player erstellen (F135, F136, F138)
	_combo_jingle_player = AudioStreamPlayer.new()
	_ui_click_player = AudioStreamPlayer.new()
	_countdown_tick_player = AudioStreamPlayer.new()
	add_child(_combo_jingle_player)
	add_child(_ui_click_player)
	add_child(_countdown_tick_player)

	# Spawn-Timer einrichten (wird erst nach dem Countdown gestartet)
	_spawn_timer.wait_time = spawn_rate
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	# HUD-Anfangswerte setzen
	_on_score_changed(0)
	_on_combo_changed(0)
	_time_label.text = "Zeit: %d" % int(GameManager.round_duration)

	# Wolken initialisieren (F075)
	_init_clouds()

	# Countdown abspielen, dann die Runde starten (F117)
	_run_countdown()


func _process(delta: float) -> void:
	# Screen-Shake abklingen lassen und auf die Kamera anwenden (F144)
	if _shake_strength > 0.0:
		_camera.offset = Vector2(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
		_shake_strength = maxf(_shake_strength - shake_decay * delta, 0.0)
		if _shake_strength <= 0.0:
			_camera.offset = Vector2.ZERO

	# Wolken animieren (F075)
	for cloud in _clouds:
		cloud["pos"].x += cloud["speed"] * delta
		if cloud["pos"].x > 2200:
			cloud["pos"].x = -280
			cloud["pos"].y = randf_range(70, 330)
	queue_redraw()

	# Combo-Fortschrittsbalken aktualisieren (F119)
	if GameManager.combo > 0:
		_combo_bar.value = GameManager.combo_timer_pct * 100.0
		_combo_bar.visible = true
		_combo_bar.modulate = Color(1.0, 0.8, 0.0) if GameManager.combo_shield_active else Color.WHITE
	else:
		_combo_bar.visible = false

	# Power-Up-Timer-Anzeige (F055)
	var pu_text: String = ""
	if "time_bonus" in GameManager.active_powerups:
		pu_text += "⏱ +5s (%.1fs)\n" % GameManager.get_powerup_remaining("time_bonus")
	if "big_projectile" in GameManager.active_powerups:
		pu_text += "●+1.5x (%.1fs)" % GameManager.get_powerup_remaining("big_projectile")
	if pu_text.is_empty():
		_powerup_label.visible = false
	else:
		_powerup_label.text = pu_text.trim_suffix("\n")
		_powerup_label.visible = true


## Spielt den Start-Countdown "3 – 2 – 1 – Los!" und startet danach die Runde (F117).
## Countdown-Tick-Sounds bei jedem Tick (F138).
func _run_countdown() -> void:
	# Drehpunkt = Bildschirmmitte (Label füllt die Basis-Auflösung 1920x1200)
	_countdown_label.pivot_offset = Vector2(960, 600)
	_countdown_label.visible = true
	for n in ["3", "2", "1"]:
		_countdown_label.text = n
		_pop_label(_countdown_label, 1.8, Vector2(960, 600))
		_play_countdown_tick()  # F138
		await get_tree().create_timer(0.8).timeout
	_countdown_label.text = "Los!"
	_pop_label(_countdown_label, 1.8, Vector2(960, 600))
	await get_tree().create_timer(0.7).timeout
	_countdown_label.visible = false

	# Jetzt erst läuft die eigentliche Runde
	GameManager.start_game()
	_spawn_timer.start()
	_on_time_changed(GameManager.time_left)


## Reagiert auf einen Treffer mit einer Kamera-Erschütterung (F144).
func _on_hit_registered(_points: int) -> void:
	_shake_strength = minf(_shake_strength + shake_per_hit, shake_max)


## Öffnet das Pause-Overlay (F114).
func _on_pause_pressed() -> void:
	_pause_menu.show_pause()


## Schaltet Stummschaltung um (F140).
func _on_mute_pressed() -> void:
	toggle_mute()
	_mute_button.text = "🔇" if _muted else "🔊"


## Spawnt ein neues Strichmännchen, solange das Limit nicht erreicht ist.
func _on_spawn_timer_timeout() -> void:
	if not GameManager.game_active:
		return
	if maennchen_scene == null:
		push_warning("Keine maennchen_scene zugewiesen!")
		return
	if get_tree().get_nodes_in_group("maennchen").size() >= max_maennchen:
		return

	var maennchen: Maennchen = maennchen_scene.instantiate()
	maennchen.position = Vector2(randf_range(spawn_x_min, spawn_x_max), ground_y)
	_apply_variant(maennchen)
	add_child(maennchen)


## Wählt per Gewichtung eine Variante und überträgt ihre Werte auf das Männchen.
func _apply_variant(maennchen: Maennchen) -> void:
	var variant: Dictionary = _pick_weighted_variant()
	var s: float = variant["scale"]
	maennchen.scale = Vector2(s, s)            # skaliert Optik UND Trefferbereich
	maennchen.walk_speed = variant["speed"]
	maennchen.figure_color = variant["color"]
	maennchen.point_multiplier = variant["mult"]
	maennchen.jump_height = variant.get("jump_height", 0.0)
	maennchen.sleeping = variant.get("sleeping", false)
	maennchen.has_shield = variant.get("has_shield", false)


## Liefert eine zufällige Variante entsprechend ihrer Gewichtung.
func _pick_weighted_variant() -> Dictionary:
	var total: int = 0
	for v in VARIANTS:
		total += int(v["weight"])
	var roll: int = randi() % total
	for v in VARIANTS:
		roll -= int(v["weight"])
		if roll < 0:
			return v
	return VARIANTS[0]


# --- HUD-Aktualisierungen ---

func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Punkte: %d" % new_score


func _on_time_changed(seconds_left: float) -> void:
	var secs: int = int(ceil(seconds_left))
	_time_label.text = "Zeit: %d" % secs

	# Letzte 10 Sekunden: Timer rot färben und pro Sekunde pulsieren (F118)
	if seconds_left <= 10.0 and GameManager.game_active:
		if not _timer_warning:
			_timer_warning = true
			_time_label.modulate = Color(1.0, 0.25, 0.2)
		if secs != _last_shown_second:
			_pop_label(_time_label, 1.4)
	elif _timer_warning:
		_timer_warning = false
		_time_label.modulate = Color.WHITE
	_last_shown_second = secs


func _on_combo_changed(new_combo: int) -> void:
	if new_combo >= 2:
		_combo_label.text = "Combo x%d!" % new_combo
		_combo_label.visible = true
		_pop_label(_combo_label, 1.5)          # animierter Combo-Zähler (F115)
		if new_combo == 2 or new_combo % 5 == 0:  # Jingle bei 2+ und alle 5er (F135)
			play_combo_jingle()
	else:
		_combo_label.visible = false


## Zeigt die Treffer-Streak an (F126)
func _on_streak_changed(new_streak: int) -> void:
	if new_streak >= 3:
		_streak_label.text = "🔥 Streak: %d" % new_streak
		_streak_label.visible = true
	else:
		_streak_label.visible = false


## Kleiner "Pop"-Effekt: Element kurz vergrößern und auf Normalgröße zurückfedern.
## Mit pivot < 0 wird der Drehpunkt automatisch in die Elementmitte gelegt.
func _pop_label(label: Control, from_scale: float, pivot: Vector2 = Vector2(-1, -1)) -> void:
	label.pivot_offset = label.size * 0.5 if pivot.x < 0.0 else pivot
	label.scale = Vector2(from_scale, from_scale)
	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Wolken (F075) ---

## Füllt das _clouds-Array mit zufällig verteilten Wolken.
func _init_clouds() -> void:
	for i in 7:
		_clouds.append({
			"pos": Vector2(randf_range(-200, 2100), randf_range(70, 340)),
			"speed": randf_range(14, 38),
			"size": randf_range(75, 165),
			"alpha": randf_range(0.45, 0.82)
		})


## Zeichnet alle Wolken hinter der Spielszene (F075).
func _draw() -> void:
	for c in _clouds:
		_draw_cloud(c["pos"], c["size"], c["alpha"])


## Zeichnet eine einzelne Wolke aus drei überlappenden Kreisen.
func _draw_cloud(pos: Vector2, size: float, alpha: float) -> void:
	var col: Color = Color(1, 1, 1, alpha)
	draw_circle(pos, size * 0.6, col)
	draw_circle(pos + Vector2(size * 0.56, size * 0.08), size * 0.48, col)
	draw_circle(pos + Vector2(-size * 0.46, size * 0.1), size * 0.44, col)
	draw_circle(pos + Vector2(size * 0.18, -size * 0.32), size * 0.42, col)


# --- Audio (F135, F136, F138, F140) ---

## Gibt den Countdown-Tick-Sound aus (F138)
func _play_countdown_tick() -> void:
	if _muted:
		return
	_countdown_tick_player.stream = SoundGen.countdown_tick()
	_countdown_tick_player.play()


## Gibt das Combo-Jingle aus, wenn Combo >= 2 (F135)
func play_combo_jingle() -> void:
	if _muted:
		return
	_combo_jingle_player.stream = SoundGen.combo_jingle()
	_combo_jingle_player.play()


## Gibt den UI-Klick-Sound aus (F136)
func play_ui_click() -> void:
	if _muted:
		return
	_ui_click_player.stream = SoundGen.click()
	_ui_click_player.play()


## Schaltet den Ton an/aus (F140)
func toggle_mute() -> void:
	_muted = not _muted
