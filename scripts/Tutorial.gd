class_name TutorialOverlay
extends CanvasLayer
## Tutorial – Erst-Start-Erklärung der Schleuder-Steuerung (F162).
## Zeigt eine animierte Zieh-und-Loslass-Demo in Schleife, bis der
## Spieler auf "Los geht's!" tippt.

signal tutorial_closed                         ## Wird beim Schließen gesendet

@onready var _start_button: Button = $Center/Panel/VBox/StartButton
@onready var _demo: Control = $Center/Panel/VBox/Demo

var _ui_click_player: AudioStreamPlayer
var _demo_phase: float = 0.0                   ## 0..1 ziehen, 1..2 fliegen


func _ready() -> void:
	visible = false
	_start_button.pressed.connect(_on_start_pressed)
	_demo.draw.connect(_draw_demo)

	# Audio-Player für UI-Klicks (F136), über den SFX-Bus (F137/F142)
	_ui_click_player = AudioStreamPlayer.new()
	_ui_click_player.bus = "SFX"
	add_child(_ui_click_player)


func _process(delta: float) -> void:
	if not visible:
		return
	# Demo-Schleife: 1,2s ziehen, 0,8s Flug, dann von vorn
	_demo_phase = fmod(_demo_phase + delta, 2.0)
	_demo.queue_redraw()


## Zeigt das Tutorial-Overlay.
func show_tutorial() -> void:
	_demo_phase = 0.0
	visible = true


## Zeichnet die animierte Schleuder-Demo in das Demo-Control.
func _draw_demo() -> void:
	var size: Vector2 = _demo.size
	var anchor: Vector2 = Vector2(size.x * 0.3, size.y * 0.65)
	var drag_target: Vector2 = anchor + Vector2(-110, 90)

	# Anker (wie beim Spieler)
	_demo.draw_circle(anchor, 14.0, Color(0.4, 0.26, 0.13))

	if _demo_phase < 1.2:
		# Phase 1: Finger zieht den Haufen nach hinten unten
		var t: float = _demo_phase / 1.2
		var pos: Vector2 = anchor.lerp(drag_target, t)
		# Gummiband
		_demo.draw_line(anchor, pos, Color(0.3, 0.2, 0.1), 5.0)
		# Kackhaufen
		_demo.draw_circle(pos, 16.0, Color(0.45, 0.27, 0.12))
		# Fingerkreis
		_demo.draw_arc(pos, 26.0, 0, TAU, 24, Color(1, 1, 1, 0.85), 3.0)
	else:
		# Phase 2: Haufen fliegt in einer Parabel nach vorn oben
		var t: float = (_demo_phase - 1.2) / 0.8
		var vel: Vector2 = (anchor - drag_target) * 4.2
		var pos: Vector2 = anchor + vel * t + Vector2(0, 340.0) * t * t
		_demo.draw_circle(pos, 16.0, Color(0.45, 0.27, 0.12))

	# Ziel-Strichmännchen rechts
	var figure_x: float = size.x * 0.82
	var ground_y: float = size.y * 0.72
	var col: Color = Color(0.1, 0.1, 0.1)
	_demo.draw_arc(Vector2(figure_x, ground_y - 64), 14.0, 0, TAU, 20, col, 4.0)
	_demo.draw_line(Vector2(figure_x, ground_y - 50), Vector2(figure_x, ground_y - 14), col, 4.0)
	_demo.draw_line(Vector2(figure_x, ground_y - 42), Vector2(figure_x - 16, ground_y - 26), col, 4.0)
	_demo.draw_line(Vector2(figure_x, ground_y - 42), Vector2(figure_x + 16, ground_y - 26), col, 4.0)
	_demo.draw_line(Vector2(figure_x, ground_y - 14), Vector2(figure_x - 12, ground_y + 14), col, 4.0)
	_demo.draw_line(Vector2(figure_x, ground_y - 14), Vector2(figure_x + 12, ground_y + 14), col, 4.0)


## Schließt das Tutorial und meldet das dem Aufrufer.
func _on_start_pressed() -> void:
	_ui_click_player.stream = SoundGen.click()
	_ui_click_player.play()
	visible = false
	tutorial_closed.emit()
