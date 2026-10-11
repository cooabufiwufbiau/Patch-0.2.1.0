extends Node3D


var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")
var audioInstance3D = preload("res://Resources/AudioInstance3D.tscn")
var gameData = preload("res://Resources/GameData.tres")


var flashVFX = preload("res://Effects/Muzzle_Flash.tscn")
var smokeVFX = preload("res://Effects/Muzzle_Smoke.tscn")
var hitDefault = preload("res://Effects/Hit_Default.tscn")
var hitBlood = preload("res://Effects/Hit_Blood.tscn")


@export var variants: Array[AIData]
@export var animator: AnimationMixer
@export var skeleton: Skeleton3D
@export var aim: AimModifier
@export var identifier: Node3D
@export var impulse: ImpulseModifier
@export var head: PhysicalBone3D
@export var grabL: BoneAttachment3D
@export var grabR: BoneAttachment3D
@export var mesh: MeshInstance3D
@export var weapons: BoneAttachment3D
@export var backpacks: BoneAttachment3D
@export var grenade: PackedScene
@export var container: LootContainer
@export var collision: StaticBody3D
@export var agent: NavigationAgent3D


@onready var status: Label3D = $Tools / Status
@onready var detector: Area3D = $Tools / Detector
@onready var spatial: Area3D = $Tools / Spatial
@onready var loot: Area3D = $Tools / Loot
@onready var sensor = $Tools / Sensor
@onready var forward: RayCast3D = $Tools / Forward
@onready var below: RayCast3D = $Tools / Below
@onready var fire: RayCast3D = $Tools / Fire
@onready var flash: Flash = $Tools / Flash
@onready var LKL = $Tools / LKL


var AISpawner
var active = false


var health = 100
var dead = false


var playerDistance: float


var nickname: String


var variant: AIData
var weapon: RigidBody3D
var backpack: RigidBody3D
var muzzle: Node3D
var muzzleOffset: float
var weaponType: String
var weaponData: WeaponData
var weaponSlot: SlotData
var weaponMagazine: Node3D
var magazineTransform: Transform3D
var throwGrenade: RigidBody3D
var suppressed: bool
var optic: bool
var indoor: bool


var velocity = Vector3.ZERO
var speed = 0.0
var movementBlend = 0.0
var movementSpeed = 1.0
var rotationSpeed = 1.0


var animationCycle = 1.0
var animationTimer = 0.0


var detectorTimer = 0.0
var spatialTimer = 0.0
var points: Array
var nearbyLoot: Array
var currentPoint: Node3D
var previousPoint: Node3D


enum State{Idle, Wander, Loot, Guard, Patrol, Cover, Hide, Ambush, Combat, Hunt, Defend, Attack, Vantage, Grenade, Lurk, Switch, Group}
var currentState = State.Idle


var guardTimer: float
var guardCycle: float
var ambushTimer: float
var ambushCycle: float
var combatTimer: float
var combatCycle: float
var defendTimer: float
var defendCycle: float
var lurkTimer: float
var lurkCycle: float


var voiceTimer = 0.0
var voiceCycle = 30.0
var activeVoice = null


var interactionTarget
var interactionTime = 0.2
var interactionTimer = 0.0


var fireTime = 1.0
var fireAccuracy = 1.0
var selectorTime = 1.0
var selectorRoll = 0
var fullAuto = false
var reload = false


var looting = false
var lootTarget: Node3D


var animDirection: int
var targetOffset: Vector3


var navmesh
var pathTarget: Vector3



func Initialize():
	SelectVariant()
	SelectWeapon()
	SelectBackpack()
	SetExceptions()

func Deactivate():

	hide()
	active = false
	animator.active = false
	sensor.active = false
	detector.monitoring = false
	spatial.monitoring = false
	loot.monitoring = false
	forward.enabled = false
	below.enabled = false
	aim.active = false
	impulse.active = false


	Debug(false)


	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL


	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	skeleton.process_mode = ProcessMode.PROCESS_MODE_WHEN_PAUSED


	for child in weapons.get_children():
		child.process_mode = Node.PROCESS_MODE_DISABLED
		child.collision.disabled = true


	for child in backpacks.get_children():
		child.process_mode = Node.PROCESS_MODE_DISABLED
		child.collision.disabled = true


	container.get_child(0).get_child(0).disabled = true

func Freeze():

	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL


	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	skeleton.process_mode = ProcessMode.PROCESS_MODE_WHEN_PAUSED

func Activate(state: String):

	show()
	active = true
	animator.active = true
	sensor.active = true
	detector.monitoring = true
	spatial.monitoring = true
	loot.monitoring = true
	forward.enabled = true
	below.enabled = true
	aim.active = true
	impulse.active = true


	detectorTimer = 100.0


	process_mode = ProcessMode.PROCESS_MODE_INHERIT
	skeleton.process_mode = ProcessMode.PROCESS_MODE_INHERIT


	var characterCamo = get_node_or_null("Camo")
	var weaponCamo = weapon.get_node_or_null("Camo")
	if characterCamo: characterCamo.Update()
	if weaponCamo: weaponCamo.Update()


	await get_tree().create_timer(randi_range(1, 2), false).timeout;
	ChangeState(state)



func SelectVariant():

	variant = variants.pick_random()

	mesh.mesh = variant.mesh
	mesh.set_surface_override_material(0, variant.materials.pick_random())

	health = variant.health

	if variant.faction == variant.Faction.Nomad:

		collision.add_to_group("Interactable", false)
		collision.set_collision_layer_value(8, true)

		if variant.nicknames.size() != 0:
			nickname = variant.nicknames.pick_random()

