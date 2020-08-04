extends Spatial

var entity: Node = null setget set_entity, get_entity


func set_entity(p_entity) -> void:
	entity = p_entity


func get_entity() -> Node:
	return entity
