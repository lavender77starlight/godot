extends Control

@onready var oxygen_bar: ProgressBar = $VBoxContainer/OxygenBar
@onready var battery_bar: ProgressBar = $VBoxContainer/BatteryBar
@onready var temp_label: Label = $VBoxContainer/TempLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel

func _ready() -> void:
	if GameManager.is_connected_to_backend:
		status_label.text = "Backend Link: ONLINE"
		status_label.modulate = Color.GREEN
	else:
		status_label.text = "Backend Link: OFFLINE (Local Mode)"
		status_label.modulate = Color.YELLOW

func _process(delta: float) -> void:
	# Synchronize UI element values with GameManager telemetry state
	oxygen_bar.value = GameManager.suit_oxygen
	battery_bar.value = GameManager.suit_battery
	temp_label.text = "Suit Internal Temp: %.1f °C" % GameManager.suit_internal_temp
	
	# Optional: Warning colors when resources get critically low
	if GameManager.suit_oxygen < 20.0:
		oxygen_bar.modulate = Color.RED
	else:
		oxygen_bar.modulate = Color.WHITE
