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
		_spawn_confetti()  # Konfetti-Regen bei neuem Rekord (F152)
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


## Lässt bunten Konfetti-Regen von oben über den Bildschirm fallen (F152).
func _spawn_confetti() -> void:
	for x in [480, 960, 1440]:
		var confetti: CPUParticles2D = CPUParticles2D.new()
		confetti.one_shot = true
		confetti.emitting = true
		confetti.amount = 45
		confetti.lifetime = 2.5
		confetti.explosiveness = 0.9
		confetti.direction = Vector2(0, 1)
		confetti.spread = 70.0
		confetti.gravity = Vector2(0, 320)
		confetti.initial_velocity_min = 180.0
		confetti.initial_velocity_max = 480.0
		confetti.scale_amount_min = 3.0
		confetti.scale_amount_max = 6.0
		confetti.color = Color(1.0, 0.35, 0.35)
		confetti.hue_variation_min = -0.5
		confetti.hue_variation_max = 0.5
		confetti.position = Vector2(x, -30)
		add_child(confetti)
		# Nach dem Ausklingen aufräumen
		get_tree().create_timer(3.5).timeout.connect(confetti.queue_free)


## Startet die Runde neu, indem die Hauptszene neu geladen wird.
func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()


## Kehrt zum Hauptmenü zurück.
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
