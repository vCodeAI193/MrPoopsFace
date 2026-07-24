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
	{"scale": 1.15, "speed": 50.0, "color": Color(0.35, 0.35, 0.35), "mult": 2, "weight": 8, "ramp_weight": 8, "jump_height": 0.0, "sleeping": false, "has_shield": true},   # Schild (F023)
	{"scale": 1.0, "speed": 80.0, "color": Color(0.65, 0.08, 0.08), "mult": 0, "weight": 10, "ramp_weight": 12, "jump_height": 0.0, "sleeping": false, "has_shield": false, "is_bomb": true},  # Bombe (F029)
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
@onready var _coins_label: Label = $HUD/TopBar/CoinsLabel
@onready var _mission_label: Label = $HUD/MissionLabel
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

# F063 – Tageszeit-Stimmungen: Himmel, Sonne und Farb-Tint pro Runde
const DAYTIMES: Dictionary = {
	"morgen": {
		"sky_top": Color(0.95, 0.72, 0.72), "sky_bottom": Color(0.78, 0.9, 1.0),
		"sun": Color(1.0, 0.9, 0.55), "sun_pos": Vector2(1580, 330),
		"green": 1.0, "cloud": Color(1.0, 0.94, 0.94),
	},
	"tag": {
		"sky_top": Color(0.4, 0.7, 0.95), "sky_bottom": Color(0.82, 0.93, 1.0),
		"sun": Color(1.0, 0.95, 0.4), "sun_pos": Vector2(1620, 210),
		"green": 1.0, "cloud": Color(1.0, 1.0, 1.0),
	},
	"abend": {
		"sky_top": Color(0.9, 0.5, 0.28), "sky_bottom": Color(0.6, 0.4, 0.62),
		"sun": Color(1.0, 0.45, 0.2), "sun_pos": Vector2(1560, 480),
		"green": 0.78, "cloud": Color(1.0, 0.82, 0.78),
	},
}
var _daytime: String = "tag"
var _sun_phase: float = 0.0

# F065/F071/F153 – Landschafts-Deko und Bäume
var _decorations: Array = []
var _trees: Array = []

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

# F145 – Slow-Motion beim letzten Treffer der Runde
var _final_slowmo_done: bool = false


func _ready() -> void:
	randomize()

	# Schwierigkeitsanpassung über den Spielmodus (F089)
	match GameManager.game_mode:
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
	GameManager.combo_broken_by_miss.connect(
		func(lost: int) -> void: show_toast("Combo x%d verloren!" % lost))
	GameManager.coins_changed.connect(_on_coins_changed)
	_coins_label.text = "🪙 %d" % GameManager.coins
	GameManager.mission_changed.connect(_on_mission_changed)
	GameManager.mission_completed.connect(_on_mission_completed)
	GameManager.multi_hit.connect(_on_multi_hit)

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

	# Tageszeit würfeln und Himmel umfärben (F063); Landschaft aufbauen (F065/F071/F153)
	_daytime = DAYTIMES.keys()[randi() % DAYTIMES.size()]
	_apply_daytime_sky()
	_init_scenery()

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

	# Sonnenstrahlen rotieren (F063) und Bäume schwanken lassen (F153)
	_sun_phase += delta * 0.3
	for tree in _trees:
		tree["phase"] += delta * 1.3
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
## In den letzten 3 Sekunden: einmalige Finale-Zeitlupe (F145).
func _on_hit_registered(_points: int) -> void:
	if not _final_slowmo_done and GameManager.time_left <= 3.0 \
			and GameManager.game_mode in ["normal", "easy", "hard", "combo_hunt"] \
			and not GameManager.reduced_motion:
		_final_slowmo_done = true
		_run_final_slowmo()
	if not GameManager.screen_shake_enabled or GameManager.reduced_motion:
		return
	_shake_strength = minf(_shake_strength + shake_per_hit, shake_max)