func SelectWeapon():

	if weapons.get_child_count() != 0:




		weapon = weapons.get_child(randi_range(0, weapons.get_child_count() - 1))
		weaponData = weapon.slotData.itemData
		weapon.show()


		for child in weapons.get_children():
			if child != weapon:
				child.queue_free()


		muzzle = weapon.get_node("Muzzle")
		flash.reparent(muzzle)
		flash.global_transform = muzzle.global_transform


		var LOD0: MeshInstance3D = weapon.get_node_or_null("LOD0")
		var LOD1: MeshInstance3D = weapon.get_node_or_null("LOD1")
		if LOD0 && LOD1:
			LOD0.visibility_range_end = 10.0
			LOD1.visibility_range_begin = 9.0
			LOD1.visibility_range_end = 200.0
		else:
			print("AI: Weapon visibility failed")


		var newSlotData = SlotData.new()
		newSlotData.itemData = weapon.slotData.itemData
		newSlotData.condition = 100 if variant.fullCondition else randi_range(5, 50)
		newSlotData.amount = newSlotData.itemData.magazineSize if variant.fullMagazine else randi_range(1, newSlotData.itemData.magazineSize)
		newSlotData.chamber = true
		weapon.slotData = newSlotData
		weaponSlot = newSlotData




		if newSlotData.itemData.weaponType == "Pistol":
			weaponType = "Pistol"
			SetAnimatorWeapon("Pistol")
		else:
			weaponType = "Rifle"
			SetAnimatorWeapon("Rifle")




		if weaponData.weaponAction != "Manual":

			if weaponData.compatible.size() != 0:

				if weaponData.compatible[0].subtype == "Magazine":

					var magazine = weapon.get_node_or_null("Attachments").get_node_or_null(weaponData.compatible[0].file)
					var magazineLOD0: MeshInstance3D = magazine.get_node_or_null("LOD0")
					var magazineLOD1: MeshInstance3D = magazine.get_node_or_null("LOD1")


					weaponMagazine = magazine
					magazineTransform = magazine.transform


					if magazine && magazineLOD0 && magazineLOD1:
						magazine.show()
						magazineLOD0.visibility_range_end = 10.0
						magazineLOD1.visibility_range_begin = 9.0
						magazineLOD1.visibility_range_end = 200.0
					else: print("AI: Magazine visibility failed")


					weapon.slotData.nested.append(weaponData.compatible[0])



		if randi_range(0, 100) <= 5 || variant.forceAttachment:

			if weaponData.compatible.size() != 0:

				var attachmentData = weaponData.compatible.pick_random()

				if attachmentData.subtype != "Magazine":

					var attachment = weapon.get_node_or_null("Attachments").get_node_or_null(attachmentData.file)

					if !attachment:
						print("AI: Attachment not found: " + attachmentData.name)
						return

					var attachmentLOD0: MeshInstance3D = attachment.get_node_or_null("LOD0")
					var attachmentLOD1: MeshInstance3D = attachment.get_node_or_null("LOD1")

					if attachmentLOD0 && attachmentLOD1:
						attachment.show()
						attachmentLOD0.visibility_range_end = 10.0
						attachmentLOD1.visibility_range_begin = 9.0
						attachmentLOD1.visibility_range_end = 200.0

					else:
						print("AI: Attachment visibility failed: " + attachmentData.name)
						return


					if attachmentData.subtype == "Muzzle":
						suppressed = true
						muzzleOffset = 0.2
						flash.position.z = muzzleOffset


					if attachmentData.subtype == "Optic":

						optic = true


						if weaponData.useMount:

							var mount = weapon.get_node_or_null("Attachments").get_node_or_null("Mount")
							var mountMesh: MeshInstance3D = mount.get_node_or_null("Mesh")


							if mount && mountMesh:
								mountMesh.visibility_range_end = 200.0
								mount.show()
							else: print("AI: Mount visibility failed")


					weapon.slotData.nested.append(attachmentData)

func SelectBackpack():

	if randi_range(0, 100) <= 5:

		if backpacks.get_child_count() != 0:

			backpack = backpacks.get_child(randi_range(0, backpacks.get_child_count() - 1))


			for child in backpacks.get_children():
				if child != backpack:
					child.queue_free()


			var backpackMesh: MeshInstance3D = backpack.get_node_or_null("Mesh")


			if backpack && backpackMesh:
				backpack.show()
				backpackMesh.visibility_range_end = 400.0
			else: print("AI: Backpack visibility failed")


	else:

		if backpacks.get_child_count() != 0:

			for child in backpacks.get_children():
				child.queue_free()



func _physics_process(delta: float) -> void :
	if !active: return


	Detectors(delta)
	Parameters(delta)
	Alert()
	States(delta)
	Movement(delta)
	Rotation(delta)
	Animate(delta)
	Aiming(delta)
	Interactor(delta)
	Voices(delta)


	if AISpawner.debug: UpdateStatus()

func Detectors(delta):
	detectorTimer += delta
	spatialTimer += delta


	if detectorTimer > 5.0:

		points.clear()

		var areas = detector.get_overlapping_areas()

		if areas.size() > 0:
			for area in areas:
				points.append(area.owner)


		detectorTimer = 0.0


	if spatialTimer > 2.0:

		var areas = spatial.get_overlapping_areas()

		if areas.size() > 0:
			for area in areas:

				if area is Area:

					if area.type == "Indoor": indoor = true
					else: indoor = false

		else: indoor = false


		spatialTimer = 0.0

func Parameters(delta):

	if sensor.PVisible || sensor.threatPriority || sensor.force:
		LKL.global_position = lerp(LKL.global_position, sensor.PLocation, delta * 5.0)

	elif currentState != State.Hunt && currentState != State.Attack:
		LKL.global_position = lerp(LKL.global_position, global_position + Vector3(0.0, 1.5, 0.0) + global_basis.z * 5.0, delta)

	playerDistance = global_position.distance_to(gameData.playerPosition)

func Movement(delta):

	movementSpeed = move_toward(movementSpeed, speed, delta * 5.0)
	animator["parameters/Wander/P_Speed/blend_position"] = movementSpeed
	animator["parameters/Wander/R_Speed/blend_position"] = movementSpeed
	animator["parameters/Move/P_Speed/blend_position"] = movementSpeed
	animator["parameters/Move/R_Speed/blend_position"] = movementSpeed


	if (currentState == State.Idle
	|| currentState == State.Ambush
	|| currentState == State.Defend
	|| currentState == State.Lurk
	|| currentState == State.Grenade
	|| currentState == State.Group):
		return


	if Engine.get_physics_frames() % 10 == 0:
		pathTarget = agent.get_next_path_position()


	velocity = (pathTarget - global_position).normalized()
	global_position += velocity * delta * movementSpeed

