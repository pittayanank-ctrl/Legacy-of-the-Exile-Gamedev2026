class_name Player
extends CharacterBody2D


# =========================================================
# MOVEMENT
# =========================================================

@export_category("Movement")

@export var walk_speed: float = 100.0
@export var run_speed: float = 180.0
@export var acceleration: float = 1000.0
@export var friction: float = 1200.0


# =========================================================
# STAMINA
# =========================================================

@export_category("Stamina")

@export var max_stamina: float = 100.0
@export var stamina_drain: float = 25.0
@export var stamina_recovery: float = 20.0


# =========================================================
# COMBAT
# =========================================================

@export_category("Combat")

@export var max_hp: int = 100
@export var attack_damage: int = 20

@export var attack1_time: float = 0.15
@export var attack2_time: float = 0.15
@export var attack3_time: float = 0.20

@export var attack_cooldown: float = 0.1


# =========================================================
# DEFEND
# =========================================================

@export_category("Defense")

@export var defend_stamina_drain: float = 10.0


# =========================================================
# VARIABLES
# =========================================================

var hp: int
var stamina: float

var facing_direction: float = 1.0

var is_attacking: bool = false
var is_defending: bool = false
var is_hurt: bool = false
var is_dead: bool = false

var can_take_damage: bool = true

# Combo
var combo_step: int = 0
var combo_queued: bool = false

# Run
var is_running: bool = false


# =========================================================
# NODES
# =========================================================

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	hp = max_hp
	stamina = max_stamina

	sprite.play("Idle")


# =========================================================
# PHYSICS
# =========================================================

func _physics_process(delta: float) -> void:

	if is_dead:
		return

	handle_defend()
	handle_attack_input()

	if not is_attacking and not is_defending and not is_hurt:
		handle_movement(delta)

	update_stamina(delta)

	move_and_slide()


# =========================================================
# MOVEMENT
# =========================================================

func handle_movement(delta: float) -> void:

	var direction: float = Input.get_axis("Left", "Right")

	is_running = false

	# -----------------------------------------
	# Running
	# -----------------------------------------

	if Input.is_action_pressed("Run") and direction != 0:

		if stamina > 0:

			is_running = true

			stamina -= stamina_drain * delta

			velocity.x = move_toward(
				velocity.x,
				direction * run_speed,
				acceleration * delta
			)

		else:

			velocity.x = move_toward(
				velocity.x,
				direction * walk_speed,
				acceleration * delta
			)

	else:

		velocity.x = move_toward(
			velocity.x,
			direction * walk_speed,
			acceleration * delta
		)


	# -----------------------------------------
	# Stop
	# -----------------------------------------

	if direction == 0:

		velocity.x = move_toward(
			velocity.x,
			0,
			friction * delta
		)


	# -----------------------------------------
	# Flip
	# -----------------------------------------

	if direction != 0:

		facing_direction = direction

		if direction < 0:
			visual.scale.x = -1
		else:
			visual.scale.x = 1


	# -----------------------------------------
	# Animation
	# -----------------------------------------

	if direction == 0:

		sprite.play("Idle")

	elif is_running:

		sprite.play("Run")

	else:

		sprite.play("Walk")


# =========================================================
# STAMINA
# =========================================================

func update_stamina(delta: float) -> void:

	if not is_running and not is_defending:

		stamina += stamina_recovery * delta

		stamina = min(stamina, max_stamina)


# =========================================================
# ATTACK INPUT
# =========================================================

func handle_attack_input() -> void:

	if is_dead:
		return

	if is_defending:
		return

	if Input.is_action_just_pressed("Attack"):

		if is_attacking:

			# กดโจมตีระหว่าง Combo
			combo_queued = true

		else:

			start_attack(1)


# =========================================================
# START ATTACK
# =========================================================

func start_attack(number: int) -> void:

	if is_dead:
		return

	is_attacking = true
	combo_step = number
	combo_queued = false

	velocity.x = 0

	match number:

		1:
			sprite.play("Attack1")

		2:
			sprite.play("Attack2")

		3:
			sprite.play("Attack3")

	attack_hit_delay(number)


# =========================================================
# ATTACK HIT
# =========================================================

func attack_hit_delay(number: int) -> void:

	var delay: float = 0.15

	match number:

		1:
			delay = attack1_time

		2:
			delay = attack2_time

		3:
			delay = attack3_time


	await get_tree().create_timer(delay).timeout

	if is_dead:
		return

	if is_attacking:

		check_attack_hit()


# =========================================================
# CHECK ATTACK HIT
# =========================================================

func check_attack_hit() -> void:

	var enemies := attack_area.get_overlapping_bodies()

	for enemy in enemies:

		if enemy.is_in_group("Enemy"):

			if enemy.has_method("take_damage"):

				enemy.take_damage(attack_damage)


# =========================================================
# DEFEND
# =========================================================

func handle_defend() -> void:

	if is_dead:
		return

	if is_attacking:
		return

	if Input.is_action_pressed("Defend"):

		if stamina <= 0:
			is_defending = false
			return

		is_defending = true

		velocity.x = 0

		stamina -= defend_stamina_drain * get_physics_process_delta_time()

		sprite.play("Defend")

	else:

		if is_defending:

			is_defending = false

			sprite.play("Idle")


# =========================================================
# TAKE DAMAGE
# =========================================================

func take_damage(damage: int) -> void:

	if is_dead:
		return

	if not can_take_damage:
		return

	# กำลัง Block
	if is_defending:
		print("Player Blocked!")
		return

	hp -= damage

	print("Player HP: ", hp)

	can_take_damage = false
	is_hurt = true

	velocity.x = 0

	sprite.play("Hurt")

	await get_tree().create_timer(0.5).timeout

	can_take_damage = true


	# Invincibility
	await get_tree().create_timer(0.5).timeout

	can_take_damage = true


# =========================================================
# ANIMATION FINISHED
# =========================================================

func _on_animated_sprite_2d_animation_finished() -> void:

	if is_dead:
		return

	match sprite.animation:

		"Attack1":
			if combo_queued:
				start_attack(2)
			else:
				end_attack()

		"Attack2":
			if combo_queued:
				start_attack(3)
			else:
				end_attack()

		"Attack3":
			end_attack()

		"Hurt":
			is_hurt = false
			sprite.play("Idle")

		"Dead":
			queue_free()


# =========================================================
# END ATTACK
# =========================================================

func end_attack() -> void:

	is_attacking = false

	combo_step = 0
	combo_queued = false

	sprite.play("Idle")


# =========================================================
# DEAD
# =========================================================

func die() -> void:

	if is_dead:
		return

	is_dead = true

	is_attacking = false
	is_defending = false
	is_hurt = false

	velocity = Vector2.ZERO

	sprite.play("Dead")
