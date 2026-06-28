extends Node2D
## FloatingText – aufsteigender Punkte-Text, der nach einem Treffer erscheint (F116).
## Schwebt nach oben und verblasst, dann entfernt er sich selbst.

@export var rise_distance: float = 120.0       ## Strecke nach oben in Pixeln
@export var duration: float = 0.8              ## Dauer der Animation in Sekunden

var _text: String = ""
var _color: Color = Color.WHITE


## Vor dem Hinzufügen zur Szene aufrufen, um Text und Farbe festzulegen.
func setup(text: String, color: Color = Color(1, 0.85, 0.2)) -> void:
	_text = text
	_color = color


func _ready() -> void:
	var label: Label = $Label
	label.text = _text
	label.modulate = _color

	# Nach oben schweben und ausblenden
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - rise_distance, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), duration * 0.3) \
		.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, duration) \
		.set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
