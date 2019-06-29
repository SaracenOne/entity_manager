extends "logic_node.gd"
tool

func get_global_position():
	if _entity_node and _entity_node is Node2D:
		return _entity_node.global_position
	else:
		printerr("Not connected to a Node2D node!")
		
	return Vector2()
	
func set_global_position(p_position):
	if _entity_node and _entity_node is Node2D:
		_entity_node.global_position = p_position
	else:
		printerr("Not connected to a Node2D node!")
		
	return Vector2()
	
func get_transform():
	if _entity_node and _entity_node is Node2D:
		return _entity_node.transform
	else:
		printerr("Not connected to a Node2D node!")
		
	return Transform()
		
func set_transform(p_transform):
	if _entity_node and _entity_node is Node2D:
		_entity_node.transform = p_transform
	else:
		printerr("Not connected to a Node2D node!")
		
func get_global_transform():
	if _entity_node  and _entity_node is Node2D:
		return _entity_node.global_transform
	else:
		printerr("Not connected to a Node2D node!")
		
	return Transform()
		
func set_global_transform(p_global_transform):
	if _entity_node and _entity_node is Node2D:
		_entity_node.global_transform = p_global_transform
	else:
		printerr("Not connected to a Node2D node!")
		
func _on_transform_changed():
	pass
	
func _entity_process(p_delta):
	._entity_process(p_delta)
	
func _entity_ready():
	._entity_ready()
