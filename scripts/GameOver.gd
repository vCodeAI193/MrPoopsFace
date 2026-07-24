extends CanvasLayer
## GameOver – Endbildschirm mit Punktestand und Wiederholen-Knopf.

@onready var _score_label: Label = $Center/Panel/VBox/ScoreLabel
@onready var _stars_label: Label = $Center/Panel/VBox/StarsLabel
@onready var _goal_label: Label = $Center/Panel/VBox/GoalLabel
@onready var _coins_earned_label: Label = $Center/Panel/VBox/CoinsEarnedLabel
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
## Text passt sich dem Spielmodus an (F077/F083/F092).
func _on_game_over(final_score: int) -> void:
	match GameManager.game_mode:
		"combo_hunt":
			_score_label.text = "Beste Combo: %d" % final_score
		"endless", "survival":
			_score_label.text = "Endpunktzahl: %d\n(%d Fehlwürfe)" % [
				final_score, GameManager.misses]
		_:
			_score_label.text = "Endpunktzahl: %d" % final_score

	# Sterne-Bewertung + nächstes Ziel anzeigen (F105)
	if GameManager.game_mode in GameManager.STAR_THRESHOLDS:
		_stars_label.visible = true
		_stars_label.text = "★".repeat(GameManager.last_stars) \
			+ "☆".repeat(3 - GameManager.last_stars)
		var goal: int = GameManager.next_star_goal()
		if goal > 0:
			var unit: String = "Combo" if GameManager.game_mode == "combo_hunt" else "Punkte"
			_goal_label.text = "Nächstes Ziel: %d %s" % [goal, unit]
			_goal_label.visible = true
		else:
			_goal_label.visible = false
	else:
		# Zen/Übung: keine Wertung, keine Sterne
		_stars_label.visible = false
		_goal_label.visible = false

	# Verdiente Münzen anzeigen (F095)
	if GameManager.coins_earned_round > 0:
		_coins_earned_label.text = "+%d 🪙 verdient!" % GameManager.coins_earned_round
		_coins_earned_label.visible = true
	else:
		_coins_earned_label.visible = false
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
	# Missions-Ergebnis anhängen (F081)
	var mission: Dictionary = GameManager.current_mission
	if not mission.is_empty():
		if mission["done"]:
			stats_text += "\n🎯 Mission geschafft!"
		else:
			stats_text += "\n🎯 Mission: %d/%d" % [
				int(mission["progress"]), int(mission["target"])]
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
