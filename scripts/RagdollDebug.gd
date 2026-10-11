extends Skeleton3D


var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance3D = preload("res://Resources/AudioInstance3D.tscn")

@export_group("Debug Testing Keys")
@export var trigger_key: Key = KEY_F5
@export var reset_key: Key = KEY_F6

@export_group("Ragdoll Setup")
@export var hitBone: PhysicalBone3D
@export var impulse_force: Vector3 = Vector3(0, 0, -10)
@export var torque_twist: float = 10.0


var _initial_bone_poses: Array[Transform3D] = []
var _initial_physical_transforms: Dictionary = {}
var _animation_player: AnimationPlayer
var _last_playing_anim: String = ""
var _last_anim_position: float = 0.0
var _is_ragdoll: bool = false


var _ui_canvas: CanvasLayer
var _anim_dropdown: OptionButton
var _hitbone_dropdown: OptionButton
var _physical_bone_map: Array[PhysicalBone3D] = []

func _ready() -> void :
	if Loader and Loader.has_method("FadeOut"):
		Loader.FadeOut()

	_cache_initial_transforms()
	_find_animation_player()
	deactivate_bones()

	_setup_debug_ui()



func _setup_debug_ui() -> void :
	_ui_canvas = CanvasLayer.new()
	_ui_canvas.layer = 100
	add_child(_ui_canvas)

	var panel = PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(280, 0)
	_ui_canvas.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)


	var title = Label.new()
	title.text = "Ragdoll Debug Panel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	main_vbox.add_child(HSeparator.new())


	var bone_label = Label.new()
	bone_label.text = "Target Hit Bone:"
	main_vbox.add_child(bone_label)

	_hitbone_dropdown = OptionButton.new()
	main_vbox.add_child(_hitbone_dropdown)

	_populate_hit_bones()
	_hitbone_dropdown.item_selected.connect(_on_hit_bone_selected)

	main_vbox.add_child(HSeparator.new())


	var force_label = Label.new()
	force_label.text = "Impulse Force Vector:"
	main_vbox.add_child(force_label)

	var axes = ["X", "Y", "Z"]
	var initial_vals = [impulse_force.x, impulse_force.y, impulse_force.z]

	for i in range(3):
		var axis_hbox = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = axes[i] + ":"
		lbl.custom_minimum_size = Vector2(20, 0)

		var spin = SpinBox.new()
		spin.min_value = -100.0
		spin.max_value = 100.0
		spin.step = 0.5
		spin.value = initial_vals[i]
		spin.custom_minimum_size = Vector2(160, 0)

		var axis_index = i
		spin.value_changed.connect( func(val: float):
			impulse_force[axis_index] = val
		)

		axis_hbox.add_child(lbl)
		axis_hbox.add_child(spin)
		main_vbox.add_child(axis_hbox)


	var twist_hbox = HBoxContainer.new()
	var twist_lbl = Label.new()
	twist_lbl.text = "Torque Twist:"
	twist_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var twist_spin = SpinBox.new()
	twist_spin.min_value = 0.0
	twist_spin.max_value = 100.0
	twist_spin.step = 0.5
	twist_spin.value = torque_twist
	twist_spin.custom_minimum_size = Vector2(160, 0)
	twist_spin.value_changed.connect( func(val: float):
		torque_twist = val
	)

	twist_hbox.add_child(twist_lbl)
	twist_hbox.add_child(twist_spin)
	main_vbox.add_child(twist_hbox)

	main_vbox.add_child(HSeparator.new())


	var anim_label = Label.new()
	anim_label.text = "Animation:"
	main_vbox.add_child(anim_label)

	_anim_dropdown = OptionButton.new()
	main_vbox.add_child(_anim_dropdown)

	_populate_animations()
	_anim_dropdown.item_selected.connect(_on_animation_selected)

	main_vbox.add_child(HSeparator.new())


	var btn_hbox = HBoxContainer.new()
	var trig_btn = Button.new()
	trig_btn.text = "Trigger (F5)"
	trig_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trig_btn.pressed.connect( func():
		if not _is_ragdoll:
			activate_ragdoll()
	)

	var reset_btn = Button.new()
	reset_btn.text = "Reset (F6)"
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.pressed.connect( func():
		if _is_ragdoll:
			reset_ragdoll()
	)

	btn_hbox.add_child(trig_btn)
	btn_hbox.add_child(reset_btn)
	main_vbox.add_child(btn_hbox)

func _populate_hit_bones() -> void :
	_hitbone_dropdown.clear()
	_physical_bone_map.clear()

	for child in get_children():
		if child is PhysicalBone3D:
			_physical_bone_map.append(child)

	if _physical_bone_map.is_empty():
		_hitbone_dropdown.add_item("No PhysicalBone3D found")
		_hitbone_dropdown.disabled = true
		return

	var selected_index = 0
	for i in range(_physical_bone_map.size()):
		var p_bone = _physical_bone_map[i]
		var bone_name = p_bone.name

		_hitbone_dropdown.add_item(bone_name, i)

		if hitBone and hitBone == p_bone:
			selected_index = i

	_hitbone_dropdown.select(selected_index)
	_on_hit_bone_selected(selected_index)

