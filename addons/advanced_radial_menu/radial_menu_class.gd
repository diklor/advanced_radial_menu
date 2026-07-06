@tool
@icon('icon.svg')
class_name RadialMenuAdvanced extends Control

signal slot_selected(slot: Control, index: int)
signal selection_changed(new_selection: int)
signal selection_canceled




enum StrokeType { OUTLINE, INNER, OUTER }

const _ANGLE_OFFSET: float = PI / 2.0
const _OUT_OF_BOUNDS := Vector2(-9999.0, -9999.0)

## The action used to confirm selection
@export var select_action_name: StringName = &'fire'
## Select when action is released instead of pressed
@export var action_released := false

## Enables or disables the radial menu processing
@export var enabled := true: set = _set_enabled

## Automatic size based on this control size
@export var auto_sizing := true
## Is mouse hover and selection enabled. Works only when "Enabled" is true
@export var mouse_enabled := true: set = _set_mouse_enabled
## Does circle segments hover work when the mouse is outside the radius
@export var keep_selection_outside := true
## First child will be placed in the center
@export var first_in_center := false:	set = _set_first_in_center
## If true, sets "enabled" to false after a selection is made
@export var one_shot := false
## Rotates the starting position of the slots
@export var slots_offset: int = 0

@export_group('Controller')
## Controller works only when running the game
@export var controller_enabled := false
## Hold or press this action to enable controller. Leave empty to always work
@export var focus_action_name: StringName = &''
## Hold "focus_action_name" or just toggle. Works only if "focus_action_name" is not empty
@export var focus_action_hold_mode := true
@export var move_forward_action_name: StringName = &'move_forward'
@export var move_left_action_name: StringName = &'move_left'
@export var move_back_action_name: StringName = &'move_back'
@export var move_right_action_name: StringName = &'move_right'
## Select center element by pressing action (Works only if "first_in_center" is enabled)
@export var center_element_action_name: StringName = &''
## Deadzone for the controller stick
@export_range(0.0, 1.0, 0.01) var controller_deadzone: float = 0.2

@export_group('Base Circle')
## Offset of the entire radial menu from the center
@export var circle_offset := Vector2.ZERO
@export var color := Color(0, 0, 0, 0.3)
@export_range(0, 1024, 1) var circle_radius: int = 384
## Radius will dynamically be [code]viewport_size.y / 2.5[/code]
@export_tool_button('Set auto radius') var _set_auto_radius: Callable = func() -> void:
	circle_radius = get_viewport().get_visible_rect().size.y / 2.5
	queue_redraw()

@export_group('Arc', 'arc_')
@export var arc_color := Color.WHITE
@export_range(0, 1024) var arc_inner_radius: float = 32.0
@export_range(-TAU, TAU * 2.0) var arc_start_angle: float = TAU
@export_range(-TAU * 2.0, TAU) var arc_end_angle: float = 0.0
@export_range(2, 64) var arc_detail: int = 32
@export_range(1, 512) var arc_line_width: int = 6
@export var arc_antialiased := true

@export_group('Line', 'line_')
@export var line_rotation_offset_default: int = 0
@export var line_color := Color.WHITE
@export_range(1, 256) var line_width: int = 6
@export var line_antialiased := true

@export_group('Children', 'children_')
@export_range(1, 1024, 1) var children_size: int = 256
## If enabled, children [member Control.scale] will be changed instead of [member Control.size]
@export var children_size_as_scale := false
## Automatically resize children based on [member RadialMenuAdvanced.size]
@export var children_auto_sizing := false
@export_range(0, 2, 0.1) var children_auto_sizing_factor: float = 1.0
@export var children_distance_offset: float = 0.0
@export var children_offset := Vector2.ZERO
## Rotate children relative to their circular position
@export var children_rotate := false: set = _set_children_rotate
## Invert rotation relative to circular position (not towards, but away from center)
@export var children_rotate_inverted := false

@export_group('Hover')
@export var hover_color := Color(1, 1, 1, 0.2)
@export_range(-1024, 1024, 1) var hover_offset_start: int = 0
@export_range(-1024, 1024, 1) var hover_offset_end: int = 0
@export_range(-10, 10, 0.1) var hover_size_factor: float = 1.0
@export_range(2, 1024, 1) var hover_detail: int = 96
@export var hover_offset := Vector2.ZERO
@export_range(-10, 10) var hover_children_radial_offset: float = 0.0

