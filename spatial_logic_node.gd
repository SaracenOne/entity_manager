extends "logic_node.gd"
tool

func get_global_origin() -> Vector3:
	var entity_node : Node = get_entity_node()
	if entity_node and entity_node is Spatial:
		return entity_node.global_transform.origin
	else:
		printerr("Not connected to a Spatial node!")
		
	return Vector3()
	
func set_global_origin(p_origin : Vector3) -> void:
	var entity_node : Node = get_entity_node()
	if entity_node and entity_node is Spatial:
		entity_node.global_transform.origin = p_origin
	else:
		printerr("Not connected to a Spatial node!")
	
func get_transform() -> Transform:
	var entity_node : Node = get_entity_node()
	if entity_node and entity_node is Spatial:
		return entity_node.transform
	else:
		printerr("Not connected to a Spatial node!")
		
	return Transform()
		
func set_transform(p_transform : Transform) -> void:
	var entity_node : Node = get_entity_node()
	if entity_node and entity_node is Spatial:
		entity_node.transform = p_transform
	else:
		printerr("Not connected to a Spatial node!")
		
func get_global_transform() -> Transform:
	var entity_node : Node = get_entity_node()
	if entity_node and entity_node is Spatial:
		return entity_node.global_transform
	else:
		printerr("Not connected to a Spatial node!")
		
	return Transform()
		
func set_global_transform(p_global_transform : Transform) -> void:
	var entity_node : Node = get_entity_node()
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
