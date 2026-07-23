extends SceneTree
## Headless-Testläufer für Stinky Toss (F199).
## Start: godot --headless --path . --script tests/run_tests.gd
## Prüft, dass alle Scripts laden (Syntax + Preload-Pfade) und testet
## die GameManager-Logik (Modi, Munition, Combo, Fehlwürfe, Bomben,
## Optionen, Highscores) an einer frischen Instanz ohne Autoload.

var _passes: int = 0
var _failures: int = 0


func _initialize() -> void:
	print("=== Stinky Toss Tests ===")
	_test_parse_all_scripts()
	_test_game_modes()
	_test_ammo()
	_test_hits_and_combo()
	_test_misses()
	_test_bomb()
	_test_settings_reset()
	_test_highscores()
	print("---")
	print("%d Tests bestanden, %d fehlgeschlagen" % [_passes, _failures])
	quit(1 if _failures > 0 else 0)


## Prüft eine Bedingung und protokolliert das Ergebnis.
func _check(cond: bool, name: String) -> void:
	if cond:
		_passes += 1
		print("PASS: " + name)
	else:
		_failures += 1
		printerr("FAIL: " + name)


## Erzeugt eine frische GameManager-Instanz (ohne Autoload/_ready).
func _new_gm() -> Node:
	return load("res://scripts/GameManager.gd").new()


## Alle Scripts laden – fängt Syntaxfehler und kaputte Preload-Pfade.
func _test_parse_all_scripts() -> void:
	var dir: DirAccess = DirAccess.open("res://scripts")
	_check(dir != null, "scripts/-Ordner vorhanden")
	if dir == null:
		return
	for f in dir.get_files():
		if f.ends_with(".gd"):
			var script: Script = load("res://scripts/" + f)
			_check(script != null, "Script lädt: " + f)


## Modus-Presets aus set_game_mode (F085/F089/F077/F083/F092/F093).
func _test_game_modes() -> void:
	var gm: Node = _new_gm()
	gm.set_game_mode("hard")
	_check(gm.ammo_per_round == 30, "hard: 30 Würfe Munition")
	_check(gm.round_duration == 45.0, "hard: 45 Sekunden")
	gm.set_game_mode("endless")
	_check(gm.miss_limit == 3, "endless: 3 Fehlwürfe erlaubt")
	gm.set_game_mode("survival")
	_check(gm.miss_limit == 5, "survival: 5 Fehlwürfe erlaubt")
	gm.set_game_mode("zen")
	_check(gm.miss_limit == -1, "zen: keine Fehlwurf-Grenze")
	gm.set_game_mode("normal")
	_check(gm.round_duration == 60.0 and gm.ammo_per_round == -1,
		"normal: 60s, unbegrenzte Munition")
	gm.free()


## Munitionsverbrauch und -grenzen (F004).
func _test_ammo() -> void:
	var gm: Node = _new_gm()
	gm.set_game_mode("normal")
	gm.start_game()
	_check(gm.consume_ammo(), "unbegrenzte Munition: Wurf erlaubt")
	gm.ammo_left = 2
	_check(gm.consume_ammo() and gm.consume_ammo(), "2 Würfe verbraucht")
	_check(not gm.consume_ammo(), "leerer Vorrat: Wurf verweigert")
	gm.add_ammo(1)
	_check(gm.ammo_left == 1, "add_ammo füllt nach")
	gm.free()


## Punkteberechnung, Combo und Combo-Jagd (F092/F130).
func _test_hits_and_combo() -> void:
	var gm: Node = _new_gm()
	gm.set_game_mode("normal")
	gm.start_game()
	var p1: int = gm.register_hit(1)
	_check(p1 == 10, "1. Treffer: 10 Punkte (10 * Combo 1 * Typ 1)")
	var p2: int = gm.register_hit(2)
	_check(p2 == 40, "2. Treffer: 40 Punkte (10 * Combo 2 * Typ 2)")
	_check(gm.score == 50, "Score summiert 50")
	_check(gm.best_combo == 2 and gm.hits_total == 2, "Statistiken (F130)")
	gm.free()

	var hunt: Node = _new_gm()
	hunt.set_game_mode("combo_hunt")
	hunt.start_game()
	hunt.register_hit(1)
	hunt.register_hit(1)
	hunt.register_hit(1)
	_check(hunt.score == 3, "Combo-Jagd: Score = höchste Combo")
	hunt.free()


## Fehlwurf-Limit beendet die Runde (F077).
func _test_misses() -> void:
	var gm: Node = _new_gm()
	gm.set_game_mode("endless")
	gm.start_game()
	gm.register_miss()
	gm.register_miss()
	_check(gm.game_active, "nach 2 Fehlwürfen läuft die Runde noch")
	gm.register_miss()
	_check(not gm.game_active, "3. Fehlwurf beendet die Endlos-Runde")
	gm.free()

	var zen: Node = _new_gm()
	zen.set_game_mode("zen")
	zen.start_game()
	for i in 10:
		zen.register_miss()
	_check(zen.game_active, "zen: Fehlwürfe beenden nichts")
	zen.free()


## Bomben-Strafe und Bomben-Schutz (F029/F048).
func _test_bomb() -> void:
	var gm: Node = _new_gm()
	gm.set_game_mode("normal")
	gm.start_game()
	gm.register_hit(1)                          # Score 10
	gm.register_bomb_hit(50)
	_check(gm.score == 0, "Bombe: Score sinkt, aber nie unter 0")
	gm.register_hit(1)                          # Combo läuft weiter
	gm.bomb_shield_active = true
	var before: int = gm.score
	gm.register_bomb_hit(50)
	_check(gm.score == before, "Bomben-Schutz verhindert den Abzug")
	gm.free()


## Optionen-Reset stellt die Standardwerte her (F187).
func _test_settings_reset() -> void:
	var gm: Node = _new_gm()
	gm._setup_audio_buses()                     # Busse für apply_audio_settings
	gm.music_volume = 0.1
	gm.sfx_volume = 0.2
	gm.screen_shake_enabled = false
	gm.reduced_motion = true
	gm.vibration_strength = 0.0
	gm.reset_settings()
	_check(gm.music_volume == 0.7 and gm.sfx_volume == 1.0
		and gm.screen_shake_enabled and not gm.reduced_motion
		and gm.vibration_strength == 1.0, "reset_settings: Standardwerte")
	gm.free()


## Highscore-Sortierung und Top-10-Kappung (F168).
func _test_highscores() -> void:
	var gm: Node = _new_gm()
	gm.highscores = []
	for v in [50, 200, 100]:
		gm._record_highscore(v)
	_check(int(gm.highscores[0]) == 200 and int(gm.highscores[2]) == 50,
		"Highscores absteigend sortiert")
	gm._record_highscore(0)
	_check(gm.highscores.size() == 3, "Score 0 wird nicht eingetragen")
	for i in 15:
		gm._record_highscore(300 + i)
	_check(gm.highscores.size() == 10, "Top-10-Kappung greift")
	_check(int(gm.highscores[0]) == 314, "höchster Wert steht oben")
	gm.free()