@export_group('Stroke', 'stroke_')
@export var stroke_enabled := false
@export var stroke_color := Color.WHITE
@export var stroke_type: StrokeType = StrokeType.OUTER
@export_range(0, 1024) var stroke_width: int = 6

@export_group('Animated Pulse', 'animated_pulse_')
@export var animated_pulse_enabled := false
@export_range(-250, 256, 1) var animated_pulse_intensity: int = 5
@export_range(-250, 256, 1) var animated_pulse_offset: int = 0
@export_range(-56, 56, 1) var animated_pulse_speed: int = 10
@export var animated_pulse_color := Color.WHITE


var _current_selection_idx: int = -2 # 0+ = child index, -1 = center, -2 = none
var _children_list: Array[Control] = []
var _local_children_count: int = 0
var _time_tick: float = 0.0

var _current_menu_radius: float = 0.0
var _current_menu_offset := Vector2.ZERO
var _global_angle_offset: float = 0.0

var _temporary_selection: int = -2
var _is_focus_action_pressed := false



# ========================================= PUBLIC ========================================= #

func set_temporary_selection(value: int = -2) -> void:
	_temporary_selection = value
	selection_changed.emit(clampi(_temporary_selection, -1, _local_children_count - 1))

func force_update() -> void:
	_update_children()

func get_selected_child() -> Control:
	if _current_selection_idx == -2:
		return null
	var list_idx: int = _current_selection_idx + (1 if first_in_center else 0)
	if list_idx >= 0 and list_idx < _children_list.size():
		return _children_list[list_idx]
	return null

func select() -> void:
	if _current_selection_idx == -2:
		selection_canceled.emit()
		return
	
	var selected_child: Control = get_selected_child()
	if selected_child:
		slot_selected.emit(selected_child, _current_selection_idx)
		
	if one_shot:
		enabled = false
	_current_selection_idx = -2

# ========================================================================================= #



func _set_enabled(value: bool) -> void:
	enabled = value
	set_process(value)
	set_process_input(value)
	if not value:
		_current_selection_idx = -2
	_reset_children_rotation()
	_update_children()
	queue_redraw()

func _set_first_in_center(value: bool) -> void:
	first_in_center = value
	_reset_children_rotation()
	_update_children()

func _set_mouse_enabled(value: bool) -> void:
	mouse_enabled = value
	if not value:
		_current_selection_idx = -2

func _set_children_rotate(value: bool) -> void:
	children_rotate = value
	if not value:
		_reset_children_rotation()

func _ready() -> void:
	child_entered_tree.connect(_update_children.unbind(1))
	child_order_changed.connect(_update_children)
	child_exiting_tree.connect(func(_node: Node): _update_children.call_deferred())
	visibility_changed.connect(_update_children)
	_update_children()

func _update_children() -> void:
	_children_list.clear()
	
	for node: Node in get_children():
		if (node is Control) and node.visible:
			_children_list.append(node)
	
	_local_children_count = _children_list.size()
	if first_in_center and _local_children_count > 0:
		_local_children_count -= 1
	
	# _arrange_children()
	queue_redraw()

func _reset_children_rotation() -> void:
	for child: Node in _children_list:
		child.rotation = 0.0

func _get_stroke_radius_offset(width: float, type: StrokeType) -> float:
	match type:
		StrokeType.INNER: return -width / 2.0
		StrokeType.OUTER: return width / 2.0
		_: return 0.0 # OUTLINE

