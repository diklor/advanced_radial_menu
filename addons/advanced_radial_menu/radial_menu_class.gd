@tool
@icon('res://addons/advanced_radial_menu/icon.svg')
extends Control
class_name RadialMenuAdvanced

##Draws layer every frame, will be disabled on start
@export										var select_action_name : String = 'fire'
@export										var action_released : bool = false
@export										var enabled : bool = true:							set = _set_drawing
@export										var auto_sizing : bool = true
##Is mouse hover and selection enabled. Works only with "Enabled"
@export										var mouse_enabled : bool = true:					set = _set_mouse_enabled
@export										var first_in_center : bool = false
@export										var slots_offset : int = 0
@export_group('Base Circle')
@export										var circle_offset:Vector2
@export										var color:Color = Color(0,0,0, 0.3) 
@export_range(0, 1024, 1)					var circle_radius:int = 384
@export										var set_auto_radius : bool = false:					set = _set_auto_radius

@export_group('Arc', 'arc_')
@export										var arc_color:Color = Color.WHITE
@export_range(0, 1024)						var arc_inner_radius:int = 128
@export_range(-TAU, TAU*2)					var arc_start_angle:float = TAU
@export_range(-256, 256)					var arc_end_angle:float = 128
@export_range(0, 64)						var arc_detail:int = 32
@export_range(1, 512)						var arc_line_width:int = 6
@export										var arc_antialiased:bool = true

@export_group('Line', 'line_')
@export										var line_rotation_offset_default:int = 0
@export										var line_color:Color = Color.WHITE
@export_range(1, 256)						var line_width:int = 6
@export										var line_antialised:bool = true

@export_group('Children', 'children_')
@export_range(1, 1024, 1)					var children_size:int = 256
@export										var children_auto_sizing:bool = false
@export_range(0, 2, 0.1)					var children_auto_sizing_factor:float = 1.0
@export										var children_offset:Vector2
@export										var children_rotate:bool = false:					set = _set_children_rotate

@export_group('Hover', 'hover_')
@export										var hover_color:Color = Color(1,1,1, 0.2)
@export_range(-1024, 1024, 1)				var hover_offset_start:int = 0
@export_range(-1024, 1024, 1)				var hover_offset_end:int = 0
@export_range(-10.0, 10.0, 0.1)				var hover_size_factor:float = 1.0
@export_range(0, 1024, 1)					var hover_detail:int = 96

@export_group('Stroke', 'stroke_')
@export										var stroke_enabled:bool = false
@export										var stroke_color:Color = Color.WHITE
@export										var stroke_type:STROKE_TYPE = STROKE_TYPE.OUTER
@export_range(-1024, 1024)					var stroke_width:int = 6

@export_group('Animated Pulse', 'animated_pulse_')
@export										var animated_pulse_enabled:bool = false
@export_range(-250, 256, 1)					var animated_pulse_intensity:int = 5
@export_range(-250, 256, 1)					var animated_pulse_offset:int = 0
@export_range(-56, 56, 1)					var animated_pulse_speed:int = 10
@export										var animated_pulse_color:Color = Color.WHITE




signal slot_selected(slot,  index: int)
signal selection_canceled


enum STROKE_TYPE {OUTLINE, INNER, OUTER}


var viewport_size:Vector2

var selection := -2
var child_count := 0
var delta := 0.0
var childs := {}

var radius := 0
var line_rotation_offset := 0
var offset := Vector2.ZERO



func _ready():
	viewport_size = Vector2(
		ProjectSettings.get('display/window/size/viewport_width'),
		ProjectSettings.get('display/window/size/viewport_height')
	)



func _set_drawing(val:bool):
	enabled = val
	set_process(val)
	set_process_unhandled_input(mouse_enabled if val else false)


func _set_mouse_enabled(val:bool):
	mouse_enabled = val
	set_process_unhandled_input(val)
	if !val:		selection = -1

func _set_children_rotate(val:bool):
	children_rotate = val
	if !val:
		for v in get_children():
			if (v is Control) and v.visible:
				v.rotation = 0
		

func _set_auto_radius(val):
	if val:
		radius = int(viewport_size.y / 2.5)






const ROT_OFFSETS = {
	3 : deg_to_rad(30),
	5 : deg_to_rad(54),
	7 : deg_to_rad(13),
	9 : deg_to_rad(30),
	11 : deg_to_rad(8),
	13 : deg_to_rad(20),
	15 : deg_to_rad(6),
}



func calc_by_stroke_type(width, type:STROKE_TYPE):
	return (((width / 2.0) * (-1 if type == STROKE_TYPE.INNER else 1)) if (type != STROKE_TYPE.OUTLINE)else 0.0)



func draw_child(i:int, texture_offset = Vector2.ZERO, i_default:int = 0):
	var children := []
	for v in get_children():
		if (v is Control) and v.visible:		children.append(v)
	
	var child = (children[i]as Control) if i <= children.size() else null
	if child:
		childs[str(i_default)] = child
		if child_count == 1:			texture_offset = Vector2.ZERO
		
		var factor := 1.0
#		if radius <= children_size * 1.5:
#			factor = radius / (children_size * 1.5)
		
		if children_auto_sizing:
			factor = (radius / (children_size * 1.5)) * children_auto_sizing_factor
			
		
		child._set_size.call_deferred(Vector2.ONE * children_size * factor)
		child.position = (offset - (child.size / 2.0)) + texture_offset + children_offset
		child.pivot_offset = child.size / 2.0
		
		
		if children_rotate:
			child.rotation_degrees = int(360 - 360 * (i / float(child_count)))



