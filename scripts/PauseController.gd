extends Node

# อ้างอิงสคริปต์หลัก MainManager
@onready var main_manager = get_node_or_null("/root/Main Scene Place")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		# ป้องกันการทำงานซ้ำซ้อนในเฟรมเดียวกัน
		get_viewport().set_input_as_handled()
		if main_manager and main_manager.has_method("handle_esc_press"):
			main_manager.handle_esc_press()
