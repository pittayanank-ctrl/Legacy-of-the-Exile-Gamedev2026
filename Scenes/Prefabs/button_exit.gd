extends Button


@export var exitToScene: PackedScene

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:

	sprite.play("off")

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# =========================================================
# MOUSE HOVER
# =========================================================

func _on_mouse_entered() -> void:

	sprite.play("on")


func _on_mouse_exited() -> void:

	sprite.play("off")


# =========================================================
# BUTTON PRESSED
# =========================================================

func _on_pressed() -> void:
	$ButtonSound.play(0)
	get_tree().change_scene_to_file("res://Scenes/Managers/menu.tscn")
