extends "simulation_logic.gd"
tool

var last_transform: Transform = Transform()

func _network_transform_update(p_transform: Transform) -> void:
	set_transform(p_transform, true)


func get_origin() -> Vector3:
	return entity_node.transform.origin


func set_origin(p_origin: Vector3, _p_update_physics: bool = false) -> void:
	entity_node.transform.origin = p_origin
	

func get_global_origin() -> Vector3:
	return entity_node.global_transform.origin


func set_global_origin(p_origin: Vector3, _p_update_physics: bool = false) -> void:
	entity_node.global_transform.origin = p_origin


func get_transform() -> Transform:
	return entity_node.transform


func set_transform(p_transform: Transform, _p_update_physics: bool = false) -> void:
	entity_node.transform = p_transform


func get_global_transform() -> Transform:
	return entity_node.global_transform


func set_global_transform(p_global_transform: Transform, _p_update_physics: bool = false) -> void:
	entity_node.global_transform = p_global_transform


func get_last_transform() -> Transform:
	return last_transform


func _cache_last_transform(p_transform: Transform) -> void:
	last_transform = p_transform


func _entity_physics_post_process(_delta: float) -> void:
	._entity_physics_post_process(_delta)
	
	_cache_last_transform(get_transform())

func _entity_ready() -> void:
	_cache_last_transform(get_transform())


func _on_transform_changed() -> void:
	pass


func _set(p_property, p_value) -> bool:
	match p_property:
		"transform":
			set_transform(p_value)
			return true
		"global_transform":
			set_global_transform(p_value)
			return true
			
	return false
