extends "runtime_entity.gd"
class_name Entity
tool

static func get_logic_node_properties(p_node : Node) -> Array:
	var properties: Array = []
	var node_property_list: Array = p_node.get_property_list()
	for property in node_property_list:
		if (
			property["usage"] & PROPERTY_USAGE_EDITOR
			and property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE
		):
			if property["name"].substr(0, 1) != '_':
				properties.push_back(property)
				
	return properties

func is_root_entity() -> bool:
	var networked_scenes: Array = []
	
	if ProjectSettings.has_setting("network/config/networked_scenes"):
		networked_scenes = ProjectSettings.get_setting("network/config/networked_scenes")
	
	if get_owner() == null and networked_scenes.find(get_filename()) != -1:
		return true
	
	return false

func is_subnode_property_valid() -> bool:
	if ! Engine.is_editor_hint():
		return true
	else:
		return (
			filename != ""
			or (
				is_inside_tree()
				and get_tree().edited_scene_root
				and get_tree().edited_scene_root == self
			)
		)


static func sub_property_path(p_property: String, p_sub_node_name: String) -> String:
	var split_property: PoolStringArray = p_property.split("/", -1)
	var property: String = ""
	if split_property.size() > 1 and split_property[0] == p_sub_node_name:
		for i in range(1, split_property.size()):
			property += split_property[i]
			if i != (split_property.size() - 1):
				property += "/"

	return property


func _get_property_list() -> Array:
	var properties: Array = []
	var node: Node = get_node_or_null(simulation_logic_node_path)
	if node and node != self:
		if is_subnode_property_valid():
			var logic_node_properties : Array = get_logic_node_properties(node)
			for property in logic_node_properties:
				property["name"] = "simulation_logic_node/%s" % property["name"]
				properties.push_back(property)
	
	return properties


func get_sub_property(p_path: NodePath, p_property: String, p_sub_node_name: String):
	var variant = null
	var node = get_node_or_null(p_path)
	if node and node != self:
		var property: String = sub_property_path(p_property, p_sub_node_name)
		if property.substr(0, 1) != '_':
			variant = node.get(property)
			if typeof(variant) == TYPE_NODE_PATH:
				if variant != "":
					var sub_node: Node = node.get_node_or_null(variant)
					if sub_node:
						variant = get_path_to(sub_node)
					else:
						variant = NodePath()
				else:
					variant = NodePath()
	return variant


func set_sub_property(p_path: NodePath, p_property: String, p_value, p_sub_node_name: String) -> bool:
	var node = get_node_or_null(p_path)
	if node != null and node != self:
		var property: String = sub_property_path(p_property, p_sub_node_name)
		if property.substr(0, 1) != '_':
			var variant = p_value
			if typeof(variant) == TYPE_NODE_PATH:
				if variant != "":
					var sub_node = get_node_or_null(variant)
					if sub_node:
						return node.set(property, node.get_path_to(sub_node))
					else:
						return node.set(property, NodePath())
				else:
					return node.set(property, NodePath())
			return node.set(property, variant)
	return false


func _get(p_property: String):
	var variant = null
	if is_subnode_property_valid():
		variant = get_sub_property(simulation_logic_node_path, p_property, "simulation_logic_node")
	return variant


func _set(p_property: String, p_value) -> bool:
	var return_val: bool = false
	if is_subnode_property_valid():
		return_val = set_sub_property(
			simulation_logic_node_path, p_property, p_value, "simulation_logic_node"
		)

	return return_val
