extends CanvasLayer


# =========================================================
# TOP UI
# =========================================================

@onready var hp_bar: ProgressBar = $TopUI/HealthBar1/HPBar
@onready var stamina_bar: ProgressBar = $TopUI/HealthBar1/StaminaBar


# =========================================================
# PAUSE UI
# =========================================================

@onready var pause_ui: Control = $PauseUI
@onready var game_over_ui: Control = $OverUI

@onready var option_button: Button = $PauseUI/PauseTab/OptionButton
@onready var restart_button: Button = $PauseUI/PauseTab/RestartButton
@onready var exit_button: Button = $PauseUI/PauseTab/ExitButton
@onready var restart_button2: Button = $OverUI/PauseTab2/RestartButton
@onready var exit_button2: Button = $OverUI/PauseTab2/ExitButton

# =========================================================
# BUTTON ANIMATION
# =========================================================

@onready var buttons = {
	option_button: $PauseUI/PauseTab/OptionButton/AnimatedSprite2D,
	restart_button: $PauseUI/PauseTab/RestartButton/AnimatedSprite2D2,
	exit_button: $PauseUI/PauseTab/ExitButton/AnimatedSprite2D3,
	restart_button2: $OverUI/PauseTab2/RestartButton/AnimatedSprite2D2,
	exit_button2: $OverUI/PauseTab2/ExitButton/AnimatedSprite2D3
}


# =========================================================
# PLAYER
# =========================================================

var player: Player = null


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# UI ต้องทำงานได้ตอนเกม Pause
	process_mode = Node.PROCESS_MODE_ALWAYS

	# ซ่อน Pause ตอนเริ่มเกม
	pause_ui.visible = false
	game_over_ui.visible = false

	# หา Player
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("Player")

	if player:
		update_ui()

	# ตั้ง Animation ปุ่ม
	for button in buttons:

		var button_sprite: AnimatedSprite2D = buttons[button]

		button_sprite.play("off")

		button.mouse_entered.connect(
			_on_button_mouse_entered.bind(button_sprite)
		)

		button.mouse_exited.connect(
			_on_button_mouse_exited.bind(button_sprite)
		)


# =========================================================
# UPDATE UI
# =========================================================

func _process(_delta: float) -> void:

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")

	if player:
		update_ui()


func update_ui() -> void:

	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp

	stamina_bar.max_value = player.max_stamina
	stamina_bar.value = player.stamina


# =========================================================
# PAUSE INPUT
# =========================================================

func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("pause"):

		if get_tree().paused:
			resume_game()
		else:
			pause_game()


# =========================================================
# PAUSE
# =========================================================

func pause_game() -> void:

	pause_ui.visible = true

	get_tree().paused = true


# =========================================================
# RESUME
# =========================================================

func resume_game() -> void:

	get_tree().paused = false

	pause_ui.visible = false


# =========================================================
# OPTION
# =========================================================

func _on_option_button_pressed() -> void:

	get_tree().paused = false

	get_tree().change_scene_to_file(
		"res://Scenes/Managers/options.tscn"
	)


# =========================================================
# RESTART
# =========================================================

func _on_restart_button_pressed() -> void:

	get_tree().paused = false

	get_tree().reload_current_scene()


# =========================================================
# EXIT
# =========================================================

func _on_exit_button_pressed() -> void:

	get_tree().paused = false

	get_tree().change_scene_to_file(
		"res://Scenes/Levels/menu.tscn"
	)


# =========================================================
# BUTTON HOVER
# =========================================================

func _on_button_mouse_entered(
	button_sprite: AnimatedSprite2D
) -> void:

	button_sprite.play("on")


func _on_button_mouse_exited(
	button_sprite: AnimatedSprite2D
) -> void:

	button_sprite.play("off")
	
func show_game_over() -> void:

	get_tree().paused = true

	game_over_ui.visible = true
