extends Node2D
## Player – die Schleuder-/Wurfmechanik mit Touch-Steuerung.
## Ziehen-und-Loslassen (wie bei Angry Birds): Der Spieler zieht vom
## Anker-Punkt weg und lässt los, um den Kackhaufen zu schleudern.

@export var throw_power: float = 9.0           ## Multiplikator für die Wurfstärke
@export var max_drag_distance: float = 350.0   ## Maximale Ziehweite in Pixeln
@export var projectile_scene: PackedScene      ## Szene des Kackhaufens
@export var max_projectiles: int = 3           ## Max. Geschosse gleichzeitig (F003)
@export var projectile_weight: float = 1.0     ## Geschoss-Gewicht (1.0 = normal, 0.7 = leicht, 1.3 = schwer, F019)

# Vorschau-Trajektorie
@export var trajectory_points: int = 24        ## Anzahl der Vorschaupunkte
@export var trajectory_step: float = 0.06      ## Zeitschritt zwischen den Punkten

var _aiming: bool = false
var _touch_index: int = -1                     ## Aktiv verfolgter Finger
var _drag_current: Vector2 = Vector2.ZERO      ## Aktuelle Zugposition (lokal)

# F005 – Nachlade-Animation
var _last_projectile: Node2D = null
var _projectile_returning: bool = false
var _projectile_return_progress: float = 0.0

# F013 – Doppeltipp zum Wiederholen
var _last_tap_time: float = 0.0
var _last_drag: Vector2 = Vector2.ZERO
const DOUBLE_TAP_WINDOW: float = 0.35

# Combo-Aura (F146)
var _combo: int = 0
var _aura_phase: float = 0.0

@onready var _whoosh_player: AudioStreamPlayer = $WhooshPlayer


