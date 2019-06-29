extends Node
tool

export(NodePath) var _entity_node_path = NodePath()
var _entity_node = null

func get_entity_node():
	return _entity_node

func _ready():
	if !Engine.is_editor_hint():
		if has_node(_entity_node_path):
			_entity_node = get_node(_entity_node_path)
			if _entity_node == self:
				_entity_node = null
