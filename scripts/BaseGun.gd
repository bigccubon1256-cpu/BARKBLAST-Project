class_name BaseGun extends Node3D # <--- เปลี่ยนเป็น Node3D

var wielder: Node3D = null # <--- เปลี่ยนเป็น Node3D

# เปลี่ยนเป็น Vector3 (มีแกน X, Y, Z) สมมติให้ปืนอยู่ห่างไปทางขวา 1 หน่วย
@export var hold_offset: Vector3 = Vector3(1.0, 0.0, 0.0) 

func equip_to(character: Node3D): 
	wielder = character
	set_process(true)

func _ready():
	pass # 🌟 อย่าพึ่งปิด process ทิ้ง เพราะปืนที่โหลดจากเซฟยังต้องทำงานต่อ

func _process(_delta):
	# 🌟 [แก้บั๊ก] ถ้าปืนถูกโหลดจากเซฟ มันจะไม่มี wielder 
	# ให้มันดึง wielder จาก metadata 'linked_char' ที่ MainManager ผูกไว้ให้
	if wielder == null and has_meta("linked_char"):
		wielder = get_meta("linked_char")
		
	if wielder != null:
		# ปืนวิ่งตามตัวละครในโลก 3D
		global_position = wielder.global_position + hold_offset
