extends Spatial

signal transform_changed()

func _notification(p_notification):
	if NOTIFICATION_TRANSFORM_CHANGED:
		emit_signal("transform_changed")
		
func _ready():
	set_notify_transform(true)