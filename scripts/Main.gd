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
	{"scale": 1.0, "speed": 80.0, "color": Color(0.65, 0.08, 0.08), "mult": 0, "weight": 10, "jump_height": 0.0, "sleeping": false, "has_shield": false, "is_bomb": true},  # Bombe (F029)
	{"scale": 1.0, "speed": 55.0, "color": Color(0.45, 0.15, 0.55), "mult": 3, "weight": 8, "jump_height": 0.0, "sleeping": false, "has_shield": false, "has_umbrella": true},  # Regenschirm (F026)
	{"scale": 0.95, "speed": 90.0, "color": Color(0.85, 0.45, 0.1), "mult": 3, "weight": 10, "jump_height": 0.0, "sleeping": false, "has_shield": false, "dodges": true},  # ausweichend (F027)
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
@onready var _ammo_label: Label = $HUD/TopBar/AmmoLabel
@onready var _miss_label: Label = $HUD/TopBar/MissLabel
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _settings: SettingsOverlay = $Settings
@onready var _tutorial: TutorialOverlay = $Tutorial
@onready var _settings_button: Button = $HUD/SettingsButton
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

# F123 – Toast-Benachrichtigungen
var _toast_label: Label
var _toast_tween: Tween

# F149 – Bildschirm-Aufblitzen bei Mega-Combo
var _flash_rect: ColorRect

# F083 – Wellenzähler im Überlebens-Modus
var _wave_count: int = 0

# F084 – Bonus-Runde Goldregen
var _bonus_done: bool = false
var _bonus_active: bool = false


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
	GameManager.powerup_activated.connect(_on_powerup_activated)
	GameManager.ammo_changed.connect(_on_ammo_changed)
	GameManager.misses_changed.connect(_on_misses_changed)

	# Pause-Knopf verbinden (F114)
	_pause_button.pressed.connect(_on_pause_pressed)
	# Stummschalt-Knopf verbinden (F140)
	_mute_button.pressed.connect(_on_mute_pressed)
	# Optionen-Knopf verbinden (F124): öffnet die Einstellungen und pausiert
	_settings_button.pressed.connect(func() -> void: _settings.show_settings(true))

	# Audio-Player erstellen (F135, F136, F138); alle auf den SFX-Bus (F137/F142)
	_combo_jingle_player = AudioStreamPlayer.new()
	_ui_click_player = AudioStreamPlayer.new()
	_countdown_tick_player = AudioStreamPlayer.new()
	for p in [_combo_jingle_player, _ui_click_player, _countdown_tick_player]:
		p.bus = "SFX"
		add_child(p)

	# Spawn-Timer einrichten (wird erst nach dem Countdown gestartet)
	_spawn_timer.wait_time = spawn_rate
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	# HUD-Anfangswerte setzen
	_on_score_changed(0)
	_on_combo_changed(0)
	_time_label.text = "Zeit: %d" % int(GameManager.round_duration)

	# HUD an den Spielmodus anpassen (F077/F083/F092/F093)
	_apply_mode_hud()

	# Wolken initialisieren (F075)
	_init_clouds()

	# Toast-Label für Benachrichtigungen erstellen (F123)
	_toast_label = Label.new()
	_toast_label.visible = false
	_toast_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast_label.offset_top = 200.0
	_toast_label.offset_bottom = 280.0
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 52)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
	_toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_toast_label.add_theme_constant_override("outline_size", 10)
	$HUD.add_child(_toast_label)

	# Vollbild-Flash-Overlay für Mega-Combos erstellen (F149)
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(_flash_rect)

	# Wellen-Schwierigkeit alle 15 Sekunden erhöhen (F036)
	var wave_timer: Timer = Timer.new()
	wave_timer.wait_time = 15.0
	wave_timer.timeout.connect(_on_wave_tick)
	add_child(wave_timer)
	wave_timer.start()

	# Erst-Start-Tutorial vor dem Countdown zeigen (F162)
	if not GameManager.tutorial_seen:
		_tutorial.show_tutorial()
		await _tutorial.tutorial_closed
		GameManager.mark_tutorial_seen()

	# Countdown abspielen, dann die Runde starten (F117)
	_run_countdown()


## Zeitlupe nie in andere Szenen mitnehmen (F012-Sicherheitsnetz):
## greift bei Neustart und Wechsel ins Hauptmenü.
func _exit_tree() -> void:
	Engine.time_scale = 1.0