func Rotation(delta):

	if (currentState == State.Idle
	|| currentState == State.Group):
		return


	if currentState == State.Guard || currentState == State.Ambush:
		rotation.y = lerp_angle(rotation.y, currentPoint.global_rotation.y, delta * rotationSpeed)
		animator["parameters/Hunt/P_Direction/blend_position"] = 0.0
		animator["parameters/Hunt/R_Direction/blend_position"] = 0.0

	elif currentState == State.Defend || currentState == State.Grenade || currentState == State.Lurk:
		var LKLDirection = global_position - Vector3(LKL.global_position.x, 0.0, LKL.global_position.z)
		var targetAngle = atan2( - LKLDirection.x, - LKLDirection.z)
		rotation.y = lerp_angle(rotation.y, targetAngle, delta * rotationSpeed)
		var turnDirection = angle_difference(rotation.y, targetAngle)
		animator["parameters/Defend/P_Direction/blend_position"] = - turnDirection * 10.0
		animator["parameters/Defend/R_Direction/blend_position"] = - turnDirection * 10.0
		animator["parameters/Grenade/P_Direction/blend_position"] = - turnDirection * 10.0
		animator["parameters/Grenade/R_Direction/blend_position"] = - turnDirection * 10.0

	elif currentState == State.Combat || currentState == State.Hunt || currentState == State.Switch:

		var LKLDirection = (LKL.global_position - global_position).normalized()
		animDirection = 1 if velocity.dot(LKLDirection) >= 0.0 else -1
		movementBlend = move_toward(movementBlend, animDirection, delta * 2.0)
		animator["parameters/Combat/P_Direction/blend_position"] = movementBlend
		animator["parameters/Combat/R_Direction/blend_position"] = movementBlend
		animator["parameters/Hunt/P_Direction/blend_position"] = movementBlend
		animator["parameters/Hunt/R_Direction/blend_position"] = movementBlend


		var forwardAngle = atan2(velocity.x, velocity.z)
		var targetAngle = forwardAngle


		if animDirection < 0:
			var switcher = sign(angle_difference(forwardAngle, atan2(LKLDirection.x, LKLDirection.z)))
			targetAngle = forwardAngle + (PI * switcher) - (switcher * 0.001)


		var shortestRotation = angle_difference(rotation.y, targetAngle)
		rotation.y = rotate_toward(rotation.y, rotation.y + shortestRotation, delta * rotationSpeed)


	else:
		rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), delta * rotationSpeed)

func Animate(delta):

	if playerDistance > 200.0: animationCycle = 1.0 / 5.0
	elif playerDistance > 50.0: animationCycle = 1.0 / 15.0
	elif playerDistance > 25.0: animationCycle = 1.0 / 30.0
	else: animationCycle = 1.0 / 60.0


	animationTimer += delta


	if animationTimer >= animationCycle:
		var animDelta = animationTimer
		if animator && animator.active:
			animator.advance(animDelta)
			skeleton.advance(animDelta)


		animationTimer = 0.0

func Aiming(delta):

	if (currentState == State.Combat
	|| currentState == State.Defend
	|| currentState == State.Hunt
	|| currentState == State.Lurk
	|| currentState == State.Switch
	|| currentState == State.Attack):
		aim.influence = lerp(aim.influence, 1.0, delta * 2.0)
	else:
		aim.influence = lerp(aim.influence, 0.0, delta * 2.0)


	if currentState == State.Combat:
		if weaponType == "Pistol":
			if animDirection == 1: targetOffset = aim.pistolCombatF
			else: targetOffset = aim.pistolCombatB
		elif weaponType == "Rifle":
			if animDirection == 1: targetOffset = aim.rifleCombatF
			else: targetOffset = aim.rifleCombatB


	elif currentState == State.Defend || currentState == State.Lurk:
		if weaponType == "Pistol":
			targetOffset = aim.pistolDefend
		elif weaponType == "Rifle":
			targetOffset = aim.rifleDefend


	elif currentState == State.Hunt || currentState == State.Switch:
		if weaponType == "Pistol":
			if animDirection == 1: targetOffset = aim.pistolHuntF
			else: targetOffset = aim.pistolHuntB
		elif weaponType == "Rifle":
			if animDirection == 1: targetOffset = aim.rifleHuntF
			else: targetOffset = aim.rifleHuntB


	elif currentState == State.Attack:
		if weaponType == "Pistol":
			if animDirection == 1: targetOffset = aim.pistolAttackF
			else: targetOffset = aim.pistolAttackB
		elif weaponType == "Rifle":
			if animDirection == 1: targetOffset = aim.rifleAttackF
			else: targetOffset = aim.rifleAttackB


	aim.offset = lerp(aim.offset, targetOffset, delta)

func Alert():

	if sensor.PVisible || sensor.threatPriority:

		if currentState == State.Group:
			Decision()
			AISpawner.AlertGroup(sensor.priority)


		elif currentState == State.Wander: Decision()
		elif currentState == State.Loot: Decision()
		elif currentState == State.Guard: Decision()
		elif currentState == State.Patrol: Decision()
		elif currentState == State.Loot: Decision()
		elif currentState == State.Ambush: ChangeState("Combat")

func Interactor(delta):
	forward.global_rotation.y = atan2(velocity.x, velocity.z)
	interactionTimer += delta

	if interactionTimer > interactionTime:
		if forward.is_colliding():
			interactionTarget = forward.get_collider()

			if interactionTarget.is_in_group("Interactable"):

				if interactionTarget.owner is Door && !interactionTarget.owner.isOpen:

					if interactionTarget.owner.locked: return
					if interactionTarget.owner.jammed: return

					interactionTarget.owner.Interact()
					interactionTarget.owner.isOccupied = true

		interactionTimer = 0.0



