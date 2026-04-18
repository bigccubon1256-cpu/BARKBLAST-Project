extends Node3D

@onready var rotation_x = $CameraRotationX
@onready var zoon_pivot = $CameraRotationX/CameraZoomPivot
@onready var camera = $CameraRotationX/CameraZoomPivot/Camera3D

var move_speed = 0.6
var move_target: Vector3
var rotate_keys_speed = 1.5
var rotate_keys_target: float
var zoom_speed = 1.0
var zoom_target: float
var min_zoom = -20.0
var max_zoom = 20.0
var mouse_sensitivity = 0.20
var ots_unit: Node3D = null

var saved_mouse_pos: Vector2 = Vector2.ZERO 
var pitch_target: float = 0.0 
# ==========================================
# 🌟 ตัวแปรระบบหน้าจอโยกแผ่นดินไหว (Smooth Earthquake)
# ==========================================
var trauma: float = 0.0 
var trauma_decay: float = 1.5 # 🌟 หายสั่นช้าลง จะได้โยกค้างไว้นานๆ
var max_x_offset: float = 0.8 # 🌟 เพิ่มระยะเหวี่ยงเป็น 80 เซนติเมตร! (กว้างมาก)
var max_y_offset: float = 0.6 # 🌟 เหวี่ยงบนล่าง 60 เซนติเมตร!
var max_r_offset: float = 4.0 # 🌟 [ตัวใหม่!] องศาการ "เอียงหน้าจอ" (Roll) ทำให้ดูเหมือนแผ่นดินไหวจริง



# ==========================================
# 🌟 ตัวแปรที่ต้องเอาไปเพิ่มในกลุ่มตัวแปร Touch ด้านบนสุดครับ!
# ==========================================
var touch_start_pos: Vector2 = Vector2.ZERO
var is_camera_rotating: bool = false
var drag_deadzone: float = 15.0 # 🌟 ระยะหน่วงกันกล้องกระตุก (ต้องลากเกิน 15 พิกเซล กล้องถึงจะหมุน)
# ==========================================
# 🌟 ตัวแปรระบบสัมผัส (สลับโหมด: ลาก=หัน / ดับเบิลเทป=ลากคลุม)
# ==========================================
var touch_points: Dictionary = {}
var initial_pinch_distance: float = 0.0
var touch_sensitivity: float = 0.25 
var pinch_zoom_speed: float = 0.05  

var last_tap_time: float = 0.0
var double_tap_threshold: float = 300.0 # เวลาดับเบิลคลิก (มิลลิวินาที)
var is_double_tapping: bool = false

var selection_start_pos: Vector2 = Vector2.ZERO
var selection_current_pos: Vector2 = Vector2.ZERO
var is_drawing_box: bool = false

# 🌟 ตัวแปรรับค่าจากปุ่มเดินบนหน้าจอ (UI Joystick/Buttons)
var ui_move_direction: Vector2 = Vector2.ZERO



func _ready() -> void:
	# 🌟 ประกาศตัวออกไมค์เลยว่า "ฉันคือกล้องหลักโว้ย!"
	add_to_group("RTSCamera")
	# 🌟 ปิดโชว์เมาส์เมื่อเล่นบน iPad / โทรศัพท์
	if OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android":
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	if rotation_x.rotation_degrees.x != 0:
		camera.rotation_degrees.x = rotation_x.rotation_degrees.x
		rotation_x.rotation_degrees.x = 0
		
	pitch_target = camera.rotation_degrees.x
		
	move_target = position
	rotate_keys_target = rotation_degrees.y
	zoom_target = camera.position.z

func set_ots_mode(unit: Node3D):
	ots_unit = unit
	if unit:
		var offset_x = 0.0 
		if unit.has_meta("linked_gun"):
			var gun = unit.get_meta("linked_gun")
			if is_instance_valid(gun):
				var local_gun_pos = unit.to_local(gun.global_position)
				offset_x = local_gun_pos.x * 0.0 
				
		camera.position.x = offset_x
	else:
		camera.position.x = 0.0
		move_target = position
		rotate_keys_target = rotation_degrees.y
		zoom_target = camera.position.z




# ฟังก์ชันรับแรงกระแทกจาก MainManager
func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0) # สะสมแรงสั่น แต่ไม่ให้เกิน 1.0 (เดี๋ยวอ้วก)






