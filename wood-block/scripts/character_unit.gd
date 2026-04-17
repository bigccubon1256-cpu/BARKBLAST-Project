extends RigidBody3D
class_name CharacterUnit

# เพิ่มค่า Stat ประจำตัว
@export var energy_required: float = 1.0  # ค่าพลังงานที่ใช้ตอนวาง
@export var hp_value: int = 1            # ค่าพลังชีวิตที่จะเพิ่มให้ทีม

signal character_down

var is_dead: bool = false

func _ready():
	# ในช่วงแรก (Setup) ให้หยุดนิ่งไว้ก่อน
	freeze = true
	# ตั้งค่า Contact Monitor เพื่อให้เช็กการชนได้
	contact_monitor = true
	max_contacts_reported = 5

func start_physics():
	freeze = false

func _physics_process(_delta):
	if not freeze and not is_dead:
		check_if_fallen()

func check_if_fallen():
	# ตรวจสอบองศาการเอียง (ถ้าเอียงเกิน 60 องศา ถือว่าล้ม)
	var up_vector = global_transform.basis.y
	var angle = up_vector.angle_to(Vector3.UP)
	
	if rad_to_deg(angle) > 60:
		is_dead = true
		emit_signal("character_down")
		# เปลี่ยนสีหรือแสดง Effect ว่าตายแล้ว
		print("ตัวละครล้มแล้ว!")