func _process(_delta: float) -> void:
	if not enabled:
		return
	
	if animated_pulse_enabled:
		_time_tick += _delta
	
	_current_menu_offset = size / 2.0 + circle_offset
	
	if auto_sizing:
		_current_menu_radius = minf(size.x, size.y) / 2.0
	else:
		_current_menu_radius = circle_radius
		
	var segment_angle: float = TAU / float(_local_children_count) if _local_children_count > 0 else TAU
	_global_angle_offset = deg_to_rad(line_rotation_offset_default) + (slots_offset * segment_angle)
	
	if _temporary_selection != -2:
		_current_selection_idx = clampi(_temporary_selection, -1, _local_children_count - 1)
		_arrange_children()
		queue_redraw()
		return
	
	var local_input_pos: Vector2 = _OUT_OF_BOUNDS
	var is_controller_active := false
	
	if mouse_enabled:
		local_input_pos = get_local_mouse_position() - _current_menu_offset
	
	if controller_enabled and not Engine.is_editor_hint():
		var controller_pos: Vector2 = _get_controller_simulated_pos()
		is_controller_active = controller_pos != _OUT_OF_BOUNDS
		
		if is_controller_active:
			local_input_pos = controller_pos
		elif not mouse_enabled:
			if _current_selection_idx != -2:
				_current_selection_idx = -2
				
	var prev_selection: int = _current_selection_idx
	var input_radius: float = local_input_pos.length()
	
	if local_input_pos != _OUT_OF_BOUNDS:
		if input_radius < arc_inner_radius:
			_current_selection_idx = -1 if first_in_center else -2
		elif _local_children_count == 1 and not first_in_center:
			_current_selection_idx = 0 if input_radius < _current_menu_radius else -2
		else:
			if _local_children_count > 0 and (keep_selection_outside or input_radius <= _current_menu_radius):
				var input_angle: float = fposmod(local_input_pos.angle() + _ANGLE_OFFSET - _global_angle_offset, TAU)
				_current_selection_idx = int(input_angle / segment_angle) % _local_children_count
			else:
				_current_selection_idx = -2
			
		if is_controller_active and not center_element_action_name.is_empty() and Input.is_action_just_pressed(center_element_action_name):
			_current_selection_idx = -1
			select()

	if _current_selection_idx != prev_selection:
		selection_changed.emit(_current_selection_idx)
	
	_arrange_children()
	queue_redraw()


func _get_controller_simulated_pos() -> Vector2:
	var is_active := false
	
	if not focus_action_name.is_empty():
		if not focus_action_hold_mode:
			if Input.is_action_just_pressed(focus_action_name):
				_is_focus_action_pressed = not _is_focus_action_pressed
			is_active = _is_focus_action_pressed
		else:
			is_active = Input.is_action_pressed(focus_action_name)
	else:
		is_active = true
	
	if is_active:
		var vec: Vector2 = Input.get_vector(move_left_action_name, move_right_action_name, move_forward_action_name, move_back_action_name)
		if vec.length_squared() > controller_deadzone * controller_deadzone:
			var mid_radius := (arc_inner_radius + _current_menu_radius) / 2.0
			return vec * mid_radius
			
	return _OUT_OF_BOUNDS


func _arrange_children() -> void:
	if _local_children_count == 0:
		return
	
	var segment_angle: float = TAU / float(_local_children_count)
	var child_size_factor: float = 1.0
	if children_auto_sizing and _current_menu_radius > 0:
		child_size_factor = (_current_menu_radius / (children_size * 1.5)) * children_auto_sizing_factor
	var target_child_size: Vector2 = Vector2.ONE * children_size * child_size_factor

	for i: int in _local_children_count:
		var angle: float = i * segment_angle - _ANGLE_OFFSET + _global_angle_offset
		var mid_rad: float = angle + (segment_angle / 2)
		var draw_pos: Vector2 = Vector2.from_angle(mid_rad) * ((arc_inner_radius + _current_menu_radius) / 2.0)
		
		if _current_selection_idx == i:
			draw_pos *= (1.0 + hover_children_radial_offset)
			draw_pos += hover_offset
		
		draw_pos *= (1.0 + children_distance_offset)
		
		var list_idx: int = i + (1 if first_in_center else 0)
		var child: Control = _children_list[list_idx]
		
		if children_size_as_scale:
			if child.scale != target_child_size:
				child.scale = target_child_size
		else:
			if child.size != target_child_size:
				child.size = target_child_size
		
		var target_pos: Vector2 = _current_menu_offset - (child.size / 2.0) + draw_pos + children_offset
		if child.has_meta(&'radial_offset'):
			target_pos += child.get_meta(&'radial_offset', Vector2.ZERO)
		
		child.position = target_pos
		child.pivot_offset = child.size / 2.0
		
		# Rotation
		if children_rotate:
			if _local_children_count == 1:
				child.rotation = 0
			else:
				var rot_dir: int = -1 if children_rotate_inverted else 1
				child.rotation = rot_dir * _ANGLE_OFFSET + mid_rad
			
	if first_in_center and _children_list.size() > 0:
		var center_child: Control = _children_list[0]
		# var target_size := Vector2.ONE * children_size * (children_auto_sizing_factor if children_auto_sizing else 1.0)
		if children_size_as_scale:
			if center_child.scale != target_child_size:
				center_child.scale = target_child_size
		else:
			if center_child.size != target_child_size:
				center_child.size = target_child_size
		
		center_child.position = _current_menu_offset - (center_child.size / 2.0) + children_offset
		center_child.pivot_offset = center_child.size / 2.0
		# if not children_rotate:
		# 	center_child.rotation = 0.0


