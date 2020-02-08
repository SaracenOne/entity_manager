extends Node
class_name ComponentNode
tool

var entity_node : Node = null
export(NodePath) var _entity_node_path : NodePath = NodePath()

func get_entity_node() -> Node:
	return entity_node
	
func cache_nodes():
	entity_node = get_node_or_null(_entity_node_path)
	if entity_node == self:
		entity_node = null

func _ready() -> void:
	cache_nodes()
