extends Node
tool

const mutex_lock_const = preload("res://addons/gdutil/mutex_lock.gd")
var mutex: Mutex = Mutex.new()

var entity_pool: Array = []

signal entity_added(p_entity)
signal entity_removed(p_entity)


func _entity_ready(p_entity: Node) -> void:
	_add_entity(p_entity)
	emit_signal("entity_added", p_entity)
	p_entity._entity_ready()


func _entity_exiting(p_entity: Node) -> void:
	_remove_entity(p_entity)
	emit_signal("entity_removed", p_entity)


func _add_entity(p_entity: Node) -> void:
	var mutex_lock: mutex_lock_const = mutex_lock_const.new(mutex)
	entity_pool.append(p_entity)


func _remove_entity(p_entity: Node) -> void:
	var mutex_lock: mutex_lock_const = mutex_lock_const.new(mutex)
	entity_pool.erase(p_entity)


func get_all_entities() -> Array:
	var mutex_lock: mutex_lock_const = mutex_lock_const.new(mutex)
	var return_array: Array = []

	for entity in entity_pool:
		return_array.push_back(entity)

	return return_array


func get_entity_root_node() -> Node:
	return NetworkManager.get_entity_root_node()
