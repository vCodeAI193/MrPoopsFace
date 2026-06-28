extends Control
## MainMenu – Startbildschirm mit Start-, Optionen-Platzhalter und Beenden-Knopf (F113).
## Zeigt zusätzlich den aktuellen Highscore an. UI-Klick-Sounds (F136).

@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _quit_button: Button = $Center/VBox/QuitButton
@onready var _highscore_label: Label = $Center/VBox/HighscoreLabel

var _ui_click_player: AudioStreamPlayer


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_highscore_label.text = "Bester: %d" % GameManager.get_high_score()

	# Audio-Player für UI-Klicks (F136)
	_ui_click_player = AudioStreamPlayer.new()
	add_child(_ui_click_player)


## Startet eine neue Runde, indem zur Hauptszene gewechselt wird.
func _on_start_pressed() -> void:
	_play_click_sound()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


## Beendet das Spiel.
func _on_quit_pressed() -> void:
	_play_click_sound()
	get_tree().quit()


## Gibt den UI-Klick-Sound aus (F136)
func _play_click_sound() -> void:
	_ui_click_player.stream = SoundGen.click()
	_ui_click_player.play()
