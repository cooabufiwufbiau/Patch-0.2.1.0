extends Resource
class_name AudioLibrary



@export_group("Character")

@export_subgroup("Common")
@export var transition: AudioEvent
@export var death: AudioEvent
@export var vostok: AudioEvent
@export var teleport: AudioEvent
@export var furniture: AudioEvent
@export var sleep: AudioEvent

@export_subgroup("Conditions")
@export var indicator: AudioEvent
@export var bleeding: AudioEvent
@export var burn: AudioEvent
@export var poisoning: AudioEvent
@export var dehydration: AudioEvent
@export var fracture: AudioEvent
@export var frostbite: AudioEvent
@export var insanity: AudioEvent
@export var overweight: AudioEvent
@export var rupture: AudioEvent
@export var headshot: AudioEvent
@export var starvation: AudioEvent

@export_subgroup("Footsteps")
@export var footstepConcrete: AudioEvent
@export var footstepConcreteLand: AudioEvent
@export var footstepDirt: AudioEvent
@export var footstepDirtLand: AudioEvent
@export var footstepGeneric: AudioEvent
@export var footstepGenericLand: AudioEvent
@export var footstepGrass: AudioEvent
@export var footstepGrassLand: AudioEvent
@export var footstepMetal: AudioEvent
@export var footstepMetalLand: AudioEvent
@export var footstepSnow: AudioEvent
@export var footstepSnowLand: AudioEvent
@export var footstepWater: AudioEvent
@export var footstepWaterLand: AudioEvent
@export var footstepWood: AudioEvent
@export var footstepWoodLand: AudioEvent
@export var footstepRazor: AudioEvent

@export_subgroup("Handling")
@export var equip: AudioEvent
@export var unequip: AudioEvent
@export var semi: AudioEvent
@export var auto: AudioEvent
@export var gadget: AudioEvent
@export var inspectEnd: AudioEvent
@export var inspectRotate: AudioEvent
@export var inspectStart: AudioEvent

@export_subgroup("Impacts")
@export var impact: AudioEvent
@export var impactArmor: AudioEvent
@export var impactArmorBreak: AudioEvent
@export var damage: AudioEvent

@export_subgroup("Movement")
@export var movementCloth: AudioEvent
@export var movementGear: AudioEvent



@export_group("Effects")

@export_subgroup("Bullets")
@export var bulletCrack: AudioEvent
@export var bulletFlyby: AudioEvent

@export_subgroup("Casing")
@export var casingHard: AudioEvent
@export var casingSoft: AudioEvent
@export var casingWood: AudioEvent
@export var shellHard: AudioEvent
@export var shellSoft: AudioEvent

@export_subgroup("Explosions")
@export var explosionIndoorNear: AudioEvent
@export var explosionIndoorClose: AudioEvent
@export var explosionIndoorFar: AudioEvent
@export var explosionOutdoorNear: AudioEvent
@export var explosionOutdoorClose: AudioEvent
@export var explosionOutdoorFar: AudioEvent
@export var explosionTinnitus: AudioEvent

@export_subgroup("Hits")
@export var hitGrass: AudioEvent
@export var hitDirt: AudioEvent
@export var hitConcrete: AudioEvent
@export var hitMetal: AudioEvent
@export var hitWood: AudioEvent
@export var hitGeneric: AudioEvent
@export var hitSnow: AudioEvent
@export var hitWater: AudioEvent
@export var knifeHitSoft: AudioEvent
@export var knifeHitHard: AudioEvent
@export var knifeHitMetal: AudioEvent
@export var knifeHitWood: AudioEvent
@export var knifeHitFleshSlash: AudioEvent
@export var knifeHitFleshStab: AudioEvent

@export_subgroup("Malfunctions")
@export var malfunction: AudioEvent
@export var malfunctionClearPistol: AudioEvent
@export var malfunctionClearRifle: AudioEvent

@export_subgroup("Water")
@export var swimSubmerged: AudioEvent
@export var swimSurface: AudioEvent
@export var waterDive: AudioEvent
@export var waterGasp: AudioEvent
@export var waterSurface: AudioEvent



@export_group("Interaction")
@export var unlock: AudioEvent
@export var extinguish: AudioEvent
@export var ignite: AudioEvent
@export var pickup: AudioEvent
@export var radio: AudioEvent
@export var switch: AudioEvent



@export_group("NPC")
@export var ragdoll: AudioEvent
@export var reloadPistol: AudioEvent
@export var reloadRifle: AudioEvent



@export_group("UI")
@export var UIArmor: AudioEvent
@export var UIAttach: AudioEvent
@export var UICasettePlay: AudioEvent
@export var UICasetteStop: AudioEvent
@export var UIClick: AudioEvent
@export var UIDrop: AudioEvent
@export var UIEquip: AudioEvent
@export var UIUnequip: AudioEvent
@export var UIError: AudioEvent
@export var UILoad: AudioEvent
@export var UIStack: AudioEvent
@export var UITraderClose: AudioEvent
@export var UITraderOpen: AudioEvent
@export var UITraderReset: AudioEvent
@export var UITraderTask: AudioEvent
@export var UITraderTrade: AudioEvent
