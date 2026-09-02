extends Node2D

func _on_btn_start_2_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	GameManager.restart()

func _on_btn_start_pressed() -> void:
		SceneTransition.load_scene(
	preload("res://Scenes/Managers/menu.tscn")
)
