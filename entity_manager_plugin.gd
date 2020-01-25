extends EditorPlugin
tool

var editor_interface : EditorInterface = null

func get_name() -> String: 
	return "EntityManager"

func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	
	add_autoload_singleton("EntityManager", "res://addons/entity_manager/entity_manager.gd")
	
	add_custom_type("SpatialEntity", "Spatial", preload("entity.gd"), editor_interface.get_base_control().get_icon("Spatial", "EditorIcons"))
	add_custom_type("Node2DEntity", "Node2D", preload("entity.gd"), editor_interface.get_base_control().get_icon("Node2D", "EditorIcons"))

func _exit_tree() -> void:
	remove_custom_type("SpatialEntity")
	remove_custom_type("Node2DEntity")

	remove_autoload_singleton("EntityManager")
