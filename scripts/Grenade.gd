extends RigidBody3D


var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")
var audioInstance3D = preload("res://Resources/AudioInstance3D.tscn")
var grenadeExplosion = preload("res://Effects/Explosion.tscn")
var grenadeSmoke = preload("res://Effects/Grenade_Smoke.tscn")


const hitConcrete = preload("res://Audio/Equipment/Grenades/Grenade_Hit_Concrete.tres")
const hitDirt = preload("res://Audio/Equipment/Grenades/Grenade_Hit_Dirt.tres")
const hitGrass = preload("res://Audio/Equipment/Grenades/Grenade_Hit_Grass.tres")
const hitMetal = preload("res://Audio/Equipment/Grenades/Grenade_Hit_Metal.tres")
const hitWood = preload("res://Audio/Equipment/Grenades/Grenade_Hit_Wood.tres")


@export var frag = false
@export var smoke = false


var handle = null
var identifier = null


var fuseTime = 3.0
var fuseTimer = 0.0

func _ready():

	body_entered.connect(self.Collided)
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 1

func _physics_process(delta):
	fuseTimer += delta

	if fuseTimer > fuseTime:
		Detonate()



func Detonate():

	if frag:
		var effect = grenadeExplosion.instantiate()
		get_tree().get_root().add_child(effect)
		effect.position = global_position + Vector3(0, 0.5, 0)
		effect.identifier = identifier
		effect.Explode()


	if smoke:
		var effect = grenadeSmoke.instantiate()
		get_tree().get_root().add_child(effect)
		effect.position = global_position
		effect.Emit()


	if handle: handle.queue_free()
	queue_free()

func Collided(body: Node3D):

	body_entered.disconnect(self.Collided)


	var surface = body.get("surface")
	PlayHit(surface)



func PlayHit(surface):

	var audio = audioInstance3D.instantiate()
	add_child(audio)


	if surface == "Grass": audio.PlayInstance(hitGrass, 10, 50)
	elif surface == "Dirt": audio.PlayInstance(hitDirt, 10, 50)
	elif surface == "Wood": audio.PlayInstance(hitWood, 10, 50)
	elif surface == "Metal": audio.PlayInstance(hitMetal, 10, 50)
	else: audio.PlayInstance(hitConcrete, 10, 50)
