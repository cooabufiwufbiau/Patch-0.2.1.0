@tool
extends MeshInstance3D


var gameData = preload("res://Resources/GameData.tres")


enum Type{Enemy, Nomad}
@export var type = Type.Enemy
@export var head: PhysicalBone3D


@export var active: bool = false
@export var debug: bool = false
@export var force: bool = false
@export_flags_3d_physics var obstruction
@export_range(10.0, 200.0) var hearDistance = 20.0
@export_range(10.0, 200.0) var viewDistance = 150.0
@export_range(10.0, 200.0) var viewAngle = 150.0
@export_range(0.1, 10.0) var targetCycle = 5.0
@export_range(0.1, 10.0) var priorityCycle = 1.0
@export_range(0.1, 10.0) var raycastCycle = 1.0
@export_range(0.1, 10.0) var forceCycle = 0.1
@export var targets: Array[Node3D] = []
@export var priority: Node3D


var PLocation: Vector3
var PVector: Vector3
var PDistance: float
var PVisible = false


var hot = false
var hotDuration: float = 60.0
var hotTimer: float = 0.0


var threatPriority: Node3D
var threatDuration: float = 5.0
var threatTimer: float = 0.0


var targetTimer: float = 0.0
var priorityTimer: float = 0.0
var raycastTimer: float = 0.0
var boostTimer: float = 0.0
var forceTimer: float = 0.0

func _ready() -> void :

	mesh = ImmediateMesh.new()


	if active:
		Targets()
		Priority()
		PriorityLOS()



func _process(delta: float) -> void :

	if !active: return
	if gameData.isCaching: return


	global_position.y = head.global_position.y
	global_rotation.y = head.global_rotation.y


	visible = debug
	if debug: Debug()


	Visibility(delta)


	if force:
		forceTimer += delta
		if forceTimer >= forceCycle:
			Forced()
			forceTimer = 0.0
		return


	Cooldown(delta)


	PlayerFireDetection()
	PlayerHearDetection()


	if threatTimer > 0.0:
		threatTimer -= delta
		if threatTimer <= 0.0:
			threatPriority = null


	targetTimer += delta
	if targetTimer >= targetCycle:
		Targets()
		targetTimer = 0.0


	priorityTimer += delta
	if priorityTimer >= priorityCycle:
		Priority()
		priorityTimer = 0.0


	raycastTimer += delta
	if raycastTimer >= raycastCycle:
		PriorityLOS()
		raycastTimer = 0.0


	PriorityStats()

func Forced():

	priority = get_tree().get_first_node_in_group("Player")
	PLocation = gameData.cameraPosition
	PDistance = global_position.distance_to(gameData.cameraPosition)
	PVector = (gameData.cameraPosition - global_position).normalized()


	if PDistance > viewDistance:
		PVisible = false
		return


	var rayStart = global_position
	var rayEnd = gameData.cameraPosition
	var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd)
	query.collision_mask = obstruction
	var hit = get_world_3d().direct_space_state.intersect_ray(query)


	PVisible = (hit.size() == 0)

func Visibility(delta):
	if !Engine.is_editor_hint():

		var isPointing = (global_position - gameData.cameraPosition).normalized().dot(gameData.playerVector) > 0.95
		var nightLight = gameData.flashlight && isPointing && gameData.TOD == 4
		var directFire = gameData.isFiring && isPointing


		if directFire || nightLight:
			boostTimer = 5.0
		elif boostTimer > 0.0:
			boostTimer -= delta


		var visibility = 150
		if gameData.fog: visibility = 100
		elif gameData.TOD == 4: visibility = 50


		if boostTimer > 0.0: viewDistance = 200.0

		else: viewDistance = visibility

func Cooldown(delta):

	var hasThreat: bool = threatTimer > 0.0
	var hasDetection: bool = PVisible


	if hasThreat || hasDetection:
		hotTimer = hotDuration
		hot = true

	elif hotTimer > 0.0:
		hotTimer -= delta
		if hotTimer <= 0.0:
			hot = false

func Threat(id: Node3D):

	if !is_instance_valid(id): return

	if id.is_in_group("Player") && !PlayerValid(): return


	threatPriority = id
	threatTimer = threatDuration


	priority = threatPriority



func Targets():

	var newTargets: Array[Node3D] = []


	if type == Type.Enemy:

		for target in get_tree().get_nodes_in_group("Nomad"):
			if target.owner.active: newTargets.append(target)

		if PlayerValid():
			newTargets.append(get_tree().get_first_node_in_group("Player"))


	elif type == Type.Nomad:

		for target in get_tree().get_nodes_in_group("AI"):
			if target.owner.active: newTargets.append(target)

		if PlayerValid():
			newTargets.append(get_tree().get_first_node_in_group("Player"))


	targets = newTargets