func _on_hit_bone_selected(index: int) -> void :
	if index >= 0 and index < _physical_bone_map.size():
		hitBone = _physical_bone_map[index]

func _populate_animations() -> void :
	if not _animation_player:
		_anim_dropdown.add_item("No AnimationPlayer Found")
		_anim_dropdown.disabled = true
		return

	var anim_list = _animation_player.get_animation_list()
	if anim_list.is_empty():
		_anim_dropdown.add_item("No Animations Found")
		_anim_dropdown.disabled = true
		return

	_anim_dropdown.clear()
	_anim_dropdown.add_item("-- None (T-Pose) --", 0)

	for i in range(anim_list.size()):
		_anim_dropdown.add_item(anim_list[i], i + 1)

	_anim_dropdown.select(0)

func _on_animation_selected(index: int) -> void :
	if index == 0 or not _animation_player:
		_last_playing_anim = ""
		_last_anim_position = 0.0
		if _animation_player and _animation_player.is_playing():
			_animation_player.stop()
		return

	var anim_name = _anim_dropdown.get_item_text(index)
	_last_playing_anim = anim_name
	_last_anim_position = 0.0

	if not _is_ragdoll and _animation_player:
		_animation_player.play(anim_name)



func _cache_initial_transforms() -> void :
	_initial_bone_poses.clear()
	_initial_physical_transforms.clear()

	for i in get_bone_count():
		_initial_bone_poses.append(get_bone_pose(i))

	for child in get_children():
		if child is PhysicalBone3D:
			_initial_physical_transforms[child] = child.transform

func _find_animation_player() -> void :
	var parent = get_parent()
	if parent:
		_animation_player = parent.get_node_or_null("Animations") as AnimationPlayer
		if not _animation_player and parent.get_parent():
			_animation_player = parent.get_parent().get_node_or_null("Animations") as AnimationPlayer

func activate_ragdoll() -> void :
	_is_ragdoll = true


	if _animation_player and _animation_player.is_playing():
		_last_playing_anim = _animation_player.current_animation
		_last_anim_position = _animation_player.current_animation_position
		_animation_player.stop()


	for child in get_children():
		if child is PhysicalBone3D:
			child.axis_lock_linear_x = false
			child.axis_lock_linear_y = false
			child.axis_lock_linear_z = false
			child.axis_lock_angular_x = false
			child.axis_lock_angular_y = false
			child.axis_lock_angular_z = false

			if child.get_child_count() > 0 and child.get_child(0) is CollisionShape3D:
				child.get_child(0).disabled = false


	physical_bones_start_simulation()


	if hitBone:
		hitBone.apply_central_impulse(impulse_force)

		if torque_twist > 0.0:
			var random_twist = Vector3(
				randf_range(-1.0, 1.0), 
				randf_range(-1.0, 1.0), 
				randf_range(-1.0, 1.0)
			).normalized() * torque_twist


			hitBone.angular_velocity = random_twist


		await get_tree().create_timer(0.5, false).timeout;
		PlayRagdoll()

func reset_ragdoll() -> void :
	_is_ragdoll = false

	deactivate_bones()


	for child in get_children():
		if child is PhysicalBone3D:
			child.linear_velocity = Vector3.ZERO
			child.angular_velocity = Vector3.ZERO
			if _initial_physical_transforms.has(child):
				child.transform = _initial_physical_transforms[child]


	for i in get_bone_count():
		if i < _initial_bone_poses.size():
			var transform_data: Transform3D = _initial_bone_poses[i]
			set_bone_pose_position(i, transform_data.origin)
			set_bone_pose_rotation(i, transform_data.basis.get_rotation_quaternion())
			set_bone_pose_scale(i, transform_data.basis.get_scale())


	if _animation_player and not _last_playing_anim.is_empty():
		_animation_player.play(_last_playing_anim)
		_animation_player.seek(_last_anim_position, true)

func deactivate_bones() -> void :
	physical_bones_stop_simulation()

	for child in get_children():
		if child is PhysicalBone3D:
			child.axis_lock_linear_x = true
			child.axis_lock_linear_y = true
			child.axis_lock_linear_z = true
			child.axis_lock_angular_x = true
			child.axis_lock_angular_y = true
			child.axis_lock_angular_z = true

			if child.get_child_count() > 0 and child.get_child(0) is CollisionShape3D:
				child.get_child(0).disabled = true

func PlayRagdoll():
	var ragdoll = audioInstance3D.instantiate()
	hitBone.add_child(ragdoll)
	ragdoll.PlayInstance(audioLibrary.ragdoll, 5, 100)
