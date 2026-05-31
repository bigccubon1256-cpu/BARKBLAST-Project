extends Control

signal charge_finished(power)
signal charge_canceled()

@onready var power_bar = $PowerBar
@onready var power_label = $PowerLabel
@onready var thumb = $PowerBar/Thumb 

var max_power: float = 50
var current_power: float = 0
var is_dragging: bool = false
var drag_start_y: float = 0

# 🌟 [ตัวแปรใหม่!] เอาไว้จดจำแอนิเมชันสปริงที่กำลังเล่นอยู่
var active_tween: Tween 

@export var drag_sensitivity: float = 0.3 

func _ready():
	hide() 

func start_charging(p_max_power: float):
	# 🌟 [หัวใจสำคัญ!] ถ้ามีแอนิเมชันเก่ากำลังจะสั่งปิดจอ ให้สั่งฆ่าทิ้ง (kill) ทันที!
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	max_power = p_max_power
	current_power = 0.0
	is_dragging = false
	power_bar.max_value = max_power
	update_display()
	show()

func update_display():
	power_bar.value = current_power
	if power_label:
		power_label.text = str(int(current_power)) + " / " + str(int(max_power))
		
	var pct = current_power / max_power
	var thumb_top_pos = -(thumb.size.y / 20.0)
	var thumb_bottom_pos = power_bar.size.y - (thumb.size.y / 4)
	
	thumb.position.y = lerp(thumb_top_pos, thumb_bottom_pos, pct)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start_y = event.position.y
			current_power = 0.0
			update_display()
		else:
			# --- จังหวะปล่อยสปริง! ---
			if is_dragging:
				is_dragging = false
				
				if current_power > 0:
					charge_finished.emit(current_power) 
					
					# 🌟 [อัปเดตระบบแอนิเมชัน] ให้ใช้ active_tween แทนของเดิม
					if active_tween and active_tween.is_valid():
						active_tween.kill()
					active_tween = create_tween()
					
					var thumb_top_pos = -(thumb.size.y / 20.0)
					var bounce_distance = 3.0 
					
					active_tween.tween_property(power_bar, "value", 0.0, 0.05)
					active_tween.parallel().tween_property(thumb, "position:y", thumb_top_pos - bounce_distance, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					active_tween.tween_property(thumb, "position:y", thumb_top_pos, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					
					# คำสั่งนี้จะถูกยกเลิกถ้าระบบยิง Semi-Auto สั่ง start_charging สวนขึ้นมา!
					active_tween.tween_callback(hide) 
					
				else:
					hide()
					charge_canceled.emit()

	elif event is InputEventMouseMotion and is_dragging:
		var diff_y = event.position.y - drag_start_y
		var thumb_top_pos = -(thumb.size.y / 20.0)
		var thumb_bottom_pos = power_bar.size.y - (thumb.size.y / 4)
		var total_travel = (thumb_bottom_pos - thumb_top_pos) * power_bar.scale.y
		
		var dynamic_sensitivity = max_power / total_travel
		current_power = max(0.0, diff_y * dynamic_sensitivity)
		current_power = clamp(current_power, 0.0, max_power)
		update_display()
