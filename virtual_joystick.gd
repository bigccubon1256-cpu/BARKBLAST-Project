extends Control

var center_pos: Vector2
var base_radius: float = 75.0 
var knob_radius: float = 30.0 

var output_vector: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var touch_index: int = -1

func _ready():
	# 1. คำนวณจุดกึ่งกลางจอยสติ๊ก
	center_pos = Vector2(size.x / 2, size.y / 2)
	
	# ==========================================
	# 💻 ระบบซ่อนตัวเมื่อเล่นบน PC
	# ==========================================
	# เช็คระบบปฏิบัติการว่าเป็น มือถือ/แท็บเล็ต หรือไม่?
	var is_mobile = OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android"
	
	if is_mobile:
		self.show() # ถ้าเป็น iPad ให้โชว์ตามปกติ
	else:
		self.hide() # 🌟 ถ้าเป็น PC (Windows/Mac) ให้ล่องหนไปเลย!
		set_process_input(false) # 🌟 ปิดระบบรับค่าทิ้งไปด้วย จะได้ไม่กินสเปคคอม

func _draw():
	draw_circle(center_pos, base_radius, Color(0, 0, 0, 0.3))
	var knob_pos = center_pos + (output_vector * base_radius)
	draw_circle(knob_pos, knob_radius, Color(1.0, 1.0, 1.0, 0.7))

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and not is_dragging:
			is_dragging = true
			touch_index = event.index
			_update_joystick(event.position)
			
		elif not event.pressed and event.index == touch_index:
			is_dragging = false
			touch_index = -1
			output_vector = Vector2.ZERO
			queue_redraw() 
			# 🌟 ตอนยกนิ้วออก สั่งปล่อยปุ่มคีย์บอร์ดทั้งหมด กล้องจะได้หยุดเดิน!
			_release_all_keys() 

	elif event is InputEventScreenDrag and is_dragging and event.index == touch_index:
		_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2):
	var offset = touch_pos - center_pos
	if offset.length() > base_radius:
		offset = offset.normalized() * base_radius
	output_vector = offset / base_radius
	queue_redraw()
	
	# 🌟 เรียกระบบคีย์บอร์ดผีทำงาน!
	_press_fake_keys()

# ==========================================
# ⌨️ ท่าไม้ตายหักดิบ: ระบบ "คีย์บอร์ดผี" (Fake Keyboard)
# หลอกระบบ Input ของเกมโดยตรง ไม่ต้องง้อโหนดกล้อง!
# ==========================================
func _press_fake_keys():
	# ⬅️➡️ แกน X (ซ้าย-ขวา)
	if output_vector.x < 0:
		Input.action_press("left", abs(output_vector.x))
		Input.action_release("right")
	elif output_vector.x > 0:
		Input.action_press("right", abs(output_vector.x))
		Input.action_release("left")
	else:
		Input.action_release("left")
		Input.action_release("right")

	# ⬆️⬇️ แกน Y (ขึ้น-ลง)
	if output_vector.y < 0:
		Input.action_press("up", abs(output_vector.y))
		Input.action_release("down")
	elif output_vector.y > 0:
		Input.action_press("down", abs(output_vector.y))
		Input.action_release("up")
	else:
		Input.action_release("up")
		Input.action_release("down")

# ฟังก์ชันสำหรับปล่อยปุ่มทั้งหมดตอนยกนิ้ว
func _release_all_keys():
	Input.action_release("left")
	Input.action_release("right")
	Input.action_release("up")
	Input.action_release("down")
