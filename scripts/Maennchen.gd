extends Area2D
## Maennchen – ein Strichmännchen, das getroffen werden kann.
## Reagiert auf einen Treffer mit einer lustigen Umfall-Animation und
## einem prozedural erzeugten Furzgeräusch. Wird per Line2D / _draw gezeichnet.

signal hit                                     ## Wird gesendet, wenn getroffen

@export var figure_color: Color = Color(0.1, 0.1, 0.1)   ## Farbe der Striche
@export var figure_scale: float = 1.0                    ## Größenskalierung
@export var walk_speed: float = 60.0                     ## Lauftempo in Pixel/Sek.

var _is_hit: bool = false
var _direction: int = 1                          ## 1 = nach rechts, -1 = nach links
var _walk_phase: float = 0.0                     ## Phase für die Beinanimation

@onready var _fart_player: AudioStreamPlayer = $FartPlayer
@onready var _body: Node2D = $Body                ## Wird gedreht/animiert beim Treffer


func _ready() -> void:
	randomize()
	_direction = 1 if randf() < 0.5 else -1
	# Treffer-Erkennung: der Kackhaufen (RigidBody2D) löst body_entered aus
	body_entered.connect(_on_body_entered)
	# Furzgeräusch prozedural erzeugen (keine externe Audiodatei nötig)
	_fart_player.stream = _generate_fart_stream()
	queue_redraw()


func _process(delta: float) -> void:
	if _is_hit or not GameManager.game_active:
		return

	# Gemächlich hin und her laufen
	position.x += _direction * walk_speed * delta
	_walk_phase += delta * 8.0

	# Am Bildschirmrand umdrehen, damit das Männchen sichtbar bleibt
	var view_width: float = get_viewport_rect().size.x
	if position.x < 80.0 and _direction < 0:
		_direction = 1
	elif position.x > view_width - 80.0 and _direction > 0:
		_direction = -1

	_body.queue_redraw()


## Wird aufgerufen, wenn ein Körper (der Kackhaufen) das Männchen berührt.
func _on_body_entered(body: Node) -> void:
	if _is_hit:
		return
	# Nur auf Projektile reagieren
	if not body.is_in_group("projectile"):
		return
	_trigger_hit()


## Löst die Treffer-Reaktion aus: Punkte, Sound und Umfall-Animation.
func _trigger_hit() -> void:
	_is_hit = true
	GameManager.register_hit()
	hit.emit()

	# Furz abspielen
	if _fart_player.stream != null:
		_fart_player.play()

	# Lustige Umfall-Animation: kippt um und verblasst, dann entfernen
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_body, "rotation", deg_to_rad(90.0 * _direction), 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "position:y", 30.0, 0.4) \
		.set_trans(Tween.TRANS_BOUNCE)
	tween.chain().tween_interval(0.5)
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)


## Erzeugt ein kurzes, furzartiges Audiosignal als AudioStreamWAV.
## Tiefe, "blubbernde" Frequenz mit etwas Rauschen und Ausklang.
func _generate_fart_stream() -> AudioStreamWAV:
	var mix_rate: int = 22050
	var duration: float = 0.5
	var sample_count: int = int(mix_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)        # 16-Bit = 2 Bytes pro Sample

	for i in sample_count:
		var t: float = float(i) / mix_rate
		# Grundfrequenz fällt leicht ab (das "Auspusten")
		var freq: float = 90.0 - 40.0 * (t / duration)
		# Vibrato für den typischen Flatter-Effekt
		var vibrato: float = 1.0 + 0.4 * sin(TAU * 18.0 * t)
		# Sägezahnähnliche Welle klingt "schmutziger" als ein Sinus
		var phase: float = fmod(freq * vibrato * t, 1.0)
		var saw: float = 2.0 * phase - 1.0
		# Etwas Rauschen beimischen
		var noise: float = randf_range(-0.3, 0.3)
		# Hüllkurve: schneller Anstieg, langsamer Ausklang
		var env: float = clamp(t / 0.02, 0.0, 1.0) * (1.0 - t / duration)
		var sample_f: float = clamp((saw * 0.7 + noise) * env, -1.0, 1.0)
		var sample_i: int = int(sample_f * 32767.0)
		# Little-Endian 16-Bit schreiben
		data[i * 2] = sample_i & 0xFF
		data[i * 2 + 1] = (sample_i >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream
