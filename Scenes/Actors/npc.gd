extends CharacterBody2D


@export_category("NPC")
@export var npc_name: String = "ชาวบ้าน"


@export_category("Appearance")
@export var npc_sprite_frames: SpriteFrames
@export var npc_scale: float = 1.0

@export_category("Dialogue")

# บทสนทนาที่จะใช้เรียงตามลำดับ
@export var dialogue_groups: Array[DialogueGroup] = []

# บทพูดที่จะใช้ซ้ำหลังจากคุยครบทุกชุด
@export var final_dialogue: DialogueGroup

@export_category("After Dialogue")

@export var change_scene_after_dialogue: bool = false
@export_file("*.tscn") var next_scene: String

var player_in_range: bool = false
var final_dialogue_check: bool = false
var dialogue_progress: int = 0

@onready var npc_sprite: AnimatedSprite2D = $NPCVisual/AnimatedSprite2D
@onready var talk_button: AnimatedSprite2D = $talk_button
@onready var interaction_area: Area2D = $InteractionArea

var player: Node2D = null

func _ready() -> void:
	talk_button.visible = false
	npc_sprite.flip_h = true
	if npc_sprite_frames != null:
		npc_sprite.sprite_frames = npc_sprite_frames
	npc_sprite.play("default")
	npc_sprite.scale = Vector2(npc_scale, npc_scale)

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

# =========================================================
# INPUT
# =========================================================

func _unhandled_input(event: InputEvent) -> void:

	if not player_in_range:
		return

	if not event.is_action_pressed("Interact"):
		return

	if DialogueManager.is_dialogue_open():
		return

	talk()

	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:

	if not change_scene_after_dialogue:
		return

	if not final_dialogue_check:
		return

	if DialogueManager.is_dialogue_open():
		return

	if next_scene.is_empty():
		return

	change_scene_after_dialogue = false

	var target_scene: PackedScene = load(next_scene) as PackedScene

	if target_scene == null:
		push_error("ไม่สามารถโหลด Scene: " + next_scene)
		return

	SceneTransition.load_scene(target_scene)
# =========================================================
# TALK
# =========================================================

func talk() -> void:

	# หันหน้าเข้าหา Player
	face_player()

	if dialogue_groups.is_empty():
		print("ERROR: ไม่มี Dialogue Groups")
		return

	if dialogue_progress < dialogue_groups.size():

		var group: DialogueGroup = dialogue_groups[dialogue_progress]

		if group == null:
			return

		if group.dialogue_lines.is_empty():
			print("ERROR: Dialogue Group ไม่มีข้อความ")
			return

		dialogue_progress += 1

		DialogueManager.start_dialogue(
			group.dialogue_lines,
			group.left_portrait,
			group.right_portrait
		)

		return

	# Final Dialogue
	if final_dialogue == null:
		print("ERROR: ยังไม่ได้ใส่ Final Dialogue")
		return

	if final_dialogue.dialogue_lines.is_empty():
		print("ERROR: Final Dialogue ไม่มีข้อความ")
		return

	final_dialogue_check = true

	DialogueManager.start_dialogue(
		final_dialogue.dialogue_lines,
		final_dialogue.left_portrait,
		final_dialogue.right_portrait
	)

func face_player() -> void:

	if not player_in_range:
		return

	if player == null:
		return

	var direction: float = sign(
		player.global_position.x - global_position.x
	)

	if direction < 0:
		npc_sprite.flip_h = true
	elif direction > 0:
		npc_sprite.flip_h = false
# =========================================================
# PLAYER ENTER
# =========================================================

func _on_body_entered(body: Node) -> void:

	if body.is_in_group("Player"):

		player = body
		player_in_range = true
		talk_button.visible = true


# =========================================================
# PLAYER EXIT
# =========================================================

func _on_body_exited(body: Node) -> void:

	if body.is_in_group("Player"):
		player = null
		player_in_range = false
		talk_button.visible = false

		# ปิด Dialogue
		if DialogueManager.is_dialogue_open():
			DialogueManager.close_dialogue()

		# รีเซ็ตบทสนทนา
		if final_dialogue_check == true:
			return
		else:
			dialogue_progress = 0
