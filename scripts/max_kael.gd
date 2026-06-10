extends RigidBody3D

@export_group("Unit Stats")
@export var unit_name: String = "max_kael"
@export var energy_cost: float = 10.0
@export var hp_gain_on_place: int = 10
@export var hp_loss_on_death: int = 30

var is_dead: bool = false
var tile_key: String = ""
var is_combat_started: bool = false

# --- ตัวแปรสำหรับระบบ Move และปืน ---
var active_gun: Node3D = null
var is_repositioning: bool = false
var is_selected: bool = false

# --- ข้อมูล Skill ---
var skill_name: String = "LAST STAND"
var skill_description: String = "When a shot kills an enemy, a random eligible [Forces] with a gun is selected to shoot next. If they kill, the chain continues. If any shot misses or fails to kill, the turn ends immediately. Character selection is locked, and options are restricted to Shoot and Snap."
var skill_conditions: String = "Conditions: Turn 2 and later, when Player ARMY HP < 50%."
var skill_icon_path: String = "res://assets/foto/Max Kael-Skillv2.png"
var skill_fill_icon_path: String = "res://assets/foto/Max Kael-Skill-Fill-v2.png"
var skill_theme_color: Color = Color(0.0, 1.0, 0.835, 1.0)

func _ready():
	freeze = true # ล็อกไว้ก่อนเริ่มช่วง Setup

func activate_unit(key: String):
	tile_key = key

func start_combat():
	is_combat_started = true
	freeze = false 
	print(name + " พร้อมรบแล้ว!")

func _physics_process(_delta: float):
	# ถ้าอยู่ในโหมดย้าย ให้ข้ามการเช็คฟิสิกส์/ความเอียงไปก่อน
	if not is_combat_started: 
		return
	
	# ระบบความเอียง (ล้ม/ฟื้น)
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
		get_tree().current_scene.reduce_army_hp(self, hp_loss_on_death)

func revive():
	if not is_dead: return 
	is_dead = false
	print(name + " ลุกขึ้นสู้!")
	if get_tree().current_scene.has_method("restore_army_hp"):
		get_tree().current_scene.restore_army_hp(self, hp_loss_on_death)

# --- ระบบปืน ---
func pickup_gun(gun_node: Node3D):
	active_gun = gun_node
	if gun_node.has_method("equip_to"):
		gun_node.equip_to(self)

# --- ตรวจสอบความพร้อมของ Skill ---
func check_skill_progress(manager: Node) -> float:
	if manager.get("is_max_kael_skill_used") == true:
		return 0.0
		
	var turn = manager.get("player_turn_count")
	if turn == null or turn < 2:
		return 0.0 # เริ่มต้นที่ 0 ในเทิร์นแรก
		
	# เช็คเลือด
	var cur_hp = float(manager.total_hp)
	var max_hp = float(manager.get("max_player_hp"))
	if max_hp <= 0.0:
		max_hp = cur_hp if cur_hp > 0 else 100.0
		
	if cur_hp >= max_hp:
		return 0.0 # ถ้าเลือดเต็ม จะได้ค่าชาร์จเป็น 0%
	elif cur_hp > max_hp / 2.0:
		# ค่อยๆ เพิ่มขึ้นจาก 0% ไป 100% ตามสัดส่วนเลือดที่ลดลงจากเลือดเต็มถึงครึ่งหนึ่ง
		var hp_lost_ratio = (max_hp - cur_hp) / (max_hp / 2.0)
		return clamp(hp_lost_ratio * 100.0, 0.0, 100.0)
	else:
		return 100.0 # พร้อมใช้! (เลือด <= 50%)

# --- สั่งใช้งาน Skill ---
func activate_skill(manager: Node):
	manager.call("activate_max_kael_skill", self)
