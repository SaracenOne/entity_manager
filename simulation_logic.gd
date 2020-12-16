extends "component_node.gd"
class_name SimulationLogic
tool

# Static value, do not edit at runtime
export(String) var _entity_type: String = ""

func _enter_tree() -> void:
	if ! Engine.is_editor_hint():
		add_to_group("entity_managed")


func _exit_tree() -> void:
	if ! Engine.is_editor_hint():
		remove_from_group("entity_managed")


func _transform_changed() -> void:
	pass


func cache_node(p_node_path: NodePath) -> Node:
	return get_node_or_null(p_node_path)


func get_attachment_id(p_attachment_string: String) -> int:
	return -1


func get_attachment_node(p_attachment_id: int) -> Node:
	return get_entity_node()


func _entity_parent_changed() -> void:
	pass


##############
# Networking #
##############


func is_entity_master() -> bool:
	if ! get_tree().has_network_peer():
		return true
	else:
		if is_network_master():
			return true
		else:
			return false


func _entity_representation_process(_delta: float) -> void:
	pass


func _entity_physics_pre_process(_delta: float) -> void:
	pass


func _entity_physics_process(_delta: float) -> void:
	pass


func _entity_physics_post_process(_delta: float) -> void:
	pass


func _entity_ready() -> void:
	pass


func entity_child_pre_remove(p_entity_child: Node) -> void:
	pass


func can_request_master_from_peer(p_id: int) -> bool:
	return false


func can_transfer_master_from_session_master(p_id: int) -> bool:
	return false

