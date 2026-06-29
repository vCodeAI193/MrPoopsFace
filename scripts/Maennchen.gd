class_name Maennchen
extends Area2D
## Maennchen – ein Strichmännchen, das getroffen werden kann.
## Reagiert auf einen Treffer mit einer lustigen Umfall-Animation und
## einem prozedural erzeugten Furzgeräusch. Wird per Line2D / _draw gezeichnet.

signal hit                                     ## Wird gesendet, wenn getroffen

@export var figure_color: Color = Color(0.1, 0.1, 0.1)   ## Farbe der Striche
@export var figure_scale: float = 1.0                    ## Größenskalierung
@export var walk_speed: float = 60.0                     ## Lauftempo in Pixel/Sek.
@export var point_multiplier: int = 1                    ## Typabhängiger Punktebonus (F021/F025/F028)
@export var jump_height: float = 0.0                     ## Sprunghöhe in Pixeln; 0 = kein Sprung (F022)
@export var sleeping: bool = false                       ## Steht still und schläft (F032)

var _is_hit: bool = false
var _direction: int = 1                          ## 1 = nach rechts, -1 = nach links
var _walk_phase: float = 0.0                     ## Phase für die Beinanimation

# F022 – Springendes Männchen
var _base_y: float = 0.0
var _jump_phase: float = 0.0

# F032 – Schlafendes Männchen
var _zzz_timer: float = 1.5

# Vorgeladene Effekt-Szenen
const FLOATING_TEXT_SCENE: PackedScene = preload("res://scenes/FloatingText.tscn")
const HIT_EFFECT_SCENE: PackedScene = preload("res://scenes/HitEffect.tscn")
const POWERUP_SCENE: PackedScene = preload("res://scenes/PowerUp.tscn")

@onready var _fart_player: AudioStreamPlayer = $FartPlayer
@onready var _body: Node2D = $Body                ## Wird gedreht/animiert beim Treffer


func _ready() -> void:
	randomize()
	_direction = 1 if randf() < 0.5 else -1
	_base_y = position.y
	# Treffer-Erkennung: der Kackhaufen (RigidBody2D) löst body_entered aus
	body_entered.connect(_on_body_entered)
	# Zufällige Furz-Variante zuweisen (F131)
	_fart_player.stream = SoundGen.fart(randi() % 5)
	queue_redraw()


func _process(delta: float) -> void:
	if _is_hit or not GameManager.game_active:
		return

	# Gemächlich hin und her laufen (schlafende Männchen stehen still, F032)
	if not sleeping:
		position.x += _direction * walk_speed * delta
		_walk_phase += delta * 8.0

	# Am Bildschirmrand umdrehen, damit das Männchen sichtbar bleibt
	var view_width: float = get_viewport_rect().size.x
	if position.x < 80.0 and _direction < 0:
		_direction = 1
	elif position.x > view_width - 80.0 and _direction > 0:
		_direction = -1

	# Sprungbewegung (F022)
	if jump_height > 0.0:
		_jump_phase += delta * 2.8
		position.y = _base_y - abs(sin(_jump_phase)) * jump_height

	# Zzz-Effekt beim Schlafen (F032)
	if sleeping:
		_zzz_timer -= delta
		if _zzz_timer <= 0.0:
			_zzz_timer = 2.0
			_spawn_zzz()

	_body.queue_redraw()


## Wird aufgerufen, wenn ein Körper (der Kackhaufen) das Männchen berührt.
func _on_body_entered(body: Node) -> void:
	if _is_hit:
		return
	# Nur auf Projektile reagieren
	if not body.is_in_group("projectile"):
		return
	# Trefferzonen (F016): Kopf oben = 1.3x, Körper/Beine = 1.0x
	var hit_multiplier: float = 1.0
	if body.global_position.y < global_position.y - 40.0:
		hit_multiplier = 1.3
	_trigger_hit(hit_multiplier)


## Löst die Treffer-Reaktion aus: Punkte, Sound, Effekte und Umfall-Animation.
func _trigger_hit(zone_multiplier: float = 1.0) -> void:
	_is_hit = true
	var effective_mult: int = int(point_multiplier * zone_multiplier)
	var points: int = GameManager.register_hit(effective_mult)
	hit.emit()

	# Schlafendes Männchen geweckt → Combo-Schutz schalten (F032/F049)
	if sleeping:
		GameManager.activate_combo_shield(3.0)

	# Furz abspielen
	if _fart_player.stream != null:
		_fart_player.play()

	# Reaktions-Emote über dem Kopf (F038)
	_spawn_reaction_emote()

	# Schwebenden Punkte-Text und Partikel-Spritzer erzeugen (F116, F143)
	_spawn_floating_text(points)
	_spawn_hit_particles()

	# Zufälliger Power-Up-Drop (F041/F044/F052 – 15% Chance)
	if randf() < 0.15:
		_spawn_powerup()

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


## Erzeugt den aufsteigenden Punkte-Text über dem getroffenen Männchen (F116).
## Die Farbe hängt vom Männchen-Typ ab (Gold sticht hervor).
func _spawn_floating_text(points: int) -> void:
	var color: Color = Color(1, 0.85, 0.2)         # Standard: gelb
	if point_multiplier >= 5:
		color = Color(1.0, 0.84, 0.0)              # Gold
	elif point_multiplier >= 3:
		color = Color(0.4, 0.9, 1.0)               # Mini: cyan
	elif point_multiplier >= 2:
		color = Color(1.0, 0.55, 0.1)              # Schnell: orange
	var ft: FloatingText = FLOATING_TEXT_SCENE.instantiate()
	ft.setup("+%d" % points, color)
	ft.global_position = global_position + Vector2(0, -120)
	get_parent().add_child(ft)


## Zeigt ein zufälliges Reaktions-Emote über dem Männchen (F038).
func _spawn_reaction_emote() -> void:
	const EMOTES: Array = ["NEIN!", "AUA!", "WAS?!", "HILFE!", "OUGH!"]
	var ft: FloatingText = FLOATING_TEXT_SCENE.instantiate()
	ft.setup(EMOTES[randi() % EMOTES.size()], Color(1.0, 0.88, 0.88))
	ft.global_position = global_position + Vector2(randf_range(-40, 40), -190)
	get_parent().add_child(ft)


## Spawnt einen aufsteigenden Zzz-Text über dem schlafenden Männchen (F032).
func _spawn_zzz() -> void:
	var ft: FloatingText = FLOATING_TEXT_SCENE.instantiate()
	ft.setup("Zzz...", Color(0.72, 0.72, 1.0, 0.9))
	ft.global_position = global_position + Vector2(randf_range(-25, 35), -150)
	get_parent().add_child(ft)


## Erzeugt einen Partikel-Spritzer am Trefferpunkt (F143).
func _spawn_hit_particles() -> void:
	var fx: CPUParticles2D = HIT_EFFECT_SCENE.instantiate()
	fx.global_position = global_position + Vector2(0, -60)
	get_parent().add_child(fx)


## Spawnt ein zufälliges Power-Up (F041/F042/F044/F052).
func _spawn_powerup() -> void:
	var types: Array = ["time_bonus", "big_projectile", "points_double"]
	var pu: Area2D = POWERUP_SCENE.instantiate()
	pu.powerup_type = types[randi() % types.size()]
	pu.global_position = global_position + Vector2(randf_range(-30, 30), -80)
	get_parent().add_child(pu)
