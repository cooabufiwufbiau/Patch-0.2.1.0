extends Node3D


var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")
var audioInstance3D = preload("res://Resources/AudioInstance3D.tscn")
var gameData = preload("res://Resources/GameData.tres")

@export var variant: AIData
@export var animations: AnimationPlayer
@export var animation: String
@export var equipment: Array[Node3D]
@export var collision: StaticBody3D
@export var head: BoneAttachment3D
var nickname: String


var voiceTimer = 0.0
var voiceCycle = 30.0
var activeVoice = null

func _ready() -> void :

	await get_tree().create_timer(randi_range(0, 4), false).timeout;
	animations.play(animation)

	DeactivateEquipment()

	voiceCycle = randf_range(10.0, 60.0)

	if variant.faction == variant.Faction.Nomad:

		collision.add_to_group("Interactable", false)
		collision.set_collision_layer_value(8, true)

		if variant.nicknames.size() != 0:
			nickname = variant.nicknames.pick_random()

func DeactivateEquipment():

	if equipment.size() == 0: return


	for child in equipment:
		child.process_mode = Node.PROCESS_MODE_DISABLED
		child.collision.disabled = true

func _physics_process(delta: float) -> void :
	Voices(delta)

func Interact():
	pass

func UpdateTooltip():
	gameData.tooltip = nickname

func Voices(delta):

	if animation == "Sleep": return


	if !is_instance_valid(activeVoice) && !variant.silent:
		voiceTimer += delta


		if voiceTimer > voiceCycle:

			PlayIdle()

			voiceCycle = randf_range(10.0, 60.0)
			voiceTimer = 0.0

func PlayIdle():

	if !head: return

	if randi_range(0, 1) == 0: return


	if variant.idleVoices && !variant.silent:
		var voice = audioInstance3D.instantiate()
		head.add_child(voice)
		voice.PlayInstance(variant.idleVoices, 10, 100)
		activeVoice = voice
