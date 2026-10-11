extends RigidBody3D


var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")
var audioInstance3D = preload("res://Resources/AudioInstance3D.tscn")
var gameData = preload("res://Resources/GameData.tres")

@export_group("Main")
@export var speed = 15.0
@export var turnSpeed = 2.5
var maxSteerAngle = 60.0
var steerSmoothness = 2.0

@export_group("Door")
@export var doorCollider: CollisionShape3D

@export_group("Tires")
@export var Tire_FL: MeshInstance3D
@export var Tire_FR: MeshInstance3D
@export var Tire_RL: MeshInstance3D
@export var Tire_RR: MeshInstance3D

@export_group("Suspension")
@export var chassis: MeshInstance3D
@export var suspensionRay = 0.65
@export var suspensionMovement = 0.3
@export var suspensionSpeed = 5.0
@export var tiltMaxAngle = 10.0
@export var tiltSpeed = 2.0

@onready var idleAudio: AudioStreamPlayer3D = $Audio / Idle
@onready var driveAudio: AudioStreamPlayer3D = $Audio / Drive
@onready var roadAudio: AudioStreamPlayer3D = $Audio / Road
@onready var startAudio: AudioStreamPlayer3D = $Audio / Start
@onready var endAudio: AudioStreamPlayer3D = $Audio / End
@onready var hornAudio: AudioStreamPlayer3D = $Audio / Horn


enum State{Idle, Drive, Stop}
var currentState = State.Idle


var originalChassisHeight = 0.0
var originalTireHeight = 0.0
var wobbleAmplitude = 0.005
var wobbleFrequency1 = 2.0
var wobbleFrequency2 = 2.5
var steeringAngle = 0.0
var wobbleTime = 0.0
var wobbleOffset = 0.0


var selectedPath: Node3D
var inversePath = false
var waypoints: Array[Node3D] = []
var waypointThreshold = 2.5
var waypointIndex = 0
var pathEnding = false


var stops: Array[Node] = []


var driveStart = true
var driveEnd = true
var stopped = false
var stopTime = 120.0
var stopTimer = 0.0


var masterVolume = 0.0
var idleVolume = 0.0
var driveVolume = 0.0
var roadVolume = 0.0

func _ready():

	originalTireHeight = Tire_FL.position.y
	originalChassisHeight = chassis.position.y


	await get_tree().create_timer(0.1, false).timeout;


	for waypoint in selectedPath.get_children():
		waypoints.append(waypoint)


	stops = get_tree().get_nodes_in_group("Stop")
	if stops.size() == 0: print("Bus: No stops available!")


	if inversePath:
		waypoints.reverse()


	idleAudio.play()
	driveAudio.play()
	roadAudio.play()


	currentState = State.Drive


	doorCollider.disabled = false


	await get_tree().create_timer(randi_range(30, 60), false).timeout;
	hornAudio.play()



func _physics_process(delta):
	States(delta)
	Tires(delta)
	Suspension(delta)
	Audio(delta)


	if !stopped: Detection()

func States(delta):
	if currentState == State.Drive:
		speed = lerp(speed, 15.0, delta)
		physics_material_override.friction = move_toward(physics_material_override.friction, 0.0, delta * 2.0)
		Drive(delta)
		Wobble(delta)

	elif currentState == State.Stop:
		speed = lerp(speed, 0.0, delta)
		physics_material_override.friction = move_toward(physics_material_override.friction, 1.0, delta / 2.0)


		var playerDistance = global_position.distance_to(gameData.playerPosition)


		stopTimer += delta


		if stopTimer > stopTime && playerDistance > 25.0:

			doorCollider.disabled = false

			hornAudio.play()
			currentState = State.Drive

