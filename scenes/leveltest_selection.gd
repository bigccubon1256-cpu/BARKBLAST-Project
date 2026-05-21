extends Control

# ==========================================
# 🌟 ระบบปุ่มกดในหน้าเลือกด่าน Level Test
# ==========================================

# 1. ฟังก์ชันสำหรับปุ่มถอยกลับไปหน้า Lobby
func _on_btn_back_pressed():
	print("⬅️ กลับไปหน้าลอบบี้")
	# 🚨 ข้อควรระวัง: เช็กชื่อไฟล์ Lobby ของลูกพี่ให้ตรงกับในวงเล็บด้วยนะครับ
	var lobby_path = "res://scenes/Lobby.tscn"
	
	if ResourceLoader.exists(lobby_path):
		get_tree().change_scene_to_file(lobby_path)
	else:
		print("[ERROR] หาไฟล์ลอบบี้ไม่เจอ!")
