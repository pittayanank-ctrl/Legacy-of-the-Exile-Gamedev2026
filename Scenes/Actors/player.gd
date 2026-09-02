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

var footstep_timer: float = 0.0
# =========================================================
# STAMINA
# =========================================================

@export_category("Stamina")

@export var max_stamina: float = 100.0
@export var stamina_drain: float = 25.0
@export var stamina_recovery: float = 20.0
@export var stamina_min_to_defend: float = 5.0


# =========================================================
# COMBAT
# =========================================================

@export_category("Combat")

@export var max_hp: int = 100
@export var attack_damage: int = 20

@export var attack1_time: float = 0.15
@export var attack2_time: float = 0.15
@export var attack3_time: float = 0.20

@export var attack_cooldown: float = 0.5


# =========================================================
# DEFEND
# =========================================================

@export_category("Defense")

@export var defend_stamina_drain: float = 10.0
@export var run_attack_time: float = 0.15


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
var can_attack: bool = true

var combo_step: int = 0
var attack_token: int = 0
var cooldown_token: int = 0

var is_running: bool = false
var defend_locked_out: bool = false
var is_run_attacking: bool = false

var stamina_exhausted: bool = false
# =========================================================
# NODES
# =========================================================

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

@onready var walk_sfx: AudioStreamPlayer2D = $WalkSfx
@onready var run_sfx: AudioStreamPlayer2D = $RunSfx
@onready var attack_sfx: AudioStreamPlayer2D = $AttackSfx
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSfx
@onready var block_sfx: AudioStreamPlayer2D = $BlockSfx

# =========================================================
# READY
# =========================================================

func _ready() -> void:

	hp = max_hp
	stamina = max_stamina

	walk_sfx.pitch_scale = 0.5
	run_sfx.pitch_scale = 0.7
	
	can_take_damage = true
	can_attack = true
	is_dead = false

	sprite.play("Idle")


# =========================================================
# PHYSICS
# =========================================================

func _physics_process(delta: float) -> void:

	if is_dead:
		return

	handle_defend()
	handle_attack_input()

	if not is_defending and not is_hurt:
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

		if not stamina_exhausted and stamina > 0:

			is_running = true

			stamina -= stamina_drain * delta
			stamina = max(stamina, 0.0)

			velocity.x = move_toward(
				velocity.x,
				direction * run_speed,
				acceleration * delta
			)

			if stamina <= 0:

				stamina = 0
				stamina_exhausted = true
				is_running = false

		else:

			is_running = false

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
	# Animation + Sound
	# -----------------------------------------

	if is_attacking:
		return


	if direction == 0:

		sprite.play("Idle")

		# หยุดเสียงเดิน/วิ่ง
		walk_sfx.stop()
		run_sfx.stop()


	elif is_running:

		sprite.play("Run")

		# หยุดเสียงเดิน
		walk_sfx.stop()

		# เล่นเสียงวิ่งครั้งเดียว
		if not run_sfx.playing:
			run_sfx.play()


	else:

		sprite.play("Walk")

		# หยุดเสียงวิ่ง
		run_sfx.stop()

		# เล่นเสียงเดินครั้งเดียว
		if not walk_sfx.playing:
			walk_sfx.play()


# =========================================================
# STAMINA
# =========================================================

func update_stamina(delta: float) -> void:

	if not is_running and not is_defending:

		stamina += stamina_recovery * delta
		stamina = min(stamina, max_stamina)

		# หมด stamina แล้ว ต้องรอ > 10
		if stamina_exhausted and stamina > 10.0:
			stamina_exhausted = false


# =========================================================
# ATTACK INPUT
# =========================================================

func handle_attack_input() -> void:

	if is_dead:
		return

	if is_hurt:
		return

	if is_defending:
		return

	if not can_attack:
		return

	if not is_attacking and Input.is_action_pressed("Attack"):

		if is_running:
			start_run_attack()
		else:
			start_attack(1)

func start_run_attack() -> void:
	if is_dead:
		return

	if is_hurt:
		return

	is_attacking = true
	is_run_attacking = true
	can_attack = false
	combo_step = 0

	velocity.x = 0

	sprite.play("Run_Attack")

	# เสียงฟันตอน Run Attack
	attack_sfx.play()

	attack_token += 1
	cooldown_token += 1

	run_attack_hit_delay(attack_token)
	
func run_attack_hit_delay(token: int) -> void:

	await get_tree().create_timer(run_attack_time).timeout

	if is_dead:
		return

	if token != attack_token:
		return

	check_attack_hit()
	
# =========================================================
# START ATTACK
# =========================================================

