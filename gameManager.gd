extends Node

signal telemetry_updated(data)
signal hazard_alert(hazard_type, message)
signal launch_status_changed(status)

# Backend API Configuration
const BASE_URL = "https://place-juvenile-penguin.abasthan.app/api"
var auth_token: String = ""
var current_user_id: String = ""
var current_session_id: String = ""

# Game State Telemetry
var suit_oxygen: float = 100.0
var suit_battery: float = 100.0
var suit_internal_temp: float = 21.5 # Celsius
var mars_surface_temp: float = -60.0 # Celsius
var radiation_level: float = 0.12 # mSv/h

var is_connected_to_backend: bool = false
var poll_timer: Timer

func _ready() -> void:
	print("GameManager initialized. Ready to connect to Express backend.")
	setup_poll_timer()

func setup_poll_timer() -> void:
	poll_timer = Timer.new()
	poll_timer.wait_time = 2.0 # Poll telemetry every 2 seconds
	poll_timer.autostart = false
	poll_timer.one_shot = false
	poll_timer.connect("timeout", Callable(self, "_on_poll_timeout"))
	add_child(poll_timer)

# --- Authentication & Session Management ---

func authenticate_user(username: String, email: String, callback: Callable) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_auth_completed").bind(http, callback))
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"username": username,
		"email": email
	})
	
	var err = http.request(BASE_URL + "/auth/login", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("Error launching authentication request: ", err)
		callback.call(false, "Failed to connect to backend server.")

func _on_auth_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest, callback: Callable) -> void:
	http_node.queue_free()
	
	if response_code == 200 or response_code == 201:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("token"):
			auth_token = json["token"]
			if json.has("user") and json["user"].has("id"):
				current_user_id = json["user"]["id"]
			is_connected_to_backend = true
			print("Successfully authenticated with MongoDB Atlas backend!")
			callback.call(true, "Authentication successful.")
			return
			
	var error_msg = "Authentication failed with code: " + str(response_code)
	print(error_msg)
	callback.call(false, error_msg)

# --- Game Session & Telemetry Sync ---

func start_game_session(session_name: String, callback: Callable) -> void:
	if auth_token.is_empty():
		callback.call(false, "Not authenticated. Please log in first.")
		return
		
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_session_started").bind(http, callback))
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + auth_token
	]
	var body = JSON.stringify({
		"sessionName": session_name,
		"suitOxygen": suit_oxygen,
		"suitBattery": suit_battery,
		"suitInternalTemp": suit_internal_temp
	})
	
	var err = http.request(BASE_URL + "/sessions/start", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		callback.call(false, "Failed to start session.")

func _on_session_started(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest, callback: Callable) -> void:
	http_node.queue_free()
	if response_code == 201 or response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("sessionId"):
			current_session_id = json["sessionId"]
			poll_timer.start()
			print("Game session started successfully: ", current_session_id)
			callback.call(true, "Session active.")
			return
	callback.call(false, "Failed to initialize session on backend.")

func update_telemetry(oxygen: float, battery: float, temp: float) -> void:
	suit_oxygen = oxygen
	suit_battery = battery
	suit_internal_temp = temp
	
	if current_session_id.is_empty() or not is_connected_to_backend:
		return
		
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_telemetry_updated").bind(http))
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + auth_token
	]
	var body = JSON.stringify({
		"sessionId": current_session_id,
		"suitOxygen": suit_oxygen,
		"suitBattery": suit_battery,
		"suitInternalTemp": suit_internal_temp,
		"marsSurfaceTemp": mars_surface_temp,
		"radiationLevel": radiation_level
	})
	
	http.request(BASE_URL + "/telemetry/update", headers, HTTPClient.METHOD_POST, body)

func _on_telemetry_updated(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest) -> void:
	http_node.queue_free()
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("hazards") and json["hazards"].size() > 0:
			for hazard in json["hazards"]:
				emit_signal("hazard_alert", hazard.get("type", "UNKNOWN"), hazard.get("message", "Hazard detected!"))

func _on_poll_timeout() -> void:
	update_telemetry(suit_oxygen, suit_battery, suit_internal_temp)

# --- Rocket Launch Sequence Trigger ---

func trigger_rocket_launch(payload_data: Dictionary, callback: Callable) -> void:
	if auth_token.is_empty():
		callback.call(false, "Authentication required for launch sequence.")
		return
		
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_launch_completed").bind(http, callback))
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + auth_token
	]
	var body = JSON.stringify(payload_data)
	
	http.request(BASE_URL + "/rocket/launch", headers, HTTPClient.METHOD_POST, body)

func _on_launch_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest, callback: Callable) -> void:
	http_node.queue_free()
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		emit_signal("launch_status_changed", "LAUNCHED")
		callback.call(true, json)
	else:
		emit_signal("launch_status_changed", "ABORTED")
		callback.call(false, "Launch sequence aborted by backend safety protocols.")
