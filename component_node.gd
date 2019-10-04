extends Node
class_name ComponentNode
tool

export(NodePath) var _entity_node_path : NodePath = NodePath()

func get_entity_node() -> Node:
	return get_node_or_null(_entity_node_path)
