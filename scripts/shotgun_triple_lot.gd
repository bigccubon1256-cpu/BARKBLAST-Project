extends Node3D

# เมื่อ MainManager สั่งเปลี่ยนค่า freeze ตัวแม่ จะส่งคำสั่งไปทะลวงหาลูกๆ ทุกตัวอัตโนมัติ!
var freeze: bool = true:
	set(value):
		freeze = value
		for child in get_children():
			if child is RigidBody3D:
				child.freeze = value




@export var unit_name: String = "shotgun_triple_lot"
@export var energy_cost: float = 15.0
@export var hp_gain_on_place: int = 0

var tile_key: String = ""
var is_combat_started: bool = false

func _ready():
	freeze = true # ล็อกไว้ก่อนเริ่มเกม

# ฟังก์ชันนี้ถูกเรียกตอนกดวางลงตาราง
func activate_unit(key: String):
	tile_key = key

# ฟังก์ชันนี้ถูกเรียกตอนกดปุ่ม Start
func start_combat():
	is_combat_started = true
	freeze = false # ปลดล็อกฟิสิกส์!
	print("ปืนพร้อมทำงาน! รอคำสั่งยิง")
