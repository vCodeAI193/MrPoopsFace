extends Control
## MainMenu – Startbildschirm mit Start-, Optionen-Platzhalter und Beenden-Knopf (F113).
## Zeigt zusätzlich den aktuellen Highscore an.

@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _quit_button: Button = $Center/VBox/QuitButton
@onready var _highscore_label: Label = $Center/VBox/HighscoreLabel


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_highscore_label.text = "Bester: %d" % GameManager.get_high_score()


## Startet eine neue Runde, indem zur Hauptszene gewechselt wird.
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


## Beendet das Spiel.
func _on_quit_pressed() -> void:
	get_tree().quit()
