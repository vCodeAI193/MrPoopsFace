class_name ShopOverlay
extends CanvasLayer
## Shop – Geschoss-Skins kaufen und anlegen (F096/F098).
## Baut die Skin-Karten zur Laufzeit aus GameManager.SKINS auf;
## die Vorschau nutzt dieselbe Zeichenroutine wie das Projektil.

const PROJECTILE_SCRIPT: Script = preload("res://scripts/Projectile.gd")

@onready var _coins_label: Label = $Center/Panel/VBox/CoinsLabel
@onready var _skin_list: VBoxContainer = $Center/Panel/VBox/SkinList
@onready var _close_button: Button = $Center/Panel/VBox/CloseButton

var _ui_click_player: AudioStreamPlayer


## Vorschau-Control, das einen Skin über die Projektil-Routine zeichnet.
class SkinPreview:
	extends Control
	var skin_id: String = "classic"
	var _t: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		if skin_id == "rainbow":
			queue_redraw()

	func _draw() -> void:
		draw_set_transform(size * 0.5, 0.0, Vector2.ONE)
		ShopOverlay.PROJECTILE_SCRIPT.draw_poop_shape(self, 26.0, skin_id, _t)


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(_on_close_pressed)
	_ui_click_player = AudioStreamPlayer.new()
	_ui_click_player.bus = "SFX"
	add_child(_ui_click_player)


## Öffnet den Shop und baut die Liste neu auf.
func show_shop() -> void:
	_rebuild()
	visible = true


## Baut die Skin-Karten anhand des Katalogs und Besitzstands auf.
func _rebuild() -> void:
	_coins_label.text = "🪙 %d" % GameManager.coins
	for child in _skin_list.get_children():
		child.queue_free()

	for id in GameManager.SKINS:
		var info: Dictionary = GameManager.SKINS[id]
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 30)

		var preview: SkinPreview = SkinPreview.new()
		preview.skin_id = id
		preview.custom_minimum_size = Vector2(110, 100)
		row.add_child(preview)

		var name_label: Label = Label.new()
		name_label.text = String(info["name"])
		name_label.add_theme_font_size_override("font_size", 40)
		name_label.custom_minimum_size = Vector2(300, 0)
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(name_label)

		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(280, 80)
		button.add_theme_font_size_override("font_size", 34)
		var owned: bool = id in GameManager.owned_skins
		var selected: bool = id == GameManager.selected_skin
		if selected:
			button.text = "✔ Angelegt"
			button.disabled = true
		elif owned:
			button.text = "Anlegen"
			button.pressed.connect(_on_select_pressed.bind(id))
		else:
			button.text = "Kaufen: 🪙 %d" % int(info["price"])
			button.disabled = GameManager.coins < int(info["price"])
			button.pressed.connect(_on_buy_pressed.bind(id))
		row.add_child(button)

		_skin_list.add_child(row)


## Kauft den Skin und legt ihn direkt an (Kinder wollen sofort sehen, was sie haben).
func _on_buy_pressed(id: String) -> void:
	_play_click_sound()
	if GameManager.buy_skin(id):
		GameManager.select_skin(id)
	_rebuild()


func _on_select_pressed(id: String) -> void:
	_play_click_sound()
	GameManager.select_skin(id)
	_rebuild()


func _on_close_pressed() -> void:
	_play_click_sound()
	visible = false


## Gibt den UI-Klick-Sound aus (F136)
func _play_click_sound() -> void:
	_ui_click_player.stream = SoundGen.click()
	_ui_click_player.play()
