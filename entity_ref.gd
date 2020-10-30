extends Reference
class_name EntityRef
tool

# Warning! Do not access this directly from another entity!
var _entity: Node = null

func _init(p_entity) -> void:
	_entity = p_entity