func Drive(delta):

	var waypoint = waypoints[waypointIndex]
	var direction = (waypoint.global_position - global_position).normalized()


	var distance = global_position.distance_to(waypoint.global_position)


	pathEnding = (waypointIndex == waypoints.size() - 1)


	if distance < waypointThreshold:

		waypointIndex += 1

		if waypointIndex >= waypoints.size():
			currentState = State.Stop
			stopped = true
			print("Bus: Path ended")
			queue_free()


	var currentForward = global_transform.basis.z
	var newRotation = currentForward.slerp(direction, delta * turnSpeed)
	var torque = currentForward.cross(newRotation).y * turnSpeed
	apply_torque_impulse(Vector3(0, torque, 0))


	var targetSteer = atan2(direction.x, direction.z) - atan2(currentForward.x, currentForward.z)
	steeringAngle = lerp_angle(steeringAngle, targetSteer, delta * steerSmoothness)
	steeringAngle = clamp(steeringAngle, - deg_to_rad(maxSteerAngle), deg_to_rad(maxSteerAngle))


	var force = global_transform.basis.z * speed
	apply_central_force(force)


	var lateralVelocity = Vector3(linear_velocity.x, 0, linear_velocity.z).dot(global_transform.basis.x)
	apply_central_force( - global_transform.basis.x * lateralVelocity * 50.0)

func Detection():
	if Engine.get_physics_frames() % 10 == 0:
		if currentState == State.Drive:

			if stops.size() == 0: return


			for stop in stops:

				var distanceToStop = global_position.distance_to(stop.global_position)


				if distanceToStop < 10.0:

					doorCollider.disabled = true

					hornAudio.play()
					currentState = State.Stop
					stopped = true

func Audio(delta):

	if currentState == State.Drive:
		idleVolume = move_toward(idleVolume, 0.01, delta)
		driveVolume = move_toward(driveVolume, 1.0, delta)
		roadVolume = move_toward(roadVolume, 1.0, delta)

		if driveStart:
			startAudio.play()
			driveStart = false
			driveEnd = true


	elif currentState == State.Stop:
		idleVolume = move_toward(idleVolume, 1.0, delta)
		driveVolume = move_toward(driveVolume, 0.01, delta)
		roadVolume = move_toward(roadVolume, 0.01, delta)

		if driveEnd:
			endAudio.play()
			driveStart = true
			driveEnd = false


	if pathEnding: masterVolume = move_toward(masterVolume, 0.0, delta * 2.0)
	else: masterVolume = move_toward(masterVolume, 1.0, delta / 2.0)


	idleAudio.volume_db = linear_to_db(idleVolume * masterVolume)
	driveAudio.volume_db = linear_to_db(driveVolume * masterVolume)
	roadAudio.volume_db = linear_to_db(roadVolume * masterVolume)

func Tires(delta):

	var forwardVelocity = linear_velocity.dot(global_transform.basis.z)
	var wheelSpeed = forwardVelocity


	Tire_FL.rotation.y = steeringAngle
	Tire_FR.rotation.y = steeringAngle


	Tire_FL.rotation.x += wheelSpeed * delta
	Tire_FR.rotation.x += wheelSpeed * delta
	Tire_RL.rotation.x += wheelSpeed * delta
	Tire_RR.rotation.x += wheelSpeed * delta

func Suspension(delta):

	var tires = [Tire_FL, Tire_FR, Tire_RL, Tire_RR]
	var space_state = get_world_3d().direct_space_state

	for tire in tires:
		var ray_origin = tire.global_position
		var ray_direction = - global_transform.basis.y.normalized()
		var ray_end = ray_origin + ray_direction * suspensionRay

		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.exclude = [self]
		var result = space_state.intersect_ray(query)

		var targetHeight = originalTireHeight

		if !result:
			targetHeight = originalTireHeight - suspensionMovement


		tire.position.y = lerp(tire.position.y, targetHeight, delta * suspensionSpeed)

func Wobble(delta):

	wobbleTime += delta


	var wobble1 = sin(wobbleTime * wobbleFrequency1 * TAU)
	var wobble2 = sin(wobbleTime * wobbleFrequency2 * TAU)
	var wobble = (wobble1 + wobble2) * 0.5 * wobbleAmplitude


	chassis.position.y = originalChassisHeight + wobble


	var targetTilt = steeringAngle * tiltMaxAngle
	chassis.rotation.z = lerp(chassis.rotation.z, deg_to_rad(targetTilt), delta * tiltSpeed)