func _ready() -> void:
	add_to_group("player")
	# Wurf-Whoosh prozedural erzeugen (F132), über den SFX-Bus (F137/F142)
	_whoosh_player.bus = "SFX"
	_whoosh_player.stream = SoundGen.whoosh()
	# Auf Combo-Änderungen reagieren, um die Aura zu steuern (F146)
	GameManager.combo_changed.connect(_on_combo_changed)
	# Zeitlupe bei Rundenende aufheben (F012)
	GameManager.game_over.connect(func(_s: int) -> void: Engine.time_scale = 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	# Nachlade-Animation verwalten (F005): Das zuletzt geworfene Geschoss
	# kehrt zum Anker zurück, sobald es nach dem Aufprall ausgerollt ist.
	# So bleibt die Abprall-Physik (F006) unangetastet.
	if _last_projectile and not is_instance_valid(_last_projectile):
		_last_projectile = null
		_projectile_returning = false
	if _projectile_returning and _last_projectile:
		_projectile_return_progress += delta * 3.0
		if _projectile_return_progress >= 1.0:
			# Angekommen: Fehlwurf-Semantik wie beim Lifetime-Ablauf, dann entfernen
			if not _last_projectile.hit_target:
				GameManager.register_miss()
			_last_projectile.queue_free()
			_projectile_returning = false
			_last_projectile = null
		else:
			var start_pos: Vector2 = _last_projectile.global_position
			var end_pos: Vector2 = global_position
			_last_projectile.global_position = start_pos.lerp(end_pos, _projectile_return_progress)
			_last_projectile.rotation_degrees += 360.0 * delta * 5.0
	elif _last_projectile and not _last_projectile.freeze \
			and _last_projectile.has_splatted() \
			and _last_projectile.linear_velocity.length() < 30.0:
		# Ausgerollt: einfrieren und Rückkehr starten
		_last_projectile.freeze = true
		_projectile_returning = true
		_projectile_return_progress = 0.0

	# Doppeltipp-Fenster abklingen lassen (F013)
	_last_tap_time += delta

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
			# Doppeltipp-Erkennung (F013)
			var current_time: float = Time.get_ticks_msec() / 1000.0
			if current_time - _last_tap_time < DOUBLE_TAP_WINDOW and _last_drag.length() > 50.0 \
					and GameManager.consume_ammo():
				# Doppeltipp erkannt: Letzten Wurf wiederholen (verbraucht Munition, F004)
				_spawn_projectile(-_last_drag * throw_power)
				if _whoosh_player.stream != null:
					_whoosh_player.play()
				_last_tap_time = 0.0  # Fenster zurücksetzen
				return
			_last_tap_time = current_time

			_aiming = true
			_touch_index = event.index
			_drag_current = to_local(event.position)
			Engine.time_scale = 0.35  # Zeitlupe beim Zielen (F012)
			queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			# --- Finger losgelassen: werfen ---
			Engine.time_scale = 1.0  # Zeitlupe aufheben (F012)
			_release_throw()

	# --- Finger bewegt sich (Zielen) ---
	elif event is InputEventScreenDrag and _aiming and event.index == _touch_index:
		_drag_current = to_local(event.position)
		# Abbruch des Wurfs durch Zurückziehen in den Anker (F164)
		if _drag_current.length() < 30.0:
			_aiming = false
			_touch_index = -1
			_drag_current = Vector2.ZERO
			Engine.time_scale = 1.0  # Zeitlupe aufheben (F012)
			queue_redraw()
			return
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
	# Gewicht beeinflusst Reichweite: leichter (0.7) = weiter, schwerer (1.3) = näher (F019)
	var launch_impulse: Vector2 = -_drag_current * throw_power / projectile_weight

	# Zu kurze Züge ignorieren (versehentliche Tipper)
	if launch_impulse.length() > 50.0:
		# Limite für gleichzeitige Geschosse prüfen (F003)
		var active_projectiles: int = get_tree().get_nodes_in_group("projectile").size()
		# Munition prüfen und verbrauchen (F004)
		if active_projectiles < max_projectiles and GameManager.consume_ammo():
			# Mehrfach-Wurf Power-Up (F043)
			for i in GameManager.multi_shot_count:
				var spread: float = float(i) - (GameManager.multi_shot_count - 1) * 0.5
				var spread_angle: float = spread * 0.15  # 0.15 Radiant pro Geschoss
				var rotated_impulse: Vector2 = launch_impulse.rotated(spread_angle)
				_spawn_projectile(rotated_impulse)
			_last_drag = _drag_current  # Für Doppeltipp-Wiederholen speichern (F013)
			if _whoosh_player.stream != null:
				_whoosh_player.play()

	_drag_current = Vector2.ZERO
	queue_redraw()


## Instanziiert den Kackhaufen am Anker und gibt ihm den Wurfimpuls.
## Berechnet auch das Drehmoment basierend auf der Wischrichtung (F011)
func _spawn_projectile(impulse: Vector2) -> void:
	if projectile_scene == null:
		push_warning("Keine projectile_scene zugewiesen!")
		return
	var poop: RigidBody2D = projectile_scene.instantiate()
	poop.global_position = global_position
	poop.add_to_group("projectile")

	# Drehmoment durch Wischrichtung berechnen (F011)
	# Kreuzprodukt der Wurfrichtung mit "oben" ergibt die Spin-Richtung
	var spin: float = (impulse.x * 0.0 - impulse.y * -1.0) / (max(impulse.length(), 1.0))
	# Als Geschwister in die Spielszene einfügen
	get_parent().add_child(poop)
	if poop.has_method("launch"):
		poop.launch(impulse, spin)
	else:
		poop.call("launch", impulse)

	# Für Nachlade-Animation speichern (F005); Start der Rückkehr
	# übernimmt _process() über die Ruhe-Erkennung
	_last_projectile = poop
	_projectile_returning = false


## Schneller Wurf-Wiederholung durch Doppeltipp (F013).
func _quick_repeat_throw() -> void:
	if _last_drag.length() > 50.0:
		var launch_impulse: Vector2 = -_last_drag * throw_power
		_spawn_projectile(launch_impulse)
		if _whoosh_player.stream != null:
			_whoosh_player.play()


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

	# --- Wurf-Kraftanzeige (F001) und Mindest-/Höchstkraft-Markierungen (F002) ---
	var drag_len: float = _drag_current.length()
	var ratio: float = clampf(drag_len / max_drag_distance, 0.0, 1.0)
	var min_drag: float = 50.0 / throw_power
	var min_ratio: float = clampf(min_drag / max_drag_distance, 0.0, 1.0)
	const BAR_X: float = -70.0
	const BAR_Y: float = -200.0
	const BAR_W: float = 20.0
	const BAR_H: float = 155.0
	draw_rect(Rect2(BAR_X, BAR_Y, BAR_W, BAR_H), Color(0, 0, 0, 0.45))
	if ratio > 0.0:
		var fill_h: float = BAR_H * ratio
		draw_rect(Rect2(BAR_X, BAR_Y + BAR_H - fill_h, BAR_W, fill_h),
			Color(0.1 + 0.9 * ratio, 0.9 - 0.7 * ratio, 0.05, 0.92))
	draw_rect(Rect2(BAR_X, BAR_Y, BAR_W, BAR_H), Color(1, 1, 1, 0.45), false, 2.0)
	# Mindest-Markierung (F002): gelbe Linie
	var min_y: float = BAR_Y + BAR_H * (1.0 - min_ratio)
	draw_line(Vector2(BAR_X - 5, min_y), Vector2(BAR_X + BAR_W + 5, min_y),
		Color(1.0, 0.95, 0.2, 0.9), 3.0)
	# Höchst-Markierung (F002): rote Linie an der Oberkante
	draw_line(Vector2(BAR_X - 5, BAR_Y), Vector2(BAR_X + BAR_W + 5, BAR_Y),
		Color(1.0, 0.25, 0.1, 0.9), 3.0)

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
		vel += GameManager.wind_force * trajectory_step  # Wind-Abweichung (F007)
		var alpha: float = 1.0 - float(i) / trajectory_points
		draw_circle(pos, 6.0, Color(1, 1, 1, alpha * 0.7))
