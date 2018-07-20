extends Node
tool

export(NodePath) var entity_node_path = NodePath()
var entity_node = null

func _ready():
	if !Engine.is_editor_hint():
		if has_node(entity_node_path):
			entity_node = get_node(entity_node_path)
			if entity_node == self:
				entity_node = null