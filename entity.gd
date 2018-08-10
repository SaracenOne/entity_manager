extends Node
tool

"""
Entity Manager
"""
var entity_manager = null

"""
Transform Notification
"""
export(NodePath) var transform_notification_node_path = NodePath()
var transform_notification_node = null

"""
Logic Node
"""
export(NodePath) var logic_node_path = NodePath()
var logic_node = null setget set_logic_node, get_logic_node

func set_logic_node(p_logic_node):
	logic_node = p_logic_node
	
func get_logic_node():
	return logic_node

"""
Network Identity Node
"""
export(NodePath) var network_identity_node_path = NodePath()
var network_identity_node = null

"""
Network Logic Node
"""
export(NodePath) var network_logic_node_path = NodePath()
var network_logic_node = null

func _entity_ready():
	if !Engine.is_editor_hint():
		if logic_node:
			logic_node._entity_ready()
			
func is_subnode_property_valid():
	return filename != "" or (is_inside_tree() and get_tree().edited_scene_root() and get_tree().edited_scene_root() == self)

static func sub_property_path(p_property : String, p_sub_node_name : String) -> String:
	var split_property = p_property.split("/", -1)
	if split_property.size() > 1 and split_property[0] == p_sub_node_name:
		var property = ""
		for i in range(1, split_property.size()):
			property += split_property[i]
			if i != (split_property.size()-1):
				property += "/"
		return property
	
	return ""
			
func _get_property_list():
	var properties = []
	if has_node(logic_node_path):
		var logic_node = get_node(logic_node_path)
		if is_subnode_property_valid():
			var logic_node_property_list = logic_node.get_property_list()
			for property in logic_node_property_list:
				if property.usage & PROPERTY_USAGE_EDITOR and property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
					property.name = "logic_node/" + property.name
					properties.push_back(property)
		
	return properties
	
func get_sub_property(p_path, p_property, p_sub_node_name):
	var variant = null
	if has_node(p_path):
		var node = get_node(p_path)
		var property = sub_property_path(p_property, p_sub_node_name)
		variant = node.get(property)
		if typeof(variant) == TYPE_NODE_PATH:
			if variant != "" and node.has_node(variant):
				var sub_node = node.get_node(variant)
				variant = get_path_to(sub_node)
			else:
				variant = NodePath()
	return variant

func set_sub_property(p_path, p_property, p_value, p_sub_node_name):
	if has_node(p_path):
		var node = get_node(p_path)
		var property = sub_property_path(p_property, p_sub_node_name)
		var variant = p_value
		if typeof(variant) == TYPE_NODE_PATH:
			if variant != "" and has_node(variant):
				var sub_node = get_node(variant)
				return node.set(property, node.get_path_to(sub_node))
			else:
				return node.set(property, NodePath())
		return node.set(property, variant)
	return false
	
func _get(p_property):
	var variant = null
	if is_subnode_property_valid():
		variant = get_sub_property(logic_node_path, p_property, "logic_node")
	return variant
	

func _set(p_property : String, p_value):
	var return_val = false
	if is_subnode_property_valid():
		return_val = set_sub_property(logic_node_path, p_property, p_value, "logic_node")
		
	return return_val

			
func _ready():
	if !Engine.is_editor_hint() and has_node("/root/EntityManager"):
		entity_manager = get_node("/root/EntityManager")
		add_to_group("Entities")
		
		if has_node(transform_notification_node_path):
			transform_notification_node = get_node(transform_notification_node_path)
			if transform_notification_node == self:
				transform_notification_node = null
		
		if has_node(logic_node_path):
			logic_node = get_node(logic_node_path)
			if logic_node == self:
				logic_node = null
			
		if has_node(network_identity_node_path):
			network_identity_node = get_node(network_identity_node_path)
			if network_identity_node == self:
				network_identity_node = null
				
		if has_node(network_logic_node_path):
			network_logic_node = get_node(network_logic_node_path)
			if network_logic_node == self:
				network_logic_node = null
	
		connect("ready", entity_manager, "_entity_ready", [self])
		connect("tree_exiting", entity_manager, "_entity_exiting", [self])
		