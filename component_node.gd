extends Node
class_name ComponentNode
tool

var entity_node: Node = null
export (NodePath) var _entity_node_path: NodePath = NodePath()
var nodes_cached: bool = false

func nodes_are_cached() -> bool:
	return nodes_cached


func get_entity_node() -> Node:
	return entity_node


func cache_nodes() -> void:
	nodes_cached = true
	
	entity_node = get_node_or_null(_entity_node_path)
	if entity_node == self:
		entity_node = null


func _threaded_instance_setup(p_instance_id: int, p_network_reader: Reference) -> void:
	pass


func _threaded_instance_post_setup() -> void:
	pass
