@tool
class_name ImpulseModifier
extends SkeletonModifier3D

@export var boneID = 11
@export var aimBoneID = 12
@export var speed = 10.0
@export var recovery = 10.0
@export var recoilAngle = -10.0
@export var damageAngle = -20.0
@export var damageDirection = Vector3.BACK

@export_group("Triggers")
@export var recoil: bool = false:
	set(value):
		if value:
			RecoilImpulse(recoilAngle)
			recoil = false
@export var damage: bool = false:
	set(value):
		if value:
			DamageImpulse(damageDirection)
			damage = false


var targetRotationOffset = Quaternion.IDENTITY
var currentRotationOffset = Quaternion.IDENTITY
var boneRotation = Quaternion.IDENTITY
var aimBoneRotation = Quaternion.IDENTITY

func _process(delta: float) -> void :
	if !active: return
	currentRotationOffset = currentRotationOffset.slerp(targetRotationOffset, speed * delta)
	targetRotationOffset = targetRotationOffset.slerp(Quaternion.IDENTITY, recovery * delta)

func _process_modification() -> void :

	if influence <= 0.0 || boneID < 0: return


	var skeleton: Skeleton3D = get_skeleton()
	if !skeleton: return


	boneRotation = skeleton.get_bone_pose_rotation(boneID)
	aimBoneRotation = skeleton.get_bone_pose_rotation(aimBoneID)


	var finalRotation: Quaternion = boneRotation * currentRotationOffset
	if influence < 1.0: finalRotation = boneRotation.slerp(finalRotation, influence)
	skeleton.set_bone_pose_rotation(boneID, finalRotation.normalized())

func RecoilImpulse(angle: float) -> void :

	var aimAxis: Vector3 = aimBoneRotation * Vector3.RIGHT
	var recoilAxis: Vector3 = boneRotation.inverse() * aimAxis
	var recoilRotation: = Quaternion(recoilAxis.normalized(), deg_to_rad(angle))
	targetRotationOffset = targetRotationOffset * recoilRotation

func DamageImpulse(direction: Vector3) -> void :

	var skeleton: Skeleton3D = get_skeleton()


	var localDirection = skeleton.global_transform.basis.inverse() * direction.normalized()
	var damageAxis: Vector3 = localDirection.normalized().cross(Vector3.UP)
	var damageRotation: = Quaternion(damageAxis.normalized(), deg_to_rad(damageAngle))
	targetRotationOffset = targetRotationOffset * damageRotation
