extends Node2D
## SplatDecal – Schmierfleck am Boden nach Aufprall (F015).

var _radius: float = 40.0
var _alpha: float = 1.0
var _splat_seed: int = 0


func setup(pos: Vector2, radius: float) -> void:
	add_to_group("splat_decal")                # für das Decal-Limit (Performance)
	global_position = pos
	_radius = radius * randf_range(0.6, 1.1)
	_splat_seed = randi()
	queue_redraw()
	var tween: Tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_method(_set_alpha, 1.0, 0.0, 1.5)
	tween.tween_callback(queue_free)


func _set_alpha(a: float) -> void:
	_alpha = a
	queue_redraw()


func _draw() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _splat_seed
	var brown: Color = Color(0.35, 0.18, 0.08, _alpha)
	draw_circle(Vector2.ZERO, _radius, brown)
	for i in 5:
		var ox: float = rng.randf_range(-_radius, _radius)
		var oy: float = rng.randf_range(-_radius * 0.3, _radius * 0.3)
		draw_circle(Vector2(ox, oy), rng.randf_range(_radius * 0.2, _radius * 0.45), brown)
