extends Node
tool

const MAP_RESOURCE_IDENTIFIER = "mpr"

export(int) var last_representation_process_msec: int = 0
export(int) var last_physics_process_msec: int = 0

const mutex_lock_const = preload("res://addons/gdutil/mutex_lock.gd")
var mutex: Mutex = Mutex.new()

var reparent_pending: Dictionary = {}
var entity_reference_dictionary: Dictionary = {}

signal entity_added(p_entity)
signal entity_removed(p_entity)

signal process_complete(p_delta)
signal physics_process_complete(p_delta)

var get_map_id_for_entity_resource_funcref: FuncRef = FuncRef.new()
var get_entity_resource_for_map_id_funcref: FuncRef = FuncRef.new()

func assign_get_map_id_for_resource_function(p_node: Node, p_method : String) -> void:
	get_map_id_for_entity_resource_funcref.set_instance(p_node)
	get_map_id_for_entity_resource_funcref.set_function(p_method)
	
func assign_get_resource_for_map_id_function(p_node: Node, p_method : String) -> void:
	get_entity_resource_for_map_id_funcref.set_instance(p_node)
	get_entity_resource_for_map_id_funcref.set_function(p_method)

func get_map_id_for_entity_resource(p_resource: Resource) -> int:
	if get_map_id_for_entity_resource_funcref.is_valid():
		return get_map_id_for_entity_resource_funcref.call_func(p_resource)
		
	return -1
	
func get_entity_resource_for_map_id(p_int: int) -> Resource:
	if get_entity_resource_for_map_id_funcref.is_valid():
		return get_entity_resource_for_map_id_funcref.call_func(p_int)
		
	return null
	
func get_path_for_entity_resource(p_resource: Resource) -> String:
	if ! p_resource:
		return ""
	
	var map_resource_id: int = get_map_id_for_entity_resource(p_resource)
	print("map_resource_id %s" % str(map_resource_id))
	if map_resource_id != -1:
		return "%s://%s" % [MAP_RESOURCE_IDENTIFIER, str(map_resource_id)]
	
	return p_resource.resource_path
	
func get_entity_resource_for_path(p_path: String) -> Resource:
	var map_resource_string_beginning: String = "%s://" % MAP_RESOURCE_IDENTIFIER
	if p_path.begins_with(map_resource_string_beginning):
		var string_diget: String = p_path.right(map_resource_string_beginning.length())
		if string_diget.is_valid_integer():
			var id: int = string_diget.to_int()
			return get_entity_resource_for_map_id(id)
			
	return ResourceLoader.load(p_path)
	
func _entity_ready(p_entity: Node) -> void:
	_add_entity(p_entity)
	emit_signal("entity_added", p_entity)
	p_entity._entity_ready()


func _entity_exiting(p_entity: Node) -> void:
	_remove_entity(p_entity)
	emit_signal("entity_removed", p_entity)


func _add_entity(p_entity: Node) -> void:
	var mutex_lock: mutex_lock_const = mutex_lock_const.new(mutex)
	entity_reference_dictionary[p_entity.get_entity_ref()] = p_entity


func _remove_entity(p_entity: Node) -> void:
	var mutex_lock: mutex_lock_const = mutex_lock_const.new(mutex)
	entity_reference_dictionary.erase(p_entity.get_entity_ref())


func get_all_entities() -> Array:
	var mutex_lock: mutex_lock_const = mutex_lock_const.new(mutex)
	var return_array: Array = []

	for entity in entity_reference_dictionary.values():
		return_array.push_back(entity)

	return return_array


func get_entity_root_node() -> Node:
	return NetworkManager.get_entity_root_node()
	
	
func _create_entity_update_jobs() -> Array:
	var jobs: Array = []
	for entity in entity_reference_dictionary.values():
		jobs.push_back([entity])
	return jobs
	
	
#func _has_dependency_link(p_entity_a: Entity, p_entity_b: Entity) -> bool:
#	return false
	
	
#func get_validated_entity_by_ref(p_base_entity: Entity, p_reference: Reference) -> Entity:
#	return null
	
	
#func create_strong_dependency_for(p_base_entity: Entity, p_entity_ref: Reference) -> void:
#	pass
	
	
#func remove_strong_dependency_for(p_base_entity: Entity, p_entity_ref: Reference) -> void:
#	pass

func _process_reparenting() -> void:
	for entity in reparent_pending.keys():
		entity.set_entity_parent(reparent_pending[entity])


func _process(p_delta: float) -> void:
	var scheduler_msec_start:int = OS.get_ticks_msec()
	var jobs: Array = _create_entity_update_jobs()
	var scheduler_overall_time:int = OS.get_ticks_msec() - scheduler_msec_start
	
	var all_entities_representation_process_msec_start:int = OS.get_ticks_msec()
	for job in jobs:
		for entity in job:
			entity._entity_representation_process(p_delta)
	last_representation_process_msec = OS.get_ticks_msec() - all_entities_representation_process_msec_start
	
	emit_signal("process_complete", p_delta)
	
	
func _physics_process(p_delta: float) -> void:
	var scheduler_msec_start:int = OS.get_ticks_msec()
	var jobs: Array = _create_entity_update_jobs()
	var scheduler_overall_time:int = OS.get_ticks_msec() - scheduler_msec_start
	
	var entity_physics_process_msec_start:int = OS.get_ticks_msec()
	for job in jobs:
		for entity in job:
			entity._entity_physics_process(p_delta)
	last_physics_process_msec = OS.get_ticks_msec() - entity_physics_process_msec_start
	
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
