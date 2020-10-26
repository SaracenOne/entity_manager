extends Node
tool

export(int) var last_representation_process_usec: int = 0
export(int) var last_physics_process_usec: int = 0
export(int) var last_physics_post_process_usec: int = 0

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

var reparent_pending: Dictionary = {}
var entity_reference_dictionary: Dictionary = {}

signal entity_added(p_entity)
signal entity_removed(p_entity)

signal process_complete(p_delta)
signal physics_process_complete(p_delta)


func _add_entity(p_entity: Node) -> void:
	entity_reference_dictionary[p_entity.get_entity_ref()] = p_entity


func _remove_entity(p_entity: Node) -> void:
	entity_reference_dictionary.erase(p_entity.get_entity_ref())


func get_all_entities() -> Array:
	var return_array: Array = []

	for entity in entity_reference_dictionary.values():
		return_array.push_back(entity)

	return return_array


func _entity_ready(p_entity: Node) -> void:
	_add_entity(p_entity)
	emit_signal("entity_added", p_entity)
	p_entity._entity_ready()


func _entity_exiting(p_entity: Node) -> void:
	_remove_entity(p_entity)
	emit_signal("entity_removed", p_entity)


func get_entity_root_node() -> Node:
	return NetworkManager.get_entity_root_node()


static func _check_for_strong_exclusive_dependency(p_base_entity: Entity, p_current_entity: Entity) -> bool:
	if p_base_entity == p_current_entity:
		return true
	
	for strong_exclusive_dependency in p_current_entity.strong_exclusive_dependencies:
		if _check_for_strong_exclusive_dependency(p_base_entity, strong_exclusive_dependency):
			return true
		
	return false


static func _has_dependency_link(p_dependent_entity: Entity, p_dependency_entity: Entity) -> bool:
	if _check_for_strong_exclusive_dependency(p_dependency_entity, p_dependent_entity):
		return true
	else:
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


func get_dependent_entity_for_dependency(p_entity_dependency: Reference, p_entity_dependent: Reference) -> Entity:
	var entity_dependency: Entity = entity_reference_dictionary.get(p_entity_dependency)
	if ! entity_dependency:
		printerr("Could not get entity for dependency!")
	var entity_dependent: Entity = entity_reference_dictionary.get(p_entity_dependent)
	if ! entity_dependent:
		printerr("Could not get entity for dependent!")
		
	if _has_dependency_link(entity_dependent, entity_dependency):
		return entity_dependent
	else:
		printerr("Does not have dependency!")
		
	return null


func create_strong_dependency_for(p_entity_ref: Reference, p_base_entity: Entity) -> bool:
	var entity: Entity = entity_reference_dictionary.get(p_entity_ref)
	if entity == null:
		printerr("Could not get entity ref!")
	if entity == p_base_entity:
		printerr("Attempted to create dependency on self!")
		return false 

	entity._create_strong_exclusive_dependency(p_base_entity)
	return true


func remove_strong_dependency_for(p_entity_ref: Reference, p_base_entity: Entity) -> bool:
	var entity: Entity = entity_reference_dictionary.get(p_entity_ref)
	if entity:
		entity._remove_strong_exclusive_dependency(p_base_entity)
		return true
	else:
		printerr("Could not get entity ref")
		return false


func _process_reparenting() -> void:
	for entity in reparent_pending.keys():
		entity.set_entity_parent(reparent_pending[entity])


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
	var scheduler_usec_start:int = OS.get_ticks_usec()
	var jobs: Array = _create_entity_update_jobs()
	var scheduler_overall_time:int = OS.get_ticks_usec() - scheduler_usec_start
	
	var entity_physics_process_usec_start:int = OS.get_ticks_usec()
	for job in jobs:
		for entity in job.entities:
			entity._entity_physics_process(p_delta)
	last_physics_process_usec = OS.get_ticks_usec() - entity_physics_process_usec_start
	
	var entity_post_physics_process_usec_start:int = OS.get_ticks_usec()
	for entity in entity_reference_dictionary.values():
		entity._entity_physics_post_process(p_delta)
	last_physics_post_process_usec = OS.get_ticks_usec() - entity_post_physics_process_usec_start
	
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
	
	
func _ready() -> void:
	apply_project_settings()
	get_project_settings()
	
	if !Engine.is_editor_hint():
		set_process(true)
		set_physics_process(true)
	else:
		set_process(false)
		set_physics_process(false)
