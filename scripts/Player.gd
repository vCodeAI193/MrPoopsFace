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


func _ready() -> void:
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
