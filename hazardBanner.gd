extends Label

func _ready() -> void:
	text = ""
	visible = false
	
	# Connect to GameManager signal for live environmental hazards
	if not GameManager.is_connected("hazard_alert", Callable(self, "_on_hazard_alert")):
		GameManager.connect("hazard_alert", Callable(self, "_on_hazard_alert"))

func _on_hazard_alert(hazard_type: String, message: String) -> void:
	text = "WARNING [%s]: %s" % [hazard_type.to_upper(), message]
	visible = true
	
	# Play alert pulse or sound effect here if desired
	print("Hazard alert received by component: ", hazard_type)
	
	# Auto-hide the banner after 6 seconds
	var timer = get_tree().create_timer(6.0)
	await timer.timeout
	visible = false
