extends Spatial

signal transform_changed()

func _notification(p_notification : int) -> void:
	match p_notification:
		NOTIFICATION_TRANSFORM_CHANGED:
			emit_signal("transform_changed")
		
func _ready() -> void:
	set_notify_transform(true)
