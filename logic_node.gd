extends "component_node.gd"
tool

# Front-facing members
var update_fps : int = 15 setget set_update_fps, get_update_fps

func set_update_fps(p_fps : int) -> void:
	update_fps = p_fps
	
func get_update_fps() -> int:
	return update_fps

func _get_property_list() -> Array:
	var property_list : Array = []

	property_list.push_back({"name":"update_fps", "type": TYPE_INT, "hint":PROPERTY_HINT_NONE})
	
	return property_list
	
func _set(p_property : String, p_value) -> bool:
	var split_property : PoolStringArray = p_property.split("/", -1)
	if split_property.size() > 0:
		if split_property.size() == 1:
			if split_property[0] == "update_fps":
				set_update_fps(p_value)
				return true
				
	return false

func _get(p_property : String):
	var split_property : PoolStringArray = p_property.split("/", -1)
	if split_property.size() > 0:
		if split_property.size() == 1:
			if split_property[0] == "update_fps":
				return get_update_fps()

func _enter_tree() -> void:
	if Engine.is_editor_hint() == false:
		add_to_group("entity_managed")
		
func _exit_tree() -> void:
	if Engine.is_editor_hint() == false:
		remove_from_group("entity_managed")
		
func _transform_changed() -> void:
	pass
	
func cache_node(p_node_path : NodePath) -> Node:
	var node = get_node_or_null(p_node_path)
	return node
	
##############
# Networking #
##############
	
func is_entity_master() -> bool:
	if !get_tree().has_network_peer():
		return true
	else:
		if is_network_master():
			return true
		else:
			return false
	
func _entity_process(p_delta : float) -> void:
	if p_delta > 0.0:
		pass
	
func _entity_ready() -> void:
	pass
