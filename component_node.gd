extends Node
class_name ComponentNode
tool

export(NodePath) var _entity_node_path : NodePath = NodePath()
var _entity_node : Node = null

func get_entity_node() -> Node:
	return _entity_node

func _ready() -> void:
	if !Engine.is_editor_hint():
		_entity_node = get_node_or_null(_entity_node_path)
		if _entity_node == self:
			_entity_node = null
