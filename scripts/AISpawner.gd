extends Node3D


var gameData = preload("res://Resources/GameData.tres")
var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")


@export var active: bool
@export var debug: bool


enum Zone{Area05, BorderZone, Vostok, Debug}
@export var zone = Zone.Area05


var spawnDistance = 100
enum SpawnFrequency{Low, Medium, High, Debug}
var spawnFrequency = SpawnFrequency.Medium
var activeEnemyLimit = 3
var activeNomadLimit = 3
var EPoolSize = 10
var NPoolSize = 10
var initialGuard = false
var initialHider = false
var initialGroup = false


var nomad = preload("res://AI/Nomad/AI_Nomad.tscn")
var bandit = preload("res://AI/Bandit/AI_Bandit.tscn")
var guard = preload("res://AI/Guard/AI_Guard.tscn")
var military = preload("res://AI/Military/AI_Military.tscn")
var punisher = preload("res://AI/Punisher/AI_Punisher.tscn")
var bogeyman = preload("res://AI/Bogeyman/AI_Bogeyman.tscn")
var enemy
var activeNomads = 0
var activeEnemies = 0
var groupMembers: Array[Node3D]


var enemyTimer = 0.0
var nomadTimer = 0.0


var spawns: Array
var waypoints: Array
var patrols: Array
var covers: Array
var groups: Array
var hides: Array
var lurks: Array
var vehicles: Array


@onready var EPool = $E_Pool
@onready var NPool = $N_Pool
@onready var BPool = $B_Pool
@onready var enemies = $Enemies
@onready var nomads = $Nomads



func _ready():

	if !active: return

	GetPoints()

	call_deferred("Initialize")

func Initialize():

	if zone == Zone.Area05:
		enemy = bandit
		spawnFrequency = SpawnFrequency.Medium
		spawnDistance = 100.0
		EPoolSize = 10
		NPoolSize = randi_range(0, 5)
		activeEnemyLimit = 3
		activeNomadLimit = randi_range(1, 3)
		initialGuard = true
		initialHider = true
		initialGroup = true

	elif zone == Zone.BorderZone:
		enemy = guard
		spawnFrequency = SpawnFrequency.High
		spawnDistance = 100.0
		EPoolSize = 10
		NPoolSize = 0
		activeEnemyLimit = 4
		activeNomadLimit = 0
		initialGuard = true
		initialHider = false
		initialGroup = false

	elif zone == Zone.Vostok:
		enemy = military
		spawnFrequency = SpawnFrequency.High
		spawnDistance = 100.0
		EPoolSize = 10
		NPoolSize = 0
		activeEnemyLimit = 5
		activeNomadLimit = 0
		initialGuard = true
		initialHider = false
		initialGroup = false

	elif zone == Zone.Debug:
		enemy = bandit
		spawnFrequency = SpawnFrequency.Debug
		spawnDistance = 0.0
		EPoolSize = 10
		NPoolSize = 10
		activeEnemyLimit = 3
		activeNomadLimit = 3
		initialGuard = true
		initialHider = true
		initialGroup = true


	await CreatePools()


	if initialGuard: SpawnGuard()
	if initialHider && randi_range(0, 100) < 25: SpawnHider()
	if initialGroup && randi_range(0, 100) < 10: SpawnGroup()


	if zone == Zone.Area05: print("Nomads: " + "P" + str(NPoolSize) + " | " + "L" + str(activeNomadLimit))

func CreatePools():

	EPool.global_position = Vector3(0, 100, 0)
	NPool.global_position = Vector3(0, 110, 0)
	BPool.global_position = Vector3(0, 120, 0)


	for amount in EPoolSize:

		var newEnemy = enemy.instantiate()
		EPool.add_child(newEnemy, true)

		newEnemy.AISpawner = self
		newEnemy.navmesh = get_world_3d().get_navigation_map()
		newEnemy.global_position = EPool.global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
		newEnemy.Initialize()
		newEnemy.Deactivate()
		await get_tree().process_frame


	for amount in NPoolSize:

		var newNomad = nomad.instantiate()
		NPool.add_child(newNomad, true)

		newNomad.AISpawner = self
		newNomad.navmesh = get_world_3d().get_navigation_map()
		newNomad.global_position = NPool.global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
		newNomad.Initialize()
		newNomad.Deactivate()
		await get_tree().process_frame


	var newPunisher = punisher.instantiate()
	BPool.add_child(newPunisher, true)

	newPunisher.AISpawner = self
	newPunisher.navmesh = get_world_3d().get_navigation_map()
	newPunisher.global_position = BPool.global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
	newPunisher.Initialize()
	newPunisher.Deactivate()
	await get_tree().process_frame

	var newBogeyman = bogeyman.instantiate()
	BPool.add_child(newBogeyman, true)

	newBogeyman.AISpawner = self
	newBogeyman.navmesh = get_world_3d().get_navigation_map()
	newBogeyman.global_position = BPool.global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
	newBogeyman.Initialize()
	newBogeyman.Deactivate()
	await get_tree().process_frame

	print("AI Spawner: Pools created")



