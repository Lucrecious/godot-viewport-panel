extends Control

const ROTATION_DEGREES_PER_PIXEL := .5

enum ActionMode {
	None,
	Pan,
	Rotate,
	Zoom
}

var left_click_action := ActionMode.Pan as int
var _current_action := ActionMode.None as int

var _last_mouse_click_position := Vector2.ZERO
var _previous_mouse_position := Vector2.ZERO
var _original_pivot_global_transform := Transform.IDENTITY

onready var _pivot := $'%Pivot' as Spatial
onready var _camera := $'%Camera' as Camera
onready var _viewport := $'%Viewport' as Viewport
onready var _selection := $'%Selection' as SelectionViewport
onready var _pan_button := $Overlay2D/Control/Tools/Pan as Button
onready var _rotate_button := $Overlay2D/Control/Tools/Rotate as Button
onready var _zoom_button := $Overlay2D/Control/Tools/Zoom as Button
onready var _zoom_fit_button := $Overlay2D/Control/Tools/ZoomFit as Button

func _ready() -> void:
	_previous_mouse_position = _viewport.get_mouse_position()
	_camera_look_at_pivot()
	
	_pan_button.connect('pressed', self, '_on_tool_pressed', [_pan_button])
	_rotate_button.connect('pressed', self, '_on_tool_pressed', [_rotate_button])
	_zoom_button.connect('pressed', self, '_on_tool_pressed', [_zoom_button])
	_zoom_fit_button.connect('pressed', self, '_on_tool_pressed', [_zoom_fit_button])
	
	get_tree().connect('files_dropped', self, '_on_files_dropped')
	
	yield(get_tree().create_timer(3.0), 'timeout')
	
	add_mesh(load('res://cube_12m_triangles.obj'))

func _on_files_dropped(files: PoolStringArray, _screen: int) -> void:
	for f in files:
		var mesh := OBJParser.load_model(f, false) as ArrayMesh
		add_mesh(mesh, f)

func add_mesh(mesh: Mesh, file := '') -> void:
	var mesh_tool := MeshDataTool.new()
	for i in mesh.get_surface_count():
		mesh_tool.create_from_surface(mesh, i)
	
	print('add mesh from: %s' % file)
	printt('vertex count:', mesh_tool.get_vertex_count())
	printt('triangle vertex count:', (mesh_tool.get_face_count() * 3))
	print()
	
	mesh = SelectionViewport.encode_face_indices_on_vertex_color(mesh)
	
	var mesh_instance := MeshInstance.new()
	mesh_instance.mesh = mesh
	
	var material := ShaderMaterial.new()
	material.shader = load('res://normal_lighting.gdshader')
	mesh_instance.material_override = material
	
	_viewport.add_child(mesh_instance)
	
	var selection_mesh_instance := MeshInstance.new()
	selection_mesh_instance.mesh = mesh
	selection_mesh_instance.material_override = SelectionViewport.get_selection_material()
	
	_selection.add_child(selection_mesh_instance)
	
	_selection.camera.global_transform = _camera.global_transform
		
func _on_tool_pressed(button: Button) -> void:
	if _pan_button == button:
		left_click_action = ActionMode.Pan
	elif _rotate_button == button:
		left_click_action = ActionMode.Rotate
	elif _zoom_button == button:
		left_click_action = ActionMode.Zoom
	elif _zoom_fit_button == button:
		pass
	
func _camera_look_at_pivot() -> void:
	_camera.look_at(_pivot.global_transform.origin, Vector3.UP)

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	
	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion:
		var mouse_position := _viewport.get_mouse_position()
		if _current_action != ActionMode.None:
			if _current_action == ActionMode.Pan:
				var updown_axis := _camera.global_transform.basis.y
				var side_axis := _camera.global_transform.basis.x
				
				var pivot_distance := _camera.global_transform.origin.distance_to(_pivot.global_transform.origin)
				
				var a := _camera.project_position(_previous_mouse_position, pivot_distance)
				var b := _camera.project_position(mouse_position, pivot_distance)
				var delta := a - b
				
				_pivot.global_transform.origin += delta
			
			elif _current_action == ActionMode.Rotate:
				var turntable_axis := _camera.global_transform.basis.y
				var about_axis := _camera.global_transform.basis.x
				
				var pixels_delta := _previous_mouse_position - mouse_position
				
				var rotate_turntable_radians := deg2rad(pixels_delta.x * ROTATION_DEGREES_PER_PIXEL)
				var rotate_about_radians := deg2rad(pixels_delta.y * ROTATION_DEGREES_PER_PIXEL)
				
				_pivot.global_transform = _pivot.global_transform\
					.rotated(turntable_axis, rotate_turntable_radians)\
					.rotated(about_axis, rotate_about_radians)
			
			elif _current_action == ActionMode.Zoom:
				pass
			
			# Wrap cursor
			var is_warp_mouse := false
			var warped_mouse_position := Vector2.ZERO
			if mouse_position.x < 0:
				is_warp_mouse = true
				warped_mouse_position = mouse_position + Vector2.RIGHT * _viewport.size.x
			elif mouse_position.x >= _viewport.size.x:
				is_warp_mouse = true
				warped_mouse_position =  mouse_position + Vector2.LEFT * _viewport.size.x
			
			if mouse_position.y < 0:
				is_warp_mouse = true
				warped_mouse_position = mouse_position + Vector2.DOWN * _viewport.size.y
			elif mouse_position.y >= _viewport.size.y:
				is_warp_mouse = true
				warped_mouse_position = mouse_position + Vector2.UP * _viewport.size.y
			
			if is_warp_mouse:
				_viewport.warp_mouse(warped_mouse_position)
				mouse_position = warped_mouse_position
		
		
		_previous_mouse_position = mouse_position
		return
	
	var mouse_button := event as InputEventMouseButton
	if mouse_button and not mouse_button.pressed:
		_current_action = ActionMode.None
		return
	
	if _current_action != ActionMode.None:
		return
	
	if mouse_button and mouse_button.pressed:
		_last_mouse_click_position = _viewport.get_mouse_position()
		_original_pivot_global_transform = _pivot.global_transform
		
		if mouse_button.button_index == BUTTON_LEFT:
			_current_action = left_click_action
			return
		
		if mouse_button.button_index == BUTTON_RIGHT:
			_current_action = ActionMode.Pan
			return
		
		if mouse_button.button_index == BUTTON_MIDDLE:
			_current_action = ActionMode.Rotate
			return