func Priority():

	if is_instance_valid(priority) && priority.is_in_group("Player") && !PlayerValid():
		priority = null
		threatPriority = null
		threatTimer = 0.0


	if threatTimer > 0.0 && is_instance_valid(threatPriority):
		priority = threatPriority
		return


	threatPriority = null


	if targets.is_empty():
		priority = null
		return


	var closestTarget: Node3D = null
	var minDistance: float = INF


	for target in targets:

		if !is_instance_valid(target) || !target.is_inside_tree():
			continue

		var targetDistance = global_position.distance_to(target.global_position)

		if targetDistance > viewDistance:
			continue


		var targetDirection = (target.global_position - global_position).normalized()
		var forward = global_transform.basis.z.normalized()
		var angle = rad_to_deg(forward.angle_to(targetDirection))
		var view: bool = angle <= (viewAngle / 2.0)
		var hear: bool = targetDistance <= hearDistance


		if view || hear:

			if !view && hear && !target.is_in_group("Player"):
				Threat(target)

			if targetDistance < minDistance:
				minDistance = targetDistance
				closestTarget = target


	if closestTarget:
		priority = closestTarget

func PriorityLOS():

	if !is_instance_valid(priority) || !priority.is_inside_tree():
		PVisible = false
		return


	var rayStart = global_position
	var rayEnd = priority.global_position
	var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd)
	query.collision_mask = obstruction
	var hit = get_world_3d().direct_space_state.intersect_ray(query)


	PVisible = (hit.size() == 0)

func PriorityStats():
	if priority:
		PLocation = priority.global_position
		PDistance = global_position.distance_to(priority.global_position)
		PVector = (priority.global_position - global_position).normalized()



func PlayerFireDetection():

	if !PlayerValid(): return


	if gameData.isFiring:

		var fireVector = (global_position - gameData.cameraPosition).normalized().dot(gameData.playerVector)

		if fireVector > 0.95:
			Threat(get_tree().get_first_node_in_group("Player"))

func PlayerHearDetection():

	if !PlayerValid(): return


	var playerDistance = global_position.distance_to(gameData.playerPosition)

	if (playerDistance < 20 && gameData.isRunning) || (playerDistance < 5 && gameData.isWalking):
		if owner.currentState != owner.State.Ambush:
			Threat(get_tree().get_first_node_in_group("Player"))



func PlayerValid() -> bool:
	if gameData.isFlying || gameData.isTransitioning || gameData.isCaching || gameData.isTrading: return false
	if type == Type.Nomad && gameData.reputation >= 50.0: return false
	return true

func Debug() -> void :
	var IMesh = mesh as ImmediateMesh
	if !IMesh: return

	IMesh.clear_surfaces()



	IMesh.surface_begin(Mesh.PRIMITIVE_LINES)
	IMesh.surface_set_color(Color.RED if force else Color.GREEN)

	var halfAngle = deg_to_rad(viewAngle / 2.0)
	var segments = 32
	var arcPoints: Array[Vector3] = []

	for i in range(segments + 1):
		var ratio = float(i) / segments
		var sweep_angle = - halfAngle + (halfAngle * 2.0) * ratio
		var x = sin(sweep_angle) * viewDistance
		var z = cos(sweep_angle) * viewDistance
		arcPoints.append(Vector3(x, 0, z))

	IMesh.surface_add_vertex(Vector3.ZERO)
	IMesh.surface_add_vertex(arcPoints[0])
	IMesh.surface_add_vertex(Vector3.ZERO)
	IMesh.surface_add_vertex(arcPoints[-1])

	for i in range(segments):
		IMesh.surface_add_vertex(arcPoints[i])
		IMesh.surface_add_vertex(arcPoints[i + 1])

	IMesh.surface_end()



	var validTargets: Array[Dictionary] = []

	for target in targets:
		if !is_instance_valid(target) || !target.is_inside_tree():
			continue

		var dist = global_position.distance_to(target.global_position)
		if dist > viewDistance:
			continue


		var targetDirection = (target.global_position - global_position).normalized()
		var forward = global_transform.basis.z.normalized()
		var angle = rad_to_deg(forward.angle_to(targetDirection))

		if angle <= (viewAngle / 2.0):
			var is_priority = (target == priority)
			validTargets.append({"global_pos": target.global_position, "priority": is_priority})


	if validTargets.size() > 0:
		IMesh.surface_begin(Mesh.PRIMITIVE_LINES)

		for target_data in validTargets:
			var line_color = Color.BLACK

			if target_data["priority"]:
				line_color = Color.RED if PVisible else Color.YELLOW


			var local_pos = global_transform.basis.inverse() * (target_data["global_pos"] - global_position)

			IMesh.surface_set_color(line_color)
			IMesh.surface_add_vertex(Vector3.ZERO)
			IMesh.surface_set_color(line_color)
			IMesh.surface_add_vertex(local_pos)

		IMesh.surface_end()
