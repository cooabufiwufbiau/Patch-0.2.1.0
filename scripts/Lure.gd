extends RigidBody3D
class_name Lure


var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")
var audioInstance3D = preload("res://Resources/AudioInstance3D.tscn")


const hitGeneric = preload("res://Audio/Equipment/Fishing/Lure_Hit_Generic.tres")
const hitWater = preload("res://Audio/Equipment/Fishing/Lure_Hit_Water.tres")

var hooked = false
var collided = false

func ConnectHit():
	collided = false
	body_entered.connect(self.Collided)
	set_collision_mask_value(29, true)

func Collided(body: Node3D):

	collided = true


	body_entered.disconnect(self.Collided)


	var surface = body.get("surface")
	PlayHit(surface)


	if surface == "Water":
		set_collision_mask_value(29, false)



func PlayHit(surface):
	if surface == "Water":
		var audio = audioInstance3D.instantiate()
		add_child(audio)
		audio.PlayInstance(hitWater, 20, 100)
	else:
		var audio = audioInstance3D.instantiate()
		add_child(audio)
		audio.PlayInstance(hitGeneric, 20, 100)
