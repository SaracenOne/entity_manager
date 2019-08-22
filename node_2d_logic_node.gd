extends "logic_node.gd"
tool

func get_global_position() -> Vector2:
	if _entity_node and _entity_node is Node2D:
		return _entity_node.global_position
	else:
		printerr("Not connected to a Node2D node!")
		
	return Vector2()
	
func set_global_position(p_position : Vector2) -> void:
	if _entity_node and _entity_node is Node2D:
		_entity_node.global_position = p_position
	else:
		printerr("Not connected to a Node2D node!")
		
	return
	
func get_transform() -> Transform2D:
	if _entity_node and _entity_node is Node2D:
		return _entity_node.transform
	else:
		printerr("Not connected to a Node2D node!")
		
	return Transform2D()
		
func set_transform(p_transform : Transform2D) -> void :
	if _entity_node and _entity_node is Node2D:
		_entity_node.transform = p_transform
	else:
		printerr("Not connected to a Node2D node!")
		
func get_global_transform() -> Transform2D:
	if _entity_node  and _entity_node is Node2D:
		return _entity_node.global_transform
	else:
		printerr("Not connected to a Node2D node!")
		
	return Transform2D()
		
func set_global_transform(p_global_transform : Transform2D) -> void:
	if _entity_node and _entity_node is Node2D:
		_entity_node.global_transform = p_global_transform
	else:
		printerr("Not connected to a Node2D node!")
		
func _on_transform_changed() -> void:
	pass
	
func _entity_process(p_delta : float) -> void:
	._entity_process(p_delta)
	
func _entity_ready() -> void:
	._entity_ready()
