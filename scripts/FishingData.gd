extends ItemData
class_name FishingData

@export_group("Audio")
@export var catch: AudioEvent
@export var hooked: AudioEvent
@export var reelEnd: AudioEvent
@export var throwStart: AudioEvent
@export var throwReset: AudioEvent
@export var throwEnd: AudioEvent

@export_group("Handling")
@export var highPosition = Vector3.ZERO
@export var highRotation = Vector3.ZERO
@export var lowPosition = Vector3.ZERO
@export var lowRotation = Vector3.ZERO
@export var inspectPosition = Vector3.ZERO
@export var inspectRotation = Vector3.ZERO
@export var collisionPosition = Vector3.ZERO
@export var collisionRotation = Vector3.ZERO