func ChangeState(state):
	match state:


		"Idle":
			speed = 0.0
			rotationSpeed = 1.0
			agent.target_desired_distance = 1.0
			currentState = State.Idle



		"Wander":
			if GetWanderPoint():
				speed = 1.0
				rotationSpeed = 5.0
				agent.target_desired_distance = 1.0
				currentState = State.Wander
				ResetAnimator()
				animator["parameters/conditions/Wander"] = true
			else:
				print("AI: No available wander points -> Idle")
				ChangeState("Idle")



		"Loot":
			speed = 0.0
			rotationSpeed = 1.0
			agent.target_desired_distance = 1.0
			currentState = State.Loot
			ResetAnimator()
			animator["parameters/conditions/Wander"] = true
			Loot()



		"Patrol":
			if GetPatrolPoint():
				speed = 1.0
				rotationSpeed = 5.0
				agent.target_desired_distance = 0.5
				currentState = State.Patrol
				ResetAnimator()
				animator["parameters/conditions/Move"] = true
			else:
				print("AI: No available patrol points -> Wander")
				ChangeState("Wander")



		"Guard":
			speed = 0.0
			rotationSpeed = 1.0
			guardTimer = 0.0
			guardCycle = randf_range(4, 20)
			agent.target_desired_distance = 0.5
			currentState = State.Guard
			ResetAnimator()
			animator["parameters/conditions/Guard"] = true



		"Cover":
			if GetCoverPoint():
				speed = 5.0
				rotationSpeed = 5.0
				agent.target_desired_distance = 0.5
				currentState = State.Cover
				ResetAnimator()
				animator["parameters/conditions/Move"] = true
			else:
				print("AI: No available cover points -> Combat")
				ChangeState("Combat")

		"Hide":
			if GetHidePoint():
				speed = 5.0
				rotationSpeed = 5.0
				agent.target_desired_distance = 0.5
				currentState = State.Hide
				ResetAnimator()
				animator["parameters/conditions/Move"] = true
			else:
				print("AI: No available hide points")
				ChangeState("Combat")



		"Ambush":
			speed = 0.0
			rotationSpeed = 2.0
			agent.target_desired_distance = 0.5
			ambushTimer = 0.0
			ambushCycle = randf_range(60, 120)
			currentState = State.Ambush
			ResetAnimator()
			animator["parameters/conditions/Hunt"] = true



		"Combat":
			if GetWanderPoint():
				speed = 1.0
				rotationSpeed = 5.0
				agent.target_desired_distance = 1.0
				combatTimer = 0.0
				combatCycle = randf_range(5, 20)
				currentState = State.Combat
				ResetAnimator()
				animator["parameters/conditions/Combat"] = true
			else:
				print("AI: No available combat points -> Idle")
				ChangeState("Idle")



		"Defend":
			speed = 0.0
			rotationSpeed = 5.0
			defendTimer = 0.0
			defendCycle = randf_range(4, 10)
			agent.target_desired_distance = 0.5
			currentState = State.Defend
			ResetAnimator()
			animator["parameters/conditions/Defend"] = true



		"Lurk":
			speed = 0.0
			rotationSpeed = 5.0
			lurkTimer = 0.0
			lurkCycle = randf_range(10, 30)
			agent.target_desired_distance = 0.5
			currentState = State.Lurk
			ResetAnimator()
			animator["parameters/conditions/Defend"] = true



		"Switch":
			GetLurkPoint()
			speed = 1.0
			rotationSpeed = 5.0
			agent.target_desired_distance = 2.0
			currentState = State.Switch
			ResetAnimator()
			animator["parameters/conditions/Hunt"] = true



		"Vantage":
			if GetVantagePoint():
				speed = 5.0
				rotationSpeed = 5.0
				agent.target_desired_distance = 0.5
				currentState = State.Vantage
				ResetAnimator()
				animator["parameters/conditions/Move"] = true
			else:
				print("AI: No available vantage points -> Combat")
				ChangeState("Combat")



		"Hunt":
			GetLKLPoint()
			speed = 1.0
			rotationSpeed = 5.0
			agent.target_desired_distance = 2.0
			currentState = State.Hunt
			ResetAnimator()
			animator["parameters/conditions/Hunt"] = true



		"Attack":
			GetLKLPoint()
			speed = 3.0
			rotationSpeed = 5.0
			agent.target_desired_distance = 2.0
			currentState = State.Attack
			ResetAnimator()
			animator["parameters/conditions/Move"] = true



		"Grenade":
			speed = 0.0
			rotationSpeed = 5.0
			agent.target_desired_distance = 0.5
			currentState = State.Grenade
			ResetAnimator()
			animator["parameters/conditions/Grenade"] = true
			animator["parameters/Grenade/P_Grenade/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			animator["parameters/Grenade/R_Grenade/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE



		"Group":
			speed = 0.0
			rotationSpeed = 0.0
			agent.target_desired_distance = 0.5
			currentState = State.Group
			ResetAnimator()
			animator["parameters/conditions/Group"] = true
			animator["parameters/Group/P_Pose/blend_position"] = randi_range(0, 2)
			animator["parameters/Group/R_Pose/blend_position"] = randi_range(0, 2)

func States(delta):
	if currentState == State.Wander: Wander()
	elif currentState == State.Patrol: Patrol()
	elif currentState == State.Guard: Guard(delta)
	elif currentState == State.Hide: Hide(delta)
	elif currentState == State.Cover: Cover(delta)
	elif currentState == State.Ambush: Ambush(delta)
	elif currentState == State.Combat: Combat(delta)
	elif currentState == State.Hunt: Hunt(delta)
	elif currentState == State.Attack: Attack(delta)
	elif currentState == State.Defend: Defend(delta)
	elif currentState == State.Vantage: Vantage(delta)
	elif currentState == State.Lurk: Lurk(delta)
	elif currentState == State.Switch: Switch(delta)

func Decision():
	var decision = randi_range(1, 8)
	if decision == 1: ChangeState("Combat")
	elif decision == 2: ChangeState("Defend")
	elif decision == 3: ChangeState("Cover")
	elif decision == 4: ChangeState("Hide")
	elif decision == 5: ChangeState("Vantage")
	elif decision == 6 && sensor.PVisible: ChangeState("Hunt")
	elif decision == 7 && sensor.PVisible: ChangeState("Attack")
	elif decision == 8 && sensor.PVisible && (sensor.PDistance > 25.0 && sensor.PDistance < 50.0) && !indoor && currentState == State.Combat: ChangeState("Grenade")
	elif decision == 8 && sensor.PVisible && (sensor.PDistance > 25.0 && sensor.PDistance < 50.0) && !indoor && currentState == State.Defend: ChangeState("Grenade")
	else: ChangeState("Combat")



func Wander():

	if agent.is_target_reached() || agent.is_navigation_finished():

		if looting: ChangeState("Loot")

		elif randi_range(0, 100) < 25: GetLootPoint()

		else: GetWanderPoint()

func Loot():

	animator["parameters/Wander/P_Loot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	animator["parameters/Wander/R_Loot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	await get_tree().create_timer(0.5, false).timeout;


	if lootTarget && lootTarget is LootContainer:
		PlayLoot()
		var lootedItem = lootTarget.AILoot()
		await get_tree().create_timer(0.5, false).timeout;
		if lootedItem != null:
			container.loot.append(lootedItem)
			PlayPickup()


	await get_tree().create_timer(1.0, false).timeout;
	looting = false
	ChangeState("Wander")

func Patrol():

	if agent.is_target_reached() || agent.is_navigation_finished():
		ChangeState("Guard")

func Guard(delta):

	guardTimer += delta

	if guardTimer > guardCycle:
		ChangeState("Patrol")

func Ambush(delta):

	ambushTimer += delta

	if ambushTimer > ambushCycle:
		ChangeState("Wander")

func Cover(_delta):

	if global_transform.origin.distance_to(agent.target_position) < 2.0: speed = 1.0
	elif global_transform.origin.distance_to(agent.target_position) < 4.0: speed = 3.0

	if agent.is_target_reached() || agent.is_navigation_finished():
		ChangeState("Combat")

	if sensor.PDistance < 10:
		ChangeState("Combat")

func Hide(_delta):

	if global_position.distance_to(agent.target_position) < 2.0: speed = 1.0
	elif global_position.distance_to(agent.target_position) < 4.0: speed = 3.0

	if agent.is_target_reached() || agent.is_navigation_finished():
		if randi_range(0, 100) < 25: ChangeState("Ambush")
		else: ChangeState("Combat")

	if sensor.PDistance < 10:
		ChangeState("Combat")

func Vantage(_delta):

	if global_position.distance_to(agent.target_position) < 2.0: speed = 1.0
	elif global_position.distance_to(agent.target_position) < 4.0: speed = 3.0

	if agent.is_target_reached() || agent.is_navigation_finished():

		LKL.global_position = currentPoint.global_position + Vector3(0.0, 1.5, 0.0) + currentPoint.global_basis.z * 5.0
		ChangeState("Defend")

	if sensor.PDistance < 10: ChangeState("Combat")

func Defend(delta):

	if reload: return

	defendTimer += delta

	if sensor.PVisible: Fire(delta)

	if defendTimer > defendCycle:
		ChangeState("Combat")

	if weaponSlot.amount == 0 && weaponData.weaponAction != "Manual":
		Reload()
		PlayReload()

func Combat(delta):

	if reload:
		if agent.is_target_reached() || agent.is_navigation_finished(): GetWanderPoint()
		return


	combatTimer += delta

	if sensor.PVisible: Fire(delta)

	if !sensor.hot: ChangeState("Wander")

	if combatTimer > combatCycle || agent.is_target_reached() || agent.is_navigation_finished():
		Decision()

	if weaponSlot.amount == 0 && weaponData.weaponAction != "Manual":
		Reload()
		PlayReload()

func Hunt(delta):

	if reload:
		if agent.is_target_reached() || agent.is_navigation_finished(): GetWanderPoint()
		return


	if sensor.PVisible: Fire(delta)

	if Engine.get_physics_frames() % 100 == 0:
		GetLKLPoint()

	if agent.is_target_reached() || agent.is_navigation_finished() || gameData.isTrading:
		ChangeState("Combat")

	if weaponSlot.amount == 0 && weaponData.weaponAction != "Manual":
		Reload()
		PlayReload()

func Attack(delta):

	if reload:
		if Engine.get_physics_frames() % 50 == 0: GetLKLPoint()

		if agent.is_target_reached() || agent.is_navigation_finished():
			ChangeState("Combat")
		return


	if global_transform.origin.distance_to(agent.target_position) < 2.0: speed = 1.0
	elif global_transform.origin.distance_to(agent.target_position) < 4.0: speed = 3.0

	if sensor.PVisible: Fire(delta)

	if Engine.get_physics_frames() % 50 == 0:
		GetLKLPoint()

	if agent.is_target_reached() || agent.is_navigation_finished() || gameData.isTrading:
		ChangeState("Combat")

	if weaponSlot.amount == 0 && weaponData.weaponAction != "Manual":
		Reload()
		PlayReload()

func Lurk(delta):

	if reload: return

	lurkTimer += delta

	if sensor.PVisible: Fire(delta)

	if lurkTimer > lurkCycle:
		ChangeState("Switch")

	if weaponSlot.amount == 0 && weaponData.weaponAction != "Manual":
		Reload()
		PlayReload()

func Switch(delta):

	if agent.is_target_reached() || agent.is_navigation_finished():
		ChangeState("Lurk")

	if sensor.PVisible: Fire(delta)

	if sensor.PDistance < 10:
		ChangeState("Combat")

func Grenade(phase: int):

	if phase == 1:
		throwGrenade = grenade.instantiate()
		grabR.add_child(throwGrenade)
		throwGrenade.transform = grabR.get_node_or_null("Target").transform
		throwGrenade.process_mode = Node.PROCESS_MODE_DISABLED
		weapon.hide()

	elif phase == 2:
		throwGrenade.process_mode = Node.PROCESS_MODE_INHERIT
		throwGrenade.reparent(get_tree().get_root())

		var throwForce = 25.0
		if sensor.PDistance <= 10: throwForce = 10.0
		elif sensor.PDistance > 10 && sensor.PDistance <= 25: throwForce = 20.0
		elif sensor.PDistance > 25 && sensor.PDistance <= 50: throwForce = 40.0

		throwGrenade.linear_velocity = grabR.global_basis.z * throwForce
		throwGrenade.angular_velocity = grabR.global_basis.x * 5.0
		throwGrenade.fuseTime = 5.0

	elif phase == 3:
		weapon.show()
		ChangeState("Combat")



func Fire(delta):

	if LKL.global_position.distance_to(sensor.PLocation) > 1.0: return


	if weaponData.weaponAction == "Semi-Auto":
		Selector(delta)


	fireTime -= delta
	if fireTime <= 0:

		Raycast()
		PlayFire()
		PlayTail()
		MuzzleVFX()


		if is_instance_valid(sensor.priority):
			if !sensor.priority.is_in_group("Player"):
				sensor.priority.owner.sensor.Threat(identifier)


		if fullAuto: impulse.RecoilImpulse(-5.0)
		else: impulse.RecoilImpulse(-10.0)


		if weaponSlot.amount > 0: weaponSlot.amount -= 1


		FireFrequency()


		if playerDistance > 50:
			await get_tree().create_timer(0.1, false).timeout;
			PlayCrack()

func Selector(delta):
	selectorTime -= delta


	if selectorTime <= 0:

		if currentState == State.Attack: selectorRoll = 0

		else: selectorRoll = randi_range(0, 100)


		if selectorRoll <= 10 && !fullAuto:
			selectorTime = randf_range(1.0, 2.0)
			fullAuto = true
		else:
			selectorTime = randf_range(1.0, 5.0)
			fullAuto = false

func Raycast():

	fire.look_at(FireAccuracy(), Vector3.UP, true)
	fire.force_raycast_update()
	if AISpawner.debug: DebugRay(fire)


	if fire.is_colliding():
		var hitCollider = fire.get_collider()


		if hitCollider is Hitbox:
			hitCollider.ApplyDamage(weaponData.damage, muzzle.global_basis.z, identifier)

		elif hitCollider.name == "Controller":
			hitCollider.get_child(0).WeaponDamage(weaponData.damage, weaponData.penetration)

		else:
			var hitPoint = fire.get_collision_point()
			var hitNormal = fire.get_collision_normal()
			var hitSurface = hitCollider.get("surface")
			BulletDecal(hitCollider, hitPoint, hitNormal, hitSurface)


	elif sensor.priority.is_in_group("Player") && playerDistance > 50:
		await get_tree().create_timer(0.1, false).timeout;
		PlayFlyby()

func FireFrequency():

	if weaponData.weaponAction == "Semi-Auto" && fullAuto:
		fireTime = weaponData.fireRate


	elif (weaponData.weaponAction == "Semi-Auto" || weaponData.weaponAction == "Semi") && !fullAuto:
		if sensor.PDistance < 10: fireTime = randf_range(0.1, 0.5)
		elif sensor.PDistance > 10 && sensor.PDistance < 50: fireTime = randf_range(0.1, 1.0)
		else: fireTime = randf_range(0.1, 4.0)


	elif weaponData.weaponAction == "Pump" || weaponData.weaponAction == "Bolt":
		if sensor.PDistance < 10: fireTime = randf_range(1.0, 2.0)
		elif sensor.PDistance > 10 && sensor.PDistance < 50: fireTime = randf_range(1.0, 2.0)
		else: fireTime = randf_range(1.0, 4.0)


	else:
		fireTime = randf_range(1.0, 4.0)

func FireAccuracy() -> Vector3:

	var spreadMultiplier = 1.0 if !fullAuto else 2.5
	var spreadReduction = 0.1 if optic else 0.0
	var spreadOffset = 0.1


	if sensor.PDistance <= 10: spreadOffset = variant.accuracy.x

	elif sensor.PDistance > 10 && sensor.PDistance <= 50: spreadOffset = variant.accuracy.y

	else: spreadOffset = variant.accuracy.z


	var spreadX = randf_range( - spreadOffset, spreadOffset) * (spreadMultiplier - spreadReduction)
	var spreadY = randf_range( - spreadOffset, spreadOffset) * (spreadMultiplier - spreadReduction)
	var spread = (fire.global_transform.basis.x * spreadX) + (fire.global_transform.basis.y * spreadY)


	var centerMass = sensor.PLocation - Vector3(0.0, 0.5, 0.0)


	return centerMass + spread

func MagazineGrab(start: bool):

	if start:
		weaponMagazine.reparent(grabL)
		weaponMagazine.transform = grabL.get_node_or_null("Target").transform
	else:
		weaponMagazine.reparent(weapon)
		weaponMagazine.transform = magazineTransform
		await get_tree().create_timer(2.0, false).timeout;
		animator["parameters/Move/P_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		animator["parameters/Move/R_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		animator["parameters/Combat/P_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		animator["parameters/Combat/R_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		animator["parameters/Defend/P_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		animator["parameters/Defend/R_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		animator["parameters/Guard/P_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		animator["parameters/Guard/R_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		animator["parameters/Hunt/P_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		animator["parameters/Hunt/R_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		reload = false

func Reload():

	reload = true

	animator["parameters/Move/P_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	animator["parameters/Move/R_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	animator["parameters/Combat/P_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	animator["parameters/Combat/R_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	animator["parameters/Defend/P_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	animator["parameters/Defend/R_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	animator["parameters/Guard/P_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	animator["parameters/Guard/R_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	animator["parameters/Hunt/P_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	animator["parameters/Hunt/R_Reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

	weaponSlot.amount = weaponData.magazineSize



func BulletDecal(hitCollider, hitPoint, hitNormal, hitSurface):

	var bulletDecal = hitDefault.instantiate()
	hitCollider.add_child(bulletDecal)
	bulletDecal.global_transform.origin = hitPoint


	var surfaceUp = Vector3(0, 1, 0)
	var surfaceDown = Vector3(0, -1, 0)
	if hitNormal == surfaceUp: bulletDecal.look_at(hitPoint + hitNormal, Vector3.RIGHT)
	elif hitNormal == surfaceDown: bulletDecal.look_at(hitPoint + hitNormal, Vector3.RIGHT)
	else: bulletDecal.look_at(hitPoint + hitNormal, Vector3.DOWN)
	bulletDecal.global_rotation.z = randf_range(-360, 360)


	bulletDecal.PlayHit(hitSurface)

func MuzzleVFX():

	var newSmoke = smokeVFX.instantiate()
	muzzle.add_child(newSmoke)
	newSmoke.transform = muzzle.transform
	newSmoke.position.z = muzzleOffset
	newSmoke.Emit(true, 0.5)


	if suppressed: return


	var newFlash = flashVFX.instantiate()
	muzzle.add_child(newFlash)
	newFlash.transform = muzzle.transform
	newFlash.position.z = muzzleOffset
	newFlash.Emit(true, 0.1)
	flash.Activate()



func WeaponDamage(hitbox: String, damage: float, vector: Vector3, id: Node3D):

	if dead: return
	health -= damage


	impulse.DamageImpulse(vector)


	if variant.faction == variant.Faction.Nomad:
		if id.is_in_group("Player"):
			gameData.reputation -= 20.0
			Loader.Message("Nomad Reputation [-20]", Color.RED)


	if health <= 0:

		if is_instance_valid(activeVoice):
			activeVoice.queue_free()
			activeVoice = null

		if hitbox != "Head": PlayDeath()

		Death(vector, 10.0)


	else:

		if !is_instance_valid(activeVoice):
			PlayDamage()

func ExplosionDamage(direction, id: Node3D):

	if id != null:

		if variant.faction == variant.Faction.Nomad:
			if id.is_in_group("Player"):
				gameData.reputation -= 10.0
				Loader.Message("Nomad Reputation [-10]", Color.RED)


	Death(direction, 20.0)

func Death(direction, force):

	dead = true


	active = false
	animator.active = false
	sensor.active = false
	detector.monitoring = false
	spatial.monitoring = false
	loot.monitoring = false
	forward.enabled = false
	below.enabled = false
	aim.active = false
	impulse.active = false


	Debug(false)


	identifier.queue_free()


	if variant.faction == variant.Faction.Boss:
		Loader.Message("Boss Killed: " + variant.name, Color.GREEN)


	collision.get_child(0).disabled = true


	agent.velocity = Vector3.ZERO


	if weapon:
		weapon.process_mode = Node.PROCESS_MODE_INHERIT
		weapon.collision.disabled = false

	if backpack:
		backpack.process_mode = Node.PROCESS_MODE_INHERIT
		backpack.collision.disabled = false


	if reload:
		weaponMagazine.reparent(weapon)
		weaponMagazine.transform = magazineTransform


	container.get_child(0).get_child(0).disabled = false


	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_IDLE
	skeleton.Activate(direction, force)


	if variant.faction == variant.Faction.Nomad:
		AISpawner.activeNomads -= 1
	elif variant.faction != variant.Faction.Boss:
		AISpawner.activeEnemies -= 1



func UpdateStatus():
	var statusColor = Color.RED if sensor.PVisible else Color.GREEN
	var statusIndicator = "Reload" if reload else str(State.find_key(currentState))
	var ammoIndicator = "[" + str(weaponSlot.amount) + "]"
	var indoorIndicator = "*" if indoor else ""
	var lootIndicator = "(L)" if looting else ""
	status.text = statusIndicator + lootIndicator + indoorIndicator + "\n" + str(health) + ammoIndicator
	status.modulate = statusColor

func GetWanderPoint():

	var validPoints: Array[Node3D]


	if points.size() != 0:

		for point in points:

			if point.is_in_group("AI_WP"):

				if point != currentPoint:
					validPoints.append(point)


	if validPoints.size() != 0:

		var waypoint = validPoints.pick_random()
		currentPoint = waypoint
		MoveToPoint(waypoint.global_position)
		return true
	else:

		var waypoint = get_tree().get_nodes_in_group("AI_SP").pick_random()
		currentPoint = waypoint
		MoveToPoint(waypoint.global_position)
		print("AI Wander: Fallback to spawn point")
		return true

func GetLootPoint():

	nearbyLoot.clear()

	var areas = loot.get_overlapping_areas()

	if areas.size() > 0:
		for area in areas:
			nearbyLoot.append(area.owner)


	if nearbyLoot.size() != 0:

		var lootPoint = nearbyLoot.pick_random()
		looting = true
		lootTarget = lootPoint
		currentPoint = lootPoint
		MoveToPoint(lootPoint.global_position)
		return true
	else:
		return false

func GetPatrolPoint() -> bool:

	var validPoints: Array[Node3D]


	var pointParent = currentPoint.get_parent()


	if pointParent && pointParent.name == "AI":

		for point in pointParent.get_children():

			if point.is_in_group("AI_PP"):

				if point != currentPoint:

					validPoints.append(point)


	if validPoints.size() != 0:

		var patrolPoint = validPoints.pick_random()
		currentPoint = patrolPoint
		MoveToPoint(patrolPoint.global_position)
		return true
	else:
		return false

func GetHidePoint() -> bool:

	var validPoints: Array[Node3D]


	if points.size() != 0:

		for point in points:

			if point.is_in_group("AI_HP"):
				var distanceToAI = global_position.distance_to(point.global_position)
				var distantoToPriority = point.global_position.distance_to(sensor.PLocation)


				if distanceToAI < 40 && distanceToAI < distantoToPriority:

					if point != currentPoint:

						validPoints.append(point)


	if validPoints.size() != 0:

		var hidePoint = validPoints.pick_random()
		currentPoint = hidePoint
		MoveToPoint(hidePoint.global_position)
		return true
	else:
		return false

func GetCoverPoint() -> bool:

	var validPoints: Array[Node3D]


	if points.size() != 0:

		for point in points:

			if point.is_in_group("AI_CP"):
				var distanceToAI = global_position.distance_to(point.global_position)
				var distantoToPriority = point.global_position.distance_to(sensor.PLocation)


				if distanceToAI < 40 && distanceToAI < distantoToPriority:
					var direction = (sensor.PLocation - point.global_position).normalized()
					var vector = direction.dot(point.global_transform.basis.z)


					if vector < -0.8:

						if point != currentPoint:
							validPoints.append(point)


	if validPoints.size() != 0:

		var cover = validPoints.pick_random()

		currentPoint = cover

		MoveToPoint(cover.global_position)
		return true
	else:
		return false

func GetVantagePoint() -> bool:

	var validPoints: Array[Node3D]


	if points.size() != 0:

		for point in points:

			if point.is_in_group("AI_PP"):
				var distanceToAI = global_position.distance_to(point.global_position)
				var distantoToPriority = point.global_position.distance_to(sensor.PLocation)


				if distanceToAI < 40 && distanceToAI < distantoToPriority:
					var direction = (sensor.PLocation - point.global_position).normalized()
					var vector = direction.dot(point.global_transform.basis.z)


					if vector > 0.9:

						if point != currentPoint:
							validPoints.append(point)


	if validPoints.size() != 0:

		var vantage = validPoints.pick_random()

		currentPoint = vantage

		MoveToPoint(vantage.global_position)
		return true
	else:
		return false

func GetLurkPoint():

	var validPoints: Array[Node3D]


	if AISpawner.lurks.size() != 0:

		for point in AISpawner.lurks:

			if point.is_in_group("AI_LP"):

				if point != currentPoint:
					validPoints.append(point)


	if validPoints.size() != 0:

		var lurk = validPoints.pick_random()
		currentPoint = lurk
		MoveToPoint(lurk.global_position)
		return true
	else:

		var waypoint = get_tree().get_nodes_in_group("AI_SP").pick_random()
		currentPoint = waypoint
		MoveToPoint(waypoint.global_position)
		print("AI Lurk: Fallback to spawn point")
		return true

func GetLKLPoint():
	MoveToPoint(LKL.global_position)

func MoveToPoint(point: Vector3):
	var closestPosition = NavigationServer3D.map_get_closest_point(navmesh, point)
	agent.target_position = closestPosition

func ResetAnimator():

	animator["parameters/conditions/Move"] = false
	animator["parameters/conditions/Wander"] = false
	animator["parameters/conditions/Guard"] = false
	animator["parameters/conditions/Combat"] = false
	animator["parameters/conditions/Defend"] = false
	animator["parameters/conditions/Hunt"] = false
	animator["parameters/conditions/Grenade"] = false
	animator["parameters/conditions/Group"] = false

func SetAnimatorWeapon(type: String):

	if type == "Pistol":
		animator["parameters/Move/Weapon/blend_amount"] = 0.0
		animator["parameters/Wander/Weapon/blend_amount"] = 0.0
		animator["parameters/Combat/Weapon/blend_amount"] = 0.0
		animator["parameters/Defend/Weapon/blend_amount"] = 0.0
		animator["parameters/Guard/Weapon/blend_amount"] = 0.0
		animator["parameters/Hunt/Weapon/blend_amount"] = 0.0
		animator["parameters/Grenade/Weapon/blend_amount"] = 0.0
		animator["parameters/Group/Weapon/blend_amount"] = 0.0

	elif type == "Rifle":
		animator["parameters/Move/Weapon/blend_amount"] = 1.0
		animator["parameters/Wander/Weapon/blend_amount"] = 1.0
		animator["parameters/Combat/Weapon/blend_amount"] = 1.0
		animator["parameters/Defend/Weapon/blend_amount"] = 1.0
		animator["parameters/Guard/Weapon/blend_amount"] = 1.0
		animator["parameters/Hunt/Weapon/blend_amount"] = 1.0
		animator["parameters/Grenade/Weapon/blend_amount"] = 1.0
		animator["parameters/Group/Weapon/blend_amount"] = 1.0

func ReloadEnded():
	reload = false

func SetExceptions():

	for child in skeleton.get_children():

		if child.name.contains("HB"):
			fire.add_exception(child.get_child(0))



func Interact():
	pass

func UpdateTooltip():
	gameData.tooltip = nickname



func Debug(toggle: bool):

	if toggle && !dead:
		status.show()
		sensor.show()
		sensor.debug = true
		agent.debug_enabled = true

	else:
		status.hide()
		sensor.hide()
		sensor.debug = false
		agent.debug_enabled = false

func DebugRay(ray: RayCast3D, color: Color = Color.PURPLE, duration: float = 2.0) -> void :

	if !is_instance_valid(ray): return


	var startPosition: Vector3 = ray.global_position
	var endPosition: Vector3 = ray.global_transform * ray.target_position


	var meshInstance: = MeshInstance3D.new()
	var IMesh: = ImmediateMesh.new()
	var material: = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.no_depth_test = true
	IMesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	IMesh.surface_add_vertex(startPosition)
	IMesh.surface_add_vertex(endPosition)
	IMesh.surface_end()
	meshInstance.mesh = IMesh
	get_tree().root.add_child(meshInstance)


	var tween: = create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, duration)
	tween.tween_callback(meshInstance.queue_free)



func Voices(delta):

	if !is_instance_valid(activeVoice) && !variant.silent:
		voiceTimer += delta


		if voiceTimer > voiceCycle:

			if currentState == State.Wander || currentState == State.Guard || currentState == State.Patrol || currentState == State.Group:
				PlayIdle()

			elif currentState == State.Combat || currentState == State.Attack || currentState == State.Grenade:
				PlayCombat()


			voiceCycle = randf_range(10.0, 60.0)
			voiceTimer = 0.0



func PlayFootstep():

	if playerDistance > 50.0: return

	if !below.is_colliding(): return


	var surface = below.get_collider().get("surface")

	var audio = audioInstance3D.instantiate()
	add_child(audio)


	if gameData.season == 1:
		if surface == "Grass": audio.PlayInstance(audioLibrary.footstepGrass, 10, 50)
		elif surface == "Dirt": audio.PlayInstance(audioLibrary.footstepDirt, 10, 50)
		elif surface == "Wood": audio.PlayInstance(audioLibrary.footstepWood, 10, 50)
		elif surface == "Metal": audio.PlayInstance(audioLibrary.footstepMetal, 10, 50)
		elif surface == "Concrete": audio.PlayInstance(audioLibrary.footstepConcrete, 10, 50)
		elif surface == "Generic": audio.PlayInstance(audioLibrary.footstepGeneric, 10, 50)
		else: audio.PlayInstance(audioLibrary.footstepGeneric, 10, 50)
	elif gameData.season == 2:
		if surface == "Grass": audio.PlayInstance(audioLibrary.footstepSnow, 10, 50)
		elif surface == "Dirt": audio.PlayInstance(audioLibrary.footstepSnow, 10, 50)
		elif surface == "Wood": audio.PlayInstance(audioLibrary.footstepWood, 10, 50)
		elif surface == "Metal": audio.PlayInstance(audioLibrary.footstepMetal, 10, 50)
		elif surface == "Concrete": audio.PlayInstance(audioLibrary.footstepConcrete, 10, 50)
		elif surface == "Generic": audio.PlayInstance(audioLibrary.footstepGeneric, 10, 50)
		else: audio.PlayInstance(audioLibrary.footstepGeneric, 10, 50)


	audio.panning_strength = 2.0

func PlayIdle():

	if variant.idleVoices && !variant.silent:

		var audio = audioInstance3D.instantiate()
		head.add_child(audio)
		audio.PlayInstance(variant.idleVoices, 10, 100)
		activeVoice = audio

		audio.panning_strength = 2.0

func PlayCombat():

	if variant.combatVoices && !variant.silent:
		var audio = audioInstance3D.instantiate()
		head.add_child(audio)
		audio.PlayInstance(variant.combatVoices, 10, 100)
		activeVoice = audio

		audio.panning_strength = 2.0

func PlayDamage():

	if variant.damageVoices && !variant.silent:
		var audio = audioInstance3D.instantiate()
		head.add_child(audio)
		audio.PlayInstance(variant.damageVoices, 10, 100)
		activeVoice = audio

		audio.panning_strength = 2.0

func PlayDeath():

	if variant.deathVoices && !variant.silent:
		var audio = audioInstance3D.instantiate()
		head.add_child(audio)
		audio.PlayInstance(variant.deathVoices, 10, 100)
		activeVoice = audio

		audio.panning_strength = 2.0

func PlayLoot():

	if lootTarget == null: return
	var audio = audioInstance3D.instantiate()
	get_tree().get_root().add_child(audio)
	audio.global_position = lootTarget.global_position
	audio.PlayInstance(lootTarget.audioEvent, 10, 100)

	audio.panning_strength = 2.0

func PlayPickup():

	if lootTarget == null: return
	var audio = audioInstance3D.instantiate()
	get_tree().get_root().add_child(audio)
	audio.global_position = lootTarget.global_position
	audio.PlayInstance(audioLibrary.pickup, 10, 100)

	audio.panning_strength = 2.0

func PlayFire():

	var audio = audioInstance3D.instantiate()
	get_tree().get_root().add_child(audio)
	audio.global_position = muzzle.global_position


	if suppressed:
		audio.PlayInstance(weaponData.fireSuppressed, 50, 400)

	elif weaponData.weaponAction == "Semi-Auto" && fullAuto:
		audio.PlayInstance(weaponData.fireAuto, 50, 400)

	else:
		audio.PlayInstance(weaponData.fireSemi, 50, 400)


	audio.panning_strength = 2.0

func PlayReload():

	if weaponType == "Pistol":
		var audio = audioInstance3D.instantiate()
		head.add_child(audio)
		audio.PlayInstance(audioLibrary.reloadPistol, 10, 100)

		audio.panning_strength = 2.0

	elif weaponType == "Rifle":
		var audio = audioInstance3D.instantiate()
		head.add_child(audio)
		audio.PlayInstance(audioLibrary.reloadRifle, 10, 100)

		audio.panning_strength = 2.0

func PlayTail():

	var audio = audioInstance3D.instantiate()
	get_tree().get_root().add_child(audio)
	audio.global_position = muzzle.global_position


	if suppressed:
		if indoor && weaponData.tailIndoorSuppressed:
			audio.PlayInstance(weaponData.tailIndoorSuppressed, 100, 400)
		elif weaponData.tailOutdoorSuppressed:
			audio.PlayInstance(weaponData.tailOutdoorSuppressed, 100, 400)

	else:
		if indoor && weaponData.tailIndoor:
			audio.PlayInstance(weaponData.tailIndoor, 100, 400)
		elif weaponData.tailOutdoor:
			audio.PlayInstance(weaponData.tailOutdoor, 100, 400)


	audio.panning_strength = 2.0

func PlayCrack():
	if randi_range(0, 1) == 0: return
	var audio = audioInstance3D.instantiate()
	get_tree().get_root().add_child(audio)
	audio.global_position = muzzle.global_position
	audio.PlayInstance(audioLibrary.bulletCrack, 100, 600)


	audio.panning_strength = 2.0

func PlayFlyby():
	if randi_range(0, 1) == 0: return
	var audio = audioInstance2D.instantiate()
	add_child(audio)
	audio.PlayInstance(audioLibrary.bulletFlyby)