func _physics_process(delta):

	if !active: return


	if zone == Zone.Area05:
		EnemySpawner(delta)
		NomadSpawner(delta)
	else:
		EnemySpawner(delta)

func EnemySpawner(delta):

	if activeEnemies < activeEnemyLimit:

		enemyTimer -= delta

		if enemyTimer <= 0:

			SpawnEnemy()

			if spawnFrequency == SpawnFrequency.Low: enemyTimer = randf_range(60, 120)
			elif spawnFrequency == SpawnFrequency.Medium: enemyTimer = randf_range(10, 60)
			elif spawnFrequency == SpawnFrequency.High: enemyTimer = randf_range(1, 10)
			elif spawnFrequency == SpawnFrequency.Debug: enemyTimer = 1

func NomadSpawner(delta):

	if activeNomads < activeNomadLimit:

		nomadTimer -= delta

		if nomadTimer <= 0:

			SpawnNomad()

			if spawnFrequency == SpawnFrequency.Low: nomadTimer = randf_range(60, 120)
			elif spawnFrequency == SpawnFrequency.Medium: nomadTimer = randf_range(10, 60)
			elif spawnFrequency == SpawnFrequency.High: nomadTimer = randf_range(1, 10)
			elif spawnFrequency == SpawnFrequency.Debug: nomadTimer = 1



func SpawnEnemy():

	if EPool.get_child_count() == 0:
		print("AI Spawner: Pool empty (Enemy)")
		return


	var validPoints: Array[Node3D]


	for point in spawns:

		var distanceToPlayer = point.global_position.distance_to(gameData.playerPosition)

		if distanceToPlayer > spawnDistance:
			validPoints.append(point)


	if validPoints.size() != 0:

		var spawnPoint = validPoints.pick_random()

		var newEnemy = EPool.get_child(0)
		newEnemy.reparent(enemies)

		newEnemy.global_transform = spawnPoint.global_transform
		newEnemy.currentPoint = spawnPoint

		newEnemy.Activate("Wander")
		activeEnemies += 1
		print("AI Spawner: Agent active (Enemy)")

	else:
		print("AI Spawner: No valid spawn points (Enemy)")

func SpawnNomad():

	if NPool.get_child_count() == 0:
		print("AI Spawner: Pool empty (Nomad)")
		return


	var validPoints: Array[Node3D]


	for point in spawns:

		var distanceToPlayer = point.global_position.distance_to(gameData.playerPosition)

		if distanceToPlayer > spawnDistance:
			validPoints.append(point)


	if validPoints.size() != 0:

		var spawnPoint = validPoints.pick_random()

		var newNomad = NPool.get_child(0)
		newNomad.reparent(nomads)

		newNomad.global_transform = spawnPoint.global_transform
		newNomad.currentPoint = spawnPoint

		newNomad.Activate("Wander")
		activeNomads += 1
		print("AI Spawner: Agent active (Nomad)")

	else:
		print("AI Spawner: No valid spawn points (Nomad)")

func SpawnHider():

	if EPool.get_child_count() == 0:
		print("AI Spawner: Pool empty (Hider)")
		return


	if hides.size() != 0:

		var hidePoint = hides.pick_random()

		var newEnemy = EPool.get_child(0)
		newEnemy.reparent(enemies)

		newEnemy.global_transform = hidePoint.global_transform
		newEnemy.currentPoint = hidePoint

		newEnemy.Activate("Ambush")
		activeEnemies += 1
		print("AI Spawner: Agent active (Hider)")
	else:
		print("AI Spawner: No valid hide points (Hider)")

