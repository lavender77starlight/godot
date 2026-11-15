extends Node3D

@onready var launch_button: Button = $UI/LaunchButton
@onready var status_indicator: Label = $UI/StatusIndicator

func _ready() -> void:
	launch_button.pressed.connect(_on_launch_pressed)
	
	# Listen for launch status changes broadcasted from backend sync
	if not GameManager.is_connected("launch_status_changed", Callable(self, "_on_launch_status_changed")):
		GameManager.connect("launch_status_changed", Callable(self, "_on_launch_status_changed"))

func _on_launch_pressed() -> void:
	launch_button.disabled = true
	status_indicator.text = "Transmitting launch payload to server..."
	
	var payload = {
		"sessionId": GameManager.current_session_id,
		"launchCode": "MARS_ASCENT_VERIFY_01",
		"oxygenStatus": GameManager.suit_oxygen,
		"batteryStatus": GameManager.suit_battery
	}
	
	# Call global GameManager rocket launcher method
	GameManager.trigger_rocket_launch(payload, Callable(self, "_on_launch_response"))

func _on_launch_response(success: bool, response_data) -> void:
	if not success:
		launch_button.disabled = false
		status_indicator.text = "Launch Sequence Aborted by Server."

func _on_launch_status_changed(status: String) -> void:
	status_indicator.text = "Rocket Status: " + status
	if status == "LAUNCHED":
		print("Triggering lift-off sequence animations and cutscenes!")
