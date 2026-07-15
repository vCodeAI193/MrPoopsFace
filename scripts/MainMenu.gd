extends Control
## MainMenu – Startbildschirm mit Start-, Optionen- und Beenden-Knopf (F113).
## Zeigt zusätzlich den aktuellen Highscore an. UI-Klick-Sounds (F136).
## "Spielen" öffnet die Modus-Auswahl mit Vorschau-Beschreibungen (F094).

@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _options_button: Button = $Center/VBox/OptionsButton
@onready var _quit_button: Button = $Center/VBox/QuitButton
@onready var _highscore_label: Label = $Center/VBox/HighscoreLabel
@onready var _settings: SettingsOverlay = $Settings
@onready var _mode_center: CenterContainer = $ModeCenter
@onready var _mode_vbox: VBoxContainer = $ModeCenter/ModePanel/ModeVBox

var _ui_click_player: AudioStreamPlayer


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_highscore_label.text = "Bester: %d" % GameManager.get_high_score()

	# Modus-Buttons verbinden (F094)
	_mode_vbox.get_node("NormalButton").pressed.connect(_start_mode.bind("normal"))
	_mode_vbox.get_node("EndlessButton").pressed.connect(_start_mode.bind("endless"))
	_mode_vbox.get_node("SurvivalButton").pressed.connect(_start_mode.bind("survival"))
	_mode_vbox.get_node("ComboHuntButton").pressed.connect(_start_mode.bind("combo_hunt"))
	_mode_vbox.get_node("ZenButton").pressed.connect(_start_mode.bind("zen"))
	_mode_vbox.get_node("PracticeButton").pressed.connect(_start_mode.bind("practice"))
	_mode_vbox.get_node("BackButton").pressed.connect(_on_mode_back_pressed)

	# Audio-Player für UI-Klicks (F136)
	_ui_click_player = AudioStreamPlayer.new()
	_ui_click_player.bus = "SFX"
	add_child(_ui_click_player)


## Android-Zurück-Taste im Menü: offene Panels schließen, sonst Beenden-Dialog.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _mode_center.visible:
		_mode_center.visible = false
		return
	# Bestätigungsdialog vor dem Beenden (F120-Muster)
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Beenden?"
	dialog.dialog_text = "Stinky Toss wirklich beenden?"
	dialog.confirmed.connect(func() -> void: get_tree().quit())
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered_ratio(0.35)


## Öffnet die Modus-Auswahl (F094).
func _on_start_pressed() -> void:
	_play_click_sound()
	_mode_center.visible = true


## Schließt die Modus-Auswahl wieder.
func _on_mode_back_pressed() -> void:
	_play_click_sound()
	_mode_center.visible = false


## Setzt den gewählten Modus und startet die Runde (F094).
func _start_mode(mode: String) -> void:
	_play_click_sound()
	GameManager.set_game_mode(mode)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


## Öffnet die Optionen (F179).
func _on_options_pressed() -> void:
	_play_click_sound()
	_settings.show_settings()


## Beendet das Spiel.
func _on_quit_pressed() -> void:
	_play_click_sound()
	get_tree().quit()


## Gibt den UI-Klick-Sound aus (F136)
func _play_click_sound() -> void:
	_ui_click_player.stream = SoundGen.click()
	_ui_click_player.play()