func SpawnGuard():

	if EPool.get_child_count() == 0:
		print("AI Spawner: Pool empty (Guard)")
		return


	if patrols.size() != 0:

		var patrolPoint = patrols.pick_random()

		var newEnemy = EPool.get_child(0)
		newEnemy.reparent(enemies)

		newEnemy.global_transform = patrolPoint.global_transform
		newEnemy.currentPoint = patrolPoint

		newEnemy.Activate("Guard")
		activeEnemies += 1
		print("AI Spawner: Agent active (Guard)")
	else:
		print("AI Spawner: No valid patrol points (Guard)")

func SpawnGroup():

	var targetPool


	if randi_range(0, 1) == 0: targetPool = EPool
	else: targetPool = NPool


	if groups.size() != 0:

		var groupPoint = groups.pick_random()

		var pointParent = groupPoint.get_parent()

		if pointParent:

			for point in pointParent.get_children():

				if targetPool.get_child_count() == 0:
					print("AI Spawner: Target pool empty (Group)")
					return

				if point.is_in_group("AI_GP"):

					var newAgent = targetPool.get_child(0)
					newAgent.reparent(enemies)

					newAgent.global_transform = point.global_transform
					newAgent.currentPoint = point

					newAgent.Activate("Group")
					if targetPool == EPool: activeEnemies += 1
					elif targetPool == NPool: activeNomads += 1

					groupMembers.append(newAgent)
					await get_tree().process_frame


			var fires = get_tree().get_nodes_in_group("Fire")

			if fires.size() != 0:

				for fire in fires:

					var distanceToGroup = pointParent.global_position.distance_to(fire.global_position)

					if distanceToGroup < 5.0: fire.Activate()

	print("AI Spawner: Agents active (Group)")

func SpawnMinion(spawnPosition: Vector3):

	if EPool.get_child_count() == 0:
		print("AI Spawner: Pool empty (Enemy/Minion)")
		return


	var newEnemy = EPool.get_child(0)
	newEnemy.reparent(enemies)

	newEnemy.global_position = spawnPosition
	newEnemy.currentPoint = waypoints.pick_random()

	newEnemy.sensor.force = true
	newEnemy.Activate("Attack")
	activeEnemies += 1
	print("AI Spawner: Agent active (Enemy/Minion)")

func SpawnBoss(boss: String, state: String, spawnPosition: Vector3, currentPoint: Node3D):

	if BPool.get_child_count() == 0:
		print("AI Spawner: Pool empty (Boss)")
		return


	var newBoss = BPool.get_node_or_null("AI_" + boss)

	if newBoss == null:
		print("AI Spawner: Boss selection failed")
		return


	newBoss.reparent(enemies)

	newBoss.global_position = spawnPosition
	newBoss.currentPoint = currentPoint

	newBoss.sensor.force = true
	newBoss.Activate(state)
	activeEnemies += 1
	print("AI Spawner: Agent active " + "(" + boss + ")")



func GetPoints():
	spawns = get_tree().get_nodes_in_group("AI_SP")
	waypoints = get_tree().get_nodes_in_group("AI_WP")
	patrols = get_tree().get_nodes_in_group("AI_PP")
	covers = get_tree().get_nodes_in_group("AI_CP")
	hides = get_tree().get_nodes_in_group("AI_HP")
	groups = get_tree().get_nodes_in_group("AI_GP")
	lurks = get_tree().get_nodes_in_group("AI_LP")
	vehicles = get_tree().get_nodes_in_group("AI_VP")

func AlertGroup(attacker):

	if groupMembers.size() != 0:

		for agent in groupMembers:
			await get_tree().create_timer(randf_range(1.0, 2.0), false).timeout;
			agent.sensor.Threat(attacker)
			print("AI Spawner: Group member alerted")

func CreateHotspot(location: Vector3):

	if enemies.get_child_count() != 0:

		for child in enemies.get_children():
			await get_tree().create_timer(randf_range(0.5, 2.0), false).timeout;
			child.lastKnownLocation = location
			child.attackReturn = true
			child.ChangeState("Attack")

func Deactivate():

	active = false


	if enemies.get_child_count() != 0:
		for agent in enemies.get_children():
			agent.queue_free()

	if nomads.get_child_count() != 0:
		for agent in nomads.get_children():
			agent.queue_free()

func Debug(toggle: bool):
	if toggle:
		for agent in enemies.get_children(): agent.Debug(true)
		for agent in nomads.get_children(): agent.Debug(true)
	else:
		for agent in enemies.get_children(): agent.Debug(false)
		for agent in nomads.get_children(): agent.Debug(false)
