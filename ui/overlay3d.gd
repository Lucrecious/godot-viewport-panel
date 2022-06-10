extends Spatial

export(NodePath) var _camera_path := NodePath()

onready var _camera := get_node_or_null(_camera_path) as Camera
onready var _arrows3d := $'%Arrows3D'


func _process(delta: float) -> void:
	if Engine.get_idle_frames() % 3 != 0:
		return
	
	_arrows3d.look_at(_arrows3d.global_transform.origin + _camera.global_transform.basis.z, _camera.global_transform.basis.y)
