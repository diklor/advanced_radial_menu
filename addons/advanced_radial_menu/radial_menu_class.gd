@tool
@icon('icon.svg')
class_name RadialMenuAdvanced extends Control

signal slot_selected(slot: Control,  index: int)
signal selection_changed(new_selection: int)
signal selection_canceled

enum STROKE_TYPE { OUTLINE, INNER, OUTER }

const CONSTANT_ANGLE_OFFSET: float = (PI / 2.0)


## Draws layer every frame, will be disabled on start
@export							var select_action_name := 'fire'
## Select when action is released
@export							var action_released := false
@export							var enabled := true:		set = _set_drawing
## Automatic size based on this control size
@export							var auto_sizing := true
## Is mouse hover and _current_selection_idx enabled. Works only with "Enabled"
@export								var mouse_enabled := true:		set = _set_mouse_enabled
## Does circle segments hover work when the mouse is outside
@export								var keep_selection_outside := true
## First child will be in center
@export								var first_in_center := false
## If true, sets "enabled" to false after _current_selection_idx
@export								var one_shot := false
@export								var slots_offset: int = 0
@export_group('Controller')
## controller works only when running
@export								var controller_enabled := false
## If you hold / pressed this action, the controller will work. For example, Button 7 or 8
## Leave empty to always work
@export								var focus_action_name := ''
## Do hold "focus_action_name" or just toggle. Works only if "focus_action_name" is not empty
@export								var focus_action_hold_mode := true
@export								var move_forward_action_name := 'move_forward'
@export								var move_left_action_name := 'move_left'
@export								var move_back_action_name := 'move_back'
@export								var move_right_action_name := 'move_right'
## Select center element by pressing action (Works only if "first_in_center" is enabled)
@export								var center_element_action_name := ''
@export_range(0.0, 1.0, 0.01)		var controller_deadzone: float = 0.0
@export_group('Base Circle')
## Offset of the entire radial menu
@export								var circle_offset := Vector2.ZERO
@export								var color := Color(0,0,0, 0.3) 
@export_range(0, 1024, 1)			var circle_radius: int = 384
## Radius will be `viewport_size.y / 2.5`
@export								var set_auto_radius := false:		set = _set_auto_radius

@export_group('Arc', 'arc_')
@export								var arc_color : = Color.WHITE
@export_range(0, 1024)				var arc_inner_radius: float = 128.0
## Limit: -TAU, TAU (-PI * 2, PI * 2)
@export_range(-TAU, TAU * 2.0)		var arc_start_angle: float = TAU
@export_range(-256, 256)			var arc_end_angle: float = 128.0
@export_range(2, 64)				var arc_detail: int = 32
@export_range(1, 512)				var arc_line_width: int = 6
@export								var arc_antialiased := true

@export_group('Line', 'line_')
@export								var line_rotation_offset_default: int = 0
@export								var line_color := Color.WHITE
@export_range(1, 256)				var line_width: int = 6
@export								var line_antialised := true

@export_group('Children', 'children_')
@export_range(1, 1024, 1)			var children_size: int = 256
## Automatically resize children based on radial menu size 
@export								var children_auto_sizing : = false
@export_range(0, 2, 0.1)			var children_auto_sizing_factor: float = 1.0
@export								var children_offset := Vector2.ZERO
## Rotate children relative to the circular position 
@export								var children_rotate := false:		set = _set_children_rotate
## If enabled, iterating and collecting children will only happen when the visibility or number of children changes, not every frame
## This means the display will not update when the visibility of the children changes
## Use the new radial_menu.force_update() function to force an update
@export								var children_optimized := false

@export_group('Hover')
@export								var hover_color := Color(1, 1, 1, 0.2)
@export_range(-1024, 1024, 1)		var hover_offset_start: int = 0
@export_range(-1024, 1024, 1)		var hover_offset_end: int = 0
@export_range(-10, 10, 0.1)			var hover_size_factor: float = 1.0
@export_range(2, 1024, 1)			var hover_detail: int = 96
@export								var hover_offset := Vector2.ZERO
@export_range(-10, 10)				var hover_children_radial_offset: float = 0.0

