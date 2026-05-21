extends Node

# อ้างอิง Path ตามโครงสร้างใหม่ที่พี่จัดกลุ่มไว้ใน UI_Root
@onready var main_menu_panel = $MainMenuCamera3D/CanvasLayer/UI_Root/MainMenuPanel
@onready var mode_select_panel = $MainMenuCamera3D/CanvasLayer/UI_Root/ModeSelectPanel

func _ready():
	# เซ็ตสถานะเริ่มต้นให้เรียบร้อย
	if main_menu_panel and mode_select_panel:
		main_menu_panel.show()
		mode_select_panel.hide()

# ==========================================
# 🌟 ส่วนของหน้า Main Menu (ปุ่ม Play)
# ==========================================

func _on_play_button_pressed():
	print("1. สลับไปหน้าเลือกโหมด!")
	# การสลับหน้าด้วยการซ่อน/โชว์ จะช่วยให้ไม่ต้องโหลดซีนใหม่ ประหยัด CPU ครับ
	main_menu_panel.hide()
	mode_select_panel.show()

# ==========================================
# 🌟 ส่วนของหน้า Mode Select (ปุ่ม Level Test & Back)
# ==========================================

func _on_btn_level_test_pressed():
	print("🎮 กำลังเปลี่ยนไปหน้าเลือกด่าน (Chapter Selection)...")
	var scene_path = "res://scenes/leveltest_selection.tscn"
	
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		print("[ERROR] หาไฟล์ chapter_selection.tscn ไม่เจอ เช็ก Path อีกทีนะครับ")

func _on_btn_back_pressed():
	print("⬅️ กลับไปหน้าเมนูหลัก")
	mode_select_panel.hide()
	main_menu_panel.show()
