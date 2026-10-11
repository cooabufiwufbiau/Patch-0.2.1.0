extends ItemData
class_name GrenadeData

@export_group("Audio")
@export var handleRelease: AudioEvent
@export var pinAttach: AudioEvent
@export var pinRemove: AudioEvent
@export var throwPrepare: AudioEvent
@export var throwHigh: AudioEvent
@export var throwLow: AudioEvent

@export_group("Handling")
@export var highPosition = Vector3.ZERO
@export var highRotation = Vector3.ZERO
@export var lowPosition = Vector3.ZERO
@export var lowRotation = Vector3.ZERO
@export var inspectPosition = Vector3.ZERO
@export var inspectRotation = Vector3.ZERO
@export var collisionPosition = Vector3.ZERO
@export var collisionRotation = Vector3.ZERO
