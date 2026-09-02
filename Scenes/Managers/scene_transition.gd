extends CanvasLayer


@onready var scene_transition_anim: AnimationPlayer = $SceneTransitionAnim
@onready var dissolve_rect: ColorRect = $DissolveRect


func _ready() -> void:
	dissolve_rect.hide()


func load_scene(target_scene: PackedScene) -> void:

	if target_scene == null:
		print("ERROR: target_scene เป็น NULL")
		return

	print("========== SCENE TRANSITION ==========")
	print("Scene: ", target_scene)
	print("Path: ", target_scene.resource_path)

	await transition_animation(
		"fade",
		target_scene
	)


func transition_animation(animation_name: String, scene: PackedScene):
	scene_transition_anim.play(animation_name)

	await scene_transition_anim.animation_finished

	get_tree().change_scene_to_packed(scene)

	# รอให้ Scene ใหม่โหลดเสร็จ
	await get_tree().process_frame

	# Save หลังเปลี่ยน Scene
	GameManager.save_game()

	scene_transition_anim.play_backwards(animation_name)
