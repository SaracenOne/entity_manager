extends "simulation_logic.gd"
tool


func get_global_position() -> Vector2:
	return entity_node.global_position


func set_global_position(p_position: Vector2, _p_update_physics: bool = false) -> void:
	entity_node.global_position = p_position


func get_transform() -> Transform2D:
	return entity_node.transform


func set_transform(p_transform: Transform2D, _p_update_physics: bool = false) -> void:
	entity_node.transform = p_transform


func get_global_transform() -> Transform2D:
	return entity_node.global_transform


func set_global_transform(p_global_transform: Transform2D, _p_update_physics: bool = false) -> void:
	entity_node.global_transform = p_global_transform


func _on_transform_changed() -> void:
	pass


func _entity_representation_process(p_delta: float) -> void:
	._entity_representation_process(p_delta)


func _entity_ready() -> void:
	._entity_ready()
