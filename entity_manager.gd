extends Node
tool

var mutex = Mutex.new()
var entity_pool = []

signal entity_added(p_entity)
signal entity_removed(p_entity)

func _entity_ready(p_entity):
	_add_entity(p_entity)
	emit_signal("entity_added", p_entity)
	p_entity._entity_ready()
	
func _entity_exiting(p_entity):
	_remove_entity(p_entity)
	emit_signal("entity_removed", p_entity)

func _add_entity(p_entity):
	mutex.lock()
	entity_pool.append(p_entity)
	mutex.unlock()
	
func _remove_entity(p_entity):
	mutex.lock()
	entity_pool.erase(p_entity)
	mutex.unlock()