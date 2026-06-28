extends RigidBody2D
## Projectile – der Kackhaufen, den der Spieler wirft.
## Ein RigidBody2D mit Schwerkraft, der per _draw() als brauner Haufen
## mit Emoji-Augen gezeichnet wird (keine externen Grafiken nötig).

@export var poop_radius: float = 40.0          ## Radius des Haufens in Pixeln
@export var lifetime: float = 6.0              ## Sekunden bis zur automatischen Entfernung

var _alive_time: float = 0.0
var _has_splatted: bool = false

@onready var _splat_player: AudioStreamPlayer = $SplatPlayer


func _ready() -> void:
	# Kontaktüberwachung erlauben, damit der Aufprall erkannt wird
	contact_monitor = true
	max_contacts_reported = 4
	# Platsch-Sound prozedural erzeugen (F133)
	_splat_player.stream = SoundGen.splat()
	body_entered.connect(_on_body_entered)
	# Sicherstellen, dass der Haufen gezeichnet wird
	queue_redraw()


## Spielt beim ersten Aufprall (Boden oder Männchen) den Platsch-Sound.
func _on_body_entered(_body: Node) -> void:
	if _has_splatted:
		return
	_has_splatted = true
	if _splat_player.stream != null:
		_splat_player.play()


func _process(delta: float) -> void:
	# Den Haufen nach einer Weile aufräumen, damit die Szene nicht vollläuft
	_alive_time += delta
	if _alive_time >= lifetime:
		queue_free()


## Gibt dem Haufen einen Anfangsimpuls (wird vom Player beim Loslassen aufgerufen).
func launch(impulse: Vector2) -> void:
	apply_central_impulse(impulse)
	# Etwas Drehung für mehr Komik
	angular_velocity = randf_range(-8.0, 8.0)


func _draw() -> void:
	var r: float = poop_radius
	var brown: Color = Color(0.45, 0.27, 0.12)
	var brown_dark: Color = Color(0.36, 0.21, 0.09)

	# --- Drei gestapelte Kugeln als klassischer Emoji-Kackhaufen ---
	# Unterste, breiteste Schicht
	draw_circle(Vector2(0, r * 0.55), r, brown_dark)
	# Mittlere Schicht
	draw_circle(Vector2(-r * 0.15, -r * 0.05), r * 0.72, brown)
	# Obere Spitze
	draw_circle(Vector2(r * 0.1, -r * 0.55), r * 0.45, brown)

	# --- Augen (weißes Oval + schwarze Pupille) ---
	var eye_y: float = -r * 0.1
	var eye_dx: float = r * 0.28
	var eye_r: float = r * 0.18
	for sx in [-1.0, 1.0]:
		var eye_pos: Vector2 = Vector2(sx * eye_dx, eye_y)
		draw_circle(eye_pos, eye_r, Color.WHITE)
		draw_circle(eye_pos + Vector2(0, eye_r * 0.15), eye_r * 0.5, Color.BLACK)