func start_attack(number: int) -> void:
	if is_dead:
		return

	if is_hurt:
		return

	is_attacking = true
	can_attack = false
	combo_step = number

	match number:

		1:
			sprite.play("Attack1")

		2:
			sprite.play("Attack2")

		3:
			sprite.play("Attack3")


	# เล่นเสียงฟัน
	if not attack_sfx.playing:
		attack_sfx.play()


	attack_token += 1
	cooldown_token += 1

	attack_hit_delay(number, attack_token)


# =========================================================
# ATTACK HIT
# =========================================================

func attack_hit_delay(number: int, token: int) -> void:

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

	# ถ้ามีการเริ่มท่าใหม่ (คอมโบถัดไป) ไปแล้วก่อนที่ delay นี้จะครบ
	# token จะไม่ตรงกันอีกต่อไป -> ไม่ตรวจโดนตีซ้ำ/เพี้ยนจังหวะ
	if token != attack_token:
		return

	# หมายเหตุ: ไม่เช็ค is_hurt / is_attacking ตรงนี้โดยตั้งใจ
	# ถ้าเราโดนตีสวน "พอดี" จังหวะเดียวกับที่ swing ของเราลงดาเมจ
	# ก็ยังให้ดาเมจของเราลงด้วย (fair trade / clash) แทนที่จะให้การโดนตี
	# ของเรายกเลิกดาเมจที่ swing สร้างไปแล้วอย่างเงียบๆ
	check_attack_hit()


# =========================================================
# CHECK ATTACK HIT
# =========================================================

func check_attack_hit() -> void:

	var bodies := attack_area.get_overlapping_bodies()

	for body in bodies:

		if body.has_method("take_damage"):

			print("PLAYER HIT ENEMY")

			body.take_damage(attack_damage)

			break

# =========================================================
# DEFEND
# =========================================================

func handle_defend() -> void:

	if is_dead:
		return

	if is_attacking:
		return

	if is_hurt:
		return

	# ถ้า stamina ยังไม่ถึง 10 หลังจากหมด stamina
	if stamina_exhausted:
		is_defending = false

		# รอให้ stamina มากกว่า 10
		if stamina > 10.0:
			stamina_exhausted = false
		else:
			return

	# กด Defend
	if Input.is_action_pressed("Defend"):

		if stamina <= 0:

			stamina = 0
			is_defending = false
			stamina_exhausted = true

			sprite.play("Idle")

			return

		is_defending = true

		velocity.x = 0

		stamina -= defend_stamina_drain * get_physics_process_delta_time()

		stamina = max(stamina, 0.0)

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

	if is_defending:

		print("Enemy Blocked!")

		return


	# ล็อกทันที ป้องกันโดนซ้ำ
	can_take_damage = false

	hp -= damage
	hurt_sfx.play()
	if hp <= 0:

		hp = 0

		print("Player HP: 0")

		die()

		return


	print("Player HP: ", hp)


	# ยกเลิกการกระทำทั้งหมด
	is_attacking = false
	is_defending = false
	can_attack = true
	is_run_attacking = false

	combo_step = 0
	# หมายเหตุ: ไม่เพิ่ม attack_token ตรงนี้แล้วโดยตั้งใจ — เดิมเพิ่มเพื่อยกเลิก
	# attack_hit_delay() ของ swing ที่ค้างอยู่เมื่อโดนตี แต่ทำให้ดาเมจของเรา
	# หายไปเงียบๆ แม้ swing จะลงถึงจังหวะฟันไปแล้ว ตอนนี้ปล่อยให้ swing
	# ที่กำลังจะ resolve พอดีจังหวะเดียวกัน ยังคงลงดาเมจได้ตามปกติ

	is_hurt = true

	velocity = Vector2.ZERO

	sprite.play("Hurt")

	# Invincibility
	await get_tree().create_timer(0.4).timeout

	if not is_dead:
		can_take_damage = true


# =========================================================
# ANIMATION FINISHED
# =========================================================

func _on_animated_sprite_2d_animation_finished() -> void:

	if is_dead:
		return

	match sprite.animation:

		"Attack1":
			if Input.is_action_pressed("Attack") and can_take_this_combo_step():
				start_attack(2)
			else:
				end_attack()

		"Attack2":
			if Input.is_action_pressed("Attack") and can_take_this_combo_step():
				start_attack(3)
			else:
				end_attack()

		"Attack3":
			finish_combo_cycle()

		"Hurt":
			is_hurt = false
			sprite.play("Idle")

		"Dead":
			queue_free()
			
		"Run_Attack":
			is_run_attacking = false
			is_attacking = false
			sprite.play("Idle")

			var my_token := cooldown_token

			await get_tree().create_timer(attack_cooldown).timeout

			if is_dead or is_hurt:
				return

			if my_token != cooldown_token:
				return

	can_attack = true

