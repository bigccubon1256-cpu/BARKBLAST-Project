extends RigidBody3D

@export_group("Unit Stats")
@export var unit_name: String = "lotcher"
@export var energy_cost: float = 5.0
@export var hp_gain_on_place: int = 10
@export var hp_loss_on_death: int = 10
#=======ความแม่นสำหรับศัตรู=======
@export var accuracy: float = 0.989

var is_dead: bool = false
var tile_key: String = ""
var is_combat_started: bool = false

# --- ตัวแปรสำหรับระบบ Move และปืน ---
var active_gun: Node3D = null
var is_repositioning: bool = false
var is_selected: bool = false

func _ready():
	freeze = true # ล็อกไว้ก่อนเริ่ม

func activate_unit(key: String):
	tile_key = key

func start_combat():
	is_combat_started = true
	freeze = false 
	print(name + "ศัตรู พร้อมรบแล้ว!")

func _physics_process(_delta: float):
	# ถ้าอยู่ในโหมดย้าย ให้ข้ามการเช็คฟิสิกส์/ความเอียงไปก่อน
	if not is_combat_started: 
		return
	# ระบบความเอียง (ล้ม/ฟื้น) ของคุณ
	var tilt_angle = rad_to_deg(global_transform.basis.y.angle_to(Vector3.UP))
	if tilt_angle > 60:
		die()
	elif tilt_angle <= 45:
		revive()

func die():
	if is_dead: return 
	is_dead = true
	print(name + " ล้มลงแล้ว!")
	if get_tree().current_scene.has_method("reduce_army_hp"):
		# 🌟 เติม self, เข้าไปข้างหน้า เพื่อส่ง "ตัวมันเอง" ไปให้ MainManager เช็คค่าย!
		get_tree().current_scene.reduce_army_hp(self, hp_loss_on_death)

func revive():
	if not is_dead: return 
	is_dead = false
	print(name + " ลุกขึ้นสู้!")
	if get_tree().current_scene.has_method("restore_army_hp"):
		# 🌟 เติม self, เข้าไปตรงนี้ด้วยเหมือนกันครับ
		get_tree().current_scene.restore_army_hp(self, hp_loss_on_death)

# --- ระบบปืน ---
func pickup_gun(gun_node: Node3D):
	active_gun = gun_node
	if gun_node.has_method("equip_to"):
		gun_node.equip_to(self)
