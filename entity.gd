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
		