func _draw():
	offset = Vector2(
		self.size.x / 2.0,
		self.size.y / 2.0,
	) + circle_offset
	
	var smallest = (self.size.y / 2.0)
	if (size.x / 2.0) < smallest:
		smallest = (self.size.x / 2.0)
	
	
	radius = int(smallest)
	childs.clear()
	
	if auto_sizing:
			if radius <= smallest:
				radius = int(smallest)
			elif smallest < radius:
				radius = int(smallest)
	else:
		radius = circle_radius
	
	
	
	
	
	
	draw_circle(offset, radius, color)
	
	
	
	
	if selection == -1 and first_in_center:
		draw_circle(offset, arc_inner_radius, hover_color)
	
	
	
	
	
	child_count = 0
	for v in get_children():
		if (v is Control) and v.visible:		child_count +=1
	
	if first_in_center and (child_count > 0):
		child_count -= 1
	line_rotation_offset = ((360 / float(child_count)) * slots_offset) + line_rotation_offset_default
	
	var rads_offset := 0.0
	if ROT_OFFSETS.has(child_count):
		rads_offset = (ROT_OFFSETS[child_count]as float)
	
	
	if child_count > 0:
		for i in child_count:
			var rads = (TAU * i / child_count)
			rads += rads_offset + deg_to_rad(line_rotation_offset)
			
			i += 1
			
			
			
			var starts_rads = ((TAU * (i - 1)) / child_count) - rads_offset
			var ends_rads = ((TAU * i) / child_count) - rads_offset
			
			starts_rads -= deg_to_rad(line_rotation_offset)
			ends_rads -= deg_to_rad(line_rotation_offset)
			
			
			match child_count:
				1:			ends_rads += 0.4188		#deg_to_rad(24)
				5, 9:		i -= 1
			
			
			var mid_rads = (starts_rads + ends_rads) / 2.0 * -1
			var radius_mid = (arc_inner_radius + radius) / 2.0
			
			
			var draw_pos = (radius_mid * Vector2.from_angle(mid_rads))
			
			
			
			i = wrap(i, 0, child_count)
			
			if (arc_inner_radius < radius) and (selection == i):
				var points_per_arc :int= hover_detail
				var points_inner = PackedVector2Array()
				var points_outer = PackedVector2Array()
				
				for j in range(1, points_per_arc):
					var angle = (starts_rads + j * (ends_rads - starts_rads) / float(points_per_arc))
					points_inner.append(offset + ((arc_inner_radius + hover_offset_start)	* Vector2.from_angle(TAU - angle) * hover_size_factor))
					points_outer.append(offset + ((radius + hover_offset_end) 				* Vector2.from_angle(TAU - angle) * hover_size_factor))
				
				points_outer.reverse()
				
				draw_polygon(
					points_inner + points_outer,
					PackedColorArray([hover_color]),
				)
			
			
			if child_count > 1:
				var point :Vector2= Vector2.from_angle(rads)
				draw_line(
					offset +  point * arc_inner_radius,
					offset +  point * radius,
					line_color,
					line_width,
					line_antialised
				)
			
			
			draw_child(i + (1 if first_in_center else -1), draw_pos, i)
	
	
	if first_in_center and (child_count > 0):
		draw_child(0, Vector2.ZERO, -1)
	
	
	
	draw_arc(offset, arc_inner_radius, arc_start_angle, arc_end_angle, arc_detail, arc_color, arc_line_width, arc_antialiased)
	
	if stroke_enabled:
		draw_arc(offset, radius + calc_by_stroke_type(stroke_width, stroke_type) , TAU, 128, arc_detail, stroke_color, stroke_width, arc_antialiased)
	
	if animated_pulse_enabled:
		if delta >= 100:			delta = 0.0
		draw_arc(offset, (radius - animated_pulse_offset + animated_pulse_intensity + sin(delta * animated_pulse_speed) * animated_pulse_intensity), TAU, 128, arc_detail, animated_pulse_color, arc_line_width, arc_antialiased)



func _process(_delta):
	if radius < 2:		return
	
	
	if animated_pulse_enabled:
		delta += _delta
	
	if mouse_enabled:
		var pos_offset = viewport_size - (size + position)
		var size_offset = (viewport_size/2.0 - (offset - circle_offset))
		
		var mouse_pos = (get_global_mouse_position() - viewport_size / 2.0) - size_offset + pos_offset - circle_offset
		
		
		var mouse_radius = mouse_pos.length()
		
		selection = -2
		if mouse_radius < arc_inner_radius:
			if first_in_center:
				selection = -1
		elif !first_in_center and child_count == 1:
			if mouse_radius < radius:
				selection= 0
		else:
			var mouse_rads = fposmod(-mouse_pos.angle(), TAU) + deg_to_rad(line_rotation_offset)
			
			selection = wrap(      ceil(((mouse_rads / TAU) * child_count)),   0,    child_count      )
	
	
	queue_redraw()





func _input(event):
	if (event.is_action_released(select_action_name)if action_released else event.is_action_pressed(select_action_name)): 
		if selection != -2:
			emit_signal('slot_selected', childs[str(selection)]if childs.has(str(selection))else null, selection)
	
	if event.is_action_pressed('ui_cancel'):
		emit_signal('selection_canceled')
	
