class_name EnemyCastle
extends CharacterBody2D


enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEFEND,
	HURT,
	DEAD
}

var state: State = State.IDLE


# =========================
# SETTINGS
# =========================

@export_category("Movement")
@export var move_speed: float = 120
@export var detection_distance: float = 250.0
@export var attack_distance: float = 75


@export_category("Combat")
@export var max_hp: int = 500
@export var attack_damage: int = 20
@export var attack_cooldown: float = 1.2

# ระยะเวลาที่ enemy จะค้างอยู่ในสถานะ Hurt (บังคับด้วย timer แทนการพึ่ง
# animation_finished signal อย่างเดียว) — กันไม่ให้ enemy หยุดนิ่งถาวร
# ถ้า signal ไม่ได้ต่อไว้ในหน้า Editor หรือ animation "Hurt" ตั้ง Loop ไว้
@export var hurt_stun_duration: float = 0.3


@export_category("Defense")
@export_range(0.0, 1.0)
var block_chance: float = 0.35

@export var block_duration: float = 0.5
@export var block_cooldown: float = 2.0


# =========================
# VARIABLES
# =========================

var hp: int

var player: Node2D = null

var can_attack: bool = true
var can_block: bool = true

var is_attacking: bool = false
var is_defending: bool = false
var is_hurt: bool = false
var is_dead: bool = false


# =========================
# NODES
# =========================

@onready var sprite: AnimatedSprite2D = $BodyVisual/AnimatedSprite2D
@onready var attack_area: Area2D = $BodyVisual/AttackArea
@onready var detection_area: Area2D = $BodyVisual/DetectionArea
@onready var body_visual: Node2D = $BodyVisual
@onready var health_bar: ProgressBar = $HealthBar

var is_block_stunned: bool = false

@export var block_stun_duration: float = 2

# =========================
# READY
# =========================

func _ready() -> void:

	hp = max_hp

	health_bar.max_value = max_hp
	health_bar.value = hp

	sprite.play("Idle")

	find_player()


# =========================
# MAIN
# =========================

func _physics_process(_delta: float) -> void:

	if is_dead:
		return

	if player == null:
		find_player()
		return

	if is_hurt:
		return

	if is_block_stunned:
		return

	if is_attacking:
		return

	if is_defending:
		return


	var distance_x: float = abs(
		player.global_position.x - global_position.x
	)


	# =========================
	# PLAYER TOO FAR
	# =========================

	if distance_x > detection_distance:

		idle()


	# =========================
	# CHASE
	# =========================

	elif distance_x > attack_distance:

		chase_player()


	# =========================
	# COMBAT
	# =========================

	elif distance_x <= attack_distance:

		combat()


# =========================
# FIND PLAYER
# =========================

func find_player() -> void:

	var players := get_tree().get_nodes_in_group("Player")

	if players.size() > 0:

		player = players[0]


# =========================
# IDLE
# =========================

func idle() -> void:

	state = State.IDLE

	velocity.x = 0

	sprite.play("Idle")

	move_and_slide()


# =========================
# CHASE
# =========================

func chase_player() -> void:

	state = State.CHASE


	var direction: float = sign(
		player.global_position.x - global_position.x
	)


	velocity.x = direction * move_speed

	sprite.play("Walk")

	flip_enemy(direction)

	move_and_slide()


# =========================
# COMBAT
# =========================

func combat() -> void:
	velocity.x = 0
	if can_block and randf() < block_chance:
		block()
	elif can_attack:
		attack()


# =========================
# ATTACK
# =========================

func attack() -> void:

	if is_attacking:
		return

	if not can_attack:
		return

	is_attacking = true
	can_attack = false

	state = State.ATTACK
	velocity = Vector2.ZERO

	# =========================
	# ATTACK 1
	# =========================

	sprite.play("Attack_1")

	if is_dead:
		return

	if is_hurt:
		is_attacking = false
		can_attack = true
		return

	check_attack_hit()
	await get_tree().create_timer(0.5).timeout

	# =========================
	# ATTACK 2
	# =========================

	sprite.play("Attack_2")

	if is_dead:
		return

	if is_hurt:
		is_attacking = false
		can_attack = true
		return

	check_attack_hit()
	await get_tree().create_timer(0.5).timeout
	# =========================
	# ATTACK 3
	# =========================

	sprite.play("Attack_3")

	if is_dead:
		return

	if is_hurt:
		is_attacking = false
		can_attack = true
		return

	check_attack_hit()
	await get_tree().create_timer(0.4).timeout
	# =========================
	# ATTACK 4
	# =========================

	sprite.play("Attack_4")

	if is_dead:
		return

	if is_hurt:
		is_attacking = false
		can_attack = true
		return

	check_attack_hit()
	await get_tree().create_timer(0.6).timeout
	# =========================
	# IDLE
	# =========================

	is_attacking = false
	state = State.IDLE

	sprite.play("Idle")

	await get_tree().create_timer(attack_cooldown).timeout

	if is_dead:
		return

	can_attack = true


# =========================
# ATTACK HIT
# =========================

