class_name Enemy
extends CharacterBody2D


# =========================================================
# STATE
# =========================================================

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEFEND,
	HURT,
	DEAD
}

var state: State = State.IDLE


# =========================================================
# MOVEMENT
# =========================================================

@export_category("Movement")

@export var move_speed: float = 70.0
@export var detection_distance: float = 250.0
@export var attack_distance: float = 70


# =========================================================
# COMBAT
# =========================================================

@export_category("Combat")

@export var max_hp: int = 100
@export var attack_damage: int = 15
@export var attack_cooldown: float = 1.2


# =========================================================
# DEFENSE
# =========================================================

@export_category("Defense")

@export_range(0.0, 1.0)
var block_chance: float = 0.5

@export var block_duration: float = 0.6
@export var block_cooldown: float = 1.5


# =========================================================
# VARIABLES
# =========================================================

var hp: int

var player: Node2D = null

var can_attack: bool = true
var can_block: bool = true

var is_attacking: bool = false
var is_defending: bool = false
var is_hurt: bool = false
var is_dead: bool = false


# =========================================================
# NODES
# =========================================================

@onready var sprite: AnimatedSprite2D = $BodyVisual/AnimatedSprite2D
@onready var attack_area: Area2D = $BodyVisual/AttackArea
@onready var body_visual: Node2D = $BodyVisual

# =========================================================
# READY
# =========================================================

func _ready() -> void:

	hp = max_hp

	sprite.play("Idle")

	find_player()


# =========================================================
# MAIN LOOP
# =========================================================
		
func _physics_process(_delta: float) -> void:

	if is_dead:
		return

	if player == null:
		find_player()
		return

	# ไม่ให้ AI ทำอะไรระหว่าง Attack / Hurt / Defend
	if is_attacking or is_hurt or is_defending:
		return

	var distance := global_position.distance_to(player.global_position)


	# Player อยู่ไกลเกินไป
	if distance > detection_distance:

		idle()


	# Player อยู่ในระยะตรวจจับ
	elif distance > attack_distance:

		chase_player()


	# Player อยู่ในระยะโจมตี
	else:

		combat()


# =========================================================
# FIND PLAYER
# =========================================================

func find_player() -> void:

	var players := get_tree().get_nodes_in_group("Player")

	if players.size() > 0:
		player = players[0]


# =========================================================
# IDLE
# =========================================================

func idle() -> void:

	state = State.IDLE

	velocity.x = 0

	sprite.play("Idle")

	move_and_slide()


# =========================================================
# CHASE PLAYER
# =========================================================

func chase_player() -> void:

	state = State.CHASE

	var direction: float = sign(player.global_position.x - global_position.x)

	velocity.x = direction * move_speed

	sprite.play("Walk")

	flip_enemy(direction)

	move_and_slide()


# =========================================================
# COMBAT
# =========================================================

func combat() -> void:

	velocity.x = 0

	if not can_attack:
		sprite.play("Idle")
		return

	attack()


# =========================================================
# ATTACK
# =========================================================

func attack() -> void:

	if is_attacking:
		return

	if not can_attack:
		return

	is_attacking = true
	can_attack = false

	state = State.ATTACK

	velocity.x = 0

	sprite.play("Attack")

	# รอให้ Animation ฟันถึงตำแหน่งโจมตี
	await get_tree().create_timer(0.2).timeout

	if not is_dead:

		check_attack_hit()

	# รอ Cooldown
	await get_tree().create_timer(attack_cooldown).timeout

	can_attack = true


# =========================================================
# CHECK ATTACK HIT
# =========================================================

func check_attack_hit() -> void:

	var bodies := attack_area.get_overlapping_bodies()

	for body in bodies:

		if body.is_in_group("Player"):

			if body.has_method("take_damage"):

				body.take_damage(attack_damage)


# =========================================================
# PLAYER ATTACKED ENEMY
# =========================================================

func on_player_attack(damage: int) -> void:

	if is_dead:
		return

	if is_hurt:
		return

	if is_defending:
		return


	# มีโอกาส Block
	if can_block and randf() <= block_chance:

		block()

	else:

		take_damage(damage)


# =========================================================
# DEFEND
# =========================================================

func block() -> void:

	if is_dead or not can_block:
		return

	is_defending = true
	can_block = false

	state = State.DEFEND

	velocity.x = 0

	sprite.play("Defend")

	await get_tree().create_timer(block_duration).timeout

	if is_dead:
		return

	is_defending = false
	state = State.IDLE

	sprite.play("Idle")

	await get_tree().create_timer(block_cooldown).timeout

	if not is_dead:
		can_block = true


# =========================================================
# TAKE DAMAGE
# =========================================================

func take_damage(damage: int) -> void:

	if is_dead:
		return

	if is_defending:

		print("Enemy blocked!")

		return


	hp -= damage

	print("Enemy HP: ", hp)


	if hp <= 0:

		die()

	else:

		hurt()


# =========================================================
# HURT
# =========================================================

func hurt() -> void:

	if is_dead:
		return

	is_hurt = true

	state = State.HURT

	velocity.x = 0

	sprite.play("Hurt")


# =========================================================
# DEAD
# =========================================================

func die() -> void:

	if is_dead:
		return

	is_dead = true

	state = State.DEAD

	is_attacking = false
	is_defending = false
	is_hurt = false

	velocity = Vector2.ZERO

	sprite.play("Dead")


# =========================================================
# FLIP
# =========================================================

func flip_enemy(direction: float) -> void:
	if direction < 0:
		body_visual.scale.x = -1
	elif direction > 0:
		body_visual.scale.x = 1

# =========================================================
# ANIMATION FINISHED
# =========================================================

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_dead:
		return

	match sprite.animation:

		"Attack":
			is_attacking = false
			sprite.play("Idle")

		"Hurt":
			is_hurt = false
			sprite.play("Idle")

		"Dead":
			queue_free()
