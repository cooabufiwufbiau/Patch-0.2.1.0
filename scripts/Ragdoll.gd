extends Skeleton3D


var gameData = preload("res://Resources/GameData.tres")
var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance3D = preload("res://Resources/AudioInstance3D.tscn")

@export var hitBone: PhysicalBone3D

var simulationTime = 10.0
var simulationTimer = 0.0
var active = false

func _ready():
	DeactivateBones()

func DeactivateBones():
	physical_bones_stop_simulation()

	for child in get_children():
		if child is PhysicalBone3D:
			child.axis_lock_linear_x = true
			child.axis_lock_linear_y = true
			child.axis_lock_linear_z = true
			child.axis_lock_angular_x = true
			child.axis_lock_angular_y = true
			child.axis_lock_angular_z = true
			child.get_child(0).disabled = true

func ActivateBones():
	physical_bones_start_simulation()

	for child in get_children():
		if child is PhysicalBone3D:
			child.axis_lock_linear_x = false
			child.axis_lock_linear_y = false
			child.axis_lock_linear_z = false
			child.axis_lock_angular_x = false
			child.axis_lock_angular_y = false
			child.axis_lock_angular_z = false
			child.get_child(0).disabled = false


	await get_tree().create_timer(0.5, false).timeout;
	PlayRagdoll()

func _physics_process(delta):
	if active:
		simulationTimer += delta
		if simulationTimer > simulationTime:
			DeactivateBones()
			owner.Freeze()
			print("AI: Process ended")
			active = false

func Activate(direction, force):
	active = true
	hitBone.linear_velocity = direction.normalized() * force
	hitBone.angular_velocity = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * force
	ActivateBones()

func PlayRagdoll():
	var ragdoll = audioInstance3D.instantiate()
	hitBone.add_child(ragdoll)
	ragdoll.PlayInstance(audioLibrary.ragdoll, 5, 100)
