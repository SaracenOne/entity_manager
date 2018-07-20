extends "logic_node.gd"
tool

func get_global_position():
	if entity_node and entity_node is Node2D:
		return entity_node.global_position
	else:
		printerr("Not connected to a Node2D node!")
		
	return Vector2()
	
func set_global_position(p_position):
	if entity_node and entity_node is Node2D:
		entity_node.global_position = p_position
	else:
		printerr("Not connected to a Node2D node!")
		
	return Vector2()
		
func get_global_transform():
	if entity_node  and entity_node is Node2D:
		return entity_node.global_transform
	else:
		printerr("Not connected to a Node2D node!")
		
	return Transform()
		
func set_global_transform(p_global_transform):
	if entity_node and entity_node is Node2D:
		entity_node.global_transform = p_global_transform
	else:
		printerr("Not connected to a Node2D node!")
		
func _on_transform_changed():
	pass
	
func _entity_process(p_delta):
	._entity_process(p_delta)
	
func _entity_ready():
	._entity_ready()