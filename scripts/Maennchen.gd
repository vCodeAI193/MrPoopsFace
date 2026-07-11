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
@export var has_shield: bool = false                     ## Schild-Männchen braucht 2 Treffer (F023)
@export var is_bomb: bool = false                        ## Bomben-Männchen gibt Minuspunkte (F029)
@export var has_umbrella: bool = false                   ## Regenschirm blockt Treffer von oben (F026)
@export var dodges: bool = false                         ## Weicht Geschossen zur Seite aus (F027)

var _is_hit: bool = false
var _shield_hits: int = 0                                ## Verbleibende Schildtreffer (F023)
var _direction: int = 1                          ## 1 = nach rechts, -1 = nach links
var _walk_phase: float = 0.0                     ## Phase für die Beinanimation

# F022 – Springendes Männchen
var _base_y: float = 0.0
var _jump_phase: float = 0.0

# F032 – Schlafendes Männchen
var _zzz_timer: float = 1.5

# F027 – Ausweichendes Männchen
var _dodge_cooldown: float = 0.0

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
	# Zufällige Furz-Variante zuweisen (F131), über den SFX-Bus (F137/F142)
	_fart_player.bus = "SFX"
	_fart_player.stream = SoundGen.fart(randi() % 5)
	queue_redraw()


func _process(delta: float) -> void:
	if _is_hit or not GameManager.game_active:
		return

	# Eingefroren durch Power-Up (F045)
	if GameManager.freeze_active:
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

	# Ausweichen: springt zur Seite, wenn ein Geschoss näher kommt (F027)
	_dodge_cooldown = maxf(_dodge_cooldown - delta, 0.0)
	if dodges and _dodge_cooldown <= 0.0:
		for p in get_tree().get_nodes_in_group("projectile"):
			if p.global_position.distance_to(global_position) < 250.0:
				_do_dodge(p.global_position)
				break

	_body.queue_redraw()


## Wird aufgerufen, wenn ein Körper (der Kackhaufen) das Männchen berührt.
func _on_body_entered(body: Node) -> void:
	# Nur auf Projektile reagieren
	if not body.is_in_group("projectile"):
		return

	# Regenschirm-Männchen (F026): fallende Treffer von oben werden geblockt
	if has_umbrella and body is RigidBody2D \
			and body.global_position.y < global_position.y - 40.0 \
			and body.linear_velocity.y > 0.0:
		# Geschoss abprallen lassen und Block anzeigen
		body.linear_velocity.y = -absf(body.linear_velocity.y) * 0.6
		var ft: FloatingText = FLOATING_TEXT_SCENE.instantiate()
		ft.setup("Geblockt!", Color(0.7, 0.85, 1.0))
		ft.global_position = global_position + Vector2(0, -160)
		get_parent().add_child(ft)
		return

	# Schild-Männchen (F023): 2 Treffer nötig
	if has_shield:
		_shield_hits += 1
		if _shield_hits < 2:
			# Erstes Treffer: Schild aktivieren/visuell aktualisieren
			queue_redraw()
			return

	if _is_hit:
		return

	# Trefferzonen (F016): Kopf oben = 1.3x, Körper/Beine = 1.0x
	var hit_multiplier: float = 1.0
	if body.global_position.y < global_position.y - 40.0:
		hit_multiplier = 1.3
	_trigger_hit(hit_multiplier)


