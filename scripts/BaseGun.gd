class_name BaseGun extends Node3D # <--- เปลี่ยนเป็น Node3D

var wielder: Node3D = null # <--- เปลี่ยนเป็น Node3D

# เปลี่ยนเป็น Vector3 (มีแกน X, Y, Z) สมมติให้ปืนอยู่ห่างไปทางขวา 1 หน่วย
@export var hold_offset: Vector3 = Vector3(1.0, 0.0, 0.0) 

func equip_to(character: Node3D): # <--- เปลี่ยนเป็น Node3D
	wielder = character

func _process(_delta):
	if wielder != null:
		# ปืนวิ่งตามตัวละครในโลก 3D
		global_position = wielder.global_position + hold_offset
