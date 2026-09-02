class_name DialogueLine
extends Resource


enum SpeakerSide {
	LEFT,
	RIGHT
}


@export var speaker_name: String = ""

@export_multiline var dialogue_text: String = ""

@export var speaker_side: SpeakerSide = SpeakerSide.LEFT
