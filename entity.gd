extends Node
class_name Entity
tool

const entity_manager_const = preload("entity_manager.gd")

"""
Parenting
"""

var entity_parent : Node = null
var entity_children : Array = []

"""
Entity Manager
"""
var entity_manager : entity_manager_const = null

"""
Transform Notification
"""
export(NodePath) var transform_notification_node_path : NodePath = NodePath()
var transform_notification_node : Node = null

"""
Logic Node
"""
export(NodePath) var logic_node_path : NodePath = NodePath()
var logic_node : Node = null setget set_logic_node, get_logic_node

func set_logic_node(p_logic_node : Node) -> void:
	logic_node = p_logic_node
	
func get_logic_node() -> Node:
	return logic_node

"""
Network Identity Node
"""
export(NodePath) var network_identity_node_path : NodePath = NodePath()
var network_identity_node : Node = null

"""
Network Logic Node
"""
export(NodePath) var network_logic_node_path : NodePath = NodePath()
var network_logic_node : Node = null

func _entity_ready() -> void:
	if !Engine.is_editor_hint():
		if logic_node:
			logic_node._entity_ready()
			
func is_subnode_property_valid() -> bool:
	return filename != "" or (is_inside_tree() and get_tree().edited_scene_root and get_tree().edited_scene_root == self)

static func sub_property_path(p_property : String, p_sub_node_name : String) -> String:
	var split_property : PoolStringArray = p_property.split("/", -1)
	var property : String = ""
	if split_property.size() > 1 and split_property[0] == p_sub_node_name:
		for i in range(1, split_property.size()):
			property += split_property[i]
			if i != (split_property.size()-1):
				property += "/"
	
	return property
			
func _get_property_list() -> Array:
	var properties : Array = []
	var logic_node : Node = get_node(logic_node_path)
	if logic_node and logic_node != self:
		if is_subnode_property_valid():
			var logic_node_property_list = logic_node.get_property_list()
			for property in logic_node_property_list:
				if property.usage & PROPERTY_USAGE_EDITOR and property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
					if property.name.substr(0, 1) != '_': 
						property.name = "logic_node/" + property.name
						properties.push_back(property)
		
	return properties
	
func get_sub_property(p_path : NodePath, p_property : String, p_sub_node_name : String):
	var variant = null
	var node = get_node_or_null(p_path)
	if node and node != self:
		return variant
		var property : String = sub_property_path(p_property, p_sub_node_name)
		if property.substr(0, 1) != '_': 
			variant = node.get(property)
			if typeof(variant) == TYPE_NODE_PATH:
				if variant != "":
					var sub_node : Node = node.get_node_or_null(variant)
					if sub_node:
						variant = get_path_to(sub_node)
					else:
						variant = NodePath()
				else:
					variant = NodePath()
	return variant

func set_sub_property(p_path : NodePath, p_property : String, p_value, p_sub_node_name : String) -> bool:
	var node = get_node_or_null(p_path)
	if node != null and node != self:
		return false
		var property : String = sub_property_path(p_property, p_sub_node_name)
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
	
func _get(p_property : String):
	var variant = null
	if is_subnode_property_valid():
		variant = get_sub_property(logic_node_path, p_property, "logic_node")
	return variant
	

func _set(p_property : String, p_value) -> bool:
	var return_val : bool = false
	if is_subnode_property_valid():
		return_val = set_sub_property(logic_node_path, p_property, p_value, "logic_node")
		
	return return_val
	
func _add_entity_child_internal(p_entity_child : Node) -> void:
	if p_entity_child:
		if entity_children.has(p_entity_child):
			ErrorManager.error("_add_entity_child: does not have entity child " + p_entity_child.get_name() + "!")
		else:
			entity_children.push_back(p_entity_child)
	else:
		ErrorManager.error("_add_entity_child: attempted to add null entity child!")
	
func _remove_entity_child_internal(p_entity_child : Node) -> void:
	if p_entity_child:
		if entity_children.has(p_entity_child):
			var index = entity_children.find(p_entity_child)
			if index != -1:
				entity_children.remove(index)
			else:
				ErrorManager.error("_remove_entity_child: does not have entity child " + p_entity_child.get_name() + "!")
		else:
			ErrorManager.error("_remove_entity_child: does not have entity child " + p_entity_child.get_name() + "!")
	else:
		ErrorManager.error("_remove_entity_child: attempted to remove null entity child!")
	
func _has_entity_parent_internal() -> bool:
	if entity_parent != null:
		if entity_parent.get_script() == get_script():
			return true
			
	return false
	
func _set_entity_parent_internal(p_entity_parent : Node) -> void:
	if p_entity_parent == entity_parent:
		return
		
	# Remove any previous parents
	if _has_entity_parent_internal():
		entity_parent._remove_entity_child_internal(self)
	
	# Set the entity parent if its a valid entity
	if p_entity_parent == null or (p_entity_parent and p_entity_parent.get_script() == get_script()):
		entity_parent = p_entity_parent
	
	# If the entity parent is not null, check if it is valid, and then add it to its list of children
	if entity_parent != null:
		entity_parent._add_entity_child_internal(self)
		
func set_entity_parent(p_entity_parent : Node) -> void:
	# Same parent, no update needed
	if p_entity_parent == entity_parent:
		return
	
	# Save the global transform
	var last_global_transform : Transform = Transform()
	if logic_node:
		last_global_transform = logic_node.get_global_transform()
	
	# Remove it from the tree and remove its original entity parent
	if is_inside_tree():
		get_parent().remove_child(self)
	
	# Make sure that the entity parent is null or a valid entity node
	if p_entity_parent == null or (p_entity_parent.get_script() == get_script()):
		# Now add it back into the tree which will automatically reparent it
		if p_entity_parent == null:
			network_identity_node.network_replication_manager.get_entity_root_node().add_child(self)
		else:
			p_entity_parent.add_child(self)
			
		# Reload the previously saved global transform
		if logic_node:
			logic_node.set_global_transform(last_global_transform)
		
		# Now send the network update...
		if network_identity_node:
			network_identity_node.send_parent_entity_update()
		
func clear_entity_parent() -> void:
	set_entity_parent(null)
			
func _enter_tree() -> void:
	if !Engine.is_editor_hint():
		if _has_entity_parent_internal():
			ErrorManager.error("Entity is trying to enter the tree with an existing entity parent!")
		else:
			_set_entity_parent_internal(get_parent())
	
func _exit_tree() -> void:
	if !Engine.is_editor_hint():
		if _has_entity_parent_internal():
			_set_entity_parent_internal(null)
	
func _ready() -> void:
	if !Engine.is_editor_hint():
		entity_manager = get_node_or_null("/root/EntityManager")
		if entity_manager:
			add_to_group("Entities")
			
			transform_notification_node = get_node_or_null(transform_notification_node_path)
			if transform_notification_node == self:
				transform_notification_node = null
		
			logic_node = get_node_or_null(logic_node_path)
			if logic_node == self:
				logic_node = null
			
			network_identity_node = get_node_or_null(network_identity_node_path)
			if network_identity_node == self:
				network_identity_node = null
				
			network_logic_node = get_node_or_null(network_logic_node_path)
			if network_logic_node == self:
				network_logic_node = null
			
			if connect("ready", entity_manager, "_entity_ready", [self]) != OK:
				printerr("entity: ready could not be connected!")
			if connect("tree_exiting", entity_manager, "_entity_exiting", [self]) != OK:
				printerr("entity: tree_exiting could not be connected!")
			
