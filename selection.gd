class_name SelectionViewport
extends Viewport

onready var camera := $Camera as Camera

const MAX_TEXTURE_DIMENSION := 4096

static func encode_face_indices_on_vertex_color(mesh: ArrayMesh) -> ArrayMesh:
	var mesh_tool := MeshDataTool.new()
	for i in mesh.get_surface_count():
		mesh_tool.create_from_surface(mesh, i)
	
	for i in mesh_tool.get_face_count():
		var color_index := int_to_color8(i)
		for j in 3:
			var vertex_index := mesh_tool.get_face_vertex(i, j)
			mesh_tool.set_vertex_color(vertex_index, color_index)
	
	for i in mesh.get_surface_count():
		mesh.surface_remove(i)
	
	mesh_tool.commit_to_surface(mesh)
	
	return mesh

static func get_selection_material() -> SpatialMaterial:
	return preload('res://selection_material.tres')

static func color8(r: int, g: int, b: int) -> Color:
	var color := Color()
	color.r8 = r
	color.g8 = g
	color.b8 - b
	
	return color

static func color8_to_int(value: Color) -> int:
	return value.r8 + (value.g8 * 256)  + (value.b8 * 256 * 256)

static func int_to_color8(value: int) -> Color:
	var color := Color()
	
	color.r8 = value % 256
	color.g8 = (value / 256) % 256
	color.b8 = value / (256 * 256)
	
	return color
