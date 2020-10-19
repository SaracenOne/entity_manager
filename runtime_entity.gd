extends Node
class_name RuntimeEntity
tool

#const entity_manager_const = preload("entity_manager.gd")

"""
Dependency Graph
"""

var representation_process_ticks_msec: int = 0
var physics_process_ticks_msec: int = 0

var strong_dependency: Node = null
var entity_ref: Reference = Reference.new()
var nodes_cached: bool = false

"""
Parenting
"""
enum {
	ENTITY_PARENT_STATE_OK,
	ENTITY_PARENT_STATE_CHANGED,
	ENTITY_PARENT_STATE_INVALID,
}

signal entity_deletion
signal entity_parent_changed
signal attachment_points_pre_change
signal attachment_points_post_change

var entity_parent_state: int = ENTITY_PARENT_STATE_OK
var entity_parent: Node = null
var entity_children: Array = []
var attachment_id: int = 0

"""
Entity Manager
"""
var entity_manager: Node = null

"""
Transform Notification
"""
var transform_notification_node_path: NodePath = NodePath()
var transform_notification_node: Node = null

"""
Simulation Logic Node
"""
var simulation_logic_node_path: NodePath = NodePath()
var simulation_logic_node: Node = null

"""
Network Identity Node
"""
var network_identity_node_path: NodePath = NodePath()
var network_identity_node: Node = null

"""
Network Logic Node
"""
var network_logic_node_path: NodePath = NodePath()
var network_logic_node: Node = null

"""
"""


func request_to_become_master() -> void:
	NetworkManager.network_replication_manager.request_to_become_master(
		self, NetworkManager.get_current_peer_id()
	)


func process_master_request(p_id: int) -> void:
	set_network_master(p_id)


func _entity_ready() -> void:
	_entity_cache()
	
	if ! Engine.is_editor_hint():
		if simulation_logic_node:
			simulation_logic_node._entity_ready()
		else:
			printerr("Missing simulation logic node!")
			
		if network_identity_node:
			network_identity_node._entity_ready()
		else:
			printerr("Missing network identity node")
			
		if network_logic_node:
			network_logic_node._entity_ready()
		else:
			printerr("Missing network logic node")
			
		network_identity_node.update_name()

func _entity_representation_process(p_delta: float) -> void:
	var start_ticks: int = OS.get_ticks_msec()
	
	if network_logic_node:
		network_logic_node._entity_representation_process(p_delta)
	else:
		printerr("Missing network logic node")
			
	if simulation_logic_node:
		simulation_logic_node._entity_representation_process(p_delta)
	else:
		printerr("Missing simulation logic node!")
		
	representation_process_ticks_msec = OS.get_ticks_msec() - start_ticks
		
func _entity_physics_process(p_delta: float) -> void:
	var start_ticks: int = OS.get_ticks_msec()
	
	if simulation_logic_node:
		simulation_logic_node._entity_physics_process(p_delta)
	else:
		printerr("Missing simulation logic node!")
		
	physics_process_ticks_msec = OS.get_ticks_msec() - start_ticks
		
func get_attachment_id(p_attachment_name: String) -> int:
	return simulation_logic_node.get_attachment_id(p_attachment_name)


func get_attachment_node(p_attachment_id: int) -> Node:
	return simulation_logic_node.get_attachment_node(p_attachment_id)


func _add_entity_child_internal(p_entity_child: Node) -> void:
	if p_entity_child:
		var child_name: String = p_entity_child.get_name()
		if entity_children.has(p_entity_child):
			ErrorManager.error(
				"_add_entity_child: does not have entity child {child_name}!".format(
					{"child_name": child_name}
				)
			)
		else:
			entity_children.push_back(p_entity_child)
			#p_entity_child.connect("attachment_points_pre_change", self, "remove_to_attachment")
			#p_entity_child.connect("attachment_points_post_change", self, "add_to_attachment")
	else:
		ErrorManager.error("_add_entity_child: attempted to add null entity child!")


