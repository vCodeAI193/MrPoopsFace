class_name PauseMenu
extends CanvasLayer
## PauseMenu – Pause-Overlay mit Fortsetzen / Neustart / Hauptmenü (F114).
## Läuft im Modus ALWAYS weiter, damit die Knöpfe trotz Spielpause reagieren.
## UI-Klick-Sounds (F136).

@onready var _resume_button: Button = $Center/Panel/VBox/ResumeButton
@onready var _restart_button: Button = $Center/Panel/VBox/RestartButton
@onready var _menu_button: Button = $Center/Panel/VBox/MenuButton

var _ui_click_player: AudioStreamPlayer


func _ready() -> void:
	visible = false
	_resume_button.pressed.connect(_on_resume_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)

	# Audio-Player für UI-Klicks (F136)
	_ui_click_player = AudioStreamPlayer.new()
	add_child(_ui_click_player)


## Pausiert das Spiel und zeigt das Overlay.
func show_pause() -> void:
	get_tree().paused = true
	visible = true


## Setzt das Spiel fort.
func _on_resume_pressed() -> void:
	_play_click_sound()
	get_tree().paused = false
	visible = false


## Startet die laufende Runde neu.
func _on_restart_pressed() -> void:
	_play_click_sound()
	get_tree().paused = false
	get_tree().reload_current_scene()


## Kehrt zum Hauptmenü zurück (mit Bestätigung, F120).
func _on_menu_pressed() -> void:
	_play_click_sound()
	# Bestätigungsdialog (F120)
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Zum Menü?"
	dialog.dialog_text = "Aktuelle Runde beenden?"
	dialog.confirmed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered_ratio(0.35)


## Gibt den UI-Klick-Sound aus (F136)
func _play_click_sound() -> void:
	_ui_click_player.stream = SoundGen.click()
	_ui_click_player.play()
