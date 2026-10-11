@tool
extends Skeleton3D

@export var boneName: String = ""
@export var findBone: bool = false: set = ExecuteFindBone

func ExecuteFindBone(_value: bool) -> void :

	if !Engine.is_editor_hint() || !is_inside_tree() || !_value:
		return


	var boneID: int = find_bone(boneName)


	if boneID != -1: print_rich("[color=green] Found Bone:[/color] '%s' -> [b]ID: %d[/b]" % [boneName, boneID])
	else: print_rich("[color=yellow] Bone Not Found:[/color] Could not find '%s' in skeleton." % boneName)


	findBone = false