## Android-Lebenszyklus: bei Fokusverlust (Anruf, Home-Button) automatisch
## pausieren; die Zurück-Taste öffnet das Pause-Menü statt die App zu beenden.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			if GameManager.game_active and not get_tree().paused:
				_pause_menu.show_pause()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if not get_tree().paused:
				_pause_menu.show_pause()


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
		pu_text += "●+1.5x (%.1fs)\n" % GameManager.get_powerup_remaining("big_projectile")
	if "points_double" in GameManager.active_powerups:
		pu_text += "2x Punkte (%.1fs)\n" % GameManager.get_powerup_remaining("points_double")
	if "freeze" in GameManager.active_powerups:
		pu_text += "❄ Eingefroren (%.1fs)\n" % GameManager.get_powerup_remaining("freeze")
	if "magnet" in GameManager.active_powerups:
		pu_text += "Magnet (%.1fs)\n" % GameManager.get_powerup_remaining("magnet")
	if "bomb_shield" in GameManager.active_powerups:
		pu_text += "Bomben-Schutz (%.1fs)\n" % GameManager.get_powerup_remaining("bomb_shield")
	# Wind-Anzeige (F007)
	if GameManager.game_active and abs(GameManager.wind_force.x) > 10.0:
		var wind_dir: String = ">" if GameManager.wind_force.x > 0 else "<"
		var wind_str: int = clampi(int(abs(GameManager.wind_force.x) / 40.0), 1, 3)
		pu_text += "Wind " + wind_dir.repeat(wind_str) + "\n"
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
## Abschaltbar in den Optionen (F181); bei reduzierter Bewegung aus (F183).
func _on_hit_registered(_points: int) -> void:
	if not GameManager.screen_shake_enabled or GameManager.reduced_motion:
		return
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
	_apply_variant_dict(maennchen, _pick_weighted_variant())


## Überträgt die Werte eines Varianten-Dictionaries auf das Männchen.
func _apply_variant_dict(maennchen: Maennchen, variant: Dictionary) -> void:
	var s: float = variant["scale"]
	maennchen.scale = Vector2(s, s)            # skaliert Optik UND Trefferbereich
	maennchen.walk_speed = variant["speed"]
	maennchen.figure_color = variant["color"]
	maennchen.point_multiplier = variant["mult"]
	maennchen.jump_height = variant.get("jump_height", 0.0)
	maennchen.sleeping = variant.get("sleeping", false)
	maennchen.has_shield = variant.get("has_shield", false)
	maennchen.is_bomb = variant.get("is_bomb", false)
	maennchen.has_umbrella = variant.get("has_umbrella", false)
	maennchen.dodges = variant.get("dodges", false)


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
	# Combo-Jagd (F092): Der Punktestand IST die beste Combo
	if GameManager.game_mode == "combo_hunt":
		_score_label.text = "Beste Combo: %d" % new_score
	else:
		_score_label.text = "Punkte: %d" % new_score


func _on_time_changed(seconds_left: float) -> void:
	var secs: int = int(ceil(seconds_left))
	_time_label.text = "Zeit: %d" % secs

	# Bonus-Runde Goldregen (F084): einmal pro Runde ab der Hälfte der Zeit,
	# nur in Modi mit echtem Timer
	if not _bonus_done and GameManager.game_active \
			and GameManager.game_mode in ["normal", "easy", "hard", "combo_hunt"] \
			and seconds_left <= GameManager.round_duration * 0.5:
		_bonus_done = true
		_start_bonus_round()

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
		# Bildschirm-Aufblitzen bei Mega-Combo ab x5 (F149)
		if new_combo >= 5:
			_flash_screen()
	else:
		_combo_label.visible = false


## Kurzes weißes Aufblitzen des Bildschirms (F149).
## Bei reduzierter Bewegung deaktiviert (F183).
func _flash_screen() -> void:
	if GameManager.reduced_motion:
		return
	_flash_rect.color = Color(1, 1, 1, 0.3)
	var tween: Tween = create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, 0.35)


## Zeigt eine Toast-Benachrichtigung oben in der Mitte (F123).
## Ein evtl. noch laufender Toast wird abgebrochen, damit er den
## neuen nicht vorzeitig ausblendet.
func show_toast(text: String) -> void:
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_label.text = text
	_toast_label.visible = true
	_toast_label.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_label, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast_label.visible = false)


## Toast beim Einsammeln eines Power-Ups (F123).
func _on_powerup_activated(type: String) -> void:
	const NAMES: Dictionary = {
		"time_bonus": "⏱ Zeit-Bonus!",
		"big_projectile": "Riesen-Haufen!",
		"points_double": "Doppelte Punkte!",
		"multi_shot": "Mehrfach-Wurf!",
		"freeze": "❄ Einfrieren!",
		"magnet": "Magnet!",
		"bomb_shield": "Bomben-Schutz!",
	}
	show_toast(NAMES.get(type, type))


