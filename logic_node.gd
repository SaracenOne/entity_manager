extends "component_node.gd"
tool

# Managers
var entity_manager = null

# Front-facing members
var update_fps = 15 setget set_update_fps, get_update_fps

# Private members
var previous_entity_process_time = 0.0

func set_update_fps(p_fps):
	update_fps = p_fps
	
func get_update_fps():
	return update_fps

func _get_property_list():
	var property_list = []

	property_list.push_back({"name":"update_fps", "type": TYPE_INT, "hint":PROPERTY_HINT_NONE})
	
	return property_list
	
func _set(p_property, p_value):
	var split_property = p_property.split("/", -1)
	if split_property.size() > 0:
		if split_property.size() == 1:
			if split_property[0] == "update_fps":
				set_update_fps(p_value)

func _get(p_property):
	var split_property = p_property.split("/", -1)
	if split_property.size() > 0:
		if split_property.size() == 1:
			if split_property[0] == "update_fps":
				return get_update_fps()

func _enter_tree():
	if Engine.is_editor_hint() == false:
		add_to_group("entity_managed")
		
func _exit_tree():
	if Engine.is_editor_hint() == false:
		remove_from_group("entity_managed")
		
func _transform_changed():
	pass
	
##############
# Networking #
##############
	
func is_entity_master():
	if !get_tree().has_network_peer():
		return true
	else:
		if is_network_master():
			return true
		else:
			return false
	
func _entity_process(p_delta):
	pass
	
func _entity_ready():
	pass