@export_group('Stroke', 'stroke_')
@export								var stroke_enabled := false
@export								var stroke_color := Color.WHITE
@export								var stroke_type: STROKE_TYPE = STROKE_TYPE.OUTER
@export_range(-1024, 1024)			var stroke_width: int = 6

@export_group('Animated Pulse', 'animated_pulse_')
@export								var animated_pulse_enabled := false
@export_range(-250, 256, 1)			var animated_pulse_intensity: int = 5
@export_range(-250, 256, 1)			var animated_pulse_offset: int = 0
@export_range(-56, 56, 1)			var animated_pulse_speed: int = 10
@export								var animated_pulse_color := Color.WHITE





var _last_viewport_size := Vector2.ZERO

var _current_selection_idx: int = -2 #0 first child, -1 center child,  -2 none
var _children_list: Array[Control] = []
var _real_children_count: int = 0
var _local_children_count: int = 0
var _time_tick: float = 0.0

var _current_menu_radius: int = 0
var _current_menu_offset := Vector2.ZERO
var _line_rotation_offset: int = 0

var _temporary_selection: int = -2
var _is_editor := true
var _is_focus_action_pressed := false



# ###################################### PUBLIC ###################################### #
func set_temporary_selection(value: int = -2) -> void:
	_temporary_selection = value
	selection_changed.emit(clampi(_temporary_selection, -1, _local_children_count - 1))

func force_update() -> void:
	_update_children()

func get_selected_child() -> Node:
	return get_child(_current_selection_idx + (1 if first_in_center else -1))

func select() -> void: # select currently hovered element. Like trigerring action "select_action_name"
	if (_current_selection_idx == -2):
		selection_canceled.emit()
		return
	slot_selected.emit(get_selected_child(), _current_selection_idx)
	if one_shot:
		enabled = false
	_current_selection_idx = -2
# #################################################################################### #



func _set_drawing(value: bool) -> void:
	enabled = value
	set_process(value)
	set_process_unhandled_input(mouse_enabled if value else false)
	_update_children()

func _set_mouse_enabled(value: bool) -> void:
	mouse_enabled = value
	set_process_unhandled_input(value)
	if !value:
		_current_selection_idx = -1

func _set_children_rotate(value: bool) -> void:
	children_rotate = value
	if !value:
		for v: Node in get_children():
			if v.is_class(&'Control') and v.visible:
				v.rotation = 0

func _set_auto_radius(value: bool) -> void:
	if value:
		_current_menu_radius = int(_last_viewport_size.y / 2.5)


func _ready() -> void:
	_last_viewport_size = Vector2(
		ProjectSettings.get('display/window/size/viewport_width'),
		ProjectSettings.get('display/window/size/viewport_height')
	)
	
	_is_editor = Engine.is_editor_hint()
	child_entered_tree.connect(_update_children.call_deferred.unbind(1))
	child_exiting_tree.connect(_update_children.call_deferred.unbind(1))
	visibility_changed.connect(_update_children.call_deferred)
 


func _update_children() -> void:
	_children_list.clear()
	_real_children_count = 0
	_local_children_count = 0
	
	for node: Node in get_children():
		if node.is_class(&'Control') and node.visible:
			_real_children_count += 1
			_children_list.append(node)
	
	_local_children_count = _real_children_count
	if first_in_center and (_local_children_count > 0):
		_local_children_count -= 1





func _get_width_by_stroke_type(width: float, type: STROKE_TYPE) -> float:
	return (
		(width / 2.0) * (-1.0 if type == STROKE_TYPE.INNER else 1.0)
			if (type != STROKE_TYPE.OUTLINE) else
		0.0
	)