# =========================================================
# COMBO CONTINUE CHECK
# =========================================================

func can_take_this_combo_step() -> bool:
	# กันไม่ให้คอมโบต่อเนื่องทันทีถ้าเพิ่งโดนตี/ตายไประหว่าง animation กำลังจบ
	return not is_dead and not is_hurt


# =========================================================
# END ATTACK
# =========================================================

func end_attack() -> void:

	is_attacking = false

	combo_step = 0

	sprite.play("Idle")

	var my_token := cooldown_token

	# attack_cooldown เริ่มนับหลังคอมโบจบ ก่อนหน้านี้ผู้เล่นโจมตีต่อได้ทันที
	# โดยไม่มีดีเลย์ ทั้งที่ export ตัวแปรนี้ไว้แต่ไม่เคยถูกใช้
	await get_tree().create_timer(attack_cooldown).timeout

	if is_dead or is_hurt:
		return

	# ถ้ามีท่าโจมตีใหม่เริ่มไปแล้วระหว่างที่รอ cooldown นี้อยู่
	# (เช่นโดนตีขัดจังหวะแล้วผู้เล่นกดโจมตีใหม่ทัน) ให้ยกเลิกตัวเอง
	# ไม่ไปยุ่งกับ can_attack ที่ท่าใหม่ควบคุมอยู่แล้ว
	if my_token != cooldown_token:
		return

	can_attack = true


# =========================================================
# FINISH COMBO CYCLE (จบครบ Attack3)
# =========================================================

func finish_combo_cycle() -> void:

	# จบคอมโบ 3 ท่าเสมอ ไม่ว่าผู้เล่นจะยังกดปุ่มค้างอยู่หรือไม่ก็ตาม
	# เพื่อให้ attack_cooldown มีผลจริงทุกครั้งที่คอมโบครบรอบ
	# (เดิมถ้ากดค้าง จะวน Attack3 -> Attack1 ตรงๆ ข้าม cooldown ไปเลย)
	is_attacking = false

	combo_step = 0

	sprite.play("Idle")

	var my_token := cooldown_token

	await get_tree().create_timer(attack_cooldown).timeout

	if is_dead or is_hurt:
		return

	# ถ้ามีท่าโจมตีใหม่เริ่มไปแล้วระหว่างที่รอ cooldown นี้อยู่ ให้ยกเลิกตัวเอง
	# กัน start_attack(1) ยิงซ้อนทับคอมโบใหม่ที่กำลังเล่นอยู่แล้ว
	if my_token != cooldown_token:
		return

	can_attack = true

	# ถ้ายังกดปุ่มค้างอยู่หลัง cooldown จบ ให้เริ่มคอมโบใหม่ต่ออัตโนมัติ
	if Input.is_action_pressed("Attack"):
		start_attack(1)


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

	can_take_damage = false

	velocity = Vector2.ZERO

	sprite.play("Dead")
	
	await get_tree().create_timer(1.0).timeout

	var ui = get_tree().get_first_node_in_group("UserInterface")

	if ui:
		ui.show_game_over()

# =========================================================
# RESET ANIMATION STATE (เรียกจากภายนอก เช่นตอน enemy ตาย)
# =========================================================
#
# ล้าง state ที่อาจค้างอยู่ (เช่นกำลังอยู่กลางคอมโบ/ท่าโจมตีพอดีจังหวะ
# ที่ enemy ตายไปพร้อมกัน) แล้วบังคับกลับ Idle กันปัญหา animation ค้าง
# ไม่แตะ is_dead เพราะถ้า Player ตายไปแล้วไม่ควรถูกดึงกลับมา Idle

func reset_animation_state() -> void:

	if is_dead:
		return

	is_attacking = false
	is_defending = false
	is_hurt = false

	can_attack = true

	combo_step = 0

	# เพิ่ม token ทั้งคู่ เพื่อยกเลิก coroutine เก่าที่อาจค้างรออยู่
	# (attack_hit_delay / end_attack / finish_combo_cycle) ไม่ให้มา
	# ยุ่งกับ state ที่เพิ่ง reset ไปทีหลัง
	attack_token += 1
	cooldown_token += 1

	velocity = Vector2.ZERO

	sprite.play("Idle")

# =========================================================
# FOOTSTEP SOUND
# =========================================================
