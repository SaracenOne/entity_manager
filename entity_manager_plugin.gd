extends EditorPlugin
tool

var editor_interface = null

func get_name(): 
	return "EntityManager"

func _enter_tree():
	editor_interface = get_editor_interface()
	
	add_autoload_singleton("EntityManager", "res://addons/entity_manager/entity_manager.gd")
	
	add_custom_type("SpatialEntity", "Spatial", preload("entity.gd"), editor_interface.get_base_control().get_icon("Spatial", "EditorIcons"))
	add_custom_type("Node2DEntity", "Node2D", preload("entity.gd"), editor_interface.get_base_control().get_icon("Node2D", "EditorIcons"))
	
	add_custom_type("LogicNode", "Node", preload("logic_node.gd"), editor_interface.get_base_control().get_icon("Node", "EditorIcons"))
	add_custom_type("SpatialLogicNode", "Node", preload("spatial_logic_node.gd"), editor_interface.get_base_control().get_icon("Node", "EditorIcons"))

func _exit_tree():
	remove_autoload_singleton("EntityManager")
	remove_custom_type("LogicNode")
	remove_custom_type("SpatialLogicNode")