## Löst die Treffer-Reaktion aus: Punkte, Sound, Effekte und Umfall-Animation.
func _trigger_hit(zone_multiplier: float = 1.0) -> void:
	_is_hit = true
	var points: int = 0
	if is_bomb:
		# Bomben-Männchen: Punkteabzug statt Gewinn (F029),
		# außer der Bomben-Schutz (F048) ist aktiv
		if not GameManager.bomb_shield_active:
			GameManager.register_bomb_hit(50)
			points = -50
	else:
		var effective_mult: int = int(point_multiplier * zone_multiplier)
		points = GameManager.register_hit(effective_mult)
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

	# Stink-Wölkchen aufsteigen lassen (F148)
	_spawn_stink_cloud()

	# Haptisches Feedback auf Android (F157), Stärke einstellbar (F166)
	if GameManager.vibration_strength > 0.0:
		Input.vibrate_handheld(int(60 * GameManager.vibration_strength))

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
	var color: Color
	var text: String
	if is_bomb:
		color = Color(1.0, 0.2, 0.2)              # Bombe: rot
		text = "%d" % points
	elif point_multiplier >= 5:
		color = Color(1.0, 0.84, 0.0)              # Gold
		text = "+%d" % points
	elif point_multiplier >= 3:
		color = Color(0.4, 0.9, 1.0)               # Mini: cyan
		text = "+%d" % points
	elif point_multiplier >= 2:
		color = Color(1.0, 0.55, 0.1)              # Schnell: orange
		text = "+%d" % points
	else:
		color = Color(1, 0.85, 0.2)
		text = "+%d" % points
	var ft: FloatingText = FLOATING_TEXT_SCENE.instantiate()
	ft.setup(text, color)
	ft.global_position = global_position + Vector2(0, -120)
	get_parent().add_child(ft)


## Zeigt ein zufälliges Reaktions-Emote über dem Männchen (F038).
func _spawn_reaction_emote() -> void:
	const EMOTES: Array = ["NEIN!", "AUA!", "WAS?!", "HILFE!", "OUGH!"]
	const BOMB_EMOTES: Array = ["BOOM!", "VERLOREN!", "OH NEIN!"]
	var list: Array = BOMB_EMOTES if is_bomb else EMOTES
	var ft: FloatingText = FLOATING_TEXT_SCENE.instantiate()
	ft.setup(list[randi() % list.size()], Color(1.0, 0.88, 0.88))
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


## Lässt grüne Stink-Wölkchen über dem getroffenen Männchen aufsteigen (F148).
func _spawn_stink_cloud() -> void:
	var stink: CPUParticles2D = CPUParticles2D.new()
	stink.one_shot = true
	stink.emitting = true
	stink.amount = 10
	stink.lifetime = 1.4
	stink.explosiveness = 0.4
	stink.direction = Vector2(0, -1)
	stink.spread = 25.0
	stink.gravity = Vector2(0, -140)
	stink.initial_velocity_min = 30.0
	stink.initial_velocity_max = 70.0
	stink.scale_amount_min = 2.5
	stink.scale_amount_max = 5.5
	stink.color = Color(0.45, 0.75, 0.2, 0.55)
	stink.global_position = global_position + Vector2(0, -90)
	get_parent().add_child(stink)
	# Nach dem Ausklingen automatisch aufräumen
	get_tree().create_timer(2.0).timeout.connect(stink.queue_free)


## Seitlicher Ausweichsprung mit Abklingzeit (F027).
func _do_dodge(threat_pos: Vector2) -> void:
	_dodge_cooldown = 1.5
	# Vom Geschoss weg ausweichen; am Bildschirmrand in die Gegenrichtung
	var away: float = signf(global_position.x - threat_pos.x)
	if away == 0.0:
		away = 1.0
	var view_width: float = get_viewport_rect().size.x
	var target_x: float = clampf(position.x + away * 140.0, 80.0, view_width - 80.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", target_x, 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Spawnt ein zufälliges Power-Up (F041/F042/F043/F044/F045/F047/F052).
func _spawn_powerup() -> void:
	var types: Array = ["time_bonus", "big_projectile", "points_double", "multi_shot", "freeze", "magnet", "bomb_shield"]
	var pu: Area2D = POWERUP_SCENE.instantiate()
	pu.powerup_type = types[randi() % types.size()]
	pu.global_position = global_position + Vector2(randf_range(-30, 30), -80)
	get_parent().add_child(pu)
