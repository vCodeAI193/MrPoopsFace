extends Area2D
## PowerUp – ein Bonus-Objekt, das nach Treffern spawnt und eingesammelt werden kann (F041/F044/F052).
## Mit Animation und Timer-Anzeige (F055).

signal collected

@export var powerup_type: String = "time_bonus"   ## Typ: "time_bonus" oder "big_projectile"
@export var lifetime: float = 8.0                 ## Sekunden, bis der Pickup verschwindet
@export var duration: float = 15.0                ## Wie lange wirkt das Power-Up

var _alive_time: float = 0.0
var _fall_velocity: float = 0.0
var _collected: bool = false

@onready var _collect_player: AudioStreamPlayer = $CollectPlayer


func _ready() -> void:
	_collect_player.stream = SoundGen.whoosh()
	add_to_group("powerup")
	queue_redraw()


func _process(delta: float) -> void:
	# Nach unten fallen (F052 – Drop-Animation)
	_fall_velocity += 500.0 * delta
	position.y += _fall_velocity * delta

	# Auto-Einsammlung durch Nähe zum Player (wenn der Player nahe genug ist)
	if not _collected:
		var player: Node2D = get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) < 80.0:
			_on_pickup_collected()

	# Nach Lifetime verschwinden
	_alive_time += delta
	if _alive_time >= lifetime:
		queue_free()

	queue_redraw()


## Wird aufgerufen, wenn das Power-Up eingesammelt wird.
func _on_pickup_collected() -> void:
	if _collected:
		return
	_collected = true
	GameManager.activate_powerup(powerup_type, duration)
	if _collect_player.stream != null:
		_collect_player.play()
	collected.emit()
	# Nach kurzer Zeit (Soundwiedergabe) entfernen
	await get_tree().create_timer(0.2).timeout
	queue_free()


func _draw() -> void:
	var pct: float = clampf(1.0 - (_alive_time / lifetime), 0.0, 1.0)
	var r: float = 18.0

	# Basis-Form (abhängig vom Typ)
	match powerup_type:
		"time_bonus":
			# Sanduhr/Uhr-Form
			var col: Color = Color(1.0, 0.88, 0.2)
			draw_circle(Vector2(0, -r * 0.6), r * 0.5, col)
			draw_rect(Rect2(-r * 0.25, -r * 0.05, r * 0.5, r * 0.5), col)
			draw_circle(Vector2(0, r * 0.6), r * 0.5, col)
		"big_projectile":
			# Größerer Kreis
			var col: Color = Color(0.45, 0.27, 0.12)
			draw_circle(Vector2(0, 0), r * 1.1, col)
			draw_circle(Vector2(0, 0), r * 0.75, Color(0.55, 0.35, 0.15))
		"points_double":
			# Münz-Form mit "2x"
			var col: Color = Color(1.0, 0.84, 0.0)
			draw_circle(Vector2(0, 0), r * 0.9, col)
			draw_circle(Vector2(0, 0), r * 0.7, Color(1.0, 0.92, 0.1))
		"multi_shot":
			# Drei kleine Kreise
			var col: Color = Color(0.75, 0.4, 0.8)
			draw_circle(Vector2(-r * 0.6, 0), r * 0.5, col)
			draw_circle(Vector2(0, 0), r * 0.6, col)
			draw_circle(Vector2(r * 0.6, 0), r * 0.5, col)
		"freeze":
			# Eiskristall (F045)
			var col: Color = Color(0.5, 0.85, 1.0)
			draw_circle(Vector2.ZERO, r * 0.9, col)
			draw_circle(Vector2.ZERO, r * 0.6, Color(0.85, 0.97, 1.0))
			draw_line(Vector2(0, -r * 0.85), Vector2(0, r * 0.85), Color(0.15, 0.45, 0.85), 3.5)
			draw_line(Vector2(-r * 0.85, 0), Vector2(r * 0.85, 0), Color(0.15, 0.45, 0.85), 3.5)
		"magnet":
			# Magnet-U-Form (F047)
			var col: Color = Color(1.0, 0.28, 0.28)
			draw_arc(Vector2.ZERO, r * 0.75, PI, TAU, 16, col, 5.5)
			draw_line(Vector2(-r * 0.75, 0), Vector2(-r * 0.75, r * 0.65), col, 5.5)
			draw_line(Vector2(r * 0.75, 0), Vector2(r * 0.75, r * 0.65), col, 5.5)

	# Countdown-Ring um den Pickup (F055)
	var start_angle: float = -PI / 2.0
	var end_angle: float = start_angle + TAU * pct
	draw_arc(Vector2.ZERO, r * 1.4, start_angle, end_angle,
		32, Color(1.0, 1.0, 1.0, 0.7 * pct), 3.0)

	# Pulsierender Glanz
	var pulse: float = 0.5 + 0.5 * sin(_alive_time * 4.0)
	draw_circle(Vector2.ZERO, r * 0.4, Color(1.0, 1.0, 1.0, 0.3 * pulse))