func _remove_entity_child_internal(p_entity_child: Node) -> void:
	if p_entity_child:
		var child_name: String = p_entity_child.get_name()
		if entity_children.has(p_entity_child):
			var index = entity_children.find(p_entity_child)
			if index != -1:
				simulation_logic_node.entity_child_pre_remove(p_entity_child)
				entity_children.remove(index)
				#p_entity_child.disconnect("attachment_points_pre_change", self, "refresh_attachment")
				#p_entity_child.disconnect("attachment_points_post_change", self, "refresh_attachment")
			else:
				ErrorManager.error(
					"_remove_entity_child: does not have entity child {child_name}!".format(
						{"child_name": child_name}
					)
				)
		else:
			ErrorManager.error(
				"_remove_entity_child: does not have entity child {child_name}!".format(
					{"child_name": child_name}
				)
			)
	else:
		ErrorManager.error("_remove_entity_child: attempted to remove null entity child!")


func _has_entity_parent_internal() -> bool:
	if entity_parent != null:
		if entity_parent.get_script() == get_script():
			return true

	return false


func _set_entity_parent_internal(p_node: Node) -> void:
	var new_entity_parent: Node = null

	# Check if this node
	if p_node and p_node.has_method("get_entity"):
		new_entity_parent = p_node.call("get_entity")

	# If it has the same parent, don't change anything
	if new_entity_parent == entity_parent:
		return

	# Remove any previous parents
	if _has_entity_parent_internal():
		entity_parent._remove_entity_child_internal(self)

	# Set the entity parent if its a valid entity
	if (
		new_entity_parent == null
		or (new_entity_parent and new_entity_parent.get_script() == get_script())
	):
		entity_parent = new_entity_parent

	# If the entity parent is not null, check if it is valid, and then add it to its list of children
	if entity_parent != null:
		entity_parent._add_entity_child_internal(self)


func _add_to_attachment(p_entity_parent: Spatial, p_attachment_id: int):
	# Remove it from the tree and remove its original entity parent
	if is_inside_tree():
		printerr("add_to_attachment: already inside tree!")
	else:
		# Now add it back into the tree which will automatically reparent it
		if p_entity_parent:
			p_entity_parent.get_attachment_node(attachment_id).add_child(self)
		else:
			NetworkManager.network_replication_manager.get_entity_root_node().add_child(self)

		# Hacky workaround!
		if ! is_connected("tree_exiting", self, "_entity_deletion"):
			if connect("tree_exiting", self, "_entity_deletion") != OK:
				printerr("entity: tree_exiting could not be connected!")


func _remove_from_attachment():
	# Remove it from the tree and remove its original entity parent
	if is_inside_tree():
		# Hacky workaround!
		if is_connected("tree_exiting", self, "_entity_deletion"):
			disconnect("tree_exiting", self, "_entity_deletion")

		get_parent().remove_child(self)
	else:
		printerr("remove_from_attachment: not inside tree!")


func attachment_points_pre_change() -> void:
	emit_signal("attachment_points_pre_change")


func attachment_points_post_change() -> void:
	emit_signal("attachment_points_post_change")


func get_entity_parent() -> Node:
	return entity_parent


func set_entity_parent(p_entity_parent: Node, p_attachment_id: int) -> void:
	# Same parent, no update needed
	if p_entity_parent == entity_parent and p_attachment_id == attachment_id:
		return

	# Set the new attachment id
	attachment_id = p_attachment_id

	# Save the global transform
	var last_global_transform: Transform = Transform()

	if simulation_logic_node:
		last_global_transform = simulation_logic_node.get_global_transform()

	# Remove it from the tree and remove its original entity parent
	if is_inside_tree():
		_remove_from_attachment()

	# Make sure that the entity parent is null or a valid entity node
	if p_entity_parent == null or (p_entity_parent.get_script() == get_script()):
		# Now add it back into the tree which will automatically reparent it
		_add_to_attachment(p_entity_parent, attachment_id)

		# Reload the previously saved global transform
		if simulation_logic_node:
			simulation_logic_node.set_global_transform(last_global_transform)

	emit_signal("entity_parent_changed")


func clear_entity_parent() -> void:
	set_entity_parent(null, 0)


func _enter_tree() -> void:
	if ! Engine.is_editor_hint():
		if _has_entity_parent_internal():
			ErrorManager.error("Entity is trying to enter the tree with an existing entity parent!")
		else:
			_set_entity_parent_internal(get_parent())


