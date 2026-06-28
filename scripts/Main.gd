extends Node2D
## Main – Spielschleife: startet die Runde, spawnt Strichmännchen
## und aktualisiert die HUD (Punkte, Timer, Combo).

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

@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _score_label: Label = $HUD/TopBar/ScoreLabel
@onready var _time_label: Label = $HUD/TopBar/TimeLabel
@onready var _combo_label: Label = $HUD/TopBar/ComboLabel
@onready var _pause_button: Button = $HUD/PauseButton
@onready var _pause_menu: CanvasLayer = $PauseMenu
@onready var _camera: Camera2D = $Camera2D

var _shake_strength: float = 0.0


func _ready() -> void:
	randomize()

	# HUD mit den GameManager-Signalen verbinden
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.hit_registered.connect(_on_hit_registered)

	# Pause-Knopf verbinden (F114)
	_pause_button.pressed.connect(_on_pause_pressed)

	# Spawn-Timer einrichten
	_spawn_timer.wait_time = spawn_rate
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_spawn_timer.start()

	# Runde starten
	GameManager.start_game()
	_on_score_changed(0)
	_on_time_changed(GameManager.time_left)
	_on_combo_changed(0)


func _process(delta: float) -> void:
	# Screen-Shake abklingen lassen und auf die Kamera anwenden (F144)
	if _shake_strength > 0.0:
		_camera.offset = Vector2(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
		_shake_strength = maxf(_shake_strength - shake_decay * delta, 0.0)
		if _shake_strength <= 0.0:
			_camera.offset = Vector2.ZERO


## Reagiert auf einen Treffer mit einer Kamera-Erschütterung (F144).
func _on_hit_registered(_points: int) -> void:
	_shake_strength = minf(_shake_strength + shake_per_hit, shake_max)


## Öffnet das Pause-Overlay (F114).
func _on_pause_pressed() -> void:
	_pause_menu.show_pause()


## Spawnt ein neues Strichmännchen, solange das Limit nicht erreicht ist.
func _on_spawn_timer_timeout() -> void:
	if not GameManager.game_active:
		return
	if maennchen_scene == null:
		push_warning("Keine maennchen_scene zugewiesen!")
		return
	if get_tree().get_nodes_in_group("maennchen").size() >= max_maennchen:
		return

	var maennchen: Node2D = maennchen_scene.instantiate()
	maennchen.position = Vector2(randf_range(spawn_x_min, spawn_x_max), ground_y)
	add_child(maennchen)


# --- HUD-Aktualisierungen ---

func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Punkte: %d" % new_score


func _on_time_changed(seconds_left: float) -> void:
	_time_label.text = "Zeit: %d" % int(ceil(seconds_left))


func _on_combo_changed(new_combo: int) -> void:
	if new_combo >= 2:
		_combo_label.text = "Combo x%d!" % new_combo
		_combo_label.visible = true
	else:
		_combo_label.visible = false
