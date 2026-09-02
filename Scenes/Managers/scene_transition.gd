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


func transition_animation(
	animation_name: String,
	scene: PackedScene
) -> void:

	if scene == null:
		print("ERROR: PackedScene เป็น NULL")
		return

	print("กำลังโหลด: ", scene.resource_path)

	dissolve_rect.show()

	scene_transition_anim.play(animation_name)

	await scene_transition_anim.animation_finished


	# =====================================================
	# เปลี่ยน Scene
	# =====================================================

	print("กำลังเปลี่ยน Scene...")

	var new_scene: Node = scene.instantiate()

	if new_scene == null:
		print("ERROR: PackedScene นี้ไม่มี Node!")
		return

	print("Scene มี Root Node: ", new_scene.name)

	new_scene.queue_free()

	get_tree().change_scene_to_packed(scene)


	await get_tree().process_frame


	# =====================================================
	# Fade In
	# =====================================================

	scene_transition_anim.play_backwards(animation_name)

	await scene_transition_anim.animation_finished

	dissolve_rect.hide()
