class_name SettingsOverlay
extends CanvasLayer
## Settings – Options-Overlay mit persistenten Einstellungen (F179).
## Lautstärkeregler für Musik/Effekte (F137), Screen-Shake-Schalter (F181),
## Reduzierte-Bewegung-Option (F183), Vibrationsstärke (F166) und
## Reset-auf-Standard (F187). Läuft im Modus ALWAYS, damit es auch
## während der Spielpause bedienbar bleibt.

@onready var _music_slider: HSlider = $Center/Panel/VBox/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $Center/Panel/VBox/SfxRow/SfxSlider
@onready var _vibration_slider: HSlider = $Center/Panel/VBox/VibrationRow/VibrationSlider
@onready var _shake_check: CheckButton = $Center/Panel/VBox/ShakeCheck
@onready var _motion_check: CheckButton = $Center/Panel/VBox/MotionCheck
@onready var _reset_button: Button = $Center/Panel/VBox/ResetButton
@onready var _close_button: Button = $Center/Panel/VBox/CloseButton

var _ui_click_player: AudioStreamPlayer
var _paused_by_settings: bool = false          ## Hat dieses Overlay die Pause ausgelöst?


func _ready() -> void:
	visible = false
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_vibration_slider.value_changed.connect(_on_vibration_changed)
	_shake_check.toggled.connect(_on_shake_toggled)
	_motion_check.toggled.connect(_on_motion_toggled)
	_reset_button.pressed.connect(_on_reset_pressed)
	_close_button.pressed.connect(_on_close_pressed)

	# Audio-Player für UI-Klicks (F136)
	_ui_click_player = AudioStreamPlayer.new()
	_ui_click_player.bus = "SFX"
	add_child(_ui_click_player)


## Öffnet das Overlay; pause=true hält währenddessen das Spiel an (F124).
func show_settings(pause: bool = false) -> void:
	_sync_from_settings()
	if pause and not get_tree().paused:
		get_tree().paused = true
		_paused_by_settings = true
	visible = true


## Überträgt die gespeicherten Werte auf die Bedienelemente.
func _sync_from_settings() -> void:
	_music_slider.set_value_no_signal(GameManager.music_volume)
	_sfx_slider.set_value_no_signal(GameManager.sfx_volume)
	_vibration_slider.set_value_no_signal(GameManager.vibration_strength)
	_shake_check.set_pressed_no_signal(GameManager.screen_shake_enabled)
	_motion_check.set_pressed_no_signal(GameManager.reduced_motion)


func _on_music_changed(value: float) -> void:
	GameManager.music_volume = value
	GameManager.apply_audio_settings()
	GameManager.save_settings()


func _on_sfx_changed(value: float) -> void:
	GameManager.sfx_volume = value
	GameManager.apply_audio_settings()
	GameManager.save_settings()
	_play_click_sound()                          # direkt hörbares Feedback


func _on_vibration_changed(value: float) -> void:
	GameManager.vibration_strength = value
	GameManager.save_settings()
	# Probe-Vibration als Feedback (F166)
	if value > 0.0:
		Input.vibrate_handheld(int(60 * value))


func _on_shake_toggled(pressed: bool) -> void:
	GameManager.screen_shake_enabled = pressed
	GameManager.save_settings()
	_play_click_sound()


func _on_motion_toggled(pressed: bool) -> void:
	GameManager.reduced_motion = pressed
	GameManager.save_settings()
	_play_click_sound()


## Setzt alle Optionen zurück und aktualisiert die Anzeige (F187).
func _on_reset_pressed() -> void:
	_play_click_sound()
	GameManager.reset_settings()
	_sync_from_settings()


func _on_close_pressed() -> void:
	_play_click_sound()
	if _paused_by_settings:
		get_tree().paused = false
		_paused_by_settings = false
	visible = false


## Gibt den UI-Klick-Sound aus (F136)
func _play_click_sound() -> void:
	_ui_click_player.stream = SoundGen.click()
	_ui_click_player.play()
