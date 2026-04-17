extends RigidBody3D

@export var unit_name: String = "spear_lot"
@export var energy_cost: float = 7.0 # ปืนธรรมดาราคา 1 Energy
@export var hp_gain_on_place: int = 0

var tile_key: String = ""
var is_combat_started: bool = false

func _ready():
	# ล็อกฟิสิกส์ตัวมันเองไว้ก่อนเริ่มเกม (ใช้ property ของ RigidBody3D ได้เลย)
	freeze = true 

# ฟังก์ชันนี้ถูกเรียกตอนกดวางลงตาราง
func activate_unit(key: String):
	tile_key = key

# ฟังก์ชันนี้ถูกเรียกตอนกดปุ่ม Start
func start_combat():
	is_combat_started = true
	# ปลดล็อกฟิสิกส์ให้ร่วงลงพื้น หรือเตรียมกระเด็นตอนยิง!
	freeze = false 
	print("ปืนพกพร้อมทำงาน! รอคำสั่งยิง")
