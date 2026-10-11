extends Node3D


var gameData = preload("res://Resources/GameData.tres")
var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")
var audioInstance3D = preload("res://Resources/AudioInstance3D.tscn")


@onready var particles = $Particles
@onready var light = $Light
@onready var area: Area3D = $Area
@onready var detector: Area3D = $Detector
@onready var alert: Area3D = $Alert
@onready var LOS = $LOS


var size = 10.0
var indoor = false
var identifier = null

func Explode():

	await get_tree().create_timer(0.1, false).timeout


	particles.draw_pass_1.size = Vector2(size, size)


	Emit()
	Light()


	CheckIndoor()
	CheckID()

	PlayExplosion()


	await get_tree().create_timer(1.0, false).timeout
	queue_free()



func Emit():
	particles = get_child(0)
	particles.one_shot = true
	particles.emitting = true

func Light():
	light.omni_range = 10
	light.light_energy = 20
	await get_tree().create_timer(0.1, false).timeout
	light.omni_range = 0.0



func CheckIndoor():

	var areas = detector.get_overlapping_areas()


	if areas.size() > 0:
		for target in areas:

			if target is Area && target.type == "Indoor":
				indoor = true

func CheckID():

	var areas = area.get_overlapping_areas()


	if areas.size() > 0:
		for target in areas:

			if target is Area && target.type == "ID":
				CheckLOS(target)

func CheckLOS(target):

	LOS.look_at(target.global_position, Vector3.UP, true)
	LOS.force_raycast_update()


	if LOS.is_colliding():

		if target.is_in_group("AI") || target.is_in_group("Nomad"):
			target.owner.ExplosionDamage(LOS.global_basis.z, identifier)

		if LOS.get_collider().is_in_group("Player"):
			var character = get_tree().current_scene.get_node("/root/Map/Core/Controller/Character")
			character.ExplosionDamage()

func CheckAlert():

	var bodies = area.get_overlapping_bodies()


	if bodies.size() > 0:

		for target in bodies:

			if LOS.get_collider().is_in_group("AI") || LOS.get_collider().is_in_group("Nomad"):
				target.lastKnownLocation = global_position
				target.Decision()

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



func PlayExplosion():

	var audio = audioInstance3D.instantiate()
	get_tree().get_root().add_child(audio)
	audio.position = global_position


	var distance = global_position.distance_to(gameData.playerPosition)


	if distance < 10:
		if indoor:
			PlayTinnitus()
			audio.PlayInstance(audioLibrary.explosionIndoorClose, 50, 400)
		else:
			PlayTinnitus()
			audio.PlayInstance(audioLibrary.explosionOutdoorClose, 50, 400)

	elif distance < 50:
		if indoor:
			audio.PlayInstance(audioLibrary.explosionIndoorNear, 50, 400)
		else:
			audio.PlayInstance(audioLibrary.explosionOutdoorNear, 50, 400)

	else:
		if indoor:
			audio.PlayInstance(audioLibrary.explosionIndoorFar, 50, 200)
		else:
			audio.PlayInstance(audioLibrary.explosionOutdoorFar, 50, 200)

func PlayTinnitus():

	var audio = audioInstance2D.instantiate()
	get_tree().get_root().add_child(audio)
	audio.PlayInstance(audioLibrary.explosionTinnitus)
