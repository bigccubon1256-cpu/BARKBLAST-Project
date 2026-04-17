extends Camera3D

# ความกว้างที่ต้องการให้กล้องส่าย (องศา)
@export var rotation_amount = 2.5
# ความเร็วในการเคลื่อนที่ (ความสมูท)
@export var lerp_speed = 1.5

@onready var start_rotation = rotation

func _process(delta):
	# 1. หาตำแหน่งเมาส์สัมพันธ์กับขนาดหน้าจอ (-0.5 ถึง 0.5)
	var screen_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	var offset_x = (mouse_pos.x / screen_size.x) - 0.5
	var offset_y = (mouse_pos.y / screen_size.y) - 0.5
	
	# 2. คำนวณค่า Rotation เป้าหมาย (สลับแกน: เมาส์ซ้าย-ขวา = หมุนแกน Y, เมาส์บน-ลง = หมุนแกน X)
	var target_rot = start_rotation
	target_rot.y = start_rotation.y - deg_to_rad(offset_x * rotation_amount)
	target_rot.x = start_rotation.x - deg_to_rad(offset_y * rotation_amount)
	
	# 3. ใช้ lerp เพื่อให้กล้องหันตามอย่างนุ่มนวล
	rotation.x = lerp_angle(rotation.x, target_rot.x, delta * lerp_speed)
	rotation.y = lerp_angle(rotation.y, target_rot.y, delta * lerp_speed)
