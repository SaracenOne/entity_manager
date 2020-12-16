extends Node
tool

export(int) var last_representation_process_usec: int = 0
export(int) var last_physics_process_usec: int = 0
export(int) var last_physics_post_process_usec: int = 0
export(int) var last_physics_pre_process_usec: int = 0
export(int) var last_update_dependencies_usec: int = 0

const scene_tree_execution_table_const = preload("scene_tree_execution_table.gd")
var scene_tree_execution_table: scene_tree_execution_table_const = scene_tree_execution_table_const.new()

class EntityJob extends Reference:
	var entities: Array = []
	var overall_time_usec: int = 0
	
	func _init(p_entities: Array):
		entities = p_entities
		
	func combine(p_job: EntityJob) -> void:
		entities += p_job.entities
		overall_time_usec += p_job.overall_time_usec
		
	static func sort(a, b):
		if a.overall_time_usec > b.overall_time_usec:
			return true
		return false


var reparent_pending: Array = []
var entity_reference_dictionary: Dictionary = {}
var entity_kinematic_integration_callbacks: Array = []

signal entity_added(p_entity)
signal entity_removed(p_entity)

signal process_complete(p_delta)
signal physics_process_complete(p_delta)


# Returns the root node all network entities should parented to
func get_entity_root_node() -> Node:
	return NetworkManager.get_entity_root_node()


# Dispatches a deferred add/remove entity command to the scene tree execution table 
func scene_tree_execution_command(p_command: int, p_entity_instance: Node, p_parent_instance: Node):
	var parent_instance: Node = null
	if p_parent_instance == null:
		parent_instance = get_entity_root_node()
	else:
		parent_instance = p_parent_instance

	scene_tree_execution_table.scene_tree_execution_command(
		p_command, p_entity_instance, parent_instance
	)


func _add_entity(p_entity: Node) -> void:
	entity_reference_dictionary[p_entity.get_entity_ref()] = p_entity


func _remove_entity(p_entity: Node) -> void:
	entity_reference_dictionary.erase(p_entity.get_entity_ref())
	entity_kinematic_integration_callbacks.erase(p_entity)

func _delete_entity_unsafe(p_entity: Node) -> void:
	if p_entity and ! p_entity.is_queued_for_deletion():
		# Set all the children of this entity to root
		for entity_child in p_entity.cached_entity_children:
			_reparent_unsafe(entity_child, null, 0)
			
		p_entity.queue_free()
		if p_entity.is_inside_tree():
			p_entity.get_parent().remove_child(p_entity)
			_remove_entity(p_entity)

func get_all_entities() -> Array:
	var return_array: Array = []
	
	for entity in entity_reference_dictionary.values():
		return_array.push_back(entity)
		
	return return_array


func register_kinematic_integration_callback(p_entity: RuntimeEntity) -> void:
	if ! entity_kinematic_integration_callbacks.has(p_entity):
		entity_kinematic_integration_callbacks.push_back(p_entity)
	else:
		printerr("Attempted to add duplicate kinematic integration callback")


func unregister_kinematic_integration_callback(p_entity: RuntimeEntity) -> void:
	if entity_kinematic_integration_callbacks.has(p_entity):
		entity_kinematic_integration_callbacks.erase(p_entity)
	else:
		printerr("Attempted to remove invalid kinematic integration callback")


func _entity_ready(p_entity: RuntimeEntity) -> void:
	_add_entity(p_entity)
	emit_signal("entity_added", p_entity)
	p_entity._entity_ready()


func _entity_deleting(p_entity: RuntimeEntity) -> void:
	_remove_entity(p_entity)
	emit_signal("entity_removed", p_entity)


static func _has_immediate_dependency_link(p_dependent_entity: RuntimeEntity, p_dependency_entity: RuntimeEntity) -> bool:
	if p_dependent_entity.strong_exclusive_dependencies.has(p_dependency_entity):
		return true
			
	return false


static func check_if_dependency_is_cyclic(p_root_entity: Node, p_current_enity: Node, p_is_root: bool) -> bool:
	var is_cyclic: bool = false
	
	for strong_exclusive_dependency in p_current_enity.strong_exclusive_dependencies:
		is_cyclic = check_if_dependency_is_cyclic(p_root_entity, strong_exclusive_dependency, false)
	
	if !p_is_root and p_root_entity == p_current_enity:
		is_cyclic = true
	
	return is_cyclic


