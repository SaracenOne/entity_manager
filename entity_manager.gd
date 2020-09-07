extends Node
tool

const MAP_RESOURCE_IDENTIFIER = "mpr"

export(int) var last_process_msec: int = 0
export(int) var last_physics_process_msec: int = 0

const mutex_lock_const = preload("res://addons/gdutil/mutex_lock.gd")
var mutex: Mutex = Mutex.new()

var entity_list: Array = []

signal entity_added(p_entity)
signal entity_removed(p_entity)

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
	entity_list.append(p_entity)


func _remove_entity(p_entity: Node) -> void:
	var mutex_lock: mutex_lock_const = mutex_lock_const.new(mutex)
	entity_list.erase(p_entity)


func get_all_entities() -> Array:
	var mutex_lock: mutex_lock_const = mutex_lock_const.new(mutex)
	var return_array: Array = []

	for entity in entity_list:
		return_array.push_back(entity)

	return return_array


func get_entity_root_node() -> Node:
	return NetworkManager.get_entity_root_node()

func _process(p_delta: float) -> void:
	var msec_start:int = OS.get_ticks_msec()
	for entity in entity_list:
		entity._entity_process(p_delta)
	last_process_msec = OS.get_ticks_msec() - msec_start
	
func _physics_process(p_delta: float) -> void:
	var msec_start:int = OS.get_ticks_msec()
	for entity in entity_list:
		entity._entity_physics_process(p_delta)
	last_physics_process_msec = OS.get_ticks_msec() - msec_start
	
func _ready() -> void:
	if !Engine.is_editor_hint():
		set_process(true)
		set_physics_process(true)
	else:
		set_process(false)
		set_physics_process(false)
