extends CanvasLayer
## GameOver – Endbildschirm mit Punktestand und Wiederholen-Knopf.

@onready var _score_label: Label = $Center/Panel/VBox/ScoreLabel
@onready var _best_label: Label = $Center/Panel/VBox/BestLabel
@onready var _stats_label: Label = $Center/Panel/VBox/StatsLabel
@onready var _replay_button: Button = $Center/Panel/VBox/ReplayButton
@onready var _menu_button: Button = $Center/Panel/VBox/MenuButton


func _ready() -> void:
	visible = false
	_replay_button.pressed.connect(_on_replay_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	# Auf das Rundenende reagieren
	GameManager.game_over.connect(_on_game_over)


## Zeigt den Endbildschirm mit dem erreichten Punktestand.
func _on_game_over(final_score: int) -> void:
	_score_label.text = "Endpunktzahl: %d" % final_score
	# Neuen Rekord hervorheben bzw. den besten Wert anzeigen (F168)
	if GameManager.last_was_highscore:
		_best_label.text = "🏆 Neuer Rekord!"
	else:
		_best_label.text = "Bester: %d" % GameManager.get_high_score()

	# Spielstatistiken anzeigen (F130)
	var stats_text: String = "Beste Combo: %d | Treffer: %d\nØ Pro Hit: %.0f" % [
		GameManager.best_combo,
		GameManager.hits_total,
		GameManager.avg_points_per_hit
	]
	_stats_label.text = stats_text
	visible = true


## Startet die Runde neu, indem die Hauptszene neu geladen wird.
func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()


## Kehrt zum Hauptmenü zurück.
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
