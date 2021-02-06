extends Node
class_name RuntimeEntity
tool

#const entity_manager_const = preload("entity_manager.gd")

"""
Dependency Graph
"""

var representation_process_ticks_usec: int = 0
var physics_process_ticks_usec: int = 0

const node_3d_simulation_logic_const = preload("node_3d_simulation_logic.gd")
const node_2d_simulation_logic_const = preload("node_2d_simulation_logic.gd")

const mutex_lock_const = preload("res://addons/gdutil/mutex_lock.gd")

var current_job: Reference = null
var dependency_mutex: Mutex = Mutex.new()

# TODO: this should be a a Set/Dictionary
var strong_exclusive_dependencies: Dictionary = {}
var strong_exclusive_dependents: Array = []

enum DependencyCommand {
	ADD_STRONG_EXCLUSIVE_DEPENDENCY,
	REMOVE_STRONG_EXCLUSIVE_DEPENDENCY
}

var pending_dependency_commands: Array = []

var entity_ref: EntityRef = EntityRef.new(self)

var nodes_cached: bool = false

"""
Parenting
"""

signal entity_parent_changed
signal entity_message(p_message, p_args)
signal entity_deletion

var pending_entity_parent_ref: EntityRef = null
var pending_attachment_id: int = 0
var cached_entity_parent: Node = null
var cached_entity_attachment_id: int = 0
var cached_entity_children: Array = []

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
RPC table Node
"""
var rpc_table_node_path: NodePath = NodePath()
var rpc_table_node: Node = null

"""
"""

func clear_entity_signal_connections() -> void:
	var entity_message_connections: Array = get_signal_connection_list("entity_message")
	for connection in entity_message_connections:
		disconnect(connection["signal"], connection["target"], connection["method"])
	
	var entity_deletion_connections: Array = get_signal_connection_list("entity_deletion")
	for connection in entity_deletion_connections:
		disconnect(connection["signal"], connection["target"], connection["method"])

	var entity_parent_changed_connections: Array = get_signal_connection_list("entity_deletion")
	for connection in entity_parent_changed_connections:
		disconnect(connection["signal"], connection["target"], connection["method"])
	
func _create_strong_exclusive_dependency(p_entity_ref: Reference) -> void:
	var mutex_lock: mutex_lock_const = mutex_lock_const.new(dependency_mutex)
	pending_dependency_commands.push_back({"command":DependencyCommand.ADD_STRONG_EXCLUSIVE_DEPENDENCY, "entity":p_entity_ref})


func _remove_strong_exclusive_dependency(p_entity_ref: Reference) -> void:
	var mutex_lock: mutex_lock_const = mutex_lock_const.new(dependency_mutex)
	pending_dependency_commands.push_back({"command":DependencyCommand.REMOVE_STRONG_EXCLUSIVE_DEPENDENCY, "entity":p_entity_ref})


func _update_dependencies() -> void:
	for pending_dependency in pending_dependency_commands:
		var entity: Node = pending_dependency["entity"]._entity
		if entity:
			match pending_dependency["command"]:
				DependencyCommand.ADD_STRONG_EXCLUSIVE_DEPENDENCY:
					if strong_exclusive_dependencies.has(entity):
						strong_exclusive_dependencies[entity] += 1
					else:
						if EntityManager.check_if_dependency_is_cyclic(self, entity, true):
							printerr("Error: tried to create a cyclic dependency!")
						else:
							strong_exclusive_dependencies[entity] = 1
							entity.strong_exclusive_dependents.push_back(self)
				DependencyCommand.REMOVE_STRONG_EXCLUSIVE_DEPENDENCY:
					if ! strong_exclusive_dependencies.has(entity):
						printerr("Does not have exclusive strong dependency!")
					else:
						strong_exclusive_dependencies[entity] -= 1
						if strong_exclusive_dependencies[entity] <= 0:
							strong_exclusive_dependencies.erase(entity)
							entity.strong_exclusive_dependents.erase(self)
	pending_dependency_commands.clear()


func request_to_become_master() -> void:
	NetworkManager.network_replication_manager.request_to_become_master(
		network_identity_node.network_instance_id, self, NetworkManager.get_current_peer_id()
	)


func process_master_request(p_id: int) -> void:
	set_network_master(p_id)


func _entity_about_to_add() -> void:
	if network_logic_node:
		network_logic_node._entity_about_to_add()
	else:
		printerr("Missing network logic node")
			

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
	var start_ticks: int = OS.get_ticks_usec()
				
	if network_logic_node:
		network_logic_node._entity_representation_process(p_delta)
	else:
		printerr("Missing network logic node")
	if simulation_logic_node:
		simulation_logic_node._entity_representation_process(p_delta)
	else:
		printerr("Missing simulation logic node!")
		
	representation_process_ticks_usec = OS.get_ticks_usec() - start_ticks


func _entity_physics_pre_process(p_delta) -> void:
	if simulation_logic_node:
		simulation_logic_node._entity_physics_pre_process(p_delta)
	else:
		printerr("Missing simulation logic node!")


func _entity_physics_process(p_delta: float) -> void:
	var start_ticks: int = OS.get_ticks_usec()
	
	# Clear the job for next time the scheduler is run
	current_job = null
	
	if network_logic_node:
		network_logic_node._entity_physics_process(p_delta)
	else:
		printerr("Missing network logic node")
	if simulation_logic_node:
		simulation_logic_node._entity_physics_process(p_delta)
	else:
		printerr("Missing simulation logic node!")
		
	physics_process_ticks_usec = OS.get_ticks_usec() - start_ticks


func _entity_kinematic_integration_callback(p_delta: float) -> void:
	if simulation_logic_node:
		simulation_logic_node._entity_kinematic_integration_callback(p_delta)
	else:
		printerr("Missing simulation logic node!")


func _entity_physics_post_process(p_delta) -> void:
	if simulation_logic_node:
		simulation_logic_node._entity_physics_post_process(p_delta)


func get_attachment_id(p_attachment_name: String) -> int:
	return simulation_logic_node.get_attachment_id(p_attachment_name)


func get_attachment_node(p_attachment_id: int) -> Node:
	return simulation_logic_node.get_attachment_node(p_attachment_id)


func _cache_entity_parent() -> void:
	var parent: Node = get_parent()
	if parent and parent.has_method("get_entity"):
		cached_entity_parent = parent.get_entity()
		cached_entity_attachment_id = pending_attachment_id
	else:
		cached_entity_parent = null


func get_entity_parent() -> Node:
	return cached_entity_parent


func set_pending_parent_entity(p_entity_parent_ref: EntityRef, p_attachment_id: int) -> bool:
	if p_entity_parent_ref != pending_entity_parent_ref or p_attachment_id != pending_attachment_id:
		pending_entity_parent_ref = p_entity_parent_ref
		pending_attachment_id = p_attachment_id
		
		return true
	else:
		return false

func request_reparent_entity(p_entity_parent_ref: EntityRef, p_attachment_id: int) -> void:
	if set_pending_parent_entity(p_entity_parent_ref, p_attachment_id):
		if is_inside_tree():
			if ! EntityManager.reparent_pending.has(self):
				EntityManager.reparent_pending.push_back(self)


func _enter_tree() -> void:
	if ! Engine.is_editor_hint():
		_cache_entity_parent()
		var entity_parent: Node = get_entity_parent()
		if entity_parent:
			pending_entity_parent_ref = entity_parent.get_entity_ref()
			entity_parent.cached_entity_children.push_back(self)
			
		emit_signal("entity_parent_changed")


func _exit_tree() -> void:
	if ! Engine.is_editor_hint():
		var entity_parent: Node = get_entity_parent()
		if entity_parent:
			entity_parent.cached_entity_children.erase(self)


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
		
	rpc_table_node = get_node_or_null(rpc_table_node_path)
	if rpc_table_node == self:
		rpc_table_node = null


func get_entity() -> Node:
	return self
	
	
func get_entity_ref() -> Reference:
	return entity_ref


func _entity_deletion() -> void:
	emit_signal("entity_deletion")
	for dependent in strong_exclusive_dependents:
		dependent.strong_exclusive_dependencies.erase(self)
	entity_manager._entity_deleting(self)


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


func create_strong_exclusive_dependency_for(p_entity_ref: EntityRef) -> StrongExclusiveEntityDependencyHandle:
	return EntityManager.create_strong_dependency(p_entity_ref, get_entity_ref())


func create_strong_exclusive_dependency_to(p_entity_ref: EntityRef) -> StrongExclusiveEntityDependencyHandle:
	return EntityManager.create_strong_dependency(get_entity_ref(), p_entity_ref)


func get_dependent_entity(p_entity_ref: Reference) -> Node:
	return EntityManager.get_dependent_entity_for_dependency(get_entity_ref(), p_entity_ref)


func register_kinematic_integration_callback() -> void:
	EntityManager.register_kinematic_integration_callback(self)


func unregister_kinematic_integration_callback() -> void:
	EntityManager.unregister_kinematic_integration_callback(self)


func get_entity_type() -> String:
	if simulation_logic_node:
		return simulation_logic_node._entity_type
	else:
		return "Unknown Entity Type"

func get_last_transform():
	if simulation_logic_node and\
	simulation_logic_node is node_2d_simulation_logic_const or\
	simulation_logic_node is node_3d_simulation_logic_const:
		return simulation_logic_node.get_last_transform()
		
	return Transform()


func send_entity_message(p_target_entity: Reference, p_message: String, p_message_args: Dictionary) -> void:
	EntityManager.send_entity_message(get_entity_ref(), p_target_entity, p_message, p_message_args)


func _receive_entity_message(p_message: String, p_args: Dictionary) -> void:
	emit_signal("entity_message", p_message, p_args)


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
		},
		{
			"name":"rpc_table_node_path",
			"type":TYPE_NODE_PATH,
			"usage": usage,
			"hint": PROPERTY_HINT_FLAGS,
			"hint_string":"NodePath"
		}
	]

	return entity_properties


func is_root_entity() -> bool:
	return false

func get_rpc_table() -> Node:
	return rpc_table_node

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
		"rpc_table_node_path":
			return rpc_table_node_path

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
		"rpc_table_node_path":
			rpc_table_node_path = p_value
			return true
			
	return false
	
func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE:
		if ! Engine.is_editor_hint():
			entity_ref._entity = null
				
			_entity_deletion()

func _ready() -> void:
	if ! Engine.is_editor_hint():
		entity_manager = get_node_or_null("/root/EntityManager")
		if entity_manager:
			add_to_group("Entities")

			if connect("ready", entity_manager, "_entity_ready", [self]) != OK:
				printerr("entity: ready could not be connected!")


func _threaded_instance_setup(p_instance_id: int, p_network_reader: Reference) -> void:
	_entity_cache()
	
	if simulation_logic_node:
		simulation_logic_node._threaded_instance_setup(p_instance_id, p_network_reader)
	if network_logic_node:
		network_logic_node._threaded_instance_setup(p_instance_id, p_network_reader)
	if network_identity_node:
		network_identity_node._threaded_instance_setup(p_instance_id, p_network_reader)
