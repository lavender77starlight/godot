extends Control

@onready var username_input: LineEdit = $VBoxContainer/UsernameLineEdit
@onready var email_input: LineEdit = $VBoxContainer/EmailLineEdit
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var login_button: Button = $VBoxContainer/LoginButton

func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	status_label.text = "Awaiting credentials..."

func _on_login_pressed() -> void:
	var username = username_input.text.strip_edges()
	var email = email_input.text.strip_edges()
	
	if username.is_empty() or email.is_empty():
		status_label.text = "Error: Username and email cannot be empty."
		return
		
	login_button.disabled = true
	status_label.text = "Authenticating with MongoDB Atlas..."
	
	# Call global GameManager authentication method
	GameManager.authenticate_user(username, email, Callable(self, "_on_auth_completed"))

func _on_auth_completed(success: bool, message: String) -> void:
	login_button.disabled = false
	if success:
		status_label.text = "Authentication successful! Initializing session..."
		# Start game session automatically after login
		GameManager.start_game_session("Mars_Surface_Mission_01", Callable(self, "_on_session_started"))
	else:
		status_label.text = "Failed: " + message

func _on_session_started(success: bool, message: String) -> void:
	if success:
		status_label.text = "Session active. Entering simulation..."
		# Transition to the main game scene
		get_tree().change_scene_to_file("res://scenes/MainGame.tscn")
	else:
		status_label.text = "Session Error: " + message
