extends Control

@onready var username_input = $VBoxContainer/UsernameLineEdit
@onready var email_input = $VBoxContainer/EmailLineEdit
@onready var status_label = $VBoxContainer/StatusLabel

func _on_login_button_pressed() -> void:
    var username = username_input.text
    var email = email_input.text
    
    status_label.text = "Authenticating..."
    
    # Directly call the global GameManager method
    GameManager.authenticate_user(username, email, Callable(self, "_on_auth_response"))

func _on_auth_response(success: bool, message: String) -> void:
    if success:
        status_label.text = "Success! Starting session..."
        # Automatically trigger session start after login
        GameManager.start_game_session("Mars_Surface_Alpha", Callable(self, "_on_session_started"))
    else:
        status_label.text = "Error: " + message

func _on_session_started(success: bool, message: String) -> void:
    if success:
        # Transition to main game scene
        get_tree().change_scene_to_file("res://scenes/MainGame.tscn")
    else:
        status_label.text = "Session Error: " + message
