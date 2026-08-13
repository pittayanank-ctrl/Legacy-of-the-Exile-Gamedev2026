class_name Player
extends CharacterBody2D

signal hit_enemy
signal hit_trap

# =========================
# PLAYER
# =========================

@export_category("Player Properties")

@export var move_speed: float = 120.0
@export var run_speed: float = 220.0

@export var jump_force: float = 650.0
@export var gravity: float = 30.0
@export var max_jump_count: int = 2
@export var double_jump: bool = false

@export var max_hp: int = 100
@export var hp: int = 100

# =========================
# COMBAT
# =========================

@export_category("Combat")

@export var attack_damage: int = 20
@export var attack_cooldown: float = 0.15

var attack_combo := 0
var can_attack := true
var attack_has_hit := false

# =========================
# VARIABLES
# =========================

var jump_count: int = 2

var is_grounded := false
var movement_enabled := true

var spawn_point := Vector2.ZERO

var is_attacking := false
var is_defending := false
var is_hurt := false
var is_dead := false

var can_damage := true

# =========================
# NODES
# =========================

@onready var player_sprite: AnimatedSprite2D = $student/AnimatedSprite2D
@onready var player_node = $student

@onready var attack_area: Area2D = $AttackArea

@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles


# =========================
# READY
# =========================

func _ready() -> void:

	spawn_point = global_position

	if GameManager.save_player_position.x != 0:
		global_position = GameManager.save_player_position

	GameManager.save_player_position = Vector2.ZERO

	player_sprite.animation_finished.connect(_on_animation_finished)

	player_sprite.play("Idle")


# =========================
# PHYSICS
# =========================

func _physics_process(_delta):

	if is_dead:
		return

	is_grounded = is_on_floor()

	movement()

	move_and_slide()


# =========================
# PROCESS
# =========================

func _process(_delta):

	if is_dead:
		return

	player_animations()
	flip_player()

# =========================
# MOVEMENT
# =========================

func movement():

	# ห้ามเดินขณะโจมตี / ป้องกัน / โดนตี
	if is_attacking or is_defending or is_hurt:
		velocity.x = 0
		return


	# Gravity
	if not is_on_floor():
		velocity.y += gravity
	else:
		jump_count = max_jump_count


	handle_jumping()


	# Movement
	if movement_enabled:

		var direction := Input.get_axis("Left", "Right")

		var speed := move_speed

		# Run
		if Input.is_action_pressed("Run") and direction != 0:
			speed = run_speed

		velocity.x = direction * speed

	else:
		velocity.x = 0


	# ตกจากฉาก
	if velocity.y > 5000:
		hit_trap.emit()


# =========================
# JUMP
# =========================

func handle_jumping():

	if Input.is_action_just_pressed("Jump") and movement_enabled:

		if is_on_floor() and not double_jump:
			jump()

		elif double_jump and jump_count > 0:
			jump()
			jump_count -= 1


func jump():

	jump_tween()

	AudioManager.jump_sfx.play()

	velocity.y = -jump_force


# =========================
# ANIMATION
# =========================

func player_animations():

	particle_trails.emitting = false

	# Combat animation มี priority สูงกว่า
	if is_attacking:
		return

	if is_defending:
		player_sprite.play("Defend")
		return

	if is_hurt:
		return

	# อยู่บนพื้น
	if is_on_floor():

		if abs(velocity.x) > 0:

			particle_trails.emitting = true

			if Input.is_action_pressed("Run"):
				player_sprite.play("Run")
			else:
				player_sprite.play("Walk")

		else:
			player_sprite.play("Idle")

	else:

		# ไม่มี Jump animation
		player_sprite.play("Idle")


# =========================
# FLIP
# =========================

func flip_player():

	if velocity.x < 0:
		player_node.scale.x = -1

	elif velocity.x > 0:
		player_node.scale.x = 1


# =========================
# ATTACK
# =========================

func _input(event):

	if is_dead:
		return

	if event.is_action_pressed("Attack"):
		attack()

	if event.is_action_pressed("Defend"):
		start_defend()

	if event.is_action_released("Defend"):
		stop_defend()


func attack():

	if not movement_enabled:
		return

	if is_defending:
		return

	if is_hurt:
		return

	if is_attacking:
		return


	# ถ้าวิ่งอยู่ → Run+Attack
	if Input.is_action_pressed("Run") and abs(velocity.x) > 0:

		run_attack()

	else:

		normal_attack()


