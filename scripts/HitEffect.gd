extends CPUParticles2D
## HitEffect – kurzer Partikel-Spritzer bei einem Treffer (F143).
## Wird einmalig ausgelöst und räumt sich danach selbst auf.

func _ready() -> void:
	emitting = true
	# Nach Ablauf der Partikel-Lebensdauer entfernen
	await get_tree().create_timer(lifetime + 0.3).timeout
	queue_free()
