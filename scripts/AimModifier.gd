@tool
class_name AimModifier
extends SkeletonModifier3D

@export var target: Node3D
@export var boneID = 12
@export var offset: Vector3

@export_group("Pistol")
@export var pistolDefend: Vector3
@export var pistolCombatF: Vector3
@export var pistolCombatB: Vector3
@export var pistolHuntF: Vector3
@export var pistolHuntB: Vector3
@export var pistolAttackF: Vector3
@export var pistolAttackB: Vector3

@export_group("Rifle")
@export var rifleDefend: Vector3
@export var rifleCombatF: Vector3
@export var rifleCombatB: Vector3
@export var rifleHuntF: Vector3
@export var rifleHuntB: Vector3
@export var rifleAttackF: Vector3
@export var rifleAttackB: Vector3

func _process_modification() -> void :

	if !target or influence <= 0.0 or boneID < 0: return


	var skeleton: Skeleton3D = get_skeleton()
	if !skeleton: return


	var skeletonLocal: Transform3D = skeleton.global_transform.affine_inverse()
	var localTargetPosition: Vector3 = skeletonLocal * target.global_position
	var spinePosition: Vector3 = skeleton.get_bone_global_pose(boneID).origin
	var aimDirection: Vector3 = (spinePosition - localTargetPosition).normalized()


	var aimBasis: Basis = Basis.looking_at(aimDirection, skeletonLocal.basis * Vector3.UP)
	var offsetRadians: Vector3 = Vector3(deg_to_rad(offset.x), deg_to_rad(offset.y), deg_to_rad(offset.z))
	var finalBasis: Basis = aimBasis * Basis.from_euler(offsetRadians)
	var targetRotation: Quaternion = finalBasis.get_rotation_quaternion()


	var currentRotation: Quaternion = skeleton.get_bone_pose_rotation(boneID)
	if influence < 1.0: targetRotation = currentRotation.slerp(targetRotation, influence)
	skeleton.set_bone_pose_rotation(boneID, targetRotation.normalized())
