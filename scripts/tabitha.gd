extends RigidBody3D

@export_group("Unit Stats")
@export var unit_name: String = "tabitha"
@export var energy_cost: float = 10.0
@export var hp_gain_on_place: int = 30
@export var hp_loss_on_death: int = 15

var is_dead: bool = false
var tile_key: String = ""
var is_combat_started: bool = false

# --- ตัวแปรสำหรับระบบ Move และปืน ---
var active_gun: Node3D = null
var is_repositioning: bool = false
var is_selected: bool = false

# --- ข้อมูล Skill ---
var skill_name: String = "REVITALIZE"
var skill_description: String = "Target a fallen ally to revive them and restore army HP by 50% of the revived unit's base HP. Kills required increases after each use (caps at 5)."
var skill_conditions: String = "Conditions: Turn 2 and later, Kills: 0/1"
var skill_icon_path: String = "res://assets/foto/Tabitha-Skill.png"
var skill_fill_icon_path: String = "res://assets/foto/Tabitha-Skill-Fill.png"
var skill_theme_color: Color = Color(0.0, 1.0, 0.0, 1.0) # Green!

# --- Tabitha Skill Stacks ---
var current_kills: int = 0
var kills_required_for_next_use: int = 1

func _ready():
	freeze = true # ล็อกไว้ก่อนเริ่มช่วง Setup
	update_skill_conditions()

func activate_unit(key: String):
	tile_key = key

func start_combat():
	is_combat_started = true
	freeze = false 
	print(name + " พร้อมรบแล้ว!")

func _physics_process(_delta: float):
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

# --- เมื่อศัตรูตาย ---
func on_enemy_killed():
	if is_dead: return
	if current_kills < kills_required_for_next_use:
		current_kills += 1
		update_skill_conditions()
		print("Tabitha gained a kill stack! Current: ", current_kills, "/", kills_required_for_next_use)

func update_skill_conditions():
	skill_conditions = "Conditions: Turn 2 and later, Kills: %d/%d" % [current_kills, kills_required_for_next_use]

# --- ตรวจสอบความพร้อมของ Skill ---
func check_skill_progress(manager: Node) -> float:
	var turn = manager.get("player_turn_count")
	if turn == null or turn < 2:
		return 0.0 # เริ่มต้นที่ 0 ในเทิร์นแรก
		
	# เช็คว่ามีตัวละครตายหรือไม่
	var has_dead_allies = false
	for unit in manager.occupied_tiles.values():
		if is_instance_valid(unit) and unit.get("is_dead") == true:
			var u_name = unit.get("unit_name")
			if u_name != null and manager.has_method("is_player_char") and manager.is_player_char(u_name):
				has_dead_allies = true
				break
				
	if not has_dead_allies:
		return 0.0 # ถ้าไม่มีคนตาย สกิลจะใช้ไม่ได้ (0%)
		
	var target_kills = kills_required_for_next_use
	var ratio = float(current_kills) / float(target_kills)
	return clamp(ratio * 100.0, 0.0, 100.0)

# --- สั่งใช้งาน Skill ---
func activate_skill(manager: Node):
	manager.call("activate_tabitha_skill", self)