func _exit_tree() -> void:
	if ! Engine.is_editor_hint():
		if _has_entity_parent_internal():
			_set_entity_parent_internal(null)


func cache_nodes() -> void:
	transform_notification_node = get_node_or_null(transform_notification_node_path)
	if transform_notification_node == self:
		transform_notification_node = null

	simulation_logic_node = get_node_or_null(simulation_logic_node_path)
	if simulation_logic_node == self:
		simulation_logic_node = null

	network_identity_node = get_node_or_null(network_identity_node_path)
	if network_identity_node == self:
		network_identity_node = null

	network_logic_node = get_node_or_null(network_logic_node_path)
	if network_logic_node == self:
		network_logic_node = null


func get_entity() -> Node:
	return self
	
	
func get_entity_ref() -> Reference:
	return entity_ref


func _entity_deletion():
	emit_signal("entity_deletion")
	entity_manager._entity_exiting(self)


func can_request_master_from_peer(p_id: int) -> bool:
	if simulation_logic_node:
		return simulation_logic_node.can_request_master_from_peer(p_id)
	else:
		return false


func can_transfer_master_from_session_master(p_id: int) -> bool:
	if simulation_logic_node:
		return simulation_logic_node.can_transfer_master_from_session_master(p_id)
	else:
		return false


static func get_entity_properties(p_show_properties: bool) -> Array:
	var usage: int
	if p_show_properties:
		usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE
	else:
		usage = 0
	
	var entity_properties : Array = [
		{
			"name":"transform_notification_node_path",
			"type":TYPE_NODE_PATH,
			"usage": usage,
			"hint": PROPERTY_HINT_FLAGS,
			"hint_string":"NodePath"
		},
		{
			"name":"simulation_logic_node_path",
			"type":TYPE_NODE_PATH,
			"usage": usage,
			"hint": PROPERTY_HINT_FLAGS,
			"hint_string":"NodePath"
		},
		{
			"name":"network_identity_node_path",
			"type":TYPE_NODE_PATH,
			"usage": usage,
			"hint": PROPERTY_HINT_FLAGS,
			"hint_string":"NodePath"
		},
		{
			"name":"network_logic_node_path",
			"type":TYPE_NODE_PATH,
			"usage": usage,
			"hint": PROPERTY_HINT_FLAGS,
			"hint_string":"NodePath"
		}
	]

	return entity_properties
	
func is_root_entity() -> bool:
	return false
	
func _entity_cache() -> void:
	if ! nodes_cached:
		propagate_call("cache_nodes", [], true)
		nodes_cached = true

func _get_property_list() -> Array:
	var properties: Array = get_entity_properties(is_root_entity())
	return properties


func _get(p_property: String):
	match p_property:
		"transform_notification_node_path":
			return transform_notification_node_path
		"simulation_logic_node_path":
			return simulation_logic_node_path
		"network_identity_node_path":
			return network_identity_node_path
		"network_logic_node_path":
			return network_logic_node_path

func _set(p_property: String, p_value) -> bool:
	match p_property:
		"transform_notification_node_path":
			transform_notification_node_path = p_value
			return true
		"simulation_logic_node_path":
			simulation_logic_node_path = p_value
			return true
		"network_identity_node_path":
			network_identity_node_path = p_value
			return true
		"network_logic_node_path":
			network_logic_node_path = p_value
			return true
			
	return false


func _ready() -> void:
	if ! Engine.is_editor_hint():
		entity_manager = get_node_or_null("/root/EntityManager")
		if entity_manager:
			add_to_group("Entities")

			if connect("ready", entity_manager, "_entity_ready", [self]) != OK:
				printerr("entity: ready could not be connected!")
			if connect("tree_exiting", self, "_entity_deletion") != OK:
				printerr("entity: tree_exiting could not be connected!")


func _threaded_instance_setup(p_instance_id: int, p_network_reader: Reference) -> void:
	_entity_cache()
	
	simulation_logic_node._threaded_instance_setup(p_instance_id, p_network_reader)
	network_logic_node._threaded_instance_setup(p_instance_id, p_network_reader)
	network_identity_node._threaded_instance_setup(p_instance_id, p_network_reader)


func _threaded_instance_post_setup() -> void:
	simulation_logic_node._threaded_instance_post_setup()