## Kurze Zeitlupe für den letzten Treffer der Runde (F145).
func _run_final_slowmo() -> void:
	Engine.time_scale = 0.3
	# 0,7s Echtzeit = 0,21s skalierte Zeit
	await get_tree().create_timer(0.21).timeout
	Engine.time_scale = 1.0


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
## Risiko-Kurve: Varianten mit "ramp_weight" (Bombe, Schild) werden im
## Rundenverlauf wahrscheinlicher — die Runde wird zum Ende hin spannender.
func _pick_weighted_variant() -> Dictionary:
	var p: float = _round_progress()
	var total: int = 0
	for v in VARIANTS:
		total += int(v["weight"]) + int(v.get("ramp_weight", 0) * p)
	var roll: int = randi() % total
	for v in VARIANTS:
		roll -= int(v["weight"]) + int(v.get("ramp_weight", 0) * p)
		if roll < 0:
			return v
	return VARIANTS[0]


## Rundenfortschritt 0..1 für die Risiko-Kurve: Timer-Modi über die
## Restzeit, Survival über die Wellenzahl, sonst 0.
func _round_progress() -> float:
	match GameManager.game_mode:
		"normal", "easy", "hard", "combo_hunt":
			if GameManager.round_duration > 0.0:
				return clampf(1.0 - GameManager.time_left / GameManager.round_duration, 0.0, 1.0)
			return 0.0
		"survival":
			return clampf(_wave_count / 8.0, 0.0, 1.0)
		_:
			return 0.0


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
		# Große Lobwörter für Kinder bei Combo-Meilensteinen
		_spawn_praise_word(new_combo)
	else:
		_combo_label.visible = false


## Feiert Combo-Meilensteine mit großen bunten Lobwörtern (Kinder-Feedback).
func _spawn_praise_word(combo: int) -> void:
	const PRAISE: Dictionary = {
		3: ["SUPER!", Color(0.3, 0.9, 0.3)],
		5: ["MEGA!", Color(1.0, 0.6, 0.1)],
		8: ["WAHNSINN!", Color(1.0, 0.3, 0.6)],
		12: ["UNGLAUBLICH!", Color(0.5, 0.4, 1.0)],
	}
	if combo not in PRAISE:
		return
	var ft: FloatingText = preload("res://scenes/FloatingText.tscn").instantiate()
	ft.setup(PRAISE[combo][0], PRAISE[combo][1])
	ft.scale = Vector2(2.2, 2.2)
	ft.position = Vector2(960, 420)
	add_child(ft)


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


## Zeigt die Runden-Mission mit Fortschritt an (F081).
func _on_mission_changed(mission: Dictionary) -> void:
	if mission.is_empty():
		_mission_label.visible = false
		return
	_mission_label.visible = true
	if mission["done"]:
		_mission_label.text = "🎯 %s ✔" % mission["text"]
		_mission_label.modulate = Color(0.5, 1.0, 0.5)
	else:
		_mission_label.text = "🎯 %s (%d/%d)" % [
			mission["text"], int(mission["progress"]), int(mission["target"])]
		_mission_label.modulate = Color.WHITE


## Feiert die erfüllte Mission (F081).
func _on_mission_completed(reward: int) -> void:
	show_toast("Mission geschafft! +%d 🪙" % reward)


## Feiert mehrere Treffer mit einem Wurf (F017).
func _on_multi_hit(count: int, bonus: int) -> void:
	var word: String = "DOPPELT!" if count == 2 else "DREIFACH!" if count == 3 else "x%d WAHNSINN!" % count
	var ft: FloatingText = preload("res://scenes/FloatingText.tscn").instantiate()
	ft.setup("%s +%d" % [word, bonus], Color(1.0, 0.85, 0.1))
	ft.scale = Vector2(2.0, 2.0)
	ft.position = Vector2(960, 520)
	add_child(ft)


## Aktualisiert die Münz-Anzeige mit kleinem Pop (F095).
func _on_coins_changed(total: int) -> void:
	_coins_label.text = "🪙 %d" % total
	_pop_label(_coins_label, 1.25)


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


## Färbt den Himmel-Gradient passend zur Tageszeit um (F063).
func _apply_daytime_sky() -> void:
	var day: Dictionary = DAYTIMES[_daytime]
	var sky: TextureRect = $BackgroundLayer/Sky
	var tex: GradientTexture2D = sky.texture
	if tex and tex.gradient:
		tex.gradient.set_color(0, day["sky_top"])
		tex.gradient.set_color(1, day["sky_bottom"])


## Würfelt Blumen, Büsche, Zaunstücke und Bäume für die Landschaft (F065/F071/F153).
func _init_scenery() -> void:
	const FLOWER_COLORS: Array = [
		Color(0.95, 0.5, 0.7), Color(1.0, 1.0, 1.0), Color(0.95, 0.6, 0.2),
		Color(0.7, 0.5, 0.95),
	]
	for i in 7:
		_decorations.append({
			"type": "flower",
			"pos": Vector2(randf_range(80, 1850), randf_range(1065, 1130)),
			"color": FLOWER_COLORS[randi() % FLOWER_COLORS.size()],
			"size": randf_range(8.0, 13.0),
		})
	for i in 3:
		_decorations.append({
			"type": "bush",
			"pos": Vector2(randf_range(150, 1800), 1050.0),
			"size": randf_range(30.0, 52.0),
		})
	_decorations.append({"type": "fence", "pos": Vector2(randf_range(560, 860), 1046.0), "size": 200.0})
	_decorations.append({"type": "fence", "pos": Vector2(randf_range(1250, 1600), 1046.0), "size": 160.0})
	# Bäume an den Bildrändern, damit die Spielfläche frei bleibt (F153)
	for data in [[120.0, 260.0], [1755.0, 300.0], [1870.0, 210.0]]:
		_trees.append({"x": data[0], "h": data[1], "phase": randf() * TAU})


## Zeichnet Himmelskörper, Wolken und Landschaft hinter der Spielszene.
func _draw() -> void:
	var day: Dictionary = DAYTIMES[_daytime]
	var g: float = day["green"]

	# --- Sonne mit langsam rotierendem Strahlenkranz (F063) ---
	var sun_pos: Vector2 = day["sun_pos"]
	var sun_col: Color = day["sun"]
	for i in 8:
		var a: float = _sun_phase + TAU * float(i) / 8.0
		var dir: Vector2 = Vector2(cos(a), sin(a))
		draw_line(sun_pos + dir * 72.0, sun_pos + dir * 100.0,
			Color(sun_col.r, sun_col.g, sun_col.b, 0.6), 5.0)
	draw_circle(sun_pos, 62.0, sun_col)
	draw_circle(sun_pos, 50.0, sun_col.lightened(0.2))

	# --- Wolken (F075) ---
	for c in _clouds:
		_draw_cloud(c["pos"], c["size"], c["alpha"], day["cloud"])

	# --- Hügel in zwei Tiefenebenen (F065) ---
	var hill_back: Color = Color(0.55 * g, 0.78 * g, 0.55 * g)
	var hill_front: Color = Color(0.38 * g, 0.68 * g, 0.34 * g)
	for i in 5:
		draw_circle(Vector2(-100 + i * 520.0, 1050.0), 190.0, hill_back)
	for i in 4:
		draw_circle(Vector2(150 + i * 560.0, 1090.0), 160.0, hill_front)

	# --- Boden: Gras + Erdstreifen (F065) ---
	var grass: Color = Color(0.3 * g, 0.62 * g, 0.25 * g)
	var earth: Color = Color(0.42 * g, 0.3 * g, 0.18 * g)
	draw_rect(Rect2(0, 1050, 1920, 70), grass)
	draw_rect(Rect2(0, 1120, 1920, 80), earth)
	# Grashalme entlang der Oberkante (deterministisch aus dem Index)
	var blade: Color = Color(0.24 * g, 0.55 * g, 0.2 * g)
	for i in 48:
		var x: float = i * 40.0 + fmod(i * 17.0, 23.0)
		var h: float = 10.0 + 8.0 * absf(sin(i * 3.7))
		draw_line(Vector2(x, 1052), Vector2(x + 4.0, 1052 - h), blade, 3.0)

	# --- Deko: Zäune, Büsche, Blumen (F071) ---
	for deco in _decorations:
		match deco["type"]:
			"fence":
				_draw_fence(deco["pos"], deco["size"])
			"bush":
				_draw_bush(deco["pos"], deco["size"], g)
			"flower":
				_draw_flower(deco["pos"], deco["size"], deco["color"], g)

	# --- Schwankende Bäume (F153) ---
	for tree in _trees:
		_draw_tree(tree, g)