func _draw_child(i: int, radial_position_offset := Vector2.ZERO) -> void:
	var child: Control = _children_list[i] if (i <= _real_children_count) else null # Control?
	if child != null:
		#if _local_children_count == 1:
			#radial_position_offset = Vector2.ZERO
		
		var factor := 1.0
		
		if children_auto_sizing:
			factor = (_current_menu_radius / (children_size * 1.5)) * children_auto_sizing_factor
		
		child.set_size.call_deferred(Vector2.ONE * children_size * factor)
		child.position = (_current_menu_offset - (child.size / 2.0)) + radial_position_offset + children_offset
		if child.has_meta('radial_offset'):
			child.position += child.get_meta('radial_offset', Vector2.ZERO)
		
		child.pivot_offset = child.size / 2.0
		
		if children_rotate:
			child.rotation_degrees = 360 - (360 * int(i / float(_local_children_count)))




func _draw() -> void:
	_current_menu_offset = (size / 2.0) + circle_offset
	
	var smallest_height := int(size.y / 2.0)
	if (size.x / 2.0) < smallest_height:
		smallest_height = (size.x / 2.0)
	
	_current_menu_radius = smallest_height
	
	
	if auto_sizing:
		if _current_menu_radius <= smallest_height:
			_current_menu_radius = smallest_height
		elif smallest_height < _current_menu_radius:
			_current_menu_radius = smallest_height
	else:
		_current_menu_radius = circle_radius
	
	
	
	
	draw_circle(_current_menu_offset, _current_menu_radius, color)
	
	if (_current_selection_idx == -1 and first_in_center):
		draw_circle(_current_menu_offset, arc_inner_radius, hover_color)
	
	
	if not children_optimized:
		_update_children()
	
	_line_rotation_offset = ((360 / float(_local_children_count)) * slots_offset) + line_rotation_offset_default
	
	
	if _local_children_count > 0:
		for i: int in _local_children_count:
			var angle := i * (TAU / _local_children_count) - CONSTANT_ANGLE_OFFSET # CONSTANT_ANGLE_OFFSET is magic expression that fixes unaligned circle division
			angle += deg_to_rad(_line_rotation_offset)
			
			var start_rads: float = (i - 1) * (TAU / _local_children_count) + CONSTANT_ANGLE_OFFSET - deg_to_rad(_line_rotation_offset)
			var end_rads: float = i * (TAU / _local_children_count) + CONSTANT_ANGLE_OFFSET - deg_to_rad(_line_rotation_offset)
			
			var mid_rads: float = -(start_rads + end_rads) / 2.0
			var radius_mid: float = (arc_inner_radius + _current_menu_radius) / 2.0
			
			
			var draw_pos: Vector2 = Vector2.from_angle(mid_rads) * radius_mid
			if (_current_selection_idx == i and _current_selection_idx >= 0):
				draw_pos *= (1.0 + hover_children_radial_offset)
				draw_pos += hover_offset
			
			
			if (arc_inner_radius < _current_menu_radius) and (_current_selection_idx == i):
				if (_local_children_count == 1):
					draw_circle(_current_menu_offset, _current_menu_radius, hover_color)
				else:
					var points_per_arc: int = hover_detail
					var points_inner := PackedVector2Array()
					var points_outer := PackedVector2Array()
					
					for j: int in points_per_arc:
						var point_angle: float = (start_rads + j * (end_rads - start_rads) / float(points_per_arc)) 
						points_inner.append(_current_menu_offset + ((arc_inner_radius + hover_offset_start)	* Vector2.from_angle(TAU - point_angle) * hover_size_factor))
						points_outer.append(_current_menu_offset + ((_current_menu_radius + hover_offset_end) 				* Vector2.from_angle(TAU - point_angle) * hover_size_factor))
					
					points_outer.reverse()
					
					draw_polygon(
						points_inner + points_outer,
						PackedColorArray([hover_color]),
					)
			
			
			if _local_children_count > 1:
				var point := Vector2.from_angle(angle)
				draw_line(
					_current_menu_offset +  point * arc_inner_radius,
					_current_menu_offset +  point * _current_menu_radius,
					line_color,
					line_width,
					line_antialised
				)
			
			if first_in_center:
				i += 1
			
			_draw_child(i, draw_pos)
		
		if first_in_center:
			_draw_child(0, Vector2.ZERO)
	
	
	
	draw_arc(_current_menu_offset, arc_inner_radius, arc_start_angle, arc_end_angle, arc_detail, arc_color, arc_line_width, arc_antialiased)
	
	if stroke_enabled:
		draw_arc(_current_menu_offset, _current_menu_radius + _get_width_by_stroke_type(stroke_width, stroke_type) , TAU, 128, arc_detail, stroke_color, stroke_width, arc_antialiased)
	
	if animated_pulse_enabled:
		if _time_tick >= 100.0:
			_time_tick = 0.0
		draw_arc(_current_menu_offset, (_current_menu_radius - animated_pulse_offset + animated_pulse_intensity + sin(_time_tick * animated_pulse_speed) * animated_pulse_intensity), TAU, 128, arc_detail, animated_pulse_color, arc_line_width, arc_antialiased)



