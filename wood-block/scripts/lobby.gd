extends Node

# ฟังก์ชันนี้จะทำงานเมื่อเรากดปุ่ม Play
func _on_play_button_pressed():
	print("1. สัญญาณปุ่มส่งมาถึงแล้ว!")
	
	var scene_path = "res://scenes/chapter_selection.tscn" # เช็กชื่อไฟล์ให้ดี
	if ResourceLoader.exists(scene_path):
		print("2. เจอไฟล์ฉากที่จะเปลี่ยนไปแล้ว")
		get_tree().change_scene_to_file(scene_path)
	else:
		print("2. [ERROR] หาไฟล์ไม่เจอ! เช็กชื่อโฟลเดอร์หรือชื่อไฟล์อีกที")
