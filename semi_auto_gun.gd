extends Node3D

# --- 1. ข้อมูลพื้นฐานของยูนิต (ปรับแก้ใน Inspector ได้เลย) ---
@export var unit_name: String = "semi_auto_gun"
@export var energy_cost: float = 4.0 
@export var hp_gain_on_place: int = 0

# --- 2. ตัวแปรสำหรับระบบ (Main จะมาอ่านและเขียนค่าพวกนี้) ---
var tile_key: String = ""
var is_combat_started: bool = false
var bullets_left: int = 2
var max_bullets: int = 2

# --- 3. สวิตช์เปิดปิดฟิสิกส์ (เหมือนปืนกลเป๊ะๆ) ---
var freeze: bool = true:
	set(value):
		freeze = value
		for child in get_children():
			if child is RigidBody3D:
				child.freeze = value

# ==========================================
# 🔴 ฟังก์ชันระบบทำงาน (เหมือนปืนกลเป๊ะๆ)
# ==========================================

func _ready():
	# ล็อกฟิสิกส์ไว้ก่อนตอนเพิ่งวางลงตาราง (กันกระสุนร่วง)
	freeze = true 

# ฟังก์ชันนี้ Main จะเป็นคนเรียกตอนกดวางลงตาราง
func activate_unit(key: String):
	tile_key = key

# ฟังก์ชันนี้ Main จะเป็นคนเรียกตอนกดปุ่ม "Start" เริ่มต่อสู้
func start_combat():
	is_combat_started = true
	freeze = false # 🌟 ปลดล็อกฟิสิกส์ตรงนี้! ปืนจะไม่แข็งเป็นโล่กัปตันอเมริกาแล้ว!
	print("ปืน Semi-Auto ปลดล็อกความแข็ง พร้อมรบ!")
