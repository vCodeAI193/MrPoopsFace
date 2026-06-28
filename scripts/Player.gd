extends Node2D
## Player – die Schleuder-/Wurfmechanik mit Touch-Steuerung.
## Ziehen-und-Loslassen (wie bei Angry Birds): Der Spieler zieht vom
## Anker-Punkt weg und lässt los, um den Kackhaufen zu schleudern.

@export var throw_power: float = 9.0           ## Multiplikator für die Wurfstärke
@export var max_drag_distance: float = 350.0   ## Maximale Ziehweite in Pixeln
@export var projectile_scene: PackedScene      ## Szene des Kackhaufens

# Vorschau-Trajektorie
@export var trajectory_points: int = 24        ## Anzahl der Vorschaupunkte
@export var trajectory_step: float = 0.06      ## Zeitschritt zwischen den Punkten

var _aiming: bool = false
var _touch_index: int = -1                     ## Aktiv verfolgter Finger
var _drag_current: Vector2 = Vector2.ZERO      ## Aktuelle Zugposition (lokal)

# Combo-Aura (F146)
var _combo: int = 0
var _aura_phase: float = 0.0

@onready var _whoosh_player: AudioStreamPlayer = $WhooshPlayer


func _ready() -> void:
	# Wurf-Whoosh prozedural erzeugen (F132)
	_whoosh_player.stream = SoundGen.whoosh()
	# Auf Combo-Änderungen reagieren, um die Aura zu steuern (F146)
	GameManager.combo_changed.connect(_on_combo_changed)
	queue_redraw()


func _process(delta: float) -> void:
	# Aura pulsieren lassen, solange eine Combo aktiv ist (F146)
	if _combo >= 2:
		_aura_phase += delta
		queue_redraw()


## Merkt sich den aktuellen Combo-Stand für die Aura-Darstellung.
func _on_combo_changed(new_combo: int) -> void:
	var had_aura: bool = _combo >= 2
	_combo = new_combo
	# Beim Verschwinden der Aura einmal neu zeichnen, um sie zu entfernen
	if had_aura and _combo < 2:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.game_active:
		return

	# --- Finger aufgesetzt ---
	if event is InputEventScreenTouch:
		if event.pressed and not _aiming:
			_aiming = true
			_touch_index = event.index
			_drag_current = to_local(event.position)
			queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			# --- Finger losgelassen: werfen ---
			_release_throw()

	# --- Finger bewegt sich (Zielen) ---
	elif event is InputEventScreenDrag and _aiming and event.index == _touch_index:
		_drag_current = to_local(event.position)
		# Zugweite begrenzen
		if _drag_current.length() > max_drag_distance:
			_drag_current = _drag_current.normalized() * max_drag_distance
		queue_redraw()


## Berechnet den Impuls und erzeugt einen geworfenen Kackhaufen.
func _release_throw() -> void:
	if not _aiming:
		return
	_aiming = false
	_touch_index = -1

	# Wurfrichtung = entgegengesetzt zur Zugrichtung (Schleuder-Prinzip)
	var launch_impulse: Vector2 = -_drag_current * throw_power

	# Zu kurze Züge ignorieren (versehentliche Tipper)
	if launch_impulse.length() > 50.0:
		_spawn_projectile(launch_impulse)
		if _whoosh_player.stream != null:
			_whoosh_player.play()

	_drag_current = Vector2.ZERO
	queue_redraw()


## Instanziiert den Kackhaufen am Anker und gibt ihm den Wurfimpuls.
func _spawn_projectile(impulse: Vector2) -> void:
	if projectile_scene == null:
		push_warning("Keine projectile_scene zugewiesen!")
		return
	var poop: RigidBody2D = projectile_scene.instantiate()
	poop.global_position = global_position
	poop.add_to_group("projectile")
	# Als Geschwister in die Spielszene einfügen
	get_parent().add_child(poop)
	poop.call("launch", impulse)


func _draw() -> void:
	# --- Combo-Aura hinter dem Anker (F146) ---
	# Wächst mit der Combo und pulsiert sanft; Farbe wandert von Orange zu Rot.
	if _combo >= 2:
		var pulse: float = 0.5 + 0.5 * sin(_aura_phase * 6.0)
		var radius: float = minf(45.0 + _combo * 7.0, 130.0) + pulse * 12.0
		var heat: float = clampf(float(_combo) / 8.0, 0.0, 1.0)
		var col: Color = Color(1.0, 0.6 - 0.4 * heat, 0.1, 0.18 + 0.16 * pulse)
		draw_circle(Vector2.ZERO, radius, col)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.8, 0.2, 0.5), 4.0)

	# Anker der Schleuder (immer sichtbar)
	draw_circle(Vector2.ZERO, 18.0, Color(0.4, 0.26, 0.13))
	draw_arc(Vector2.ZERO, 18.0, 0, TAU, 24, Color(0.25, 0.16, 0.08), 4.0)

	if not _aiming or _drag_current == Vector2.ZERO:
		return

	# Gummiband der Schleuder (vom Anker zur Zugposition)
	draw_line(Vector2.ZERO, _drag_current, Color(0.3, 0.2, 0.1), 6.0)

	# --- Vorschau der Flugbahn als gepunktete Parabel ---
	# Bei Masse 1 entspricht der zentrale Impuls direkt der Startgeschwindigkeit
	var start_vel: Vector2 = -_drag_current * throw_power
	var gravity: float = float(ProjectSettings.get_setting(
		"physics/2d/default_gravity", 980.0))
	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = start_vel
	for i in trajectory_points:
		pos += vel * trajectory_step
		vel.y += gravity * trajectory_step
		var alpha: float = 1.0 - float(i) / trajectory_points
		draw_circle(pos, 6.0, Color(1, 1, 1, alpha * 0.7))
