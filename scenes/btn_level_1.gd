extends Button

# 🌟 ทริคเวทมนตร์: @export_file จะสร้างช่องให้เรา "กดเลือกไฟล์" ได้จากหน้าต่าง Inspector ฝั่งขวามือ!
@export_file("*.tscn") var level_scene_path: String

func _ready():
	# สั่งให้มันผูกสัญญาณปุ่มกดเข้ากับตัวมันเอง "อัตโนมัติ"
	# ลูกพี่จะได้ไม่ต้องไปกดเชื่อม Signal ในแถบ Node ให้เมื่อยมืออีกต่อไป!
	pressed.connect(_on_button_pressed)

func _on_button_pressed():
	# เช็คก่อนว่าลูกพี่ลืมใส่ไฟล์ฉากให้มันหรือเปล่า
	if level_scene_path == "":
		print("[ERROR] ปุ่มนี้ยังไม่ได้เลือกด่าน! ไปคลิกเลือกไฟล์ด่านที่ Inspector ขวามือก่อนนะ")
		return
		
	print("⏳ กำลังเตรียมโหลดไปด่าน: ", level_scene_path)
	
	# ==========================================
	# 🌟 [แก้ตรงนี้!] เปลี่ยนจากการโหลดฉากตรงๆ เป็นส่งไปหน้า Loading แทน
	# ==========================================
	
	# 1. ฝากชื่อไฟล์ด่านเป้าหมายไว้กับ Autoload ที่ชื่อ Global
	Global.next_scene_path = level_scene_path
	
	# 2. ตัดเข้าหน้า Loading Screen ก่อนเลย! (เช็ค Path ไฟล์หน้าโหลดของลูกพี่ให้ตรงด้วยนะครับ)
	var loading_screen_path = "res://loading_screen.tscn"
	
	if ResourceLoader.exists(loading_screen_path):
		get_tree().change_scene_to_file(loading_screen_path)
	else:
		print("[ERROR] หาไฟล์หน้าโหลด (loading_screen.tscn) ไม่เจอ!")
