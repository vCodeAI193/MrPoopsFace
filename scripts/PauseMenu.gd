class_name PauseMenu
extends CanvasLayer
## PauseMenu – Pause-Overlay mit Fortsetzen / Neustart / Hauptmenü (F114).
## Läuft im Modus ALWAYS weiter, damit die Knöpfe trotz Spielpause reagieren.

@onready var _resume_button: Button = $Center/Panel/VBox/ResumeButton
@onready var _restart_button: Button = $Center/Panel/VBox/RestartButton
@onready var _menu_button: Button = $Center/Panel/VBox/MenuButton


func _ready() -> void:
	visible = false
	_resume_button.pressed.connect(_on_resume_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)


## Pausiert das Spiel und zeigt das Overlay.
func show_pause() -> void:
	get_tree().paused = true
	visible = true


## Setzt das Spiel fort.
func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false


## Startet die laufende Runde neu.
func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


## Kehrt zum Hauptmenü zurück.
func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
