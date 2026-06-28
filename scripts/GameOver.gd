extends CanvasLayer
## GameOver – Endbildschirm mit Punktestand und Wiederholen-Knopf.

@onready var _score_label: Label = $Center/Panel/VBox/ScoreLabel
@onready var _replay_button: Button = $Center/Panel/VBox/ReplayButton


func _ready() -> void:
	visible = false
	_replay_button.pressed.connect(_on_replay_pressed)
	# Auf das Rundenende reagieren
	GameManager.game_over.connect(_on_game_over)


## Zeigt den Endbildschirm mit dem erreichten Punktestand.
func _on_game_over(final_score: int) -> void:
	_score_label.text = "Endpunktzahl: %d" % final_score
	visible = true


## Startet die Runde neu, indem die Hauptszene neu geladen wird.
func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()
