extends Node


# =========================================================
# PLAYER
# =========================================================

var player: Player = null

var hp: int = 100
var max_hp: int = 100

var life: int = 4
var max_life: int = 5

var score: int = 0


# =========================================================
# LEVEL
# =========================================================

var current_level: String = "res://Scenes/Levels/level_start1.tscn"

var respawn_position: Vector2 = Vector2.ZERO


# =========================================================
# MISSION
# =========================================================

var current_mission: String = ""

var mission_started: bool = false
var mission_completed: bool = false


# =========================================================
# AUDIO
# =========================================================

var sfx_on: bool = true
var music_on: bool = true


# =========================================================
# SAVE
# =========================================================

var save_path: String = "user://game.save"


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	load_option()


# =========================================================
# PLAYER REGISTER
# =========================================================

func register_player(new_player: Player) -> void:

	player = new_player

	if respawn_position != Vector2.ZERO:

		player.global_position = respawn_position


# =========================================================
# SCORE
# =========================================================

func add_score(value: int = 1) -> void:

	score += value


# =========================================================
# HP
# =========================================================

func damage(value: int = 1) -> void:

	hp -= value

	hp = max(hp, 0)

	if hp <= 0:

		death()


func add_hp(value: int = 1) -> void:

	hp += value

	hp = min(hp, max_hp)


# =========================================================
# LIFE / DEATH
# =========================================================

func death() -> void:

	life -= 1

	print("Life: ", life)


	# =====================================================
	# GAME OVER
	# =====================================================

	if life <= 0:
		return


	# =====================================================
	# RESPAWN CURRENT LEVEL
	# =====================================================

	var respawn_scene: PackedScene = load(
		current_level
	) as PackedScene

	if respawn_scene == null:

		print("ERROR: ไม่พบ Scene: ", current_level)

		return

	SceneTransition.load_scene(respawn_scene)


# =========================================================
# RESTART GAME
# =========================================================

func restart() -> void:

	hp = max_hp

	life = 4

	score = 0

	current_level = "res://Scenes/Levels/level_start1.tscn"

	respawn_position = Vector2.ZERO

	current_mission = ""

	mission_started = false

	mission_completed = false

	delete_save_game()


	var start_scene: PackedScene = preload(
		"res://Scenes/Levels/level_start1.tscn"
	)

	SceneTransition.load_scene(start_scene)


# =========================================================
# LEVEL
# =========================================================

func set_level(scene_path: String) -> void:

	current_level = scene_path


func load_next_level(next_scene: PackedScene) -> void:

	if next_scene == null:

		print("ERROR: Next Scene is NULL")

		return


	current_level = next_scene.resource_path

	respawn_position = Vector2.ZERO


	# ใช้ Fade Transition
	SceneTransition.load_scene(next_scene)


# =========================================================
# MISSION START
# =========================================================

func start_mission(mission_name: String) -> void:

	current_mission = mission_name

	mission_started = true

	mission_completed = false

	print("Mission Started: ", mission_name)

	save_game()


# =========================================================
# MISSION COMPLETE
# =========================================================

func complete_mission() -> void:

	if not mission_started:

		return

	mission_completed = true

	print("Mission Completed: ", current_mission)

	save_game()


# =========================================================
# SAVE GAME
# =========================================================

func save_game() -> void:

	# =====================================================
	# CURRENT LEVEL
	# =====================================================

	if get_tree().current_scene != null:

		current_level = get_tree().current_scene.scene_file_path


	# =====================================================
	# PLAYER POSITION
	# =====================================================

	var pos: Vector2 = respawn_position

	if is_instance_valid(player):

		pos = player.global_position

		respawn_position = pos


	# =====================================================
	# SAVE DATA
	# =====================================================

	var payload: Dictionary = {

		"current_level": current_level,

		"player_position": [
			pos.x,
			pos.y
		],

		"hp": hp,

		"life": life,

		"score": score,

		"mission": current_mission,

		"mission_started": mission_started,

		"mission_completed": mission_completed
	}


	var file := FileAccess.open(
		save_path,
		FileAccess.WRITE
	)


	if file:

		var json_text := JSON.stringify(
			payload,
			"  "
		)

		file.store_string(json_text)

		file.close()

		print("Game Saved")


# =========================================================
# CHECK SAVE
# =========================================================

func has_gamesaved() -> bool:

	return FileAccess.file_exists(
		save_path
	)


# =========================================================
# LOAD GAME
# =========================================================

func load_game() -> void:

	if not has_gamesaved():

		restart()

		return


	var file := FileAccess.open(
		save_path,
		FileAccess.READ
	)


	if file == null:

		return


	var text := file.get_as_text()

	file.close()


	var data = JSON.parse_string(text)


	if data == null:

		return


	# =====================================================
	# LOAD DATA
	# =====================================================

	current_level = data.get(
		"current_level",
		"res://Scenes/Levels/level_start1.tscn"
	)


	var pos = data.get(
		"player_position",
		[0, 0]
	)


	respawn_position = Vector2(
		pos[0],
		pos[1]
	)


	hp = data.get(
		"hp",
		max_hp
	)


	life = data.get(
		"life",
		4
	)


	score = data.get(
		"score",
		0
	)


	current_mission = data.get(
		"mission",
		""
	)


	mission_started = data.get(
		"mission_started",
		false
	)


	mission_completed = data.get(
		"mission_completed",
		false
	)


	print("Game Loaded")


	# =====================================================
	# LOAD SAVED SCENE WITH FADE
	# =====================================================

	var saved_scene: PackedScene = load(
		current_level
	) as PackedScene


	if saved_scene == null:

		print(
			"ERROR: ไม่พบ Saved Scene: ",
			current_level
		)

		return


	SceneTransition.load_scene(
		saved_scene
	)


# =========================================================
# DELETE SAVE
# =========================================================

func delete_save_game() -> void:

	if FileAccess.file_exists(save_path):

		DirAccess.remove_absolute(
			save_path
		)


# =========================================================
# OPTIONS
# =========================================================

func update_option() -> void:

	var music_bus := AudioServer.get_bus_index(
		"music"
	)

	var sfx_bus := AudioServer.get_bus_index(
		"sfx"
	)


	if music_bus != -1:

		AudioServer.set_bus_mute(
			music_bus,
			!music_on
		)


	if sfx_bus != -1:

		AudioServer.set_bus_mute(
			sfx_bus,
			!sfx_on
		)


func save_option() -> void:

	var file := FileAccess.open(
		"user://option.json",
		FileAccess.WRITE
	)


	if file:

		var payload := {

			"music": music_on,

			"sound": sfx_on
		}


		file.store_string(
			JSON.stringify(
				payload,
				"  "
			)
		)

		file.close()


func load_option() -> void:

	if not FileAccess.file_exists(
		"user://option.json"
	):

		update_option()

		return


	var file := FileAccess.open(
		"user://option.json",
		FileAccess.READ
	)


	if file == null:

		return


	var text := file.get_as_text()

	file.close()


	var data = JSON.parse_string(text)


	if data == null:

		return


	music_on = data.get(
		"music",
		true
	)


	sfx_on = data.get(
		"sound",
		true
	)


	update_option()