func check_attack_hit() -> void:

	if is_dead:
		return

	var bodies := attack_area.get_overlapping_bodies()

	for body in bodies:

		if body.is_in_group("Player"):

			print("ENEMY HIT PLAYER")

			# =========================
			# PLAYER BLOCK
			# =========================

			if body.get("is_defending") == true:

				print("PLAYER BLOCKED ENEMY ATTACK")

				block_stun()

				return


			# =========================
			# NORMAL HIT
			# =========================

			if body.has_method("take_damage"):

				body.take_damage(attack_damage)

			return


# =========================
# TAKE DAMAGE
# =========================

func take_damage(damage: int) -> void:

	if is_dead:
		return

	# =========================
	# BLOCK
	# =========================

	if is_defending:

		print("Enemy Blocked!")

		return


	# =========================
	# DAMAGE
	# =========================

	hp -= damage
	hp = max(hp, 0)

	health_bar.value = hp

	print("Enemy HP: ", hp)


	# =========================
	# DEAD
	# =========================

	if hp <= 0:

		die()

		return


	# =========================
	# ATTACK PRIORITY
	# =========================

	if is_attacking:

		# Enemy กำลังโจมตีอยู่
		# ให้ Attack สำคัญกว่า Hurt

		print("Enemy Attack Priority!")

		return


	# =========================
	# HURT
	# =========================

	hurt()

# =========================
# HURT
# =========================

func hurt() -> void:

	if is_dead:
		return

	is_attacking = false
	is_defending = false

	is_hurt = true

	state = State.HURT

	velocity = Vector2.ZERO

	sprite.play("Hurt")

	# แก้บั๊กหยุดนิ่งถาวร: เดิมพึ่ง animation_finished signal เพียงอย่างเดียว
	# เพื่อเซ็ต is_hurt = false กลับคืน ถ้า signal ไม่ได้ต่อไว้ในหน้า Editor
	# หรือ animation "Hurt" ตั้ง Loop เปิดอยู่ enemy จะค้าง is_hurt = true
	# ตลอดไป (เพราะ _physics_process return ทันทีทุกเฟรมที่ is_hurt เป็น true)
	# ใช้ timer คุมเวลาแทน ไม่พึ่ง signal อย่างเดียวอีกต่อไป
	await get_tree().create_timer(hurt_stun_duration).timeout

	if is_dead:
		return

	is_hurt = false

	state = State.IDLE

	sprite.play("Idle")


# =========================
# DEFEND
# =========================

func block() -> void:

	if is_dead:
		return

	if not can_block:
		return


	is_defending = true
	can_block = false

	state = State.DEFEND

	velocity = Vector2.ZERO

	sprite.play("Defend")


	await get_tree().create_timer(
		block_duration
	).timeout


	if is_dead:
		return


	is_defending = false

	state = State.IDLE

	sprite.play("Idle")


	await get_tree().create_timer(
		block_cooldown
	).timeout


	if not is_dead:

		can_block = true

func block_stun() -> void:

	if is_dead:
		return

	if is_block_stunned:
		return

	is_block_stunned = true

	# ยกเลิก Attack
	is_attacking = false

	# ยกเลิก Defense
	is_defending = false

	state = State.IDLE

	velocity = Vector2.ZERO

	sprite.play("Idle")

	# รอ 0.5 วินาที
	await get_tree().create_timer(
		block_stun_duration
	).timeout

	if is_dead:
		return

	is_block_stunned = false

	state = State.IDLE

# =========================
# DEAD
# =========================

func die() -> void:

	if is_dead:
		return

	# =========================
	# DEAD LOCK
	# =========================

	is_dead = true
	state = State.DEAD

	# ปิดทุกสถานะการต่อสู้
	is_attacking = false
	is_defending = false
	is_hurt = false
	is_block_stunned = false

	can_attack = false
	can_block = false

	velocity = Vector2.ZERO

	# =========================
	# DISABLE COLLISION
	# =========================

	$CollisionShape2D.set_deferred(
		"disabled",
		true
	)

	attack_area.set_deferred(
		"monitoring",
		false
	)

	detection_area.set_deferred(
		"monitoring",
		false
	)

	# =========================
	# PLAY DEAD
	# =========================

	# ป้องกัน Dead เป็น Loop
	if sprite.sprite_frames.has_animation("Dead"):
		sprite.sprite_frames.set_animation_loop("Dead", false)

	sprite.stop()
	sprite.play("Dead")

	# หยุด Physics ของ Enemy
	set_physics_process(false)


# =========================
# FLIP
# =========================

func flip_enemy(direction: float) -> void:

	if direction < 0:

		body_visual.scale.x = -1

	elif direction > 0:

		body_visual.scale.x = 1


# =========================
# ANIMATION FINISHED
# =========================
#
# หมายเหตุ: ตอนนี้ทั้ง "Attack_1/Attack_2" และ "Hurt" ถูกคุมด้วย timer
# ใน attack() และ hurt() โดยตรงแล้ว (ไม่พึ่ง signal นี้อีกต่อไป) เพื่อกัน
# ปัญหา 2 ระบบแย่งกันเซ็ต is_attacking/is_hurt พร้อมกัน — เหลือแค่ Dead
# ที่ยังต้องรอ signal นี้เพื่อ queue_free() ตอน animation ตายเล่นจบจริง

func _on_animated_sprite_2d_animation_finished() -> void:

	if is_dead and sprite.animation == "Dead":

		queue_free()

		return
