class_name CombatCamera
extends Camera2D


@export_category("Target Detection")
@export var lock_distance: float = 300.0

@export_category("Zoom")
@export var normal_zoom: Vector2 = Vector2(1.0, 1.0)
@export var combat_zoom: Vector2 = Vector2(1.5, 1.5)

@export_category("Camera Movement")
@export var follow_speed: float = 5.0
@export var zoom_speed: float = 5.0


var player: Node2D
var target_enemy: Node2D = null


func _ready() -> void:

	player = get_parent()

	zoom = normal_zoom
	
func find_nearest_enemy() -> Node2D:

	var enemies := get_tree().get_nodes_in_group("Enemy")

	var nearest: Node2D = null
	var nearest_distance := lock_distance

	for enemy in enemies:

		if not is_instance_valid(enemy):
			continue

		if enemy.get("is_dead") == true:
			continue

		var distance := player.global_position.distance_to(
			enemy.global_position
		)

		if distance < nearest_distance:

			nearest_distance = distance
			nearest = enemy

	return nearest
	
func _physics_process(delta: float) -> void:

	if not is_instance_valid(player):
		return

	if not is_instance_valid(target_enemy):

		target_enemy = find_nearest_enemy()


	if target_enemy != null:

		update_combat_camera(delta)

	else:

		update_normal_camera(delta)
		
func update_combat_camera(delta: float) -> void:

	if not is_instance_valid(target_enemy):
		target_enemy = null
		return


	var midpoint := (
		player.global_position +
		target_enemy.global_position
	) / 2.0


	global_position = global_position.lerp(
		midpoint,
		delta * follow_speed
	)


	zoom = zoom.lerp(
		combat_zoom,
		delta * zoom_speed
	)


	# ถ้า Enemy ออกนอกระยะ
	var distance := player.global_position.distance_to(
		target_enemy.global_position
	)

	if distance > lock_distance:

		target_enemy = null
		
func update_normal_camera(delta: float) -> void:

	global_position = global_position.lerp(
		player.global_position,
		delta * follow_speed
	)

	zoom = zoom.lerp(
		normal_zoom,
		delta * zoom_speed
	)


	# ตรวจหา Enemy ใหม่

	var enemy := find_nearest_enemy()

	if enemy != null:

		target_enemy = enemy
