extends Node3D


var gameData = preload("res://Resources/GameData.tres")
var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")

@export var audioClips: Array[AudioStreamOggVorbis]
@export var gatheringClips: Array[AudioStreamOggVorbis]
@export var tuningClips: Array[AudioStreamWAV]
@export var transmissionClips: Array[AudioStreamWAV]
@export var audio: AudioStreamPlayer3D
@export var tuning: AudioStreamPlayer3D
@export var random = false
@export var gathering = false
var active = false
var isTuning = false
var transmission = false

func _ready():

	if random && randi_range(0, 100) <= 5 || gathering:
		active = true
	else:
		active = false


	if Simulation.day >= 50:
		transmission = true

func _physics_process(_delta):
	if active && !audio.is_playing() && !tuning.is_playing():
		if isTuning:

			if transmission: audio.stream = GetRandomTransmissionClip()
			elif gathering: audio.stream = GetRandomGatheringClip()
			else: audio.stream = GetRandomClip()
			audio.play()
			isTuning = false
		else:

			tuning.stream = GetRandomTuningClip()
			tuning.play()
			isTuning = true

func Interact():
	active = !active

	if active:

		tuning.stream = GetRandomTuningClip()
		tuning.play()
		isTuning = true
	else:
		InteractAudio()
		audio.stop()
		tuning.stop()
		isTuning = false

func Transmission():
	transmission = true

func GetRandomClip():
	var randomIndex: int = randi_range(0, audioClips.size() - 1)
	return audioClips[randomIndex]

func GetRandomGatheringClip():
	var randomIndex: int = randi_range(0, gatheringClips.size() - 1)
	return gatheringClips[randomIndex]

func GetRandomTransmissionClip():
	var randomIndex: int = randi_range(0, transmissionClips.size() - 1)
	return transmissionClips[randomIndex]

func GetRandomTuningClip():
	var randomIndex: int = randi_range(0, tuningClips.size() - 1)
	return tuningClips[randomIndex]

func UpdateTooltip():
	if active:
		gameData.tooltip = "Radio [Turn Off]"
	else:
		gameData.tooltip = "Radio [Turn On]"



func InteractAudio():
	var interactAudio = audioInstance2D.instantiate()
	add_child(interactAudio)
	interactAudio.PlayInstance(audioLibrary.radio)