static func _get_job_for_entity(p_entity: Node) -> EntityJob:
	var entity_job: EntityJob = p_entity.current_job
	if ! entity_job:
		entity_job = EntityJob.new([p_entity])
		entity_job.overall_time_usec += p_entity.physics_process_ticks_usec
		for strong_dependency in p_entity.strong_exclusive_dependencies:
			var strong_dependency_entity_job: EntityJob = _get_job_for_entity(strong_dependency)
			if strong_dependency_entity_job != entity_job:
				strong_dependency_entity_job.combine(entity_job)
				entity_job = strong_dependency_entity_job
		p_entity.current_job = entity_job
	
	return entity_job


func _create_entity_update_jobs() -> Array:
	var jobs: Array = []
	var pending_entities: Array = entity_reference_dictionary.values()
	for entity in pending_entities:
		var entity_job: EntityJob = _get_job_for_entity(entity)
		if ! jobs.has(entity_job):
			jobs.push_back(entity_job)
			
	jobs.sort_custom(EntityJob, "sort")
	return jobs


func get_dependent_entity_for_dependency(p_entity_dependency: Reference, p_entity_dependent: Reference) -> RuntimeEntity:
	if ! p_entity_dependency._entity:
		printerr("Could not get entity for dependency!")
		return null
	if ! p_entity_dependent._entity:
		printerr("Could not get entity for dependent!")
		return null
		
	if _has_immediate_dependency_link(p_entity_dependent._entity, p_entity_dependency._entity):
		return p_entity_dependent._entity
	else:
		printerr("Does not have dependency!")
		
	return null


func check_bidirectional_dependency(p_entity_dependency: Reference, p_entity_dependent: Reference) -> bool:
	if ! p_entity_dependency._entity or ! p_entity_dependent._entity:
		return false
	
	if _has_immediate_dependency_link(p_entity_dependency._entity, p_entity_dependent._entity):
		return true
	if _has_immediate_dependency_link(p_entity_dependent._entity, p_entity_dependency._entity):
		return true
		
	return false


func create_strong_dependency(p_dependent: EntityRef, p_dependency: EntityRef) -> StrongExclusiveEntityDependencyHandle:
	if ! p_dependent or ! p_dependency:
		return null
	
	var dependent_entity: Node = p_dependent._entity
	var dependency_entity: Node = p_dependency._entity
	
	if ! dependent_entity or ! dependency_entity:
		printerr("Could not get entity ref!")
		return null
	if dependent_entity == dependency_entity:
		printerr("Attempted to create dependency on self!")
		return null 
		
	return StrongExclusiveEntityDependencyHandle.new(p_dependent, p_dependency)


func get_entity_type_safe(p_target_entity: EntityRef) -> String:
	if p_target_entity._entity:
		return p_target_entity._entity.get_entity_type()
	else:
		return ""
		
func get_entity_last_transform_safe(p_target_entity: EntityRef) -> String:
	if p_target_entity._entity:
		return p_target_entity._entity.get_last_transform()
	else:
		return ""


func send_entity_message(p_source_entity: EntityRef, p_target_entity: EntityRef, p_message: String, p_message_args: Dictionary) -> void:
	if check_bidirectional_dependency(p_source_entity, p_target_entity):
		p_target_entity._entity._receive_entity_message(p_message, p_message_args)
	else:
		printerr("Could not send message to target entity! No dependency link!")

static func create_entity_instance(
	p_packed_scene: PackedScene,
	p_name: String = "NetEntity",
	p_master_id: int = NetworkManager.network_constants_const.SERVER_MASTER_PEER_ID
) -> Node:
	print_debug(
		"Creating entity instance {name} of type {type}".format(
			{"name": p_name, "type": p_packed_scene.resource_path}
		)
	)
	var instance: Node = p_packed_scene.instance()
	instance.set_name(p_name)
	instance.set_network_master(p_master_id)

	return instance


func instantiate_entity_and_setup(
	p_packed_scene: PackedScene,
	p_properties: Dictionary = {},
	p_name: String = "NetEntity",
	p_master_id: int = NetworkManager.network_constants_const.SERVER_MASTER_PEER_ID
) -> Node:
	var instance: Node = create_entity_instance(p_packed_scene, p_name, p_master_id)
	
	instance._entity_cache()
	for key in p_properties.keys():
		instance.simulation_logic_node.set(key, p_properties[key])
	
	instance._threaded_instance_setup(NetworkManager.network_entity_manager.NULL_NETWORK_INSTANCE_ID, null)
	
	return instance
	

