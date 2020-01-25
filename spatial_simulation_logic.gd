extends "simulation_logic.gd"
tool

func get_global_origin() -> Vector3:
	if entity_node and entity_node is Spatial:
		return entity_node.global_transform.origin
	else:
		printerr("Not connected to a Spatial node!")
		
	return Vector3()
	
func set_global_origin(p_origin : Vector3) -> void:
	if entity_node and entity_node is Spatial:
		entity_node.global_transform.origin = p_origin
	else:
		printerr("Not connected to a Spatial node!")
	
func get_transform() -> Transform:
	if entity_node and entity_node is Spatial:
		return entity_node.transform
	else:
		printerr("Not connected to a Spatial node!")
		
	return Transform()
		
func set_transform(p_transform : Transform) -> void:
	if entity_node and entity_node is Spatial:
		entity_node.transform = p_transform
	else:
		printerr("Not connected to a Spatial node!")
		
func get_global_transform() -> Transform:
	if entity_node and entity_node is Spatial:
		return entity_node.global_transform
	else:
		printerr("Not connected to a Spatial node!")
		
	return Transform()
		
func set_global_transform(p_global_transform : Transform) -> void:
	if entity_node and entity_node is Spatial:
		entity_node.global_transform = p_global_transform
	else:
		printerr("Not connected to a Spatial node!")
		
func _on_transform_changed() -> void:
	pass
	
func _entity_process(p_delta : float) -> void:
	._entity_process(p_delta)
	
func _entity_ready() -> void:
	._entity_ready()
	
func _ready() -> void:
	entity_node = get_entity_node()
