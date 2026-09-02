extends Node


var dialogue_ui: CanvasLayer = null


func register_ui(ui: CanvasLayer) -> void:

	dialogue_ui = ui

	print("Dialogue UI Registered")


func start_dialogue(
	lines: Array[DialogueLine],
	left_texture: Texture2D,
	right_texture: Texture2D
) -> void:

	if dialogue_ui == null:

		print("ERROR: Dialogue UI is NULL")

		return


	if lines.is_empty():

		print("ERROR: Dialogue ไม่มีข้อความ")

		return


	dialogue_ui.start_dialogue(
		lines,
		left_texture,
		right_texture
	)


func is_dialogue_open() -> bool:

	if dialogue_ui == null:

		return false

	return dialogue_ui.is_open
	
func close_dialogue() -> void:

	if dialogue_ui == null:
		return

	dialogue_ui.close_dialogue()
