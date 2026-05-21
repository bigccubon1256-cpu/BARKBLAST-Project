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



func _ready() -> void:
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
	if event.is_action_pressed("rotate"):
		saved_mouse_pos = get_viewport().get_mouse_position()
		# สั่งหยุดการขยับของเมาส์ปลอมชั่วคราว (ถ้าต้องการ)
		GlobalMouse.set_physics_process(false) 

	elif event.is_action_released("rotate"):
		GlobalMouse.set_physics_process(true)
		get_viewport().warp_mouse(saved_mouse_pos)

	if event is InputEventMouseMotion and Input.is_action_pressed("rotate"):
		var manual_relative = event.position - saved_mouse_pos
		if manual_relative.length() < 1.5: return
		
		rotate_keys_target -= manual_relative.x * mouse_sensitivity
		pitch_target -= manual_relative.y * mouse_sensitivity
		# 🌟 ใส่เบรกกันกล้องตีลังกา (ล็อกไว้ห้ามเกิน -80 ถึง 80 องศา)
		# ถ้าไม่อยากให้มันเงยหน้ามองฟ้าได้เลยตอนสร้าง ให้แก้ -80.0 เป็น 0.0 
		pitch_target = clamp(pitch_target, -45.0, 90.0)
		
		get_viewport().warp_mouse(saved_mouse_pos)
		get_viewport().warp_mouse(saved_mouse_pos)
	# ==========================================
	# 🌟 [เพิ่มใหม่!] ย้ายการเช็คซูมมาไว้ที่นี่ มันจะได้เคารพหน้าต่าง UI!
	# ==========================================
	if not ots_unit or not is_instance_valid(ots_unit): # ให้ซูมอิสระได้เฉพาะโหมด RTS ปกติ
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