# =========================
# NORMAL ATTACK COMBO
# =========================

func normal_attack():

	is_attacking = true
	attack_has_hit = false

	velocity.x = 0

	attack_combo += 1

	# จำกัด Combo 1-3
	if attack_combo > 3:
		attack_combo = 1


	match attack_combo:

		1:
			player_sprite.play("Attack1")

		2:
			player_sprite.play("Attack2")

		3:
			player_sprite.play("Attack3")


	# ตรวจการโจมตีหลังจากเริ่ม Animation
	await get_tree().create_timer(0.1).timeout

	if is_attacking:
		check_attack_hit()


# =========================
# RUN ATTACK
# =========================

func run_attack():

	is_attacking = true
	attack_has_hit = false

	player_sprite.play("Run+Attack")

	await get_tree().create_timer(0.1).timeout

	if is_attacking:
		check_attack_hit()


# =========================
# ATTACK HIT
# =========================

func check_attack_hit():

	if attack_has_hit:
		return

	attack_has_hit = true

	var enemies = attack_area.get_overlapping_bodies()

	for enemy in enemies:

		if enemy.is_in_group("Enemy"):

			if enemy.has_method("take_damage"):

				enemy.take_damage(attack_damage)

				hit_enemy.emit()


# =========================
# DEFEND
# =========================

func start_defend():

	if is_attacking:
		return

	if is_hurt:
		return

	if is_dead:
		return

	is_defending = true

	velocity.x = 0

	player_sprite.play("Defend")


func stop_defend():

	is_defending = false

	if not is_attacking and not is_hurt:

		player_sprite.play("Idle")


# =========================
# TAKE DAMAGE
# =========================

func take_damage(damage: int):

	if is_dead:
		return

	if not can_damage:
		return

	# Block ลด Damage
	if is_defending:

		damage = int(damage * 0.2)

		print("Blocked! Damage: ", damage)


	hp -= damage

	print("Player HP: ", hp)


	if hp <= 0:

		die()

	else:

		hurt()


# =========================
# HURT
# =========================

func hurt():

	if is_dead:
		return

	is_hurt = true

	velocity.x = 0

	player_sprite.play("Hurt")

	damage_tween()


# =========================
# DEAD
# =========================

func die():

	if is_dead:
		return

	is_dead = true

	movement_enabled = false

	velocity = Vector2.ZERO

	player_sprite.play("Dead")

	death_particles.emitting = true


# =========================
# DAMAGE EFFECT
# =========================

func damage_tween():

	can_damage = false

	var tween = create_tween()

	for i in range(3):

		tween.tween_property(
			player_node,
			"modulate",
			Color.RED,
			0.1
		)

		tween.tween_property(
			player_node,
			"modulate",
			Color.WHITE,
			0.1
		)

	await tween.finished

	can_damage = true


# =========================
# DEATH / RESPAWN
# =========================

func death_tween():

	AudioManager.death_sfx.play()

	death_particles.emitting = true

	movement_enabled = false

	var tween = create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2.ZERO,
		0.15
	)

	await tween.finished

	global_position = spawn_point

	await get_tree().create_timer(0.3).timeout

	movement_enabled = true

	is_dead = false
	hp = max_hp

	AudioManager.respawn_sfx.play()

	respawn_tween()


func respawn_tween():

	var tween = create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.15
	)


# =========================
# TWEEN
# =========================

func jump_tween():

	var tween = create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2(0.7, 1.4),
		0.1
	)

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.1
	)


# =========================
# ANIMATION FINISHED
# =========================

func _on_animation_finished():

	var anim = player_sprite.animation


	if anim == "Attack1":
		is_attacking = false

	elif anim == "Attack2":
		is_attacking = false

	elif anim == "Attack3":
		is_attacking = false

		# จบ Combo
		attack_combo = 0

	elif anim == "Run+Attack":
		is_attacking = false

	elif anim == "Hurt":

		is_hurt = false

		if not is_dead:
			player_sprite.play("Idle")

	elif anim == "Dead":

		death_tween()


# =========================
# TRAP / COLLISION
# =========================

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Traps"):

		hit_trap.emit()


	if body.is_in_group("Enemy"):

		if not can_damage:
			return

		# ถ้าไม่ได้ป้องกัน ให้โดนชน
		if not is_defending:

			var dx = body.position.x - position.x

			velocity.y = -200

			if dx > 0:
				velocity.x = -200
			else:
				velocity.x = 200

			take_damage(10)
