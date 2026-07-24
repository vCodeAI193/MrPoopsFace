extends Control
## MainMenu – Startbildschirm mit Start-, Shop-, Optionen- und Beenden-Knopf (F113).
## Zeigt zusätzlich Highscore und Münzstand an. UI-Klick-Sounds (F136).
## "Spielen" öffnet die Modus-Auswahl mit Vorschau-Beschreibungen (F094).
## Mit antippbarem Mr.-Poops-Maskottchen für den Kinder-Charme.

const PROJECTILE_SCRIPT: Script = preload("res://scripts/Projectile.gd")
const FLOATING_TEXT_SCENE: PackedScene = preload("res://scenes/FloatingText.tscn")

@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _shop_button: Button = $Center/VBox/ShopButton
@onready var _options_button: Button = $Center/VBox/OptionsButton
@onready var _quit_button: Button = $Center/VBox/QuitButton
@onready var _highscore_label: Label = $Center/VBox/HighscoreLabel
@onready var _coins_label: Label = $Center/VBox/CoinsLabel
@onready var _settings: SettingsOverlay = $Settings
@onready var _shop: ShopOverlay = $Shop
@onready var _mode_center: CenterContainer = $ModeCenter
@onready var _mode_vbox: VBoxContainer = $ModeCenter/ModePanel/ModeVBox

var _ui_click_player: AudioStreamPlayer
var _fart_player: AudioStreamPlayer
var _mascot: Node2D


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_shop_button.pressed.connect(_on_shop_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_highscore_label.text = "Bester: %d" % GameManager.get_high_score()
	_coins_label.text = "🪙 %d" % GameManager.coins
	GameManager.coins_changed.connect(
		func(total: int) -> void: _coins_label.text = "🪙 %d" % total)

	# Maskottchen links neben dem Menü aufbauen
	_create_mascot()

	# Tagesbonus einmal pro Tag beim Menü-Besuch (F101)
	var daily: int = GameManager.claim_daily_bonus()
	if daily > 0:
		var ft: FloatingText = FLOATING_TEXT_SCENE.instantiate()
		ft.setup("+%d 🪙 Tagesbonus!" % daily, Color(1.0, 0.84, 0.0))
		ft.scale = Vector2(1.6, 1.6)
		ft.position = Vector2(960, 300)
		add_child(ft)
		# Das Maskottchen freut sich mit
		_on_mascot_tapped()

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

	# Furz-Player fürs Maskottchen
	_fart_player = AudioStreamPlayer.new()
	_fart_player.bus = "SFX"
	add_child(_fart_player)


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


## Mr.-Poops-Maskottchen: großer wackelnder Haufen links neben dem Menü.
class MascotBody:
	extends Node2D
	var _t: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		rotation = sin(_t * 2.2) * 0.07            # sanftes Wackeln
		queue_redraw()

	func _draw() -> void:
		var script: Script = load("res://scripts/Projectile.gd")
		script.draw_poop_shape(self, 95.0, GameManager.selected_skin, _t)
		# Fröhliches Gesicht
		for sx in [-1.0, 1.0]:
			var eye_pos: Vector2 = Vector2(sx * 27.0, -10.0)
			draw_circle(eye_pos, 17.0, Color.WHITE)
			draw_circle(eye_pos + Vector2(0, 3), 8.5, Color.BLACK)
		draw_arc(Vector2(0, 27.0), 21.0, 0.15 * PI, 0.85 * PI, 12, Color.BLACK, 4.0)


## Erstellt das antippbare Maskottchen (Kinder-Charme).
func _create_mascot() -> void:
	_mascot = MascotBody.new()
	_mascot.position = Vector2(300, 620)
	add_child(_mascot)


## Antippen des Maskottchens: Furz, Hüpfer und freches Emote.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and _mascot:
		if event.position.distance_to(_mascot.global_position) < 140.0:
			_on_mascot_tapped()


func _on_mascot_tapped() -> void:
	_fart_player.stream = SoundGen.fart(randi() % 5)
	_fart_player.play()
	# Hüpfer
	var tween: Tween = create_tween()
	tween.tween_property(_mascot, "scale", Vector2(1.25, 0.8), 0.1)
	tween.tween_property(_mascot, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Freches Emote
	const EMOTES: Array = ["Hihi!", "Pups!", "Nochmal!", "Hee hee!", "Wirf mich!"]
	var ft: FloatingText = FLOATING_TEXT_SCENE.instantiate()
	ft.setup(EMOTES[randi() % EMOTES.size()], Color(1.0, 0.95, 0.6))
	ft.position = _mascot.position + Vector2(randf_range(-30, 30), -140)
	add_child(ft)


## Öffnet den Shop (F096).
func _on_shop_pressed() -> void:
	_play_click_sound()
	_shop.show_shop()


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
