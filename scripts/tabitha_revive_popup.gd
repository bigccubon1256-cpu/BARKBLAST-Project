extends Control

signal confirmed
signal cancelled

@onready var panel: Panel = $Panel
@onready var char_info: Label = $Panel/VBoxContainer/CharInfo
@onready var gun_info: Label = $Panel/VBoxContainer/GunInfo
@onready var hp_info: Label = $Panel/VBoxContainer/HPInfo
@onready var btn_confirm: Button = $Panel/VBoxContainer/HBoxContainer/BtnConfirm
@onready var btn_cancel: Button = $Panel/VBoxContainer/HBoxContainer/BtnCancel

func _ready():
	# เชื่อมสัญญาณปุ่มกดส่งออกไปยังผู้เรียกใช้งาน
	btn_confirm.pressed.connect(func(): confirmed.emit())
	btn_cancel.pressed.connect(func(): cancelled.emit())

func setup(char_name: String, gun_name: String, heal_amt: int):
	char_info.text = "CHARACTER: " + char_name
	gun_info.text = "WEAPON: " + gun_name
	hp_info.text = "ARMY HEAL: +" + str(heal_amt) + " HP (50% of unit HP)"

func position_at_unit(unit: Node3D, camera: Camera3D):
	if is_instance_valid(panel) and is_instance_valid(camera):
		# เคลียร์ anchors เพื่อใช้การกำหนดตำแหน่งแบบพิกเซลตรงตัว
		panel.anchor_left = 0.0
		panel.anchor_right = 0.0
		panel.anchor_top = 0.0
		panel.anchor_bottom = 0.0
		
		# แปลงตำแหน่ง 3D ของตัวละครเป็นตำแหน่ง 2D บนหน้าจอ
		var screen_pos = camera.unproject_position(unit.global_position)
		var panel_size = panel.custom_minimum_size
		var panel_pos = Vector2.ZERO
		var viewport_size = get_viewport_rect().size
		
		# แกน X: ถ้าตัวละครอยู่ฝั่งซ้ายของจอ ให้เปิดป๊อปอัปฝั่งขวา (ขอบซ้ายป๊อปอัปชิดกับตัวละคร)
		# ถ้าอยู่ฝั่งขวา ให้เปิดป๊อปอัปฝั่งซ้าย (ขอบขวาป๊อปอัปชิดกับตัวละคร)
		if screen_pos.x < viewport_size.x / 2.0:
			panel_pos.x = screen_pos.x + 20.0
		else:
			panel_pos.x = screen_pos.x - panel_size.x - 20.0
			
		# แกน Y: แสดงผลเหนือตัวละคร (ขอบล่างของป๊อปอัปอยู่ใกล้ตัวละคร)
		# หากตัวละครอยู่สูงเกินขอบบน ให้เด้งแสดงลงมาข้างใต้แทนเพื่อไม่ให้ล้นหน้าจอ
		if screen_pos.y > panel_size.y + 40.0:
			panel_pos.y = screen_pos.y - panel_size.y - 20.0
		else:
			panel_pos.y = screen_pos.y + 20.0
		
		# ป้องกันไม่ให้ทะลุขอบหน้าจอ
		panel_pos.x = clamp(panel_pos.x, 20.0, viewport_size.x - panel_size.x - 20.0)
		panel_pos.y = clamp(panel_pos.y, 20.0, viewport_size.y - panel_size.y - 20.0)
		
		panel.position = panel_pos