func _process(delta: float) -> void:
	if animated_pulse_enabled:
		_time_tick += delta
	
	var pos_offset: Vector2 = _last_viewport_size - (size + position)
	var size_offset: Vector2 = (_last_viewport_size / 2.0 - (_current_menu_offset - circle_offset))
	var mouse_pos := -Vector2.ONE #not Vector2.ZERO because mouse can be in that position
	var controller_pressed := false
	
	
	
	if _temporary_selection != -2:
		_current_selection_idx = clampi(_temporary_selection, -1, _local_children_count - 1)
		queue_redraw()
		return
	
	
	if mouse_enabled:
		mouse_pos = (get_global_mouse_position() - _last_viewport_size / 2.0) - size_offset + pos_offset - circle_offset
	if controller_enabled and !_is_editor: #controller works only when running, otherwise spams with errors
		controller_pressed = true
		if !focus_action_name.is_empty():
			if !focus_action_hold_mode:
				if Input.is_action_just_pressed(focus_action_name):
					_is_focus_action_pressed = not _is_focus_action_pressed
				controller_pressed = _is_focus_action_pressed
			else:
				controller_pressed = Input.is_action_pressed(focus_action_name)
		
		if controller_pressed:
			var controller_vector := Vector2(
				Input.get_action_strength(move_right_action_name) - Input.get_action_strength(move_left_action_name),
				Input.get_action_strength(move_back_action_name) - Input.get_action_strength(move_forward_action_name)
			).limit_length(1.0) 
			
			if (controller_vector.length_squared() > controller_deadzone) \
				and !( focus_action_name.is_empty() and (controller_vector == Vector2.ZERO) ):
					mouse_pos = controller_vector * (arc_inner_radius + ((_current_menu_radius - arc_inner_radius) / 2.0))
			else:
				controller_pressed = false
		else:
			_current_selection_idx = -2
	
	if (mouse_pos != -Vector2.ONE):
		var mouse_radius: float = mouse_pos.length()
		var prev_selection := _current_selection_idx
		
		
		if (mouse_radius < arc_inner_radius):
			if first_in_center and !controller_pressed:
				_current_selection_idx = -1
		elif !_is_editor and !center_element_action_name.is_empty() and Input.is_action_just_pressed(center_element_action_name):
			_current_selection_idx = -1
			select()
		
		
		elif !first_in_center and _local_children_count == 1:
			if mouse_radius < _current_menu_radius:
				_current_selection_idx = 0
		else:
			if keep_selection_outside or (!keep_selection_outside and mouse_radius <= _current_menu_radius):
				var mouse_rads: float = fposmod(-mouse_pos.angle() - CONSTANT_ANGLE_OFFSET, TAU) + deg_to_rad(_line_rotation_offset)
				_current_selection_idx = wrapi(
					ceili(((mouse_rads / TAU) * _local_children_count)),
					0,
					_local_children_count
				)
			elif (!keep_selection_outside and mouse_radius > _current_menu_radius):
				_current_selection_idx = -2
			
		 
		if _current_selection_idx != prev_selection:
			selection_changed.emit(_current_selection_idx)
	
	
	queue_redraw()




func _input(event: InputEvent) -> void:
	if !select_action_name.is_empty() and (event.is_action_released(select_action_name) if action_released else event.is_action_pressed(select_action_name)): 
		if _current_selection_idx != -2:
			select()
	
	if event.is_action_pressed('ui_cancel'):
		emit_signal('selection_canceled')
