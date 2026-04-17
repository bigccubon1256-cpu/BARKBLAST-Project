extends RigidBody3D

var unit_name = "block_lot_1"
var energy_cost = 0.5      # ราคาของบล็อกตามที่คุณตั้งไว้
var hp_gain_on_place = 0   # บล็อกไม่เพิ่ม HP ให้กองทัพ (หรือถ้าอยากให้เพิ่มก็ใส่เลขได้)
var tile_key = ""          # เอาไว้เก็บตำแหน่งตอนวาง (สำคัญมากตอนลบ)

# ถ้าคุณมีฟังก์ชัน activate_unit ในตัวละครอื่น ก็ต้องมีในบล็อกด้วยครับ
func _ready():
	# แช่แข็งฟิสิกส์ไว้ บล็อกจะได้ไม่ร่วงทะลุพื้นตอนลาก
	freeze = true 

func activate_unit(key: String):
	tile_key = key
