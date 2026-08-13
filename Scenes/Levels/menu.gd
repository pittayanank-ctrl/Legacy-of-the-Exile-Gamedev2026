extends Node2D

@onready var btn_continue: Button = $UI/btnContinue
@onready var buttons = {
	$UI/btnStart: $UI/btnStart/AnimatedSprite2D,
	$UI/btnContinue: $UI/btnContinue/AnimatedSprite2D2,
	$UI/btnOption: $UI/btnOption/AnimatedSprite2D3,
	$UI/btnExit: $UI/btnExit/AnimatedSprite2D5,
	$UI/btnCredit: $UI/btnCredit/AnimatedSprite2D4
}


func _ready() -> void:
	for button in buttons:
		var sprite = buttons[button]

		sprite.play("off")

		button.mouse_entered.connect(_on_button_mouse_entered.bind(sprite))
		button.mouse_exited.connect(_on_button_mouse_exited.bind(sprite))

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	$UI.size = get_viewport_rect().size
	
	btn_continue.disabled = !GameManager.has_gamesaved()
	GameManager.load_option()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_button_mouse_entered(sprite: AnimatedSprite2D):
	sprite.play("on")

func _on_button_mouse_exited(sprite: AnimatedSprite2D):
	sprite.play("off")

func _on_btn_start_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	GameManager.restart()


func _on_btn_option_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/options.tscn")


func _on_btn_credit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/credit.tscn")


func _on_btn_continue_pressed() -> void:
	if GameManager.has_gamesaved():
		GameManager.load_game()
	else:
		show_no_save_message()

func show_no_save_message() -> void:
	var label = $UI/NoSaveLabel
	
	label.text = "คุณยังไม่ได้บันทึกเกม"
	label.modulate.a = 1.0
	label.show()

	await get_tree().create_timer(2.0).timeout

	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.5)

	await tween.finished

	label.hide()

func _on_btn_exit_pressed() -> void:
	get_tree().quit()
