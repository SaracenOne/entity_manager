extends "logic_node.gd"
tool

func get_global_origin():
	if _entity_node and _entity_node is Spatial:
		return _entity_node.global_transform.origin
	else:
		printerr("Not connected to a Spatial node!")
		
	return Vector3()
	
func set_global_origin(p_origin):
	if _entity_node and _entity_node is Spatial:
		_entity_node.global_transform.origin = p_origin
	else:
		printerr("Not connected to a Spatial node!")
		
	return Vector3()
	
func get_transform():
	if _entity_node and _entity_node is Spatial:
		return _entity_node.transform
	else:
		printerr("Not connected to a Spatial node!")
		
	return Transform()
		
func set_transform(p_transform):
	if _entity_node and _entity_node is Spatial:
		_entity_node.transform = p_transform
	else:
		printerr("Not connected to a Spatial node!")
		
func get_global_transform():
	if _entity_node and _entity_node is Spatial:
		return _entity_node.global_transform
	else:
		printerr("Not connected to a Spatial node!")
		
	return Transform()
		
func set_global_transform(p_global_transform):
	if _entity_node and _entity_node is Spatial:
		_entity_node.global_transform = p_global_transform
	else:
		printerr("Not connected to a Spatial node!")
		
func _on_transform_changed():
	pass
	
func _entity_process(p_delta):
	._entity_process(p_delta)
	
func _entity_ready():
	._entity_ready()