## Zeichnet eine einzelne Wolke aus überlappenden Kreisen; Farbe je Tageszeit.
func _draw_cloud(pos: Vector2, size: float, alpha: float, tint: Color = Color.WHITE) -> void:
	var col: Color = Color(tint.r, tint.g, tint.b, alpha)
	draw_circle(pos, size * 0.6, col)
	draw_circle(pos + Vector2(size * 0.56, size * 0.08), size * 0.48, col)
	draw_circle(pos + Vector2(-size * 0.46, size * 0.1), size * 0.44, col)
	draw_circle(pos + Vector2(size * 0.18, -size * 0.32), size * 0.42, col)


## Zaunstück aus Latten und zwei Querbalken (F071).
func _draw_fence(pos: Vector2, width: float) -> void:
	var wood: Color = Color(0.55, 0.4, 0.24)
	var posts: int = int(width / 40.0)
	for i in posts + 1:
		var x: float = pos.x + i * 40.0
		draw_line(Vector2(x, pos.y), Vector2(x, pos.y - 52.0), wood, 8.0)
		draw_circle(Vector2(x, pos.y - 52.0), 4.0, wood)
	for rail_y in [-38.0, -16.0]:
		draw_line(Vector2(pos.x - 6, pos.y + rail_y),
			Vector2(pos.x + posts * 40.0 + 6, pos.y + rail_y), wood, 6.0)


## Busch aus drei dunkelgrünen Kreisen (F071).
func _draw_bush(pos: Vector2, size: float, g: float) -> void:
	var col: Color = Color(0.2 * g, 0.5 * g, 0.18 * g)
	draw_circle(pos + Vector2(-size * 0.5, 0), size * 0.6, col)
	draw_circle(pos + Vector2(size * 0.5, 0), size * 0.6, col)
	draw_circle(pos + Vector2(0, -size * 0.35), size * 0.7, col)


## Blume: Stiel, fünf Blütenblätter, gelbe Mitte (F071).
func _draw_flower(pos: Vector2, size: float, color: Color, g: float) -> void:
	draw_line(pos, pos + Vector2(0, size * 1.8), Color(0.25 * g, 0.5 * g, 0.2 * g), 3.0)
	for i in 5:
		var a: float = TAU * float(i) / 5.0 - PI / 2.0
		draw_circle(pos + Vector2(cos(a), sin(a)) * size * 0.55, size * 0.42, color)
	draw_circle(pos, size * 0.34, Color(1.0, 0.85, 0.2))


## Baum mit Stamm und im Wind schwankender Krone (F153).
func _draw_tree(tree: Dictionary, g: float) -> void:
	var base: Vector2 = Vector2(tree["x"], 1060.0)
	var h: float = tree["h"]
	var sway: float = sin(tree["phase"]) * 7.0
	var crown: Vector2 = base + Vector2(sway, -h)
	var trunk: Color = Color(0.4, 0.26, 0.13)
	var leaves: Color = Color(0.22 * g, 0.55 * g, 0.2 * g)
	# Stamm folgt der Krone leicht
	draw_line(base, base + Vector2(sway * 0.4, -h * 0.62), trunk, 16.0)
	draw_line(base + Vector2(sway * 0.4, -h * 0.62), crown, trunk, 11.0)
	# Krone aus drei Kreisen
	draw_circle(crown, h * 0.3, leaves)
	draw_circle(crown + Vector2(-h * 0.22, h * 0.12), h * 0.24, leaves)
	draw_circle(crown + Vector2(h * 0.22, h * 0.12), h * 0.24, leaves)


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