func _draw() -> void:
	# if _local_children_count == 0 and not first_in_center:
	# 	return
	
	draw_circle(_current_menu_offset, _current_menu_radius, color)
	
	if _current_selection_idx == -1 and first_in_center:
		draw_circle(_current_menu_offset, arc_inner_radius, hover_color)
	
	if _local_children_count == 0:
		_draw_decorations()
		return
	
	var segment_angle: float = TAU / float(_local_children_count)
	
	for i: int in range(_local_children_count):
		var angle: float = i * segment_angle - _ANGLE_OFFSET + _global_angle_offset
		var start_rad: float = angle
		var end_rad: float = angle + segment_angle
		var mid_rad: float = angle + (segment_angle / 2)
		
		# Draw Hover Sector
		if _current_selection_idx == i and arc_inner_radius < _current_menu_radius:
			if _local_children_count == 1:
				draw_circle(_current_menu_offset, _current_menu_radius, hover_color)
			else:
				var points := PackedVector2Array()
				for j: int in range(hover_detail + 1):
					var t: float = j / float(hover_detail)
					var a: float = lerpf(start_rad, end_rad, t)
					points.append(_current_menu_offset + Vector2.from_angle(a) * (arc_inner_radius + hover_offset_start) * hover_size_factor)
				
				for j: int in range(hover_detail + 1):
					var t: float = 1.0 - j / float(hover_detail)
					var a: float = lerpf(start_rad, end_rad, t)
					points.append(_current_menu_offset + Vector2.from_angle(a) * (_current_menu_radius + hover_offset_end) * hover_size_factor)
					
				draw_polygon(points, PackedColorArray([hover_color]))
				
		# Draw dividing lines
		if _local_children_count > 1:
			var point := Vector2.from_angle(angle)
			draw_line(
				_current_menu_offset + point * arc_inner_radius,
				_current_menu_offset + point * _current_menu_radius,
				line_color, line_width, line_antialiased
			)
			
	_draw_decorations()


func _draw_decorations() -> void:
	# Inner Arc
	draw_arc(_current_menu_offset, arc_inner_radius, arc_start_angle, arc_end_angle, arc_detail, arc_color, arc_line_width, arc_antialiased)
	
	# Stroke
	if stroke_enabled and stroke_width != 0:
		var r_offset := _get_stroke_radius_offset(stroke_width, stroke_type)
		draw_arc(_current_menu_offset, _current_menu_radius + r_offset, 0, TAU, arc_detail, stroke_color, stroke_width, arc_antialiased)
	
	# Animated Pulse
	if animated_pulse_enabled:
		var pulse_radius: float = _current_menu_radius + animated_pulse_offset + animated_pulse_intensity + sin(_time_tick * animated_pulse_speed) * animated_pulse_intensity
		draw_arc(_current_menu_offset, pulse_radius, 0, TAU, arc_detail, animated_pulse_color, arc_line_width, arc_antialiased)


func _input(event: InputEvent) -> void:
	if not enabled:
		return
		
	# Select Action
	if not select_action_name.is_empty():
		var is_triggered := event.is_action_released(select_action_name) if action_released else event.is_action_pressed(select_action_name)
		if is_triggered and _current_selection_idx != -2:
			select()
	
	# Cancel Action
	if event.is_action_pressed(&'ui_cancel'):
		selection_canceled.emit()
		if one_shot:
			enabled = false