func _unhandled_input(event: InputEvent) -> void:
	
	# ----------------------------------------------------
	# 📱 1. ระบบสัมผัสสำหรับ iPad
	# ----------------------------------------------------
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			
			if event.index == 0:
				touch_start_pos = event.position # 🌟 จำตำแหน่งที่นิ้วแตะจอครั้งแรก
				is_camera_rotating = false # รีเซ็ตสถานะการหมุนกล้อง
				
				var current_time = Time.get_ticks_msec()
				# 🌟 เช็คดับเบิลแทป (แตะ -> ปล่อย -> แตะค้าง)
				if current_time - last_tap_time < double_tap_threshold:
					is_double_tapping = true
					is_drawing_box = true
					selection_start_pos = event.position
					Input.vibrate_handheld(50)
				else:
					is_double_tapping = false
					
				last_tap_time = current_time
		else:
			touch_points.erase(event.index)
			if event.index == 0:
				is_double_tapping = false
				is_drawing_box = false
				is_camera_rotating = false

	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		
		# 👆 ลากนิ้วเดียว
		if touch_points.size() == 1:
			var main_scene = get_tree().current_scene
			var is_holding_unit = false
			if main_scene and main_scene.get("dragging_unit") != null:
				is_holding_unit = true
			
			# 🛑 [โหมด 1] ถ้าดับเบิลแทปอยู่ -> ลากคลุม (ห้ามหันกล้อง)
			if is_double_tapping:
				selection_current_pos = event.position
				
			# 🛑 [โหมด 2] ถ้าถือยูนิตอยู่ -> ย้ายยูนิต (ห้ามหันกล้อง)
			elif is_holding_unit:
				pass # ไม่ต้องทำอะไร ปล่อยให้สคริปต์หลักจัดการยูนิตไป
				
			# 🟢 [โหมด 3] ลากนิ้วปกติ -> หันกล้อง (พร้อมระบบกันกระตุก)
			else:
				# 🌟 พระเอกกู้ชีพ! ถ้ายังไม่เริ่มหมุน ให้เช็คว่าลากนิ้วเกินระยะ Deadzone หรือยัง?
				if not is_camera_rotating:
					if touch_start_pos.distance_to(event.position) > drag_deadzone:
						is_camera_rotating = true
				
				# 🌟 ถ้าผ่าน Deadzone มาแล้ว ให้กล้องหมุนตามปกติตลอดการลาก
				if is_camera_rotating:
					rotate_keys_target -= event.relative.x * touch_sensitivity
					pitch_target -= event.relative.y * touch_sensitivity
					pitch_target = clamp(pitch_target, -45.0, 90.0)
		
		# ✌️ ซูม 2 นิ้ว
		elif touch_points.size() == 2 and (not ots_unit or not is_instance_valid(ots_unit)):
			var points = touch_points.values()
			var current_distance = points[0].distance_to(points[1])
			var distance_diff = initial_pinch_distance - current_distance
			
			zoom_target += distance_diff * pinch_zoom_speed
			zoom_target = clamp(zoom_target, min_zoom, max_zoom)
			initial_pinch_distance = current_distance

	# ----------------------------------------------------
	# 💻 2. ระบบเมาส์สำหรับ PC 
	# ----------------------------------------------------
	if event.is_action_pressed("rotate"):
		# 🌟 พระเอกกู้ชีพฝั่ง PC! ถ้ากด Ctrl ค้างไว้ตอนคลิก แปลว่าจะลากคลุม -> สั่งบล็อกกล้องทันที!
		if Input.is_key_pressed(KEY_CTRL):
			return 
			
		saved_mouse_pos = get_viewport().get_mouse_position()
		if has_node("/root/GlobalMouse"): 
			get_node("/root/GlobalMouse").set_physics_process(false) 

	elif event.is_action_released("rotate"):
		if has_node("/root/GlobalMouse"):
			get_node("/root/GlobalMouse").set_physics_process(true)
		get_viewport().warp_mouse(saved_mouse_pos)

	if event is InputEventMouseMotion and Input.is_action_pressed("rotate"):
		# 🌟 ตอนลากเมาส์ก็ต้องเช็ค Ctrl ด้วย! ถ้ากดอยู่ ห้ามหมุนกล้องเด็ดขาด!
		if Input.is_key_pressed(KEY_CTRL):
			return
			
		var manual_relative = event.position - saved_mouse_pos
		if manual_relative == Vector2.ZERO: return
		
		rotate_keys_target -= manual_relative.x * mouse_sensitivity
		pitch_target -= manual_relative.y * mouse_sensitivity
		pitch_target = clamp(pitch_target, -45.0, 90.0)
		
		get_viewport().warp_mouse(saved_mouse_pos)

	if not ots_unit or not is_instance_valid(ots_unit): 
		if event.is_action_released("camera_zoom_in"):
			zoom_target -= zoom_speed
		elif event.is_action_released("camera_zoom_out"):
			zoom_target += zoom_speed






func _process(delta: float) -> void:
	# ==========================================
	# 🔴 โหมดเล็งยิง (OTS)
	# ==========================================
	if ots_unit and is_instance_valid(ots_unit):
		# 🌟 [แก้ตรงนี้ 1] เอา Vector3(0, -10, 0) ทิ้งไป! ให้กล้องโฟกัสที่เป้าหมายเป๊ะๆ ไม่มุดดินแล้ว!
		move_target = ots_unit.global_position + Vector3(0, -10, 0)
		rotate_keys_target = ots_unit.global_rotation_degrees.y + 180.0
		
		# 🌟 [แก้ตรงนี้ 2] ลบบรรทัด zoom_target = 4.5 ทิ้งไปเลยครับ!
		
		# 🌟 พระเอกอยู่ตรงนี้: ใช้ pitch_target ที่ MainManager สั่งมา คุมการก้มเงย
		var target_pitch_rad = deg_to_rad(pitch_target)
		camera.rotation.x = lerp_angle(camera.rotation.x, target_pitch_rad, 0.1)
		
		position = lerp(position, move_target, 0.1)
		camera.position.z = lerp(camera.position.z, zoom_target, 0.1)
		
		var current_y = rotation.y
		var target_y = deg_to_rad(rotate_keys_target)
		rotation.y = lerp_angle(current_y, target_y, 0.1)
		
	# ==========================================
	# 🔵 โหมด RTS ปกติ 
	# ==========================================
	else:
		var input_direction = Input.get_vector("left", "right", "up", "down")
		
		# 🌟 ผสมปุ่มเดินจากคีย์บอร์ด + ปุ่มเดินบนหน้าจอเข้าด้วยกัน!
		var combined_input = input_direction + ui_move_direction
		if combined_input.length() > 1.0:
			combined_input = combined_input.normalized()
			
		var movement_direction = (transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
		var rotate_keys = Input.get_axis("rotate_left", "rotate_right")
		
		# 🚨 [ลบตัวแปร zoom_dir ตรงนี้ทิ้งไปแล้ว!]
		
		move_target += move_speed * movement_direction
		rotate_keys_target += rotate_keys * rotate_keys_speed
		
		# 🌟 จำกัดระยะซูมไว้เหมือนเดิม (ค่าถูกบวกลบมาจาก _unhandled_input แล้ว)
		zoom_target = clamp(zoom_target, min_zoom, max_zoom)
		
		position = lerp(position, move_target, 0.1)
		
		var current_y = rotation.y
		var target_y = deg_to_rad(rotate_keys_target)
		rotation.y = lerp_angle(current_y, target_y, 0.1)
		
		# 🌟 พระเอกคนเดิม: ใช้ pitch_target คุมการก้มเงยเหมือนกันเป๊ะ
		var target_pitch_rad = deg_to_rad(pitch_target)
		camera.rotation.x = lerp_angle(camera.rotation.x, target_pitch_rad, 0.1)
		camera.position.z = lerp(camera.position.z, zoom_target, 0.10)

	# ==========================================
	# 🌟 ระบบคำนวณหน้าจอโยกแผ่นดินไหว (Smooth Earthquake)
	# ==========================================
	if trauma > 0.0:
		trauma = max(trauma - trauma_decay * delta, 0.0)
		var shake = trauma * trauma 
		
		var time = Time.get_ticks_msec() / 1000.0
		# 🌟 ลดความเร็วคลื่นลงเหลือ 12-15! มันจะกลายเป็นการ "เหวี่ยงโยก" แบบเรือโคลงเคลง แทนการกระตุกรัวๆ
		var shake_speed = 12.0 
		
		# โยกเลนส์ซ้ายขวา/บนล่างแบบวงกว้าง
		camera.h_offset = max_x_offset * shake * sin(time * shake_speed)
		camera.v_offset = max_y_offset * shake * cos(time * shake_speed * 1.2)
		
		# 🌟 ทีเด็ด! สั่งให้หน้าจอ "เอียง" ซ้ายขวาผสมไปด้วย ฟีลลิ่งเหมือนโดนแรงระเบิด
		camera.rotation_degrees.z = max_r_offset * shake * sin(time * shake_speed * 0.8)
	else:
		# ถ้าไม่สั่น ให้ทุกอย่างกลับมาตรงเป๊ะ
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		camera.rotation_degrees.z = 0.0