"""
This method instantiates an entity and queues is to be added
to the scene. It is the function which should be called by
entities which spawn other entities which are required to
be avaliable next frame.

Return an EntityRef handle for the instance
"""
func spawn_entity(
	p_packed_scene: PackedScene,
	p_properties: Dictionary = {},
	p_name: String = "NetEntity",
	p_master_id: int = NetworkManager.network_constants_const.SERVER_MASTER_PEER_ID
) -> EntityRef:
	var instance: Node = instantiate_entity_and_setup(p_packed_scene, p_properties, p_name, p_master_id)
	if instance:
		EntityManager.scene_tree_execution_command(
			EntityManager.scene_tree_execution_table_const.ADD_ENTITY,
			instance,
			null
		)
		return instance.get_entity_ref()
	
	return null


func _reparent_unsafe(p_entity: Node, p_entity_parent_ref: EntityRef, p_attachment_id: int) -> void:
	var global_transform: Transform = p_entity.get_global_transform()
	
	p_entity.get_parent().remove_child(p_entity)
	if p_entity_parent_ref:
		var attachment_node = p_entity_parent_ref._entity.get_attachment_node(p_attachment_id)
		var relative_transform = attachment_node.get_global_transform().affine_inverse() * global_transform
		p_entity.set_transform(relative_transform)
		attachment_node.add_child(p_entity)
	else:
		p_entity.set_transform(global_transform)
		get_entity_root_node().add_child(p_entity)


func _process_reparenting() -> void:
	for entity in reparent_pending:
		_reparent_unsafe(entity, entity.pending_entity_parent_ref, entity.pending_attachment_id)
		
	reparent_pending.clear()


func _process(p_delta: float) -> void:
	var scheduler_usec_start:int = OS.get_ticks_usec()
	var jobs: Array = _create_entity_update_jobs()
	var scheduler_overall_time:int = OS.get_ticks_usec() - scheduler_usec_start
	
	var all_entities_representation_process_usec_start:int = OS.get_ticks_usec()
	for entity in get_all_entities():
		entity._entity_representation_process(p_delta)
	last_representation_process_usec = OS.get_ticks_usec() - all_entities_representation_process_usec_start
	
	emit_signal("process_complete", p_delta)


func _physics_process(p_delta: float) -> void:
	EntityManager.scene_tree_execution_table._execute_scene_tree_execution_table_unsafe()
	
	_process_reparenting()
	
	var scheduler_usec_start:int = OS.get_ticks_usec()
	var jobs: Array = _create_entity_update_jobs()
	var scheduler_overall_time:int = OS.get_ticks_usec() - scheduler_usec_start
	
	var entity_update_dependencies_usec_start: int = OS.get_ticks_usec()
	for entity in entity_reference_dictionary.values():
		entity._update_dependencies()
	last_update_dependencies_usec = OS.get_ticks_usec() - entity_update_dependencies_usec_start
	
	var entity_pre_physics_process_usec_start:int = OS.get_ticks_usec()
	for entity in entity_reference_dictionary.values():
		entity._entity_physics_pre_process(p_delta)
	last_physics_pre_process_usec = OS.get_ticks_usec() - entity_pre_physics_process_usec_start
	
	var entity_physics_process_usec_start:int = OS.get_ticks_usec()
	for job in jobs:
		for entity in job.entities:
			entity._entity_physics_process(p_delta)
	last_physics_process_usec = OS.get_ticks_usec() - entity_physics_process_usec_start
	
	for entity in entity_kinematic_integration_callbacks:
		entity._entity_kinematic_integration_callback(p_delta)
	
	var entity_post_physics_process_usec_start:int = OS.get_ticks_usec()
	for entity in entity_reference_dictionary.values():
		entity._entity_physics_post_process(p_delta)
	last_physics_post_process_usec = OS.get_ticks_usec() - entity_post_physics_process_usec_start
	
	_process_reparenting()
	
	emit_signal("physics_process_complete", p_delta)


func apply_project_settings() -> void:
	if Engine.is_editor_hint():
		if ! ProjectSettings.has_setting("entities/config/process_priority"):
			ProjectSettings.set_setting("entities/config/process_priority", 0)
	
			########
			# Save #
			########
			if ProjectSettings.save() != OK:
				printerr("Could not save project settings!")


func get_project_settings() -> void:
	process_priority = ProjectSettings.get_setting("entities/config/process_priority")


func start() -> void:
	set_process(true)
	set_physics_process(true)


func stop() -> void:
	set_process(false)
	set_physics_process(false)

func setup() -> void:
	scene_tree_execution_table.root_node = get_entity_root_node()

func _ready() -> void:
	apply_project_settings()
	get_project_settings()
	
	stop()