## Aktualisiert die Munitionsanzeige (F004).
func _on_ammo_changed(ammo_left: int) -> void:
	if ammo_left < 0:
		_ammo_label.visible = false
	else:
		_ammo_label.visible = true
		_ammo_label.text = "Würfe: %d" % ammo_left
		if ammo_left == 0:
			_ammo_label.modulate = Color(1.0, 0.3, 0.25)
			show_toast("Keine Munition mehr!")
		else:
			_ammo_label.modulate = Color.WHITE


## Zeigt die Treffer-Streak an (F126)
func _on_streak_changed(new_streak: int) -> void:
	if new_streak >= 3:
		_streak_label.text = "🔥 Streak: %d" % new_streak
		_streak_label.visible = true
	else:
		_streak_label.visible = false


## Kleiner "Pop"-Effekt: Element kurz vergrößern und auf Normalgröße zurückfedern.
## Mit pivot < 0 wird der Drehpunkt automatisch in die Elementmitte gelegt.
## Bei reduzierter Bewegung entfällt die Skalier-Animation (F183).
func _pop_label(label: Control, from_scale: float, pivot: Vector2 = Vector2(-1, -1)) -> void:
	if GameManager.reduced_motion:
		label.scale = Vector2.ONE
		return
	label.pivot_offset = label.size * 0.5 if pivot.x < 0.0 else pivot
	label.scale = Vector2(from_scale, from_scale)
	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Passt die HUD-Anzeigen an den gewählten Spielmodus an (F077/F083/F092/F093).
func _apply_mode_hud() -> void:
	match GameManager.game_mode:
		"zen":
			# Zen (F093): keine Wertung, keine Zeit
			_score_label.visible = false
			_time_label.visible = false
		"endless", "survival":
			# Endlos/Überleben (F077/F083): kein Timer, Fehlwurf-Zähler
			_time_label.visible = false
			_miss_label.visible = true
			_on_misses_changed(0)
		"combo_hunt":
			# Combo-Jagd (F092): Punkteanzeige führt die beste Combo
			_score_label.text = "Beste Combo: 0"
		"practice":
			_time_label.visible = false


## Aktualisiert den Fehlwurf-Zähler (F077/F083); kurz vor dem Limit rot.
func _on_misses_changed(new_misses: int) -> void:
	if GameManager.miss_limit < 0:
		return
	_miss_label.text = "Fehlwürfe: %d/%d" % [new_misses, GameManager.miss_limit]
	if new_misses >= GameManager.miss_limit - 1:
		_miss_label.modulate = Color(1.0, 0.3, 0.25)
	else:
		_miss_label.modulate = Color.WHITE


## Erhöht alle 15 Sekunden Schwierigkeit: mehr Männchen und schnellerer Spawn (F036).
## Im Überlebens-Modus (F083) härter und mit Wellenzähler; im Zen-Modus keine Wellen.
func _on_wave_tick() -> void:
	if not GameManager.game_active:
		return
	if GameManager.game_mode == "zen":
		return
	if GameManager.game_mode == "survival":
		_wave_count += 1
		max_maennchen = mini(max_maennchen + 2, 24)
		spawn_rate = maxf(spawn_rate * 0.85, 0.4)
		_spawn_timer.wait_time = spawn_rate
		show_toast("Welle %d!" % (_wave_count + 1))
		return
	max_maennchen = mini(max_maennchen + 1, 20)
	spawn_rate = maxf(spawn_rate * 0.9, 0.5)
	_spawn_timer.wait_time = spawn_rate
	show_toast("Neue Welle!")  # F123


## Bonus-Runde Goldregen (F084): 6 Sekunden lang regnet es Gold-Männchen.
func _start_bonus_round() -> void:
	_bonus_active = true
	show_toast("🌟 Goldregen!")
	_run_gold_rain()


## Spawnt während der Bonus-Runde alle 0,35s ein Gold-Männchen (F084).
func _run_gold_rain() -> void:
	var elapsed: float = 0.0
	while elapsed < 6.0 and GameManager.game_active:
		if maennchen_scene != null \
				and get_tree().get_nodes_in_group("maennchen").size() < max_maennchen + 6:
			var maennchen: Maennchen = maennchen_scene.instantiate()
			maennchen.position = Vector2(randf_range(spawn_x_min, spawn_x_max), ground_y)
			_apply_variant_dict(maennchen, VARIANTS[3])  # Index 3 = Gold-Männchen
			add_child(maennchen)
		await get_tree().create_timer(0.35).timeout
		elapsed += 0.35
	_bonus_active = false


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
