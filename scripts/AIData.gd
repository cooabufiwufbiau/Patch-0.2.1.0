extends Resource
class_name AIData

enum Faction{Nomad, Bandit, Guard, Military, Boss}
@export var faction = Faction.Nomad
@export var mesh: Mesh
@export var materials: Array[Material]

@export_group("Parameters")
@export var name: String
@export var health: float = 100.0
@export var accuracy: Vector3 = Vector3(0.1, 0.5, 1.0)
@export var fullCondition: bool = false
@export var fullMagazine: bool = false
@export var forceAttachment: bool = false

@export_group("Details")
@export var nicknames: Array[String]

@export_group("Voices")
@export var silent: bool
@export var idleVoices: AudioEvent
@export var combatVoices: AudioEvent
@export var damageVoices: AudioEvent
@export var deathVoices: AudioEvent
