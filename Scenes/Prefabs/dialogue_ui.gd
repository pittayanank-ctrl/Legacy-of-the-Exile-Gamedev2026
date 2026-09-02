extends CanvasLayer


@onready var panel: Panel = $Panel
@onready var name_label: Label = $Panel/VBoxContainer/NameLabel
@onready var dialogue_label: Label = $Panel/VBoxContainer/DialogueLabel
@onready var continue_label: Label = $Panel/VBoxContainer/ContinueLabel
@onready var sprite: AnimatedSprite2D = $Panel/VBoxContainer/AnimatedSprite2D
@onready var left_portrait: TextureRect = $Panel/LeftPortrait
@onready var right_portrait: TextureRect = $Panel/RightPortrait

var dialogues: Array[DialogueLine] = []

var current_index: int = 0

var is_open: bool = false

# =========================================================
# READY
# =========================================================

func _ready() -> void:

	panel.hide()

	DialogueManager.register_ui(self)


# =========================================================
# START DIALOGUE
# =========================================================

func start_dialogue(
	lines: Array[DialogueLine],
	left_texture: Texture2D,
	right_texture: Texture2D
) -> void:

	if lines.is_empty():
		return

	dialogues = lines.duplicate()

	current_index = 0

	is_open = true

	panel.show()

	# ใส่รูปทั้งสองฝั่ง
	left_portrait.texture = left_texture
	right_portrait.texture = right_texture

	left_portrait.show()
	right_portrait.show()

	show_current_dialogue()

# =========================================================
# SHOW CURRENT
# =========================================================

func show_current_dialogue() -> void:

	if current_index >= dialogues.size():

		close_dialogue()

		return


	var line: DialogueLine = dialogues[current_index]

	name_label.text = line.speaker_name

	dialogue_label.text = line.dialogue_text


	# =========================================
	# คนพูดอยู่ฝั่งซ้าย
	# =========================================

	if line.speaker_side == DialogueLine.SpeakerSide.LEFT:

		left_portrait.modulate = Color.WHITE

		right_portrait.modulate = Color(
			0.35,
			0.35,
			0.35
		)


	# =========================================
	# คนพูดอยู่ฝั่งขวา
	# =========================================

	else:

		left_portrait.modulate = Color(
			0.35,
			0.35,
			0.35
		)

		right_portrait.modulate = Color.WHITE


	continue_label.text = "[E] พูดต่อ"


# =========================================================
# INPUT
# =========================================================

func _unhandled_input(event: InputEvent) -> void:

	if not is_open:
		return

	if not event.is_action_pressed("Interact"):
		return
	sprite.play("default")
	# ไปประโยคถัดไป
	current_index += 1

	show_current_dialogue()


	# สำคัญ
	get_viewport().set_input_as_handled()


# =========================================================
# CLOSE
# =========================================================

func close_dialogue() -> void:

	print("DIALOGUE CLOSED")

	is_open = false

	panel.hide()

	dialogues.clear()

	current_index = 0
