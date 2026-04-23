extends Node3D

@export_category("System Prefabs")
@export var slot_scene: PackedScene

@export_category("Grid Settings")
@export var snap_step: float = 0.25
@export var min_unit_distance: float = 0.9

@export_category("Level Energy Settings")
@export var max_energy: float = 500.0 # พลังงานหลอดเต็มของด่านนี้
@export var starting_energy: float = 500.0 # พลังงานตอนเริ่มด่าน

@export_category("Build Area Boundaries")
# 🌟 ตัวแปรพวกนี้จะไปแทนที่ตัวแปรเก่าที่พี่เพิ่งลบไปครับ!
@export var build_boundary_x: float = 50.0 # รัศมีแนวกว้าง (ซ้าย-ขวา)
@export var build_boundary_z: float = 25.0 # รัศมีแนวยาว (หน้า-หลัง)
@export var build_offset_x: float = 0.0 # เลื่อนจุดศูนย์กลางแกน X
@export var build_offset_z: float = -24.0 # เลื่อนจุดศูนย์กลางแกน Z

@export_category("Developer Mode")
@export var is_dev_mode: bool = false # ติ๊กถูกเพื่อเปิดโหมดผู้สร้าง!

# ==========================================
# (ตัวแปร @onready ปล่อยไว้เหมือนเดิมครับ)
@onready var combat_menu = $HUD/CombatMenu
# ==========================================
# 🌟 ระบบลากคลุม (Drag Selection)
# ==========================================
var drag_start_pos: Vector2 = Vector2.ZERO
var is_dragging_selection: bool = false
var multi_selected_units: Array = [] # สมุดจดว่าลากคลุมโดนตัวไหนบ้าง
@onready var selection_box = %SelectionBox
# ==========================================
@onready var power_ui = $HUD/ShootingPowerUI
@onready var hp_display = $HUD/HPLabel
@onready var energy_bar = $HUD/EnergyBar
@onready var energy_label = $HUD/EnergyBar/EnergyLabel
@onready var unit_list_container = $HUD/VBoxContainer/ScrollContainer/UnitList
@onready var action_menu = $HUD/ActionMenu
@onready var multi_action_menu = $HUD/MultiActionMenu
@onready var error_sound_player = $ErrorSoundPlayer

@onready var enemy_hp_display = $HUD/EnemyHPLabel 
@onready var enemy_energy_label = $HUD/EnemyEnergyLabel 
var total_enemy_hp: int = 0
var total_enemy_energy_used: float = 0.0

@onready var btn_save_level = $HUD/BtnSaveLevel 

@onready var player_hp_bar = $HUD/PlayerHPBar 
@onready var enemy_hp_bar = $HUD/EnemyHPBar 
# ==========================================





var army_list = [{"name": "soren", "category": "character", "cost": 0, "hp_gain": 10, "scene": preload("res://soren.tscn"), "icon": preload("res://assets/foto/SammyforUI.png"), "max_count": 1},
	{"name": "forces", "category": "character", "cost": 5, "hp_gain": 10, "scene": preload("res://forces.tscn"), "icon": preload("res://assets/foto/ForceforUI.png"), "max_count": -1},
	
	{"name": "block", "display_name": "OAK BLOCK", "category": "block", "cost": 0.5, "scene": preload("res://construction_block.tscn"), "icon": preload("res://assets/foto/wb023forUI.png"), "max_count": -1}, 
	{"name": "block_dark", "display_name": "ROSEWOOD BLOCK", "category": "block", "cost": 1.0, "scene": preload("res://construction_block_2.tscn"), "icon": preload("res://assets/foto/wbrob02forUI.png"), "max_count": -1}, 
	
	{"name": "gun", "display_name": "PISTOL", "category": "gun", "cost": 2, "scene": preload("res://gun.tscn"), "icon": preload("res://assets/foto/gun01forUI.png"), "max_count": -1},
	{"name": "spear", "category": "gun", "cost": 7, "scene": preload("res://spear.tscn"), "icon": preload("res://assets/foto/wbspearforUI.png"), "max_count": -1 }, 
	{"name": "shotgun", "display_name": "SG", "category": "gun", "cost": 10, "scene": preload("res://shotgun.tscn"), "icon": preload("res://assets/foto/wbgun02forUI.png"), "max_count": -1},
	{"name": "shotgun_triple", "display_name": "SG TRIPLE", "category": "gun", "cost": 15, "scene": preload("res://shotgun_triple.tscn"), "icon": preload("res://assets/foto/wbgun02-2forUI.png"), "max_count": -1},
	{"name": "machine_gun_mini", "display_name": "MG 1", "category": "gun", "cost": 6, "scene": preload("res://machine_gun_mini.tscn"), "icon": preload("res://assets/foto/wbgun03-2forUI.png"), "max_count": -1},
	{"name": "machine_gun", "display_name": "MG 2", "category": "gun", "cost": 9, "scene": preload("res://machine_gun.tscn"), "icon": preload("res://assets/foto/wbgun03forUI.png"), "max_count": -1},
	{"name": "machine_gun_heavy", "display_name": "MG 3", "category": "gun", "cost": 12, "scene": preload("res://machine_gun_heavy.tscn"), "icon": preload("res://assets/foto/wbgun03-3forUI.png"), "max_count": -1},
	{"name": "semi_auto_gun", "display_name": "SEMI", "category": "gun", "cost": 4, "scene": preload("res://semi_auto_gun.tscn"), "icon": preload("res://assets/foto/wbgun04forUI.png"), "max_count": -1},
	{"name": "sniper", "category": "gun", "cost": 30, "scene": preload("res://sniper.tscn"), "icon": preload("res://assets/foto/wbsniperforUI.png"), "max_count": -1}, 
	
	
	{"name": "shield_block", "display_name": "OAK SHIELD", "category": "shield", "cost": 10, "scene": preload("res://shield_unit.tscn"), "icon": preload("res://assets/foto/wb023forUI.png"), "max_count": -1},
	
	#=====================================ศัตรู========================================
	#=====================================ศัตรู========================================
	
	{"name": "lotcher", "category": "enemy_character", "cost": 5, "scene": preload("res://lotcher.tscn"), "icon": preload("res://assets/foto/loter2.png"), "max_count": -1},
	
	{"name": "block_lot_1", "category": "enemy_block", "cost": 0.5, "scene": preload("res://construction_block_lot_1.tscn"), "icon": preload("res://assets/foto/สกรีนช็อต 2026-03-30 124945.png"), "max_count": -1},
	
	{"name": "gun_lot", "category": "enemy_gun", "cost": 2, "scene": preload("res://gun_lot.tscn"), "icon": preload("res://assets/foto/สกรีนช็อต 2026-03-30 124955.png"), "max_range": 64.0 , "max_count": -1},
	{"name": "sniper_lot", "category": "enemy_gun", "cost": 30, "scene": preload("res://sniper_lot.tscn"), "icon": preload("res://assets/foto/สกรีนช็อต 2026-03-30 125007.png"), "max_range": 256.0 , "max_count": -1},
	{"name": "shotgun_lot", "category": "enemy_gun", "cost": 10, "scene": preload("res://shotgun_lot.tscn"), "icon": preload("res://assets/foto/สกรีนช็อต 2026-03-31 172132.png"), "max_range": 48.0 , "max_count": -1},
	{"name": "shotgun_triple_lot", "category": "enemy_gun", "cost": 15, "scene": preload("res://shotgun_triple_lot.tscn"), "icon": preload("res://assets/foto/สกรีนช็อต 2026-04-01 131725.png"), "max_range": 48.0 , "max_count": -1},
	{"name": "spear_lot", "category": "enemy_gun", "cost": 7, "scene": preload("res://spear_lot.tscn"), "icon": preload("res://assets/foto/สกรีนช็อต 2026-04-01 140147.png"), "max_range": 128.0 , "max_count": -1 }, 
	{"name": "machine_gun_mini_lot", "category": "enemy_gun", "cost": 6, "scene": preload("res://machine_gun_mini_lot.tscn"), "icon": preload("res://assets/foto/สกรีนช็อต 2026-04-03 153810.png"), "max_range": 72.0 , "max_count": -1},
	{"name": "machine_gun_lot", "category": "enemy_gun", "cost": 9, "scene": preload("res://machine_gun_lot.tscn"), "icon": preload("res://assets/foto/สกรีนช็อต 2026-04-03 121249.png"), "max_range": 72.0 , "max_count": -1},
	{"name": "machine_gun_heavy_lot", "category": "enemy_gun", "cost": 12, "scene": preload("res://machine_gun_heavy_lot.tscn"), "icon": preload("res://assets/foto/สกรีนช็อต 2026-04-04 120126.png"), "max_range": 72.0 , "max_count": -1},
	{"name": "semi_auto_gun_lot", "category": "enemy_gun", "cost": 4, "scene": preload("res://semi_auto_gun_lot.tscn"), "icon": preload("res://assets/foto/สกรีนช็อต 2026-04-04 122335.png"), "max_range": 64.0 , "max_count": -1},
	
	]


var current_energy: float = 0.0 # ค่าพลังงานปัจจุบันที่ใช้อยู่จริง
var total_hp: int = 0
var occupied_tiles = {}
var dragging_unit: Node3D = null
var selected_unit: Node3D = null
var unit_data: Dictionary
var press_timer: float = 0.0
var is_pressing: bool = false
const LONG_PRESS_TIME: float = 0.15 # กดค้าง 0.5 วินาทีเพื่อย้าย
var is_moving_existing_unit: bool = false # เช็คว่าเป็นการย้ายตัวเดิมหรือไม่
# ==========================================
# 🌟 ตัวแปรสำหรับก๊อปปี้กลุ่ม (Multi-Drag)
# ==========================================
var dragging_multi_units: Array = []
var multi_drag_offsets: Array = []
var multi_drag_cost: float = 0.0
var multi_drag_hp: int = 0

var last_drag_grid_pos: Vector3 = Vector3.INF # 🌟 เพิ่มบรรทัดนี้เข้าไปครับ!
# ==========================================

var dragging_gun: Node3D = null
var gun_offset: Vector3 = Vector3.ZERO # เอาไว้จำว่าปืนอยู่ห่างจากตัวละครแค่ไหน




var unit_name = "soren"

var is_game_started: bool = false
# *********************--- ระบบต่อสู้ ---*************************
var is_combat_aiming: bool = false
var active_combat_unit: Node3D = null
var combat_action_mode: String = "shoot" # สวิตช์แยกโหมดยิง/เดิน
# --- ตัวแปรจำกัดองศาการเล็ง ---
var initial_aim_rotation: float = 0.0 # จำองศาตอนเริ่มเล็ง
var initial_gun_rotation: float = 0.0
var current_aim_offset: float = 0.0 # จำว่าตอนนี้หันซ้าย/ขวาไปกี่องศาแล้ว
var MAX_AIM_ANGLE: float = deg_to_rad(180.0) # ลิมิตให้หันซ้ายขวาได้ฝั่งละ 75 องศา (เปลี่ยนตัวเลขได้ครับ)
var current_pitch_offset: float = 0.0 # จำองศาการก้ม/เงย
var MAX_PITCH_ANGLE: float = deg_to_rad(90.0) # ลิมิตให้เงย/ก้มได้สุด 45 องศา
var original_cam_tilt: float = 0.0
var saved_rig_pos: Vector3 = Vector3.ZERO
var saved_rig_rot: Vector3 = Vector3.ZERO
var saved_zoom: float = 0.0
var is_spraying: bool = false # เอาไว้เช็คว่ากำลังกราดยิงปืนกลอยู่หรือเปล่า
var is_firing: bool = false   # 🌟 [เพิ่มบรรทัดนี้!] ตัวแปรกันบั๊กกดยกเลิกขณะกระสุนกำลังออก
var TILT_RTS = deg_to_rad(45.0)    # มุมก้มตอนสร้าง (ก้มมองพื้น)
var TILT_COMBAT = deg_to_rad(40.0) # มุมก้มตอนเล็ง (ระดับสายตาที่พี่ชอบ)
var is_changing_turn = false # 🌟 กุญแจสำหรับป้องกันบั๊กเปลี่ยนเทิร์นซ้อนทับกัน






# ==========================================
# 🌟 ระบบ Blueprint (พิมพ์เขียว)
# ==========================================
@onready var blueprint_save_ui = $HUD/BlueprintSaveUI
@onready var blueprint_input_name = $HUD/BlueprintSaveUI/InputName
@onready var btn_confirm_save = $HUD/BlueprintSaveUI/BtnConfirmSave
@onready var btn_cancel_save = $HUD/BlueprintSaveUI/BtnCancelSave

var pending_blueprint_units: Array = [] # เอาไว้จำว่ากำลังจะเซฟกลุ่มไหน
var pending_blueprint_center: Vector3 = Vector3.ZERO # จุดศูนย์กลางของกลุ่ม
# ==========================================
# 🌟 ระบบ Blueprint (พิมพ์เขียว)
# ==========================================
# ... (ตัวแปรเดิมของพี่) ...
@onready var btn_open_library = $HUD/BtnOpenLibrary
@onready var blueprint_library_ui = $HUD/BlueprintLibraryUI
@onready var btn_close_library = $HUD/BlueprintLibraryUI/BtnCloseLibrary
@onready var blueprint_list = $HUD/BlueprintLibraryUI/ScrollContainer/BlueprintList
# ==========================================






# ==========================================
# 🌟 ระบบผู้พัฒนา (Dev Mode) 
# ==========================================
var current_turn: String = "SETUP" # สถานะเทิร์น: SETUP (วางของ), PLAYER (ตาเรา), ENEMY (ตาศัตรู)
# ==========================================
# 🌟 ระบบควบคุมเทิร์น (Turn Manager)
# ==========================================
enum Turn { SETUP, PLAYER, ENEMY, WAITING_PHYSICS, GAME_OVER }
var current_state = Turn.SETUP
var next_turn = Turn.PLAYER # เอาไว้จำว่าพอนิ่งแล้ว จะสลับไปตาใครต่อ




@export_category("Level Unlocks")
# พิมพ์ชื่อยูนิตที่อนุญาตให้ใช้ (อิงตามชื่อใน army_list เช่น "soren", "block", "sniper") 
# 🌟 ทริค: ถ้าปล่อย Array นี้ว่างไว้ (size = 0) เกมจะเปิดโหมด Sandbox ให้ใช้ได้ทุกตัว!
@export var allowed_units: Array[String] = []







# ==========================================
# 🌟 ระบบ Context Menu และจัดการไฟล์
# ==========================================
var item_to_manage: String = ""

@onready var blueprint_context_menu = $HUD/BlueprintContextMenu
@onready var btn_menu_rename = $HUD/BlueprintContextMenu/BtnMenuRename
@onready var btn_menu_delete = $HUD/BlueprintContextMenu/BtnMenuDelete

# โหนดลบ (เป็นลูกของ BtnMenuDelete ตามรูปพี่เลย)
@onready var delete_confirm_ui = $HUD/DeleteConfirmUI
@onready var btn_delete_yes = $HUD/DeleteConfirmUI/Panel/HBoxContainer/BtnYes
@onready var btn_delete_no = $HUD/DeleteConfirmUI/Panel/HBoxContainer/BtnNo

# โหนดเปลี่ยนชื่อ (ถ้าพี่จัดคล้ายๆ กัน)
@onready var rename_popup = $HUD/RenamePopup
# แก้ Path ตรงนี้ให้ตรงกับที่พี่วาง RenameInput และปุ่มไว้ข้างในนะครับ
@onready var rename_input = $HUD/RenamePopup/RenameInput 
@onready var btn_rename_confirm = $HUD/RenamePopup/BtnRenameConfirm
@onready var btn_rename_cancel = $HUD/RenamePopup/BtnRenameCancel




# 🌟 เพิ่มตัวแปรปุ่ม End Turn (เช็คชื่อใน Scene ให้ตรงนะครับ)
@onready var btn_end_turn = $HUD/BtnEndTurn 
@onready var btn_start = $HUD/BtnStart # ประกาศไว้เพื่อให้สั่งซ่อนได้ง่ายๆ








func _ready():
	# วาดตารางกว้าง 10 หน่วย, ช่องละ 0.25 (ตาม snap_step), ขอบเขตสร้างกว้าง 5 หน่วย
	# --- [เพิ่มบรรทัดนี้] เซ็ตพลังงานตั้งต้นตอนเริ่มด่าน ---
	current_energy = starting_energy 
	draw_grid(build_boundary_x, build_boundary_z, build_offset_x, build_offset_z, snap_step)
	
	# 🌟 [เพิ่มบรรทัดนี้!] เสกกำแพงล่องหนทันทีที่เริ่มเกม
	create_invisible_boundaries()
	
	action_menu.hide()
	update_unit_menu("character")
	update_ui()
	var btn_shoot = combat_menu.get_node_or_null("BtnCombatShoot")
	if btn_shoot:
		btn_shoot.pressed.connect(_on_btn_combat_shoot_pressed)
	
	# 🌟 [เพิ่มบรรทัดพวกนี้เข้าไป!] เชื่อมปุ่มสแนปและปุ่มเดิน
	var btn_snap = combat_menu.get_node_or_null("BtnCombatSnap")
	if btn_snap:
		btn_snap.pressed.connect(_on_btn_combat_snap_pressed)
		
	var btn_walk = combat_menu.get_node_or_null("BtnCombatWalk")
	if btn_walk:
		btn_walk.pressed.connect(_on_btn_combat_walk_pressed)
	
	# [เพิ่มใหม่] เชื่อมสัญญาณจาก Power UI
	if power_ui:
		power_ui.charge_finished.connect(_on_charge_finished)
		power_ui.charge_canceled.connect(_on_charge_canceled)
	# ==========================================
	# 🌟 [แก้ตรงนี้!] ระบบซ่อนปุ่ม Dev Mode ทุกปุ่มที่เป็นของศัตรู
	# ==========================================
	# 1. จัดการปุ่ม Tab ศัตรู (ถ้าพี่มีหลายปุ่ม ใส่ชื่อมาให้ครบตรงนี้ครับ)
	# ==========================================
	# 🌟 ระบบซ่อนปุ่ม Dev Mode (ใช้ระบบ Group)
	# ==========================================
	# สั่งการ "ทั้งกลุ่ม" ที่เราตั้งชื่อไว้ว่า enemy_ui_tabs
	for tab in get_tree().get_nodes_in_group("enemy_ui_tabs"):
		if is_instance_valid(tab):
			tab.visible = is_dev_mode

	# 2. จัดการปุ่ม Save ด่าน
	if btn_save_level:
		btn_save_level.pressed.connect(_on_btn_save_level_pressed)
		btn_save_level.visible = is_dev_mode
	# ==========================================
	# 🌟 [เพิ่มใหม่] สั่งกู้คืนข้อมูลสำหรับด่านที่โหลดมาจากเซฟ
	# ==========================================
	call_deferred("_restore_saved_level_data")

	# เชื่อมปุ่ม Blueprint Save
	if btn_confirm_save:
		btn_confirm_save.pressed.connect(_on_blueprint_confirm_save_pressed)
	if btn_cancel_save:
		btn_cancel_save.pressed.connect(_on_blueprint_cancel_save_pressed)
	if blueprint_save_ui:
		blueprint_save_ui.hide()

	if btn_open_library:
		btn_open_library.pressed.connect(_on_btn_open_library_pressed)
	if btn_close_library:
		btn_close_library.pressed.connect(_on_btn_close_library_pressed)
		
	if blueprint_library_ui:
		blueprint_library_ui.hide()

	# 🌟 เชื่อมปุ่มในเมนูคลิกขวา
	if btn_menu_rename:
		btn_menu_rename.pressed.connect(_on_btn_menu_rename_pressed)
	if btn_menu_delete:
		btn_menu_delete.pressed.connect(_on_btn_menu_delete_pressed)
		
	# 🌟 เชื่อมปุ่มยืนยันการลบ
	if btn_delete_yes:
		btn_delete_yes.pressed.connect(_on_delete_confirmed)
	if btn_delete_no:
		btn_delete_no.pressed.connect(func(): delete_confirm_ui.hide()) # ปิดแค่กรอบถาม

	# 🌟 เชื่อมปุ่มเปลี่ยนชื่อ
	if btn_rename_confirm:
		btn_rename_confirm.pressed.connect(_on_confirm_rename_pressed)
	if btn_rename_cancel:
		btn_rename_cancel.pressed.connect(func(): rename_popup.hide())

	# ซ่อนทุกอย่างไว้ก่อนตอนเริ่มเกม
	if blueprint_context_menu: blueprint_context_menu.hide()
	if delete_confirm_ui: delete_confirm_ui.hide()
	if rename_popup: rename_popup.hide()

	# 🌟 [เพิ่มบรรทัดนี้!] สั่งซ่อนเมนูต่อสู้ตอนเริ่มเกม
	if combat_menu: combat_menu.hide()

	if btn_end_turn:
		btn_end_turn.hide() # ซ่อนตั้งแต่รันเกม







func setup(data: Dictionary):
	unit_data = data
	# เปลี่ยนข้อความราคา
	$CostLabel.text = "EN: " + str(data["cost"])
	
	# เปลี่ยนรูป Icon (ถ้ามีข้อมูลรูปส่งมา)
	if data.has("icon"):
		$Icon.texture = data["icon"]






# ฟังก์ชันสร้างปุ่มยูนิต (แบบกรองตามหมวดหมู่) + ติดตั้งระบบดักบั๊ก!
func update_unit_menu(filter_category: String):
	print("\n--- 🛠️ เริ่มสร้าง UI โหมด: '", filter_category, "' ---")
	print("จำนวนข้อมูลใน army_list: ", army_list.size())
	print("สถานะ Dev Mode: ", is_dev_mode, " | มีการล็อกยูนิต (allowed_units): ", allowed_units.size(), " ตัว")

	# 1. ล้างปุ่มยูนิตเก่าๆ ในหน้าจอออกก่อน
	for child in unit_list_container.get_children():
		child.queue_free()
		
	# 2. สร้างปุ่มใหม่เฉพาะตัวที่หมวดหมู่ตรงกัน
	for data in army_list:
		var u_name = str(data.get("name")).to_lower()
		var u_cat = str(data.get("category")).to_lower()
		var is_enemy_data = u_cat.begins_with("enemy")
		
		# ==========================================
		# 🌟 ระบบซ่อนปุ่มศัตรูสำหรับผู้เล่น
		# ==========================================
		if is_enemy_data and not is_dev_mode:
			continue # ข้ามไปเลย ไม่ต้องสร้างปุ่ม
			
		# ==========================================
		# 🌟 ระบบล็อกยูนิตประจำด่าน (Level Unlocks)
		# ==========================================
		if allowed_units.size() > 0 and not is_dev_mode:
			if not u_name in allowed_units:
				print("🚫 [โดนเตะออก!] ยูนิต '", u_name, "' ไม่มีรายชื่อใน allowed_units")
				continue 
		# ==========================================
		
		# 🌟 จุดจับผิด! ปริ้นท์เทียบหมวดหมู่ให้เห็นจะๆ
		print("🔍 กำลังเช็คยูนิต: [", u_name, "] | หมวดหมู่ของมัน = '", u_cat, "' | หมวดหมู่ที่ต้องการ = '", filter_category, "'")
		
		# [ปรับปรุง!] เติม .to_lower() ให้มันเผื่อว่าตัวพิมพ์เล็ก/ใหญ่ไม่ตรงกัน
		if u_cat == filter_category.to_lower() or filter_category == "all":
			print("✅ [ผ่านฉลุย!] สร้างปุ่ม: ", u_name)
			var slot = slot_scene.instantiate()
			unit_list_container.add_child(slot)
			slot.setup(data)
			slot.button_down.connect(_on_unit_slot_down.bind(slot))
			
	# อัปเดต UI เพื่อให้ตัวเลข HP/จำนวน ในปุ่มมันแสดงผลถูกต้องทันที
	update_ui()
	print("--- 🏁 จบการสร้าง UI ---\n")






func _on_unit_slot_down(slot):
	var category_str = str(slot.unit_data.get("category"))
	var is_enemy = category_str.begins_with("enemy")
	
	if is_enemy or current_energy >= slot.unit_data["cost"]:
		action_menu.hide()
		selected_unit = null
		
		# 🌟 [เพิ่มระบบกันผีหลอก!] ถ้ามีตัวเก่าค้างติดเมาส์อยู่ ลบทิ้งไปก่อนเลย!
		if dragging_unit and is_instance_valid(dragging_unit):
			dragging_unit.queue_free()
			if dragging_gun and is_instance_valid(dragging_gun):
				dragging_gun.queue_free()
				dragging_gun = null
		
		unit_data = slot.unit_data 
		dragging_unit = slot.unit_data["scene"].instantiate()
		add_child(dragging_unit)
		toggle_collision(dragging_unit, true)
	else:
		if error_sound_player: error_sound_player.play()
		print("Energy ไม่พอซื้อยูนิตนี้!")







# ฟังก์ชันนับจำนวนยูนิตในสนาม (รองรับทุกตัวละครในอนาคต!)
func get_unit_count_on_field(target_name: String) -> int:
	var count = 0
	for unit in get_children():
		if is_instance_valid(unit) and unit != dragging_unit:
			var u_name = ""
			if unit.get("unit_name") != null:
				u_name = unit.get("unit_name")
			elif "unit_data" in unit and unit.unit_data.has("name"):
				u_name = unit.unit_data["name"]
				
			if u_name == target_name:
				count += 1
	return count












# 1. กล่อง AABB ที่ฉลาดขั้นสุด (อัปเกรดความลื่น! Caching ระบบค้นหา)
# ==========================================
# ซ่อมจุดที่ 1: แก้อาการบล็อกเซฟเป็นผีทะลุตึก
# ==========================================
func get_unit_global_aabb(pos: Vector3, basis: Basis, unit: Node3D, is_dragging: bool = false) -> AABB:
	# 🌟 1. ระบบ Smart Cache: เปลี่ยนมาใช้ is_equal_approx ป้องกันเลขทศนิยมแกว่ง!
	if not is_dragging and unit.has_meta("cached_global_aabb") and unit.has_meta("cached_pos") and unit.has_meta("cached_rot"):
		var c_pos = unit.get_meta("cached_pos") as Vector3
		var c_rot = unit.get_meta("cached_rot") as Vector3
		if c_pos.is_equal_approx(unit.global_position) and c_rot.is_equal_approx(unit.global_rotation):
			return unit.get_meta("cached_global_aabb")

	# ... (โค้ดคำนวณ all_shapes เหมือนเดิมของพี่) ...
	var all_shapes = []
	if unit.has_meta("cached_shapes"):
		all_shapes = unit.get_meta("cached_shapes")
	else:
		all_shapes = unit.find_children("*", "CollisionShape3D", true, false)
		unit.set_meta("cached_shapes", all_shapes)
		
	var global_aabb = AABB()
	var is_first = true
	var hypothetical_transform = Transform3D(basis, pos)
	
	if all_shapes.size() > 0:
		for shape_node in all_shapes:
			if not is_instance_valid(shape_node) or shape_node.shape == null: continue
			
			var shape_global_aabb = AABB()
			if shape_node.shape is BoxShape3D:
				var local_transform = unit.global_transform.affine_inverse() * shape_node.global_transform
				var shape_global_transform = hypothetical_transform * local_transform
				var extents = (shape_node.shape.size / 2.0) - Vector3(0.05, 0.05, 0.05)
				var h_basis = shape_global_transform.basis
				var gx = abs(h_basis.x.x * extents.x) + abs(h_basis.y.x * extents.y) + abs(h_basis.z.x * extents.z)
				var gy = abs(h_basis.x.y * extents.x) + abs(h_basis.y.y * extents.y) + abs(h_basis.z.y * extents.z)
				var gz = abs(h_basis.x.z * extents.x) + abs(h_basis.y.z * extents.y) + abs(h_basis.z.z * extents.z)
				var g_ext = Vector3(gx, gy, gz)
				shape_global_aabb = AABB(shape_global_transform.origin - g_ext, g_ext * 2.0)
			else:
				var local_transform = unit.global_transform.affine_inverse() * shape_node.global_transform
				var shape_global_transform = hypothetical_transform * local_transform
				var g_ext = Vector3(0.5, 0.5, 0.5) 
				shape_global_aabb = AABB(shape_global_transform.origin - g_ext, g_ext * 2.0)
				
			if is_first:
				global_aabb = shape_global_aabb
				is_first = false
			else:
				global_aabb = global_aabb.merge(shape_global_aabb)
				
	if not is_first:
		if not is_dragging:
			unit.set_meta("cached_global_aabb", global_aabb)
			unit.set_meta("cached_pos", unit.global_position)
			# 🌟 เปลี่ยนมาเก็บ Rotation แทน Basis
			unit.set_meta("cached_rot", unit.global_rotation)
		return global_aabb

	var default_extents = Vector3(0.5, 1.5, 0.25)
	var e = default_extents - Vector3(0.05, 0.05, 0.05)
	var gx = abs(basis.x.x * e.x) + abs(basis.y.x * e.y) + abs(basis.z.x * e.z)
	var gy = abs(basis.x.y * e.x) + abs(basis.y.y * e.y) + abs(basis.z.y * e.z)
	var gz = abs(basis.x.z * e.x) + abs(basis.y.z * e.y) + abs(basis.z.z * e.z)
	var fallback_ext = Vector3(gx, gy, gz)
	var final_aabb = AABB(pos - fallback_ext, fallback_ext * 2.0)
	
	if not is_dragging:
		unit.set_meta("cached_global_aabb", final_aabb)
		unit.set_meta("cached_pos", unit.global_position)
		unit.set_meta("cached_rot", unit.global_rotation)
		
	return final_aabb





# 2. ตรวจสอบการชน (อัปเกรดความลื่น! ตัดตัวที่อยู่ไกลทิ้ง ไม่ต้องคำนวณ)
# ==========================================
# ซ่อมจุดที่ 2: แก้อาการปืนอื่นวางไม่ได้ + ลบตัวเช็คระยะ 3 เมตร
# ==========================================
func is_position_safe(target_pos: Vector3, current_unit: Node3D) -> bool:
	var my_aabb = get_unit_global_aabb(target_pos, current_unit.global_transform.basis, current_unit, true)
	
	var is_dragging_weapon = false
	if "unit_data" in current_unit:
		var cat = str(current_unit.unit_data.get("category", "")).to_lower()
		var u_name = str(current_unit.unit_data.get("name", "")).to_lower()
		if "gun" in cat or "spear" in u_name or "sniper" in u_name or "shotgun" in u_name:
			is_dragging_weapon = true

	# 🌟 อัปเกรดความเร็วขีดสุด! ลูปเช็คเฉพาะของที่วางลงบน Grid (occupied_tiles) เท่านั้น!
	for unit in occupied_tiles.values():
		if not is_instance_valid(unit) or unit.is_queued_for_deletion() or unit == current_unit or unit == dragging_unit: 
			continue

		if "unit_name" in unit or "unit_data" in unit:
			if is_dragging_weapon:
				var u_name = ""
				if unit.get("unit_name") != null:
					u_name = str(unit.get("unit_name")).to_lower()
				elif "unit_data" in unit:
					u_name = str(unit.unit_data.get("name", "")).to_lower()
					
				if is_player_char(u_name) or is_enemy_char(u_name):
					continue 

			var other_aabb = get_unit_global_aabb(unit.global_position, unit.global_transform.basis, unit, false)
			if my_aabb.intersects(other_aabb):
				return false 
				
	return true







func _process(delta: float) -> void:
	# 1. ระบบลากวางตัวละคร (Snap to Grid)
	if dragging_unit:
		
		var pos = get_ground_position()
		if pos != Vector3.ZERO:
			# 1. คำนวณตำแหน่งพื้นฐาน
			var snap_x = snapped(pos.x, snap_step)
			var snap_z = snapped(pos.z, snap_step)
		
			

			# --- หลังจากนี้ให้เป็นโค้ด Auto-Stacking และ Is_Safe เดิมของพี่ได้เลย ---
			
			# --- [เพิ่มใหม่] โค้ดปรับความสูงตอนบล็อกนอน ---
			# --- [แก้ไข] โค้ดปรับความสูงตอนบล็อกนอนให้ฉลาดขึ้น ---
			# --- ระบบคำนวณความสูงอัตโนมัติสำหรับทุกยูนิต (ทั้งบล็อกและตัวละคร) ---
			# ไม่ว่าจะเป็นใคร หรือหมุนท่าไหน จะคำนวณจากกล่อง AABB จริงๆ
			# --- ระบบคำนวณความสูงอัตโนมัติอัจฉริยะ ---
			var current_aabb = get_unit_global_aabb(dragging_unit.global_position, dragging_unit.global_transform.basis, dragging_unit)
			var local_bottom_offset = current_aabb.position.y - dragging_unit.global_position.y
			var target_y = 0.0 - local_bottom_offset
			
			# 🌟 [อัปเกรด: คืนชีพความแม่นยำ + ความลื่น 1000%]
			# 1. คำนวณกล่องของตัวเองที่ Y ล่างสุด (ทำแค่ครั้งเดียว)
			var test_pos = Vector3(snap_x, target_y, snap_z)
			var my_base_aabb = get_unit_global_aabb(test_pos, dragging_unit.global_transform.basis, dragging_unit, true)
			
			# 2. กวาดกล่องของคนอื่นรอบๆ มาเก็บไว้ (เช็คจาก occupied_tiles)
			var obstacle_aabbs = []
			for unit in occupied_tiles.values():
				if is_instance_valid(unit) and unit != dragging_unit:
					obstacle_aabbs.append(get_unit_global_aabb(unit.global_position, unit.global_transform.basis, unit, false))
			
			# 3. ลูปขยับกล่อง AABB จำลองขึ้นทีละ 0.25 (โคตรไว ไม่ต้องขยับโมเดลจริง)
			var max_stack_levels = 40 
			var step_count = 0
			var is_overlap = true
			
			while is_overlap and step_count < max_stack_levels:
				is_overlap = false
				# จำลองตำแหน่งกล่องที่ขยับขึ้น
				var current_test_aabb = my_base_aabb
				current_test_aabb.position.y += (step_count * snap_step)
				
				# เช็คการชนกับกล่องทุกใบ
				for obs_aabb in obstacle_aabbs:
					if current_test_aabb.intersects(obs_aabb):
						is_overlap = true
						break # ชนปุ๊บ เลิกเช็ค ดันขึ้นชั้นต่อไปทันที
						
				if is_overlap:
					step_count += 1
			
			# 4. ได้ความสูงที่ปลอดภัย 100% แล้ว ค่อยขยับโมเดลจริงแค่รอบเดียวจบ!
			target_y += (step_count * snap_step)
			dragging_unit.global_position = Vector3(snap_x, target_y, snap_z)
			
			# 🌟 [อัปเกรด] ทำให้ระบบดูดหอกรองรับหอกศัตรูด้วย (แค่มีคำว่า spear ในชื่อก็พอ)
			var dragging_name = str(unit_data.get("name", "")).to_lower()
			if "spear" in dragging_name:
				var magnet_dist = 2.5 # ระยะรัศมีที่จะให้เริ่มดูด
				var nearest_target = null
				
				# เช็คก่อนว่าหอกที่เราลากอยู่ เป็นของทีมไหน?
				var is_enemy_spear = str(unit_data.get("category")).begins_with("enemy")
				
				# วนลูปหาตัวละครจาก Node ลูกทั้งหมด
				for unit in get_children():
					if is_instance_valid(unit) and unit != dragging_unit:
						var u_name = ""
						if unit.get("unit_name") != null:
							u_name = str(unit.get("unit_name")).to_lower()
						elif "unit_data" in unit:
							u_name = str(unit.unit_data.get("name", "")).to_lower()
							
						# 🌟 กรองหาเป้าหมายให้ตรงฝั่ง (หอกศัตรูดูดใส่หัวศัตรู / หอกเราดูดใส่หัวเรา)
						var is_valid_target = false
						if is_enemy_spear:
							is_valid_target = is_enemy_char(u_name)
						else:
							is_valid_target = is_player_char(u_name)
							
						if is_valid_target:
							# ใช้ตำแหน่งเมาส์ (pos) เทียบกับตัวละคร
							var dist = pos.distance_to(unit.global_position)
							if dist < magnet_dist:
								magnet_dist = dist
								nearest_target = unit
							
				if nearest_target:
					# ดูดหอกเข้ากลางกึ่งกลางตัวละคร
					dragging_unit.global_position.x = nearest_target.global_position.x
					dragging_unit.global_position.z = nearest_target.global_position.z
					# วางหอกบนหัว (ความสูงตัวละคร + 1.2 เมตร)
					dragging_unit.global_position.y = nearest_target.global_position.y + 2.0
				
			# =========================================================


			
			# --- เตรียมข้อมูลเงื่อนไขต่างๆ ---
			var current_pos = dragging_unit.global_position
			var is_safe = is_position_safe(current_pos, dragging_unit)
			# ==========================================
			# 🌟 [แก้ตรงนี้!] ปลดล็อกกรอบเขตแดนให้ศัตรู
			# ==========================================
			var is_in_bounds = true
			# 🌟 ใช้ not และ begins_with เพื่อบอกว่า "ถ้าไม่ใช่พวกตระกูล enemy ให้กั้นเขตซะ"
			if not str(unit_data.get("category")).begins_with("enemy"):
				is_in_bounds = is_within_boundary(current_pos) # ถ้าไม่ใช่ศัตรู ให้เช็คกรอบตามปกติ
			# ==========================================
			
			var is_hero_limit_reached = false
			if not is_moving_existing_unit:
				var max_c = unit_data.get("max_count", -1)
				# ถ้ามีจำกัดจำนวน (max_count ไม่ใช่ -1)
				if max_c != -1:
					var current_count = get_unit_count_on_field(unit_data["name"])
					if current_count >= max_c:
						is_hero_limit_reached = true
			
			# ตรวจสอบเงื่อนไขทั้งหมดร่วมกัน
			if is_safe and is_in_bounds and not is_hero_limit_reached:
				set_unit_preview_color(dragging_unit, Color(0.0, 1.0, 1.0, 0.502)) 
			else:
				set_unit_preview_color(dragging_unit, Color(1, 0, 0, 0.5))
				
			# ==========================================
			# -# ==========================================
			# --- [เพิ่มใหม่] เช็ครัศมีสำหรับปืน ---
			# --- [แก้ไขใหม่] เช็ครัศมีสำหรับปืน (รองรับทั้งปืนเราและปืนศัตรู) ---
			var is_within_gun_radius = true
			# 🌟 1. แก้ตรงนี้: เช็คว่าเป็นปืนหรือไม่ (ดูจากหมวดหมู่ที่มีคำว่า gun)
			var category_str = str(unit_data.get("category"))
			var is_gun_type = "gun" in category_str or "gun" in unit_data.get("name", "").to_lower()
			
			if is_gun_type:
				is_within_gun_radius = false 
				var max_radius = 2.0 
				var nearest_char = null
				var min_dist = max_radius 
				# 🌟 2. แก้ตรงนี้: เช็คว่าเป็นปืนศัตรูหรือไม่
				var is_enemy_gun = category_str.begins_with("enemy")
				
				# 🌟 แก้บั๊กกุญแจทับซ้อน: เปลี่ยนจาก occupied_tiles มาสแกนจากฉากตรงๆ
				for tile_unit in get_children():
					if is_instance_valid(tile_unit) and tile_unit != dragging_unit:
						var t_name = ""
						if tile_unit.get("unit_name") != null:
							t_name = str(tile_unit.get("unit_name")).to_lower()
						else:
							t_name = tile_unit.name.to_lower()
						
						var is_valid_target = false
						if is_enemy_gun:
							# 🌟 ถ้าเราลากปืนศัตรู ต้องหาเจ้าของที่เป็นศัตรูเท่านั้น
							is_valid_target = is_enemy_char(t_name)
						else:
							# 🌟 ถ้าเราลากปืนผู้เล่น ต้องหาเจ้าของที่เป็นผู้เล่นเท่านั้น
							is_valid_target = is_player_char(t_name)
							
						if is_valid_target:
							if tile_unit.has_meta("linked_gun"):
								var g = tile_unit.get_meta("linked_gun")
								if is_instance_valid(g) and not g.is_queued_for_deletion() and g != dragging_unit:
									continue
								
							var dist = current_pos.distance_to(tile_unit.global_position)
							if dist <= min_dist:
								min_dist = dist
								nearest_char = tile_unit
								
				if nearest_char:
					is_within_gun_radius = true
					dragging_unit.global_rotation.y = nearest_char.global_rotation.y + deg_to_rad(90)
			# ==========================================
			# ==========================================
			# ==========================================
			# ==========================================

			# นำ is_within_gun_radius มาตรวจเช็คร่วมด้วย
			if is_safe and is_in_bounds and not is_hero_limit_reached and is_within_gun_radius:
				set_unit_preview_color(dragging_unit, Color(0.0, 1.0, 1.0, 0.502)) 
			else:
				set_unit_preview_color(dragging_unit, Color(1, 0, 0, 0.5))
			
			# ==========================================
			# --- [แก้ไขใหม่] ลากปืนตาม และเช็คการชนของปืนด้วย ---
			var gun_safe = true
			if dragging_gun and is_instance_valid(dragging_gun):
				dragging_gun.global_position = dragging_unit.global_position + gun_offset
				# เช็คด้วยว่า ปืนที่พ่วงมา ไปฟาดโดนบล็อกอื่นหรือเปล่า?
				gun_safe = is_position_safe(dragging_gun.global_position, dragging_gun)
			
			# รวมเงื่อนไขทั้งหมด (ถ้าตัวละครชน ปืนชน หรือนอกเขต = วางไม่ได้ทั้งคู่)
			var can_place = is_safe and is_in_bounds and not is_hero_limit_reached and is_within_gun_radius and gun_safe

			if can_place:
				set_unit_preview_color(dragging_unit, Color(0.0, 1.0, 1.0, 0.502)) 
				if dragging_gun: set_unit_preview_color(dragging_gun, Color(0.0, 1.0, 1.0, 0.502))
			else:
				set_unit_preview_color(dragging_unit, Color(1, 0, 0, 0.5))
				if dragging_gun: set_unit_preview_color(dragging_gun, Color(1, 0, 0, 0.5))
			# ==========================================
	
	
	# ==========================================
	# 🌟 โค้ดลากกลุ่ม (Multi-Dragging) แบบเสถียรที่สุด 100%
	# ==========================================
	if dragging_multi_units.size() > 0:
		var pos = get_ground_position()
		if pos != Vector3.ZERO:
			var snap_x = snapped(pos.x, snap_step)
			var snap_z = snapped(pos.z, snap_step)
			# 🌟 ล็อกความสูงศูนย์กลางให้เป็น 0 เสมอ
			var center_snap = Vector3(snap_x, 0.0, snap_z)
			
			# 🌟 ด่านลดแล็กขั้นเด็ดขาด: คำนวณเมื่อข้ามช่องตารางเท่านั้น!
			if center_snap != last_drag_grid_pos:
				last_drag_grid_pos = center_snap
			
				# 🌟 1. ตั้งตำแหน่ง และบังคับอัปเดตกระดูกทันที! 
				for i in range(dragging_multi_units.size()):
					var clone = dragging_multi_units[i]
					var offset = multi_drag_offsets[i]
					# (ค่า offset.y ของทุกคน ถูกปรับให้พอดีพื้นมาตั้งแต่ตอนกดก๊อปปี้แล้ว!)
					clone.global_position = center_snap + offset 
					clone.force_update_transform() 
					
				# 🌟 2. ระบบ Auto-Stacking (ดันขึ้นข้างบนถ้าชนของเดิม)
				var max_stack_levels = 40
				var step_count = 0
				var group_overlap = true
				
				while group_overlap and step_count < max_stack_levels:
					group_overlap = false
					var test_y_offset = step_count * snap_step
					
					for clone in dragging_multi_units:
						var test_pos = clone.global_position + Vector3(0, test_y_offset, 0)
						if not is_position_safe(test_pos, clone):
							group_overlap = true
							break
							
					if group_overlap:
						step_count += 1
						
				var final_y_offset = step_count * snap_step
				var all_safe = true
				
				# 🌟 3. วางตำแหน่งจริง และเช็คกฎเกมแบบเป๊ะๆ
				for clone in dragging_multi_units:
					clone.global_position.y += final_y_offset
					clone.force_update_transform() # บังคับอัปเดตรอบสุดท้าย
					
					# ตามหาว่าร่างโคลนนี้เป็น "ศัตรู" หรือเปล่า?
					var is_enemy = false
					if clone.has_meta("orig_unit"):
						var orig = clone.get_meta("orig_unit")
						if is_instance_valid(orig) and orig.get("unit_name") != null:
							is_enemy = is_enemy_unit(str(orig.get("unit_name")))
					elif clone.get("unit_name") != null:
						is_enemy = is_enemy_unit(str(clone.get("unit_name")))
						
					# 🌟 กฎเขตแดน: ถ้าไม่ใช่ศัตรู ต้องอยู่ในเขตสีฟ้าเท่านั้น!
					var within_bounds = true
					if not is_enemy:
						within_bounds = is_within_boundary(clone.global_position)
						
					# เช็คความปลอดภัย (ป้องกันดันจนทะลุเพดาน หรือแอบออกนอกเขต)
					if not is_position_safe(clone.global_position, clone) or not within_bounds:
						all_safe = false
						
				# 🌟 4. อัปเดตสี
				var color = Color(0.0, 1.0, 1.0, 0.502) if all_safe else Color(1.0, 0.0, 0.0, 0.5)
				for clone in dragging_multi_units:
					set_unit_preview_color(clone, color)
		
	
	# 2. ระบบกดแช่ (Long Press) เพื่อเคลื่อนย้ายตัวที่วางไปแล้ว
	if not is_game_started and is_pressing and selected_unit and not dragging_unit:
		press_timer += delta
		if press_timer >= LONG_PRESS_TIME:
			start_re_drag() # เริ่มการย้ายใหม่

	# 3. ให้เมนู (ActionMenu / CombatMenu) วิ่งตามตัวละครที่เลือก
	# 3. ให้เมนู (ActionMenu / CombatMenu) วิ่งตามตัวละครที่เลือก
	if selected_unit and is_instance_valid(selected_unit) and not dragging_unit:
		var cam = get_viewport().get_camera_3d()
		if cam:
			var screen_pos = cam.unproject_position(selected_unit.global_position) + Vector2(60, -60)
			
			if not is_game_started:
				# โหมดสร้าง: ปุ่ม Rotate/Delete ต้องขึ้น
				if action_menu.visible:
					action_menu.global_position = screen_pos
					
					# เช็คประเภทบล็อกเพื่อโชว์ปุ่มเสริม (ลอจิกเดิมของคุณ)
					var btn_horizontal = action_menu.get_node_or_null("BtnRotateHorizontal") 
					var btn_duplicate = action_menu.get_node_or_null("BtnDuplicate")
					var u_name = selected_unit.get("unit_name")
					if "block" in u_name:
						if btn_horizontal: btn_horizontal.show()
						if btn_duplicate: btn_duplicate.show()
					else:
						if btn_horizontal: btn_horizontal.hide()
						if btn_duplicate: btn_duplicate.hide()
	# ==========================================
	# 🌟 4. ให้เมนู MultiAction วิ่งตาม "ศูนย์กลาง" ของกลุ่มที่ลากคลุม
	# ==========================================
	if multi_selected_units.size() > 0 and multi_action_menu and multi_action_menu.visible and not dragging_unit:
		var cam = get_viewport().get_camera_3d()
		if cam:
			var center_pos = Vector3.ZERO
			var valid_count = 0
			
			# เอาพิกัดของทุกตัวที่ถูกเลือกมาบวกกัน
			for u in multi_selected_units:
				if is_instance_valid(u):
					center_pos += u.global_position
					valid_count += 1
					
			# หารหาค่าเฉลี่ย เพื่อหา "จุดศูนย์กลาง" ของกลุ่ม
			if valid_count > 0:
				center_pos /= valid_count
				# แปลงพิกัด 3D เป็น 2D หน้าจอ แล้วเยื้องขวา+บน (เหมือนปุ่ม Action เดี่ยว)
				var screen_pos = cam.unproject_position(center_pos) + Vector2(60, -60)
				multi_action_menu.global_position = screen_pos
	# ==========================================

				
				
	# ==========================================
	# --- โหมดเล็งยิง: หมุนด้วย A/D และเงยด้วย W/S ---
	if is_game_started and is_combat_aiming and is_instance_valid(active_combat_unit):
		# 🌟 หยุดแรงหมุน/แรงเหวี่ยงทั้งหมด ไม่ให้มันดีดเป็นนินจาโก
		active_combat_unit.angular_velocity = Vector3.ZERO
		active_combat_unit.linear_velocity = Vector3.ZERO
		
		
		# 1. รับค่า Input หมุนซ้ายขวา (A/D)
		var rotate_dir = int(Input.is_physical_key_pressed(KEY_A)) - int(Input.is_physical_key_pressed(KEY_D))
		if rotate_dir != 0:
			var turn_speed = 0.3 # ค่าเริ่มต้นตอนเล็งยิงปกติ (ช้าๆ เน้นแม่น)
			
			# 🌟 [จุดแก้!] แยกความเร็วหมุนตามโหมด
			if combat_action_mode == "walk":
				turn_speed = 1.0 # 🚶 โหมดเดิน: หันไวขึ้น (ปรับเลข 1.0 ได้ตามชอบครับ)
			elif is_spraying:
				turn_speed = 1.2 # 🔫 โหมดกราดยิง: หันไวสุด
				
			current_aim_offset += rotate_dir * turn_speed * delta
			current_aim_offset = clamp(current_aim_offset, -MAX_AIM_ANGLE, MAX_AIM_ANGLE)
			active_combat_unit.rotation.y = initial_aim_rotation + current_aim_offset
		
		
		# 2. รับค่า Input ก้มเงย (W/S)
		var pitch_dir = int(Input.is_physical_key_pressed(KEY_W)) - int(Input.is_physical_key_pressed(KEY_S))
		if pitch_dir != 0:
			# 🌟 1. ขยับเส้นเล็ง (Trajectory) เป็นหลัก (ใช้เรเดียน)
			current_pitch_offset += pitch_dir * 1.0 * delta # 1.0 คือความเร็วในการเงย
			
			# 🌟 2. ตั้งลิมิตให้เส้นเล็ง (สมมติให้ก้มเงยได้สุดทางฝั่งละ 45 องศา จากจุดเริ่ม)
			var max_rad = deg_to_rad(45.0)
			current_pitch_offset = clamp(current_pitch_offset, -max_rad, max_rad)
			
			# 🌟 3. บังคับกล้องให้ "ล็อกเป้า" ตามเส้นเล็ง 100%
			var cam = get_viewport().get_camera_3d()
			if cam:
				var cam_rig = cam.get_parent().get_parent().get_parent()
				if "pitch_target" in cam_rig:
					# เอา 40.0 (มุมเริ่มเล็ง) มาบวกกับมุมของเส้นเล็ง (ที่แปลงเป็นองศาแล้ว)
					# ถ้าพี่กด W แล้วกล้องมันสวนทาง ให้เปลี่ยนเครื่องหมาย + เป็น - แทนครับ
					cam_rig.pitch_target = 25.0 + rad_to_deg(current_pitch_offset)
			
		# 4. 🌟 จัดการปืนให้ "โคจร" และ "หมุน" ตามตัวละคร (ใช้ร่วมกันทั้งยิงและเดิน)
		if active_combat_unit.has_meta("linked_gun"):
			var attached_gun = active_combat_unit.get_meta("linked_gun")
			if is_instance_valid(attached_gun):
				
				# 🔄 1. จัดการการหมุนและตำแหน่ง (Transform)
				if combat_action_mode == "walk":
					# 🌟 ใช้กาวตราช้าง: บังคับให้หอกแปะติดกับตัวละครเป๊ะๆ
					if active_combat_unit.has_meta("walk_local_transform"):
						var local_trans = active_combat_unit.get_meta("walk_local_transform")
						attached_gun.global_transform = active_combat_unit.global_transform * local_trans
				else:
					# --- โหมดเล็งยิง: ปล่อยให้ทำงานตามเดิม ---
					attached_gun.global_rotation.y = active_combat_unit.global_rotation.y + deg_to_rad(90)
					
					# 📍 2. จัดการตำแหน่ง (Position) เฉพาะตอนยิง
					if active_combat_unit.has_meta("gun_local_offset"):
						var local_pos = active_combat_unit.get_meta("gun_local_offset")
						attached_gun.global_position = active_combat_unit.to_global(local_pos)
				
				# 🛡️ 3. สั่ง Update ทันทีเพื่อกันบั๊กฟิสิกส์
				if attached_gun is RigidBody3D:
					attached_gun.linear_velocity = Vector3.ZERO
					attached_gun.angular_velocity = Vector3.ZERO
			# =======================================================

			
		# ให้ปืนหมุนตามตัวละครเป๊ะๆ
		if active_combat_unit.has_meta("linked_gun"):
			var attached_gun = active_combat_unit.get_meta("linked_gun")
			if is_instance_valid(attached_gun):
				attached_gun.global_rotation.y = active_combat_unit.global_rotation.y + deg_to_rad(90)
				
				# --- [แก้ตรงนี้] ให้ปืนเคลื่อนที่โคจรรอบตัวละครด้วย ไม่ใช่แค่หมุนอยู่กับที่ ---
				if active_combat_unit.has_meta("gun_local_offset"):
					var local_pos = active_combat_unit.get_meta("gun_local_offset")
					attached_gun.global_position = active_combat_unit.to_global(local_pos)
					
					
		# ====================================================================================
		# --- 1. ดึงข้อมูลปืนที่ถืออยู่เพื่อเอามาวาดเส้น ---
		var current_gun = null 
		var gun_name = ""
		if active_combat_unit.has_meta("linked_gun"):
			current_gun = active_combat_unit.get_meta("linked_gun")
			if is_instance_valid(current_gun):
				gun_name = str(current_gun.get("unit_name")).to_lower() if current_gun.get("unit_name") != null else current_gun.name.to_lower()
		
		# --- 2. แสดงเส้นตอนกำลังง้าง (แยกโหมด ยิง/เดิน) ---
		if power_ui and power_ui.is_dragging:
			$TrajectoryLine.show()
			
			var base_forward = active_combat_unit.global_transform.basis.z.normalized()
			var power = power_ui.current_power
			
			if combat_action_mode == "shoot":
				# 🔫 โหมดยิง: เส้นออกจากปืน และใช้รูปทรงตามประเภทปืน
				if is_instance_valid(current_gun):
					var right_axis = active_combat_unit.global_transform.basis.x.normalized()
					var aim_dir = base_forward.rotated(right_axis, -current_pitch_offset)
					
					var impulse_mult = 0.5
					if "spear" in gun_name: impulse_mult = 0.1
					elif "sniper" in gun_name: impulse_mult = 2.5
					elif "shotgun" in gun_name: impulse_mult = 2.0
					elif "semi_auto" in gun_name: impulse_mult = 0.375
					elif "machine_gun" in gun_name: impulse_mult = 0.75
					
					var launch_v = aim_dir.normalized() * (power * impulse_mult)
					var start_p = current_gun.global_position
					
					update_trajectory_line(start_p, launch_v, gun_name, current_gun, false)
					
			elif combat_action_mode == "walk":
				# 🚶 โหมดเดิน: เส้นออกจากตัวละคร และห้ามบานเป็นลูกซอง!
				var start_p = active_combat_unit.global_position + Vector3(0, 0.5, 0) # จุดเริ่มตรงกลางลำตัว
				var launch_v = Vector3.ZERO
				
				# จำลองแรงให้ตรงกับที่ตั้งไว้ใน execute_player_walk
				if power <= 30.0:
					var walk_force = clamp(power * 0.25, 3.0, 8.0)
					launch_v = base_forward * walk_force
				else:
					var jump_dist = power * 0.15 
					var target_pos = active_combat_unit.global_position + (base_forward * jump_dist)
					var unit_mass = active_combat_unit.mass if "mass" in active_combat_unit else 1.0
					launch_v = calculate_arc_impulse(active_combat_unit.global_position, target_pos, unit_mass)
				
				# 🌟 ส่ง string ว่าง "" เข้าไปแทนชื่อปืน เพื่อบังคับให้วาดเป็นเส้นเดี่ยวปกติ
				update_trajectory_line(start_p, launch_v, "", active_combat_unit, false)
		else:
			$TrajectoryLine.hide()
					
		# ====================================================================================  ====================================================================================
# --- [ส่วนที่เพิ่มใหม่] เฉพาะหอก: Snap เข้าหาตัวละครทุกประเภท ---
			if unit_data.get("name") == "spear":
				var snap_radius = 2.0 
				var nearest_unit = null
				var min_dist = snap_radius
				
				for tile_unit in occupied_tiles.values():
					if is_instance_valid(tile_unit):
						# เช็คว่าหมวดหมู่เป็นตัวละครไหม (ไม่สนชื่อ)
						var t_cat = ""
						if "unit_data" in tile_unit: t_cat = tile_unit.unit_data.get("category", "")
							
						if t_cat == "character":
							var dist = dragging_unit.global_position.distance_to(tile_unit.global_position)
							if dist < min_dist:
								min_dist = dist
								nearest_unit = tile_unit
				
				# ถ้าเจอตัวละครในระยะ ให้ดูดเข้าหาจุดศูนย์กลาง X, Z ทันที
				if nearest_unit:
					dragging_unit.global_position.x = nearest_unit.global_position.x
					dragging_unit.global_position.z = nearest_unit.global_position.z
					# ความสูง Y จะถูกคำนวณจากระบบ Stacking เดิมของพี่ (ให้มันซ้อนบนหัว)
					
					
	for unit in get_children():
		if is_instance_valid(unit) and unit.has_meta("is_moving_ai") and unit.get_meta("is_moving_ai") == true:
			# เช็คว่ามีปืน และมีตำแหน่งที่เคยบันทึกไว้ไหม
			# 🌟 ใช้กาวตราช้าง Ai_slide_transform ล็อกหอกให้ติดแน่น!
			if unit.has_meta("linked_gun") and unit.has_meta("ai_slide_transform"):
				var gun = unit.get_meta("linked_gun")
				if is_instance_valid(gun):
					var local_trans = unit.get_meta("ai_slide_transform")
					gun.global_transform = unit.global_transform * local_trans

	# ==========================================





# ==========================================
# 🌟 ตัวแปรจับเวลาฟิสิกส์
# ==========================================
var physics_wait_timer: float = 0.0
var frame_skip: int = 0 # 🌟 ตัวช่วยลดภาระ CPU

func _physics_process(delta: float) -> void:
	# 🌟 ออฟติไมซ์ขั้นสุด: บังคับให้ทำงานแค่ 1 ใน 10 เฟรม (ลดการกินสเปคลง 90%!)
	frame_skip += 1
	if frame_skip < 10:
		return # ถ้ายังไม่ถึง 10 เฟรม ให้หยุดข้ามการคิดเลขไปเลย! ปล่อยภาพบนจอไหลลื่นไป
	frame_skip = 0

	# 🌟 1. ระบบ "เหวล้างบาง" (Kill Z)
	for unit in get_children():
		if is_instance_valid(unit) and unit is Node3D:
			if unit.global_position.y < -20.0:
				print("⚠️ ของตกแมพ! ระบบทำการลบทิ้ง: ", unit.name)
				if unit.has_method("queue_free"):
					unit.queue_free()

	# 🌟 2. เช็คฟิสิกส์นิ่ง (รอตัวละครล้ม/ลุก/กระเด็น จนเสร็จ)
	if current_state == Turn.WAITING_PHYSICS:
		# เนื่องจากเราทำงานทุกๆ 10 เฟรม เวลาที่บวกก็ต้องคูณ 10 ให้ตรงกับโลกจริง
		physics_wait_timer += delta * 10.0 
		
		# บังคับให้ระบบ "หลับตา" ห้ามเช็คฟิสิกส์ 2 วินาทีแรก
		if physics_wait_timer > 2.0:
			
			if are_all_units_settled() or physics_wait_timer > 15.0:
				if physics_wait_timer > 15.0:
					print("⏰ หมดเวลารอฟิสิกส์! บังคับสลับเทิร์นเพื่อป้องกันเกมค้าง")
				proceed_to_next_turn()
	else:
		# ถ้าไม่ได้อยู่ในโหมดรอ ให้รีเซ็ตนาฬิกากลับเป็น 0 เสมอ
		physics_wait_timer = 0.0
#===========================================================================
func is_all_units_resting() -> bool:
	for unit in get_children():
		if unit is RigidBody3D:
			# 🛠️ ปรับจาก 0.1 เป็น 0.3 หรือ 0.5 เพื่อให้เกมลื่นไหลขึ้น ไม่ต้องรอนิ่งสนิทดุจหยุดเวลา
			if unit.linear_velocity.length() > 0.4 or unit.angular_velocity.length() > 0.4:
				return false
	return true
#===========================================================================







func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if is_dragging_selection and not is_game_started:
			_update_selection_box(event.position)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# 🛡️ 1. เกราะป้องกัน UI (เช็คเฉพาะตอนกดลง)
		if event.pressed:
			if is_mouse_over_ui(): return 
			
			# (ของเดิมพี่แว่น) กันทะลุเมนูสร้างด่าน
			if multi_action_menu and multi_action_menu.visible:
				var menu_rect = multi_action_menu.get_global_rect()
				if menu_rect.has_point(event.position): return
				
			# 🌟 [เพิ่มใหม่!] กันทะลุเมนูต่อสู้ (ปุ่ม Walk, Shoot, Snap)
			if combat_menu and combat_menu.visible:
				var combat_rect = combat_menu.get_global_rect()
				if combat_rect.has_point(event.position): return

		if event.pressed:
			# ==========================================
			# 🌟 จังหวะกดเมาส์ (Pressed): คือการ "หยิบ" หรือ "เริ่มลาก"
			# ==========================================
			is_pressing = true
			press_timer = 0.0
			drag_start_pos = event.position 
			
			if is_game_started:
				combat_check_selection()
			else:
				var is_ctrl = Input.is_physical_key_pressed(KEY_CTRL)
				
				if is_ctrl:
					# โหมดลากคลุม
					_clear_multi_selection()
					is_dragging_selection = true
					if selection_box:
						selection_box.position = drag_start_pos
						selection_box.size = Vector2.ZERO
						selection_box.show()
					selected_unit = null
					if action_menu: action_menu.hide()
				else:
					# ระบบเช็คเพื่อ "หยิบ" ยูนิตเดี่ยวหรือกลุ่ม
					var old_multi_group = multi_selected_units.duplicate()
					check_for_unit_selection() 
					
					var caught_unit = null
					if dragging_unit: caught_unit = dragging_unit
					elif selected_unit: caught_unit = selected_unit
					
					# ถ้าคลิกโดนตัวในกลุ่มที่เคยคลุมไว้ -> ให้ยกพวกมาลอยติดเมาส์
					if caught_unit and caught_unit in old_multi_group:
						selected_unit = null
						if action_menu: action_menu.hide()
						if dragging_unit:
							occupied_tiles[dragging_unit.tile_key] = dragging_unit
							dragging_unit = null
						multi_selected_units = old_multi_group
						_start_multi_move_from_world()
						return
					else:
						# ถ้าไม่ได้คลิกโดนกลุ่มเดิม ให้ล้างสถานะมัลติ
						if caught_unit == null:
							_clear_multi_selection()
						else:
							for u in old_multi_group:
								if is_instance_valid(u) and u != caught_unit:
									set_unit_preview_color(u, Color(1, 1, 1, 1))
							multi_selected_units.clear()
						if multi_action_menu: multi_action_menu.hide()
		else:
			# ==========================================
			# 🌟 จังหวะปล่อยเมาส์ (Released): คือการ "วาง"
			# ==========================================
			# ==========================================
			# 🌟 จังหวะปล่อยเมาส์ (Released): คือการ "วาง"
			# ==========================================
			is_pressing = false
			
			# 🌟 ถ้ากำลังเล็งปืนอยู่ ให้บล็อคการลากกรอบซ้อนทับ# ถ้าเป็นโหมดยิง/เดิน ให้ล็อกเมาส์ซ้ายไว้เหมือนเดิม
			if is_game_started and is_combat_aiming:
				return
					
				
				
			
			
			# --- โค้ดเดิมของโหมดสร้างด่าน ---
			# ไม่ว่าจะลากไกลแค่ไหน หรือแค่คลิกปล่อยที่เดิม ถ้ามีของติดมืออยู่ -> สั่งวางทันที!
			if dragging_unit or dragging_multi_units.size() > 0:
				finalize_placement()
					
			if is_dragging_selection:
				is_dragging_selection = false
				if selection_box: selection_box.hide()
				_execute_multi_selection(event.position)

	# --- ระบบยกเลิกการเล็ง และยกเลิกการเลือกตัวละคร (คลิกขวา/Esc) ---
	if is_game_started and not is_firing: 
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed) or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
			if is_combat_aiming:
				cancel_combat_aim()
			elif selected_unit:
				deselect_combat_unit() # 🌟 ถ้าแค่คลิกซูมตัวละครอยู่ แล้วกดคลิกขวา ให้ดึงกล้องกลับทันที!

	# ==========================================
	# 🌟 เรดาร์ปิดเมนูอัตโนมัติเมื่อคลิกที่อื่น (เอามาต่อท้ายตรงนี้เลย!)
	# ==========================================
	if event is InputEventMouseButton and event.pressed:
		# ถ้ากดคลิกซ้าย หรือ คลิกขวา
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			# เช็คว่าเมนูเปิดอยู่หรือเปล่า
			if blueprint_context_menu and blueprint_context_menu.visible:
				# หาระยะกรอบสี่เหลี่ยมของเมนู
				var rect = blueprint_context_menu.get_global_rect()
				# ถ้าจุดที่เมาส์คลิก ไม่อยู่ในกรอบเมนู = สั่งปิด!
				if not rect.has_point(event.global_position):
					blueprint_context_menu.hide()












# 🌟 เปลี่ยนจาก _input เป็น _unhandled_input เพื่อไม่ให้มันไปแย่งคลิกจากปุ่ม UI
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if is_game_started and is_combat_aiming:
			
			# ==========================================
			# 🔵 โหมดเลือกจุด Snap 
			# ==========================================
			# 🌟 เพิ่ม (or combat_action_mode == "snap_ready") เพื่อให้คลิกเปลี่ยนจุดได้เรื่อยๆ
			if (combat_action_mode == "snap_setup" or combat_action_mode == "snap_ready") and event.button_index == MOUSE_BUTTON_LEFT:
				var pos = get_ground_position()
				var dist = active_combat_unit.global_position.distance_to(pos)
				
				if dist <= 7.3:
					var snap_x = snapped(pos.x, snap_step)
					var snap_z = snapped(pos.z, snap_step)
					
					# 🌟 ใช้ค่าความสูงเดิมของพี่ (ไม่แก้เป็น 0.0 แล้วครับ)
					var final_snap_pos = Vector3(snap_x, active_combat_unit.global_position.y, snap_z)
					
					active_combat_unit.set_meta("base_pos", active_combat_unit.global_position)
					active_combat_unit.set_meta("snap_pos", final_snap_pos)
					
					create_snap_ghost(active_combat_unit, final_snap_pos)
					
					if combat_menu:
						combat_menu.show()
						var btn_w = combat_menu.get_node_or_null("BtnCombatWalk")
						var btn_s = combat_menu.get_node_or_null("BtnCombatSnap")
						if btn_w: btn_w.hide()
						if btn_s: btn_s.hide()
					
					combat_action_mode = "snap_ready" 
					print("📍 อัปเดตจุดยักสำเร็จ! (ความสูงเดิม)")
				else:
					if error_sound_player: error_sound_player.play()
					print("❌ ไกลเกินไป! เลือกจุดในตารางสีเหลืองเท่านั้น")
				return













func check_for_unit_selection():
	# ถ้ากำลังลากของอยู่ ห้ามรันลอจิกการเลือกตัวละครเด็ดขาด
	if dragging_unit: return 
	
	var result = get_raycast_result()
	
	if result and result.collider:
		var target = result.collider
		
		# --- 🛠️ 1. ทะลวงหาโหนดแม่: ถ้าตัวที่โดนคลิกไม่มี tile_key ให้ถามพ่อมันดู ---
		if not "tile_key" in target and target.get_parent() != null:
			if "tile_key" in target.get_parent():
				target = target.get_parent() # สลับเป้าหมายไปที่แม่แทน!
		
		# --- 🛠️ 2. เพิ่มเงื่อนไข target is Node3D เข้าไปด้วย (เพราะลูกซองเราเป็นโหนดนี้แล้ว) ---
		if target is CharacterBody3D or target is RigidBody3D or target is Node3D:
			# ถ้ามี tile_key ค่อยถือว่าเป็นตัวละคร/ปืน ของเราจริงๆ
			if "tile_key" in target: 
				var u_name = str(target.get("unit_name"))
				
				# ==========================================
				# 🚫 กางบาเรียตรงนี้! ถ้าเป็นของศัตรู ปิดเมนูและเด้งออกทันที!
				if is_enemy_unit(u_name) and not is_dev_mode:
					print("🚫 ไม่อนุญาตให้แตะต้องยูนิตของศัตรู!")
					selected_unit = null
					action_menu.hide()
					return
				# ==========================================
				
				selected_unit = target
				action_menu.show()
				return # เจอเป้าหมายแล้ว จบการทำงานฟังก์ชันตรงนี้เลย
				
	# ถ้าไม่เข้าเงื่อนไขอะไรเลย (เช่น คลิกโดนพื้น หรือคลิกพลาด) ให้ล้างค่าทิ้ง
	selected_unit = null
	action_menu.hide()





func combat_check_selection():
	# 🛡️ [ยามเฝ้าประตู] ถ้ากำลังเล็ง (ง้างปืน) หรือกระสุนกำลังวิ่ง ห้ามกดเปลี่ยนตัวเด็ดขาด!
	if is_combat_aiming or is_firing: return
	
	if dragging_unit or current_state != Turn.PLAYER: return 
	
	var result = get_raycast_result()
	if result and (result.collider is CharacterBody3D or result.collider is RigidBody3D):
		var u_name = str(result.collider.get("unit_name"))
		
		# 🌟 เช็คว่าเป็นตัวละครฝั่งเราใช่ไหม?
		if is_player_char(u_name):
			
			# 💀 1. เช็คว่าตายหรือยัง?
			if result.collider.get("is_dead") == true:
				print("💀 ตัวละครนี้ตายแล้ว! สั่งการไม่ได้")
				return # ❌ ปล่อยผ่านไปเลย ห้ามดึงกล้องกลับ!
			
			# 🚫 2. เช็คสิทธิ์การยิง
			var is_locked = false
			if result.collider.has_meta("has_attacked_this_turn"):
				is_locked = result.collider.get_meta("has_attacked_this_turn")
				
			if is_locked == true:
				print("🚫 ตัวละครนี้ติดสถานะ Reload หรือใช้สิทธิ์ยิงไปแล้ว!")
				return # ❌ ปล่อยผ่านไปเลย ห้ามดึงกล้องกลับ!
				
			# ==========================================
			# 🌟 ถ้าผ่านทุกเงื่อนไข ก็ซูมกล้องและเปิด 3 ปุ่ม!
			# ==========================================
			print("เข้าสู่โหมดพร้อมรบ: เลือกตัวละคร ", u_name)
			selected_unit = result.collider
			select_unit_for_combat(result.collider) 
		else:
			# 🌟 ถ้าคลิกซ้ายโดนศัตรู หรือบล็อก 
			pass # ไม่ทำอะไรทั้งสิ้น! บังคับให้กดคลิกขวาเพื่อออกเอง
	else:
		# 🌟 ถ้าคลิกซ้ายโดนพื้นว่างๆ
		pass # ไม่ทำอะไรทั้งสิ้น! บังคับให้กดคลิกขวาเพื่อออกเอง




func finalize_placement():
	# ==========================================
	# 🌟 วางกลุ่มที่ก๊อปปี้ (Multi-Paste)
	# ==========================================
	# ==========================================
	# 🌟 วางกลุ่มที่ก๊อปปี้ (Multi-Paste)
	# ==========================================
	if dragging_multi_units.size() > 0:
		var all_safe = true
		for clone in dragging_multi_units:
			var safe_pos = is_position_safe(clone.global_position, clone)
			
			# ถอดรหัสหาความจริงว่ามันคือศัตรูไหม?
			var is_enemy = false
			if clone.has_meta("orig_unit"):
				var orig = clone.get_meta("orig_unit")
				if is_instance_valid(orig) and orig.get("unit_name") != null:
					is_enemy = is_enemy_unit(str(orig.get("unit_name")))
			elif clone.get("unit_name") != null:
				is_enemy = is_enemy_unit(str(clone.get("unit_name")))
				
			# 🌟 บังคับใช้กฎเขตแดนแบบเดียวกับการวางเดี่ยว!
			var within_bounds = true
			if not is_enemy:
				within_bounds = is_within_boundary(clone.global_position)
				
			# ถ้าวางทับคนอื่น หรือถ้าเป็นของฝั่งเราแล้วออกนอกเขต = ห้ามวางเด็ดขาด!
			if not safe_pos or not within_bounds:
				all_safe = false
				break
				
		if all_safe:
			# ==========================================
			# 🌟 [แก้บั๊ก] ดักจับการโคลนแบบ 100% ไม่มีหลุด!
			# ==========================================
			var is_cloning_group = false
			
			if dragging_multi_units.size() > 0:
				var first_u = dragging_multi_units[0]
				
				# 1. เสียเงินผู้เล่นโคลนใช่ไหม?
				if multi_drag_cost > 0.0:
					is_cloning_group = true 
				# 2. ก๊อปปี้มาจากในฉากใช่ไหม?
				elif first_u.has_meta("orig_unit"):
					is_cloning_group = true
				# 🌟 3. [เพิ่มตรงนี้!] ดึงมาจากพิมพ์เขียวใช่ไหม? (ต่อให้ศัตรูล้วนๆ Cost=0 ก็ต้องคิดบิล!)
				elif first_u.has_meta("from_blueprint"):
					is_cloning_group = true
			
			# เอาไปแยกบิลจ่ายเงิน
			if is_cloning_group:
				var final_player_cost = 0.0
				var final_player_hp = 0
				var final_enemy_cost = 0.0
				var final_enemy_hp = 0
				
				for clone in dragging_multi_units:
					var u_name = ""
					if clone.has_meta("orig_unit"):
						var orig = clone.get_meta("orig_unit")
						if is_instance_valid(orig) and orig.get("unit_name") != null:
							u_name = str(orig.get("unit_name")).to_lower()
					if u_name == "" and clone.get("unit_name") != null:
						u_name = str(clone.get("unit_name")).to_lower()
						
					# 🌟 [แก้ตรงนี้!] ดึงค่า Cost และ HP จากโมเดลจริงโดยตรง ไม่ต้องง้อสมุดจด
					var c_cost = clone.get("energy_cost") if clone.get("energy_cost") != null else 1.0
					var c_hp = clone.get("hp_gain_on_place") if clone.get("hp_gain_on_place") != null else 0
					
					var is_enemy_clone = false
					for data in army_list:
						if data["name"].to_lower() == u_name:
							is_enemy_clone = str(data["category"]).begins_with("enemy")
							break
							
					if is_enemy_clone:
						final_enemy_cost += c_cost
						final_enemy_hp += c_hp
					else:
						final_player_cost += c_cost
						final_player_hp += c_hp
							
				# 🌟 หักเงินและเพิ่มเลือดลงบัญชีให้ถูกฝั่ง
				current_energy -= final_player_cost
				total_hp += final_player_hp
				total_enemy_energy_used += final_enemy_cost
				total_enemy_hp += final_enemy_hp
				print("💰 จ่ายเงินค่าก๊อปปี้กลุ่ม: ", final_player_cost, " Energy")
			else:
				print("🚚 ย้ายกลุ่มสำเร็จ! ฟรี ไม่หัก Energy")
			# ==========================================
			
			# 🌟 1. ลงทะเบียนลงตารางให้หมดก่อน (แบบห้ามซ้ำ)
			for clone in dragging_multi_units:
				var key = get_tile_key(clone.global_position) + "_" + str(clone.get_instance_id())
				
				clone.tile_key = key
				occupied_tiles[key] = clone
				toggle_collision(clone, false)
				set_unit_preview_color(clone, Color(1, 1, 1, 1))
				
			# ==========================================
			# 🌟 2. [แก้บั๊กปืนพิมพ์เขียว] ฟื้นความจำ! ตามหาคู่หูให้ร่างโคลน
			# (รองรับทั้งการ Copy ปกติ และดึงจาก Blueprint)
			# ==========================================
			var unlinked_chars = []
			var unlinked_guns = []
			
			for clone in dragging_multi_units:
				if clone.has_meta("orig_unit"):
					# --- ระบบเดิม: มาจากการก๊อปปี้ (Copy) กล่องสี่เหลี่ยม ---
					var orig_unit = clone.get_meta("orig_unit")
					if is_instance_valid(orig_unit) and orig_unit.has_meta("linked_gun"):
						var orig_gun = orig_unit.get_meta("linked_gun")
						var clone_gun = null
						for g in dragging_multi_units:
							if g.has_meta("orig_unit") and g.get_meta("orig_unit") == orig_gun:
								clone_gun = g
								break
						if clone_gun:
							clone.set_meta("linked_gun", clone_gun)
							clone_gun.set_meta("linked_char", clone)
							var g_name = clone_gun.get("unit_name") if clone_gun.get("unit_name") != null else clone_gun.name
							clone.set_meta("saved_gun_name", str(g_name).to_lower())
							var l_pos = clone.to_local(clone_gun.global_position)
							clone.set_meta("saved_gun_local_pos", l_pos)
							var rot_diff = clone_gun.global_rotation.y - clone.global_rotation.y
							clone.set_meta("saved_gun_local_rot", wrapf(rot_diff, -PI, PI))
							clone.set_meta("needs_reload", false)
				else:
					# --- ระบบใหม่: มาจาก พิมพ์เขียว (Blueprint) ---
					var u_name = clone.get("unit_name").to_lower() if clone.get("unit_name") != null else clone.name.to_lower()
					var is_gun = false
					for data in army_list:
						if data["name"].to_lower() == u_name:
							if "gun" in str(data["category"]).to_lower() or "gun" in u_name:
								is_gun = true
							break
					
					# แยกปืนกับคนออกจากกันก่อน
					if is_gun:
						unlinked_guns.append(clone)
					elif not "block" in u_name:
						unlinked_chars.append(clone)

			# 🌟 จับคู่ปืนให้พิมพ์เขียวด้วย "ระยะทางใกล้สุด" (รัศมี 2 เมตร)
			for gun in unlinked_guns:
				var nearest_char = null
				var min_dist = 2.0 
				for char_node in unlinked_chars:
					if not char_node.has_meta("linked_gun"): # ต้องเป็นคนที่ยังมือว่าง
						var dist = gun.global_position.distance_to(char_node.global_position)
						if dist <= min_dist:
							min_dist = dist
							nearest_char = char_node
							
				if nearest_char:
					# ผูกสายสัมพันธ์ให้ตัวละครกับปืนรู้จักกันใหม่!
					nearest_char.set_meta("linked_gun", gun)
					gun.set_meta("linked_char", nearest_char)
					var g_name = gun.get("unit_name") if gun.get("unit_name") != null else gun.name
					nearest_char.set_meta("saved_gun_name", str(g_name).to_lower())
					
					var l_pos = nearest_char.to_local(gun.global_position)
					nearest_char.set_meta("saved_gun_local_pos", l_pos)
					var correct_rot = wrapf(gun.global_rotation.y - nearest_char.global_rotation.y, -PI, PI)
					nearest_char.set_meta("saved_gun_local_rot", correct_rot)
					nearest_char.set_meta("needs_reload", false)
			# ==========================================

			# 3. สั่ง Activate (ต้องทำหลังผูกปืนเสร็จแล้ว)
			for clone in dragging_multi_units:
				if clone.has_method("activate_unit"): clone.activate_unit(clone.tile_key)
				if clone.has_meta("orig_unit"): clone.remove_meta("orig_unit") # ลบชิปความจำทิ้งเพื่อความสะอาด
				
			print("✅ วางกลุ่มก๊อปปี้และผูกปืนสำเร็จ!")
		else:
			if error_sound_player: error_sound_player.play()
			for clone in dragging_multi_units:
				clone.queue_free()
			print("❌ วางกลุ่มไม่ได้! ติดสิ่งกีดขวาง ยกเลิกการก๊อปปี้")
			
		dragging_multi_units.clear()
		multi_drag_offsets.clear()
		update_ui()
		return
	# ==========================================
	
	if not dragging_unit: return
	
	var pos = dragging_unit.global_position
	
	# ==========================================
	# ==========================================
	# 1. เช็ครัศมีปืน (ตอนวางจริง)
	var is_within_gun_radius = true
	var linked_character = null 
	
	# 🌟 1. แก้ตรงนี้: เช็คว่าเป็นปืนประเภทไหน (ผู้เล่นหรือศัตรู)
	var category_str = str(unit_data.get("category"))
	var is_gun_type = "gun" in category_str or "gun" in unit_data.get("name", "").to_lower()
	
	if is_gun_type:
		is_within_gun_radius = false
		var max_radius = 2.0
		var min_dist = max_radius
		
		# 🌟 2. แก้ตรงนี้: เช็คว่าเป็นปืนศัตรูไหม
		var is_enemy_gun = category_str.begins_with("enemy")
		
		# 🌟 แก้บั๊กกุญแจทับซ้อน: สแกนจากฉากตรงๆ ป้องกันผีหลอก
		for tile_unit in get_children():
			if is_instance_valid(tile_unit) and tile_unit != dragging_unit:
				var t_name = ""
				if tile_unit.get("unit_name") != null:
					t_name = str(tile_unit.get("unit_name")).to_lower()
				else:
					t_name = tile_unit.name.to_lower()
				
				var is_valid_target = false
				if is_enemy_gun:
					# 🌟 ถ้าเป็นปืนศัตรู ต้องหาเจ้าของที่เป็นศัตรู
					is_valid_target = is_enemy_char(t_name)
				else:
					# 🌟 ถ้าเป็นปืนเรา ต้องหาเจ้าของฝั่งเรา
					is_valid_target = is_player_char(t_name)
					
				if is_valid_target:
					if tile_unit.has_meta("linked_gun"):
						var g = tile_unit.get_meta("linked_gun")
						if is_instance_valid(g) and not g.is_queued_for_deletion() and g != dragging_unit:
							continue
					var dist = pos.distance_to(tile_unit.global_position)
					if dist <= min_dist:
						min_dist = dist
						linked_character = tile_unit 
		if linked_character: is_within_gun_radius = true
	# ==========================================
	# ==========================================
	# ==========================================
	# ==========================================
	# 2. เช็คเงื่อนไขพื้นฐาน
	var is_hero_limit = false
	if not is_moving_existing_unit:
		var max_c = unit_data.get("max_count", -1)
		if max_c != -1 and get_unit_count_on_field(unit_data["name"]) >= max_c:
			is_hero_limit = true
			
	var char_safe = is_position_safe(pos, dragging_unit)
	# ==========================================
	# 🌟 [แก้ตรงนี้!] ปลดล็อกกรอบเขตแดนให้ศัตรูตอนวางจริง
	# ==========================================
	var in_bounds = true
	# 🛠️ แก้จากเดิมที่เทียบชื่อเป๊ะๆ เป็นการเช็คคำขึ้นต้น (Begins With)
	if not str(unit_data.get("category")).begins_with("enemy"):
		in_bounds = is_within_boundary(pos)
	# ==========================================
	var gun_safe = true
	if dragging_gun and is_instance_valid(dragging_gun):
		gun_safe = is_position_safe(dragging_gun.global_position, dragging_gun)

	# ==========================================
	# 🌟 [เพิ่มตรงนี้!] ตรวจคนเข้าเมือง: เช็คให้ชัวร์ว่าเงินพอจ่ายราคาจริง!
	# ==========================================
	var actual_cost = 0.0
	if not is_moving_existing_unit:
		actual_cost = dragging_unit.get("energy_cost") if dragging_unit.get("energy_cost") != null else 1.0
		
	var has_enough_energy = true
	if not str(unit_data.get("category")).begins_with("enemy") and not is_moving_existing_unit:
		has_enough_energy = current_energy >= actual_cost
	# ==========================================

	# 🌟 เติมคำว่า 'has_enough_energy' เข้าไปในเงื่อนไขด้วย!
	var can_place = char_safe and in_bounds and not is_hero_limit and gun_safe and is_within_gun_radius and has_enough_energy

	if can_place:
		# --- วางสำเร็จ ---
		if not is_moving_existing_unit:
			var cost = dragging_unit.get("energy_cost") if dragging_unit.get("energy_cost") != null else 1.0
			var hp_gain = dragging_unit.get("hp_gain_on_place") if dragging_unit.get("hp_gain_on_place") != null else 0
			
			# 🌟 เอาคำว่า 'var' ออก เพราะข้างบน (ในฟังก์ชันเดียวกัน) มีการประกาศไปแล้ว
			category_str = str(unit_data.get("category")) 
			
			if category_str.begins_with("enemy"):
				total_enemy_energy_used += cost
				total_enemy_hp += hp_gain
			else:
				current_energy -= cost #หักเงินผู้เล่น
				total_hp += hp_gain # เพิ่มเลือดกองทัพเรา
		
		# ใช้ฟังก์ชัน get_tile_key ตัวเดียวให้เหมือนกันทั้งระบบ!
		# 🌟 [แก้บั๊กผีล่องหน] บังคับให้ Key ห้ามซ้ำกันเด็ดขาด!
		var tile_key = get_tile_key(pos) + "_" + str(dragging_unit.get_instance_id())
		
		dragging_unit.tile_key = tile_key # บันทึกรหัสใหม่ที่ไม่ซ้ำใคร
		occupied_tiles[tile_key] = dragging_unit # เซฟลงสมุดจด
		
		if dragging_gun and is_instance_valid(dragging_gun):
			var gun_key = get_tile_key(dragging_gun.global_position)
			dragging_gun.tile_key = gun_key
			occupied_tiles[gun_key] = dragging_gun
			toggle_collision(dragging_gun, false)
			set_unit_preview_color(dragging_gun, Color(1,1,1,1))
			dragging_gun = null
			
		if is_gun_type and linked_character:
			if dragging_unit.has_meta("linked_char"):
				var old_char = dragging_unit.get_meta("linked_char")
				if is_instance_valid(old_char): old_char.set_meta("linked_gun", null)
			linked_character.set_meta("linked_gun", dragging_unit)
			dragging_unit.set_meta("linked_char", linked_character)
			# 🌟 ฝังความจำตอนลากวางปืนใหม่!
			# 🌟 [แก้ 3 บรรทัดนี้ให้เป๊ะ!]
			var g_name = dragging_unit.get("unit_name") if dragging_unit.get("unit_name") != null else dragging_unit.name
			linked_character.set_meta("saved_gun_name", str(g_name).to_lower())
			
			# จำตำแหน่งสัมพัทธ์ (Local) ว่าปืนอยู่ห่างจากตัวแค่ไหน
			var l_pos = linked_character.to_local(dragging_unit.global_position)
			linked_character.set_meta("saved_gun_local_pos", l_pos)
			
			# จำความต่างองศา (หันหน้าไปทางเดียวกันไหม)
			var rot_diff = dragging_unit.global_rotation.y - linked_character.global_rotation.y
			linked_character.set_meta("saved_gun_local_rot", wrapf(rot_diff, -PI, PI))
			
			linked_character.set_meta("needs_reload", false)
			
		toggle_collision(dragging_unit, false)
		if dragging_unit.has_method("activate_unit"): dragging_unit.activate_unit(tile_key)
		set_unit_preview_color(dragging_unit, Color(1,1,1,1)) # ล้างสีผี
		
		selected_unit = dragging_unit
		action_menu.show()
		dragging_unit = null
		is_moving_existing_unit = false
	else:
		# --- วางไม่ได้ (สีแดง) ---
		flash_red_effect(dragging_unit)
		if dragging_gun: 
			flash_red_effect(dragging_gun)
			
		if error_sound_player:
			error_sound_player.play()
		
		if is_moving_existing_unit:
			# 1. คืนเงินตัวละคร
			var cost = dragging_unit.get("energy_cost") if dragging_unit.get("energy_cost") != null else 1.0
			var hp_gain = dragging_unit.get("hp_gain_on_place") if dragging_unit.get("hp_gain_on_place") != null else 0
			
			# 🌟 แก้ตรงนี้! ใช้ begins_with เพื่อเช็คว่าเป็นศัตรูหมวดไหนก็ได้ (character/gun/block)
			var is_enemy = str(unit_data.get("category")).begins_with("enemy")
			
			if is_enemy:
				total_enemy_energy_used -= cost
				total_enemy_hp -= hp_gain
			else:
				current_energy += cost
				total_hp -= hp_gain
			# ==========================================
			# 🌟 2. [แก้ตรงนี้!] คืนเงินปืน (เช็คแยกฝั่งให้ชัวร์ก่อนโดนลบทิ้ง)
			# ==========================================
			if dragging_gun and is_instance_valid(dragging_gun):
				var gun_cost = dragging_gun.get("energy_cost") if dragging_gun.get("energy_cost") != null else 2.0
				var gun_hp = dragging_gun.get("hp_gain_on_place") if dragging_gun.get("hp_gain_on_place") != null else 0
				
				# เช็คว่าปืนที่ติดมาเนี่ย เป็นปืนศัตรูหรือปืนเรา?
				var is_gun_enemy = false
				var g_name = ""
				if dragging_gun.get("unit_name") != null:
					g_name = dragging_gun.get("unit_name").to_lower()
					for data in army_list:
						if data["name"].to_lower() == g_name:
							# 🌟 แก้ตรงนี้! ใช้ begins_with เพื่อรองรับหมวด enemy_gun ของระบบใหม่
							is_gun_enemy = str(data["category"]).begins_with("enemy")
							break
				
				if is_gun_enemy:
					total_enemy_energy_used -= gun_cost
					total_enemy_hp -= gun_hp
					print("คืนบิลปืนศัตรูที่ย้ายพลาด")
				else:
					current_energy += gun_cost
					total_hp -= gun_hp
					print("คืนเงินปืนฝั่งเราที่ย้ายพลาด")
			# ==========================================
				
		# 3. ลบปืนและล้างค่าทีหลังสุด
		if dragging_gun and is_instance_valid(dragging_gun):
			dragging_gun.queue_free()
		dragging_gun = null 
				
		dragging_unit.queue_free()
		dragging_unit = null
		is_moving_existing_unit = false

	update_ui()






func start_re_drag():
	if selected_unit:
		is_moving_existing_unit = true # บอกระบบว่าเป็นการย้ายตัวเดิม
		dragging_unit = selected_unit
		# ==========================================
		# --- [เพิ่มใหม่] คืนค่า unit_data ให้ตรงกับตัวที่กำลังลาก (แก้บั๊กย้ายแล้วแดง) ---
		var u_name = dragging_unit.get("unit_name")
		for data in army_list:
			if data["name"] == u_name:
				unit_data = data
				break
		# ==========================================
		occupied_tiles.erase(dragging_unit.tile_key)
		action_menu.hide()
		toggle_collision(dragging_unit, true)
		is_pressing = false 
		# ==========================================
		# --- [เพิ่มใหม่] เช็คและหยิบปืนที่ติดอยู่ขึ้นมาด้วย ---
		if dragging_unit.has_meta("linked_gun"):
			var attached_gun = dragging_unit.get_meta("linked_gun")
			if is_instance_valid(attached_gun):
				dragging_gun = attached_gun
				# คำนวณระยะห่างเพื่อรักษาตำแหน่งเดิมไว้เป๊ะๆ
				gun_offset = attached_gun.global_position - dragging_unit.global_position
				
				# เอาปืนออกจากสมุดจดและปิดการชนชั่วคราว
				if occupied_tiles.has(attached_gun.tile_key):
					occupied_tiles.erase(attached_gun.tile_key)
				toggle_collision(dragging_gun, true)
		# ==========================================
		print("กำลังย้ายตัวละคร (ไม่เสีย Energy)")






# ฟังก์ชันยิง Raycast แบบรวมศูนย์
func get_raycast_result():
	var m_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	if not camera: return null
	var query = PhysicsRayQueryParameters3D.create(camera.project_ray_origin(m_pos), camera.project_ray_origin(m_pos) + camera.project_ray_normal(m_pos) * 1000)
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(query)







func _on_btn_rotate_pressed():
	if dragging_unit and is_instance_valid(dragging_unit):
		# 🌟 จำท่าก่อนหมุน
		var old_rot = dragging_unit.rotation
		
		# หมุนรอบแกน Y ของโลก 90 องศา (วาร์ปไปก่อนเพื่อเช็คคณิตศาสตร์)
		dragging_unit.global_rotate(Vector3.UP, deg_to_rad(90))
		# 🌟 บังคับจัดกระดูกล็อกละ 90 องศาเป๊ะๆ (แก้บั๊กกดรัว)
		dragging_unit.rotation_degrees = dragging_unit.rotation_degrees.snapped(Vector3(90, 90, 90))
		dragging_unit.force_update_transform() 
		
		# อัปเดตสีพรีวิวตามตำแหน่งใหม่
		if is_position_safe(dragging_unit.global_position, dragging_unit):
			set_unit_preview_color(dragging_unit, Color(0.0, 1.0, 1.0, 0.502))
		else:
			set_unit_preview_color(dragging_unit, Color(1, 0, 0, 0.5))
			
		# 🌟 เก็บเป้าหมาย แล้ววาร์ปกลับมาทำแอนิเมชันให้เนียนตา
		var target_rot = dragging_unit.rotation
		dragging_unit.rotation = old_rot
		var tween = create_tween()
		tween.tween_property(dragging_unit, "rotation", target_rot, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	elif selected_unit and is_instance_valid(selected_unit):
		# จำท่าทางเดิมไว้ทั้งหมด (เผื่อหมุนแล้วชน จะได้กลับมาท่านี้)
		var old_transform = selected_unit.global_transform
		
		# ทดสอบหมุน
		selected_unit.global_rotate(Vector3.UP, deg_to_rad(90))
		# 🌟 บังคับจัดกระดูกล็อกละ 90 องศาเป๊ะๆ
		selected_unit.rotation_degrees = selected_unit.rotation_degrees.snapped(Vector3(90, 90, 90))
		selected_unit.force_update_transform() 
		
		# เช็คว่าชนไหม
		if is_position_safe(selected_unit.global_position, selected_unit):
			# 🌟 ถ้าสำเร็จ: เก็บเป้าหมาย วาร์ปกลับ แล้วทำแอนิเมชันหมุน!
			var target_rot = selected_unit.rotation
			selected_unit.global_transform = old_transform
			
			var tween = create_tween()
			tween.tween_property(selected_unit, "rotation", target_rot, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			print("หมุนตัวละครสำเร็จ")
		else:
			# ถ้าหมุนแล้วชนทับเพื่อน ให้ดึงท่าทางเดิมกลับมาแบบทันที ไม่ต้องมีแอนิเมชัน
			selected_unit.global_transform = old_transform
			flash_red_effect(selected_unit)
			print("หมุนไม่ได้! ติดตัวละครข้างๆ")
	else:
		print("ไม่มีตัวละครให้หมุน!")





func _on_btn_rotate_horizontal_pressed():
	var target_unit = null
	if dragging_unit and is_instance_valid(dragging_unit):
		target_unit = dragging_unit
	elif selected_unit and is_instance_valid(selected_unit):
		target_unit = selected_unit
	
	# 🌟 1. ดึงชื่อมาเช็คว่ามีคำว่า block ไหม
	var u_name = ""
	if target_unit and target_unit.get("unit_name") != null:
		u_name = target_unit.get("unit_name").to_lower()
	
	# 🌟 2. เปลี่ยนเงื่อนไขตรงนี้
	if target_unit and "block" in u_name:
		# 1. จำสถานะเดิมไว้เผื่อหมุนแล้วชน
		var old_transform = target_unit.global_transform
		
		# 2. หมุนรอบแกน "ขวา" ของโลก (แกน X) เพื่อให้บล็อกล้ม/ตั้ง
		target_unit.global_rotate(Vector3.RIGHT, deg_to_rad(90))
		
		# 🌟 บังคับจัดกระดูกล็อกละ 90 องศา ทุกแกน (X, Y, Z) รวดเดียวจบ!
		target_unit.rotation_degrees = target_unit.rotation_degrees.snapped(Vector3(90, 90, 90))
		target_unit.force_update_transform()
		
		# 3. จัดการความสูง (Y) ให้เหมาะสมตามท่านอน/ตั้ง
		var current_aabb = get_unit_global_aabb(target_unit.global_position, target_unit.global_transform.basis, target_unit)
		target_unit.global_position.y = current_aabb.size.y / 2.0
			
		# 4. ระบบ Auto-Stacking (ปีนขึ้นถ้าชนบล็อกล่าง)
		var max_stack_levels = 40
		var step_count = 0
		while not is_position_safe(target_unit.global_position, target_unit) and step_count < max_stack_levels:
			target_unit.global_position.y += 0.25
			step_count += 1
		
		target_unit.force_update_transform()

		# 5. ตรวจสอบผลลัพธ์
		if is_position_safe(target_unit.global_position, target_unit):
			# 🌟 ถ้าโอเค: เก็บเป้าหมายทั้ง Rotation และ Position แล้ววาร์ปกลับ
			var target_rot = target_unit.rotation
			var target_pos = target_unit.global_position
			target_unit.global_transform = old_transform
			
			# 🌟 สั่ง Tween ให้หมุน + ปีนขึ้นบล็อก ไปพร้อมๆ กัน!
			var tween = create_tween().set_parallel(true)
			tween.tween_property(target_unit, "rotation", target_rot, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(target_unit, "global_position", target_pos, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
			if target_unit == dragging_unit:
				set_unit_preview_color(target_unit, Color(0.0, 1.0, 1.0, 0.502))
			print("หมุนแนวนอนสำเร็จ")
		else:
			# ถ้าหมุนแล้วฟาดโดนตัวอื่นจนหาที่ลงไม่ได้ ให้ย้อนกลับ (ดึงของเดิมพี่กลับมา 100%)
			target_unit.global_transform = old_transform
			if target_unit == dragging_unit:
				set_unit_preview_color(target_unit, Color(1, 0, 0, 0.5))
			else:
				flash_red_effect(target_unit)
			print("หมุนไม่ได้! ติดสิ่งกีดขวาง")






func flash_red_effect(unit: Node3D):
	if has_node("ErrorSoundPlayer"):
		$ErrorSoundPlayer.play()
		
	# --- 🛠️ [แก้ตรงนี้] ทะลวงหา MeshInstance3D "ทุกตัว" ที่ซ่อนอยู่ใน unit ---
	var all_meshes = unit.find_children("*", "MeshInstance3D")
	
	# วนลูปสั่งกระพริบให้ครบทุกชิ้นที่หาเจอ
	for mesh_node in all_meshes:
		var mat = mesh_node.get_active_material(0)
		if mat is StandardMaterial3D:
			var tween = create_tween()
			# กระพริบแดง 2 รอบเร็วๆ
			tween.tween_property(mat, "albedo_color", Color(1, 0, 0), 0.1)
			tween.tween_property(mat, "albedo_color", Color(1, 1, 1), 0.1)
			tween.tween_property(mat, "albedo_color", Color(1, 0, 0), 0.1)
			tween.tween_property(mat, "albedo_color", Color(1, 1, 1), 0.1)







func _on_btn_delete_pressed():
	if selected_unit and is_instance_valid(selected_unit):
		
		# ==========================================
		# 🌟 0. สร้างฟังก์ชันตัวช่วย (Lambda) เอาไว้เช็คว่าไอ้เจ้านี่คือ "ศัตรู" หรือเปล่า
		# ==========================================
		var check_is_enemy = func(unit_node: Node3D) -> bool:
			var u_name = ""
			if unit_node.get("unit_name") != null:
				u_name = unit_node.get("unit_name").to_lower()
				for data in army_list:
					if data["name"].to_lower() == u_name:
						# 🌟 เปลี่ยนมาใช้ begins_with ตรงนี้ครับ!
						return str(data["category"]).begins_with("enemy")
			return false
			
		var is_selected_enemy = check_is_enemy.call(selected_unit)
		
		# ==========================================
		# --- 1. ถ้าตัวที่กำลังจะลบคือ "ตัวละคร" -> ให้เช็คว่ามีปืนติดมาด้วยไหม?
		# ==========================================
		if selected_unit.has_meta("linked_gun"):
			var attached_gun = selected_unit.get_meta("linked_gun")
			if is_instance_valid(attached_gun):
				# ดึงค่าของปืน
				var is_gun_enemy = check_is_enemy.call(attached_gun)
				var gun_cost = attached_gun.get("energy_cost") if attached_gun.get("energy_cost") != null else 1.0
				var gun_hp = attached_gun.get("hp_gain_on_place") if attached_gun.get("hp_gain_on_place") != null else 0
				
				# 🌟 แยกบิลคืนเงินปืน: ของศัตรู vs ของเรา
				if is_gun_enemy:
					total_enemy_energy_used -= gun_cost
					total_enemy_hp -= gun_hp
				else:
					current_energy += gun_cost
					total_hp -= gun_hp
				
				# ลบปืนออกจากสมุดจดและลบออกจากฉาก
				if occupied_tiles.has(attached_gun.tile_key):
					occupied_tiles.erase(attached_gun.tile_key)
				attached_gun.queue_free()
				print("ลบปืนที่ติดอยู่กับตัวละครออกด้วย!")
				
		# ==========================================
		# --- 2. ถ้าตัวที่กำลังจะลบคือ "ปืน" เฉยๆ -> ต้องไปบอกตัวละครว่าตอนนี้มือว่างแล้ว
		# ==========================================
		if selected_unit.has_meta("linked_char"):
			var owner_char = selected_unit.get_meta("linked_char")
			if is_instance_valid(owner_char):
				owner_char.set_meta("linked_gun", null) # เคลียร์ป้ายชื่อทิ้ง
				print("ลบปืนออกแล้ว ตัวละครสามารถติดตั้งปืนใหม่ได้!")
		
		# ==========================================
		# --- 3. จัดการเรื่องเงินและเลือดของ "ตัวหลัก" ที่โดนลบ
		# ==========================================
		var unit_cost = selected_unit.get("energy_cost") if selected_unit.get("energy_cost") != null else 1.0
		var unit_hp = selected_unit.get("hp_gain_on_place") if selected_unit.get("hp_gain_on_place") != null else 0
		
		# 🌟 แยกบิลตัวหลัก: ของศัตรู vs ของเรา
		if is_selected_enemy:
			total_enemy_energy_used -= unit_cost
			total_enemy_hp -= unit_hp
			print("ลบศัตรู/บล็อกศัตรู: หักยอดบิล Dev และลดเลือดศัตรู")
		else:
			current_energy += unit_cost
			total_hp -= unit_hp
			print("ลบยูนิตฝั่งเรา: คืน Energy และหัก HP")
		
		# --- 4. ลบข้อมูลใน Grid และลบตัวละครทิ้ง ---
		if occupied_tiles.has(selected_unit.tile_key):
			occupied_tiles.erase(selected_unit.tile_key)
		
		selected_unit.queue_free()
		selected_unit = null
		action_menu.hide()
		
		# --- 5. อัปเดต UI ทันที ---
		update_ui()
		print("ลบตัวละครเรียบร้อย: คืน Energy และหัก HP")






func _on_btn_duplicate_pressed():
	if selected_unit and is_instance_valid(selected_unit):
		var u_name = ""
		if selected_unit.get("unit_name") != null:
			u_name = selected_unit.get("unit_name").to_lower()
		
		# 🌟 เช็คขอแค่มีคำว่า block
		if "block" in u_name:
			# 1. 🌟 หาข้อมูลของบล็อกจาก army_list โดยจับคู่ชื่อให้ "ตรงกันเป๊ะ"
			var target_data = null
			for data in army_list:
				if data["name"].to_lower() == u_name: # <--- บล็อกไหนก็จับคู่ตัวนั้น!
					target_data = data
					break
					
			if target_data == null: return
			
			# 2. เช็คว่ามี Energy พอไหม
			if current_energy >= target_data["cost"]:
				action_menu.hide() # ซ่อนเมนู
				
				# 🌟 [เพิ่มระบบกันผีหลอก!]
				if dragging_unit and is_instance_valid(dragging_unit):
					dragging_unit.queue_free()
					
				# 3. เตรียมข้อมูลให้ระบบจำได้ว่าเรากำลังลากบล็อกอยู่
				unit_data = target_data 
				
				# 4. สร้างบล็อกตัวใหม่
				dragging_unit = target_data["scene"].instantiate()
				add_child(dragging_unit)
				
				# 5. ก๊อปปี้ "ท่าทางการหมุน" จากตัวต้นฉบับมาใส่ตัวใหม่เป๊ะๆ!
				dragging_unit.global_transform.basis = selected_unit.global_transform.basis
				
				# 6. ปิดการชนของตัวใหม่ชั่วคราวจนกว่าจะวางเสร็จ
				toggle_collision(dragging_unit, true)
				
				selected_unit = null
				is_moving_existing_unit = false # บอกระบบว่านี่คือ "ตัวใหม่นะ" (ต้องเก็บเงินตอนวาง)
				print("โคลนบล็อกสำเร็จ! ลากไปวางได้เลย")
			else:
				# --- เล่นเสียงเตือนตอนเงินไม่พอ ---
				if error_sound_player:
					error_sound_player.play()
				print("Energy ไม่พอสำหรับก๊อปปี้บล็อก!")







func _on_btn_combat_shoot_pressed():
	# 🛡️ [ยามเฝ้าประตู] ถ้ากำลังเล็ง หรือ กำลังยิง ห้ามกดซ้ำเด็ดขาด!
	if not selected_unit or not is_instance_valid(selected_unit): return
	
	if is_firing: return
	if is_combat_aiming and combat_action_mode != "snap_ready": return
	
	# 🌟 กำหนดค่าตัวละครให้พร้อมก่อน ค่อยสั่งสไลด์!
	active_combat_unit = selected_unit
	is_combat_aiming = true
	combat_action_mode = "shoot"
	combat_menu.hide()
	
	# ==========================================
	# 🌟 [Phase 2] ระบบสไลด์ยื่นหน้า (Snap Out) + กันล้ม + ล็อกปืน!
	# ==========================================
	if active_combat_unit.has_meta("snap_pos"):
		active_combat_unit.set_meta("base_pos", active_combat_unit.global_position)
		var snap_pos = active_combat_unit.get_meta("snap_pos")
		
		# แช่แข็งฟิสิกส์
		if active_combat_unit is RigidBody3D: active_combat_unit.freeze = true
		
		var slide_tween = create_tween()
		slide_tween.tween_property(active_combat_unit, "global_position", snap_pos, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# 🌟 กาวตราช้าง: ล็อกปืนให้ติดมือตอนสไลด์ออกแบบเฟรมต่อเฟรม!
		if active_combat_unit.has_meta("linked_gun") and active_combat_unit.has_meta("gun_local_offset"):
			var attached_gun = active_combat_unit.get_meta("linked_gun")
			var l_pos = active_combat_unit.get_meta("gun_local_offset")
			if is_instance_valid(attached_gun):
				slide_tween.parallel().tween_method(func(_v):
					if is_instance_valid(active_combat_unit) and is_instance_valid(attached_gun):
						attached_gun.global_position = active_combat_unit.to_global(l_pos)
				, 0.0, 1.0, 0.25)
		
		slide_tween.tween_callback(func():
			if is_instance_valid(active_combat_unit) and active_combat_unit is RigidBody3D:
				active_combat_unit.freeze = false
		)
		
		var snap_vis = get_node_or_null("SnapVisualizer")
		if is_instance_valid(snap_vis): snap_vis.hide()
		clear_snap_ghost(active_combat_unit)
	# ==========================================
	
	# ตรวจพบประเภทปืน
	if active_combat_unit.has_meta("linked_gun"):
		var gun = active_combat_unit.get_meta("linked_gun")
		if is_instance_valid(gun):
			var g_name = gun.get("unit_name") if gun.get("unit_name") != null else gun.name
			print("🔍 ระบบตรวจพบปืนประเภท: ", str(g_name).split("_id_")[0].to_lower())
	
	if power_ui: power_ui.start_charging(100)
	
	initial_aim_rotation = active_combat_unit.rotation.y
	current_aim_offset = 0
	
	# เก็บค่าปืน
	if active_combat_unit.has_meta("linked_gun"):
		var attached_gun = active_combat_unit.get_meta("linked_gun")
		if is_instance_valid(attached_gun):
			initial_gun_rotation = attached_gun.global_rotation.y
			var local_offset = active_combat_unit.to_local(attached_gun.global_position)
			active_combat_unit.set_meta("gun_local_offset", local_offset)
			
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_rig = cam.get_parent().get_parent().get_parent() 
		
		if cam_rig.has_method("set_ots_mode"):
			var target_for_camera = active_combat_unit
			if active_combat_unit.has_meta("linked_gun"):
				var attached_gun = active_combat_unit.get_meta("linked_gun")
				if is_instance_valid(attached_gun):
					var dummy = Node3D.new()
					active_combat_unit.add_child(dummy)
					dummy.global_position = attached_gun.global_position
					dummy.global_rotation = active_combat_unit.global_rotation
					target_for_camera = dummy
					active_combat_unit.set_meta("cam_dummy", dummy)
					
			cam_rig.set_ots_mode(target_for_camera)
			
			if "pitch_target" in cam_rig: cam_rig.pitch_target = 25.0
			if "zoom_target" in cam_rig: cam_rig.zoom_target = 4.5 
				
	print("เล็งยิง! สั่ง CameraRig ปรับเป้าหมายไปที่ 25 องศา")










func cancel_combat_aim(just_shot: bool = false, fired_gun_name: String = ""):
	if not is_combat_aiming: return
	
	is_firing = false 
	var shooter_unit = active_combat_unit
	
	# ซ่อนตารางสีฟ้า/เหลือง
	if combat_action_mode == "walk" and has_node("GridVisualizer"):
		$GridVisualizer.hide()
	if combat_action_mode == "snap_setup" and has_node("SnapVisualizer"):
		$SnapVisualizer.hide()
	
	if not just_shot and is_instance_valid(shooter_unit) and shooter_unit.has_meta("linked_gun"):
		var gun = shooter_unit.get_meta("linked_gun")
		if is_instance_valid(gun):
			var g_name = gun.get("unit_name") if gun.get("unit_name") != null else gun.name
			if "semi_auto" in g_name.to_lower():
				if gun.get("bullets_left") != null and "max_bullets" in gun and gun.bullets_left < gun.max_bullets and gun.bullets_left > 0:
					print("❌ ยกเลิกไม่ได้! ต้องยิงให้หมดแม็ก")
					if has_node("ErrorSoundPlayer"): $ErrorSoundPlayer.play()
					if has_node("HUD/ShootingPowerUI"):
						var p_ui = $HUD/ShootingPowerUI
						p_ui.show()
						p_ui.is_dragging = false
						if p_ui.has_method("start_charging"):
							p_ui.start_charging(100)
					return
					
	is_combat_aiming = false
	if has_node("TrajectoryLine"):
		$TrajectoryLine.hide()
		var mesh = $TrajectoryLine.mesh as ImmediateMesh
		if mesh: mesh.clear_surfaces() 
	
	if not just_shot:
		if has_node("HUD/ShootingPowerUI"):
			var power_ui = $HUD/ShootingPowerUI
			power_ui.hide()
			power_ui.current_power = 0.0
			power_ui.is_dragging = false
			
		if combat_action_mode == "walk":
			if has_node("GridVisualizer"): $GridVisualizer.hide()
			toggle_invisible_walls(false) 
			
		# ==========================================
		if is_instance_valid(active_combat_unit):
			active_combat_unit.rotation.y = initial_aim_rotation
			active_combat_unit.force_update_transform() 
			
			if active_combat_unit.has_meta("linked_gun"):
				var attached_gun = active_combat_unit.get_meta("linked_gun")
				if is_instance_valid(attached_gun):
					attached_gun.global_rotation.y = initial_gun_rotation
					if active_combat_unit.has_meta("gun_local_offset"):
						var local_pos = active_combat_unit.get_meta("gun_local_offset")
						attached_gun.global_position = active_combat_unit.to_global(local_pos)
					attached_gun.force_update_transform() 
					for child in attached_gun.get_children():
						if child is RigidBody3D: child.force_update_transform()
		# ==========================================
					
	var cam = get_viewport().get_camera_3d()
	var cam_rig = null
	if cam: cam_rig = cam.get_parent().get_parent().get_parent()
	
	if just_shot:
		# ==========================================
		# 💥 กรณียิงออกไปแล้ว (จบการโจมตี)
		# ==========================================
		if combat_menu: combat_menu.hide()
		selected_unit = null
		
		if is_instance_valid(active_combat_unit):
			if fired_gun_name != "walk":
				# หน่วงเวลา 1.5 วินาที แล้วค่อยหันกลับ
				get_tree().create_timer(1.5).timeout.connect(func():
					if is_instance_valid(shooter_unit):
						shooter_unit.rotation.y = initial_aim_rotation
						shooter_unit.force_update_transform() 
						
						# ==========================================
						# 🌟 [Phase 2] ระบบสไลด์หดกลับ (Snap In) ตอนยิงเสร็จ! + ล็อกปืน!
						# ==========================================
						if shooter_unit.has_meta("base_pos"):
							var base_pos = shooter_unit.get_meta("base_pos")
							
							if shooter_unit is RigidBody3D: shooter_unit.freeze = true
							var slide_tween = create_tween()
							slide_tween.tween_property(shooter_unit, "global_position", base_pos, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
							
							# 🌟 กาวตราช้าง: ล็อกปืนให้ติดมือตอนสไลด์กลับ!
							if shooter_unit.has_meta("linked_gun") and shooter_unit.has_meta("gun_local_offset"):
								var attached_gun = shooter_unit.get_meta("linked_gun")
								var l_pos = shooter_unit.get_meta("gun_local_offset")
								if is_instance_valid(attached_gun):
									slide_tween.parallel().tween_method(func(_v):
										if is_instance_valid(shooter_unit) and is_instance_valid(attached_gun):
											attached_gun.global_position = shooter_unit.to_global(l_pos)
									, 0.0, 1.0, 0.20)
							
							# 🌟 [แก้บั๊กตรงนี้!] ย้ายการหมุนปืนกลับ มาไว้ตอนที่สไลด์เสร็จแล้วเท่านั้น!
							slide_tween.tween_callback(func():
								if is_instance_valid(shooter_unit):
									if shooter_unit is RigidBody3D:
										shooter_unit.freeze = false
									
									if shooter_unit.has_meta("linked_gun"):
										var gun = shooter_unit.get_meta("linked_gun")
										if is_instance_valid(gun):
											gun.global_rotation.y = initial_gun_rotation
											if shooter_unit.has_meta("gun_local_offset"):
												gun.global_position = shooter_unit.to_global(shooter_unit.get_meta("gun_local_offset"))
											gun.force_update_transform()
							)
							
							if shooter_unit.has_meta("snap_ghost"):
								var ghost = shooter_unit.get_meta("snap_ghost")
								if is_instance_valid(ghost): ghost.show()
						# ==========================================
				)
			
			if active_combat_unit.has_meta("cam_dummy"):
				var dummy = active_combat_unit.get_meta("cam_dummy")
				if is_instance_valid(dummy): dummy.queue_free()
				active_combat_unit.remove_meta("cam_dummy")
				
		active_combat_unit = null
		current_aim_offset = 0.0
		current_pitch_offset = 0.0
		
		if cam_rig:
			if cam_rig.has_method("set_ots_mode"): cam_rig.set_ots_mode(null)
			if "pitch_target" in cam_rig: cam_rig.pitch_target = original_cam_tilt
			
			var pullback_dist = 4.0 
			var g_name = fired_gun_name.to_lower()
			if "sniper" in g_name: pullback_dist = 15.0 
			elif "machine_gun" in g_name: pullback_dist = 6.0 
			elif "shotgun" in g_name: pullback_dist = 9.0 
			elif "spear" in g_name: pullback_dist = 2.0 
			elif "semi_auto" in g_name: pullback_dist = 3.0 
			
			if "zoom_target" in cam_rig:
				var max_z = cam_rig.max_zoom if "max_zoom" in cam_rig else 7.0
				cam_rig.zoom_target = min(cam_rig.zoom_target + pullback_dist, max_z) 
				
			if "move_target" in cam_rig:
				var height_compensate = pullback_dist * 0.42 
				cam_rig.move_target.y -= height_compensate
			
		post_shoot_turn_check(shooter_unit)
		
	else:
		# ==========================================
		# 🔄 กรณีกดยกเลิกการเล็ง (คลิกขวา)
		# ==========================================
		current_aim_offset = 0.0
		current_pitch_offset = 0.0
		
		var snap_vis = get_node_or_null("SnapVisualizer")
		if is_instance_valid(snap_vis): snap_vis.hide()
		
		if is_instance_valid(active_combat_unit):
			if active_combat_unit.has_meta("base_pos"):
				var base_pos = active_combat_unit.get_meta("base_pos")
				
				if active_combat_unit is RigidBody3D: active_combat_unit.freeze = true
				var slide_tween = create_tween()
				slide_tween.tween_property(active_combat_unit, "global_position", base_pos, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				
				if active_combat_unit.has_meta("linked_gun") and active_combat_unit.has_meta("gun_local_offset"):
					var attached_gun = active_combat_unit.get_meta("linked_gun")
					var l_pos = active_combat_unit.get_meta("gun_local_offset")
					if is_instance_valid(attached_gun):
						slide_tween.parallel().tween_method(func(_v):
							if is_instance_valid(active_combat_unit) and is_instance_valid(attached_gun):
								attached_gun.global_position = active_combat_unit.to_global(l_pos)
						, 0.0, 1.0, 0.25)
				
				slide_tween.tween_callback(func():
					if is_instance_valid(active_combat_unit) and active_combat_unit is RigidBody3D:
						active_combat_unit.freeze = false
				)
				
				if active_combat_unit.has_meta("snap_ghost"):
					var ghost = active_combat_unit.get_meta("snap_ghost")
					if is_instance_valid(ghost): ghost.show()
			
			clear_snap_ghost(active_combat_unit)
			
		if cam_rig and "pitch_target" in cam_rig:
			cam_rig.pitch_target = original_cam_tilt

	# ==========================================
	# 🌟 เรียกปุ่มทั้งหมดกลับมาให้ครบ 3 ปุ่ม! 
	# ==========================================
	if combat_menu: 
		var btn_w = combat_menu.get_node_or_null("BtnCombatWalk")
		var btn_s = combat_menu.get_node_or_null("BtnCombatShoot")
		var btn_sn = combat_menu.get_node_or_null("BtnCombatSnap")
		if btn_w: btn_w.show()
		if btn_s: btn_s.show()
		if btn_sn: btn_sn.show()
		
		# ถ้าเป็นการกดยกเลิกเฉยๆ ให้โชว์เมนูทันที
		if not just_shot:
			combat_menu.show()
	# ==========================================





# --- Helper Functions ---
func get_ground_position():
	var camera = get_viewport().get_camera_3d()
	var m_pos = get_viewport().get_mouse_position()
	var query = PhysicsRayQueryParameters3D.create(camera.project_ray_origin(m_pos), camera.project_ray_origin(m_pos) + camera.project_ray_normal(m_pos) * 1000)
	query.collision_mask = 1
	var res = get_world_3d().direct_space_state.intersect_ray(query)
	return res.position if res else Vector3.ZERO

func get_tile_key(pos: Vector3) -> String:
	# --- [แก้ไข] เพิ่ม pos.y กลับเข้ามา เพื่อให้ระบบแยกแยะการ "ซ้อนหัวกัน" เป็นชั้นๆ ได้ครับ ---
	return "%.2f_%.2f_%.2f" % [snapped(pos.x, snap_step), snapped(pos.y, snap_step), snapped(pos.z, snap_step)]

func toggle_collision(unit, is_disabled):
	for child in unit.find_children("*", "CollisionShape3D"): child.disabled = is_disabled

func set_unit_preview_color(unit: Node3D, color: Color):
	# 🌟 [ไม้ตายแก้แล็ก 2] ระบบ Cache สี เลิกค้นหาโมเดล 60 ครั้งต่อวินาที!
	var meshes = []
	if unit.has_meta("cached_meshes"):
		meshes = unit.get_meta("cached_meshes")
	else:
		meshes = unit.find_children("*", "MeshInstance3D")
		unit.set_meta("cached_meshes", meshes)
		
	for mesh_node in meshes:
		if mesh_node is MeshInstance3D:
			if color.a >= 1.0:
				mesh_node.material_override = null
			else:
				var mat
				# จำ Material ไว้ใช้ซ้ำ เลิกสร้างใหม่ทุกเฟรมที่เมาส์ขยับ!
				if mesh_node.has_meta("preview_mat"):
					mat = mesh_node.get_meta("preview_mat")
				else:
					mat = StandardMaterial3D.new()
					mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
					mesh_node.set_meta("preview_mat", mat)
					
				mat.albedo_color = color
				mesh_node.material_override = mat






# ฟังก์ชันวาดตารางสี่เหลี่ยม
# 🌟 ปรับรับค่าแยก size_x กับ size_z
func draw_grid(size_x: float, size_z: float, offset_x: float, offset_z: float, step: float):
	if step <= 0: step = 0.5 
	
	var mesh_instance = $GridVisualizer
	var mesh = mesh_instance.mesh as ImmediateMesh
	mesh.clear_surfaces()
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var grid_color = Color(0.0, 1.0, 1.0, 0.02) 
	
	# 🌟 คำนวณจุดขอบสุดซ้าย/ขวา หน้า/หลัง แบบอ้างอิงจุดศูนย์กลางใหม่
	var min_x = offset_x - size_x
	var max_x = offset_x + size_x
	var min_z = offset_z - size_z
	var max_z = offset_z + size_z
	
	# วาดเส้นแกน Z
	var current_x = min_x
	while current_x <= max_x:
		mesh.surface_set_color(grid_color)
		mesh.surface_add_vertex(Vector3(current_x, 0.15, min_z))
		mesh.surface_set_color(grid_color)
		mesh.surface_add_vertex(Vector3(current_x, 0.15, max_z))
		current_x += step 
		
	# วาดเส้นแกน X
	var current_z = min_z
	while current_z <= max_z:
		mesh.surface_set_color(grid_color)
		mesh.surface_add_vertex(Vector3(min_x, 0.15, current_z))
		mesh.surface_set_color(grid_color)
		mesh.surface_add_vertex(Vector3(max_x, 0.15, current_z))
		current_z += step 
	
	var bound_color = Color(0, 0.8, 1.0, 1.0) 
	
	# --- วาดเส้นขอบ (Boundary) แบบย้ายตำแหน่ง ---
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(min_x, 0.16, min_z))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(max_x, 0.16, min_z))
	
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(max_x, 0.16, min_z))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(max_x, 0.16, max_z))
	
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(max_x, 0.16, max_z))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(min_x, 0.16, max_z))
	
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(min_x, 0.16, max_z))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(min_x, 0.16, min_z))
		
	mesh.surface_end()










# ==========================================
# 🌟 ฟังก์ชันสร้างกำแพงล่องหน (อัปเกรด: ปิดสวิตช์ตั้งแต่เกิด!)ไ
# ==========================================
func create_invisible_boundaries():
	# ลบของเก่าทิ้งก่อน ป้องกันบั๊กสร้างกำแพงซ้อนกัน
	if has_node("InvisibleBoundaries"):
		get_node("InvisibleBoundaries").queue_free()
		
	var boundary_node = Node3D.new()
	boundary_node.name = "InvisibleBoundaries"
	add_child(boundary_node)

	var min_x = build_offset_x - build_boundary_x
	var max_x = build_offset_x + build_boundary_x
	var min_z = build_offset_z - build_boundary_z
	var max_z = build_offset_z + build_boundary_z

	var wall_thickness = 2.0
	var wall_height = 50.0
	var wall_y_center = 25.0 

	var walls = [
		[Vector3(build_offset_x, wall_y_center, min_z - wall_thickness/2.0), Vector3((build_boundary_x * 2.0) + (wall_thickness*2.0), wall_height, wall_thickness)],
		[Vector3(build_offset_x, wall_y_center, max_z + wall_thickness/2.0), Vector3((build_boundary_x * 2.0) + (wall_thickness*2.0), wall_height, wall_thickness)],
		[Vector3(min_x - wall_thickness/2.0, wall_y_center, build_offset_z), Vector3(wall_thickness, wall_height, build_boundary_z * 2.0)],
		[Vector3(max_x + wall_thickness/2.0, wall_y_center, build_offset_z), Vector3(wall_thickness, wall_height, build_boundary_z * 2.0)]
	]

	for w in walls:
		var static_body = StaticBody3D.new()
		
		# 🌟 [ไม้ตายที่ 1] ปิด Layer เป็น 0 ให้กลายเป็นอากาศธาตุ เมาส์ยิงทะลุได้ 100%
		static_body.collision_layer = 0 
		static_body.collision_mask = 0
		
		var col_shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = w[1]
		col_shape.shape = box
		
		# 🌟 [ไม้ตายที่ 2] ปิดการชนตั้งแต่เพิ่งสร้าง Node!
		col_shape.disabled = true 
		
		static_body.add_child(col_shape)
		static_body.position = w[0]
		boundary_node.add_child(static_body)



# ==========================================
# 🌟 สวิตช์เปิด/ปิด กำแพงล่องหน (อัปเกรดความชัวร์ 100%)
# ==========================================
func toggle_invisible_walls(is_active: bool):
	var boundary_node = get_node_or_null("InvisibleBoundaries")
	if boundary_node:
		for static_body in boundary_node.get_children():
			# 🌟 ถ้าเปิด(true) ให้กลับมาชนได้(1) / ถ้าปิด(false) ให้กลายเป็นอากาศธาตุ(0)
			static_body.collision_layer = 1 if is_active else 0
			static_body.collision_mask = 1 if is_active else 0
			
			# ค้นหาลูกที่เป็น CollisionShape3D แล้วเปิด/ปิดตรงๆ ไม่ต้องง้อ find_children
			for child in static_body.get_children():
				if child is CollisionShape3D:
					child.set_deferred("disabled", not is_active)







func is_within_boundary(pos: Vector3) -> bool:
	# 🌟 เช็คแกน X เทียบกับขอบ X, เช็คแกน Z เทียบกับขอบ Z
	# 🌟 คำนวณขอบเขตใหม่ โดยเอาระยะไปบวก/ลบ กับจุดศูนย์กลาง (Offset)
	var in_x = pos.x >= (build_offset_x - build_boundary_x) and pos.x <= (build_offset_x + build_boundary_x)
	var in_z = pos.z >= (build_offset_z - build_boundary_z) and pos.z <= (build_offset_z + build_boundary_z)
	
	return in_x and in_z







func update_ui():
	hp_display.text = "ARMY HP: " + str(total_hp)
	energy_bar.value = current_energy
	# วนลูปเช็คปุ่ม Slot ทั้งหมดใน UI
	# ป้องกัน Error ถ้า Node ยังไม่พร้อม
	if not hp_display or not unit_list_container: return 
	
	hp_display.text = "ARMY HP: " + str(total_hp)
	energy_bar.value = current_energy
	
	for slot in unit_list_container.get_children():
		var u_name = slot.unit_data.get("name")
		var count = 0
		
		# นับว่าในสนามมีตัวละครชื่อนี้กี่ตัว
		for unit in occupied_tiles.values():
			if is_instance_valid(unit) and unit.get("unit_name") == u_name:
				count += 1
		
		# ส่งจำนวนที่ตรวจพบไปให้ Slot คำนวณตัวเลขที่เหลือ
		if slot.has_method("update_count_display"):
			slot.update_count_display(count)
		
		
	if energy_bar:
		# อัปเดตให้หลอด UI รู้ว่าขีดจำกัดสูงสุดคือเท่าไหร่
		energy_bar.max_value = max_energy 
		energy_bar.value = current_energy
	if energy_label:
		# ฟังก์ชันสั้นๆ สำหรับลบ .0 ส่วนเกิน
		var current_display = str(current_energy)
		if current_display.ends_with(".0"):
			current_display = current_display.left(-2) # ตัด .0 ออกจากด้านท้าย
	
		var max_display = str(max_energy)
		if max_display.ends_with(".0"):
			max_display = max_display.left(-2)
		energy_label.text = current_display + " / " + max_display
	
	# ==========================================
	# 🌟 อัปเดต UI ฝั่งศัตรู (มุมขวาบน)
	# ==========================================
	if enemy_hp_display:
		enemy_hp_display.text = "ENEMY HP: " + str(total_enemy_hp)
		
	if enemy_energy_label:
		# ฟังก์ชันตัด .0 ของบิลฝั่งศัตรู
		var enemy_en_display = str(total_enemy_energy_used)
		if enemy_en_display.ends_with(".0"):
			enemy_en_display = enemy_en_display.left(-2)
			
		enemy_energy_label.text = "COST EN: " + enemy_en_display
		# 🌟 ซ่อนหลอด EN ศัตรู ถ้าไม่ใช่ Dev Mode!
		enemy_energy_label.visible = is_dev_mode

	# ==========================================
	# 🌟 อัปเดตการหด/ขยาย ของหลอดเลือดภาพ (TextureProgressBar)
	# ==========================================
	if player_hp_bar:
		# ถ้ายังไม่เริ่มสู้ ให้หลอด Max ขยายตามเลือดปัจจุบัน (หลอดจะเต็ม 100% ตลอดตอนสร้าง)
		if not is_game_started:
			player_hp_bar.max_value = total_hp if total_hp > 0 else 1
		# อัปเดตเลือดปัจจุบัน
		player_hp_bar.value = total_hp
		
	if enemy_hp_bar:
		if not is_game_started:
			enemy_hp_bar.max_value = total_enemy_hp if total_enemy_hp > 0 else 1
		enemy_hp_bar.value = total_enemy_hp



# --- ฟังก์ชันสำหรับปุ่มหมวดหมู่ (Category Tabs) ---
func _on_btn_tab_char_pressed() -> void:
	update_unit_menu("character")


func _on_btn_tab_gun_pressed() -> void:
	update_unit_menu("gun")


func _on_btn_tab_block_pressed() -> void:
	update_unit_menu("block")


func _on_btn_tab_shield_pressed() -> void:
	update_unit_menu("shield")



# 🌟 3 ปุ่มใหม่สำหรับหมวดศัตรู! (โชว์เฉพาะตอนเปิด Dev Mode)
func _on_btn_tab_enemy_char_pressed() -> void:
	if not is_dev_mode: return
	update_unit_menu("enemy_character")

func _on_btn_tab_enemy_gun_pressed() -> void:
	if not is_dev_mode: return
	update_unit_menu("enemy_gun")

func _on_btn_tab_enemy_block_pressed() -> void:
	if not is_dev_mode: return
	update_unit_menu("enemy_block")





func _on_btn_start_pressed():
	if current_state == Turn.SETUP:
		is_game_started = true
		print("เข้าสู่ช่วงต่อสู้! ล็อกการสร้างทั้งหมด")

		# ซ่อน UI สร้างด่าน
		action_menu.hide()
		if unit_list_container.get_parent() is ScrollContainer:
			unit_list_container.get_parent().hide() 
		
		var ui_panel = $HUD/VBoxContainer 
		if ui_panel: ui_panel.hide()
		
		# ==========================================
		# 🌟 [เอากลับมา!] ซ่อนหลอด Energy และ Grid
		# ==========================================
		if energy_bar: energy_bar.hide()
		if has_node("GridVisualizer"): $GridVisualizer.hide()
		# ==========================================
		
		if btn_start: btn_start.hide() 
		
		if btn_open_library: btn_open_library.hide()
		if blueprint_library_ui: blueprint_library_ui.hide()
		
		if dragging_unit:
			dragging_unit.queue_free()
			dragging_unit = null
		selected_unit = null
		
		# ปลุกฟิสิกส์ให้ยูนิตทั้งหมดร่วงลงพื้น
		print("ปลุกยูนิตทั้งหมดและเปิดระบบฟิสิกส์!")
		for unit in occupied_tiles.values():
			if is_instance_valid(unit):
				if unit is RigidBody3D: unit.freeze = false
				if unit.has_method("start_combat"): unit.start_combat()

		print("⏳ เริ่มเกม! รอทุกคนหล่นถึงพื้น...")
		current_state = Turn.WAITING_PHYSICS
		next_turn = Turn.PLAYER







func _on_btn_end_turn_pressed():
	# กดได้เฉพาะตาเราเท่านั้น
	if current_state == Turn.PLAYER:
		# 🌟 ซ่อนปุ่มทันทีที่กด เพื่อกันผู้เล่นกดซ้ำตอนกำลังเปลี่ยนเทิร์น
		if btn_end_turn: btn_end_turn.hide() 
		print("🚩 ผู้เล่นสั่งจบเทิร์น")
		end_current_turn()







# ฟังก์ชันสั่งตัดจบเทิร์น! (เอาไว้อยู่ล่างฟังก์ชันปุ่ม Start เลยครับ)
func end_current_turn():
	if combat_menu: combat_menu.hide()
	selected_unit = null
	cancel_combat_aim() # ยกเลิกการเล็งถ้าเผลอง้างค้างไว้
	
	if current_state == Turn.PLAYER:
		print("⏳ จบตาผู้เล่น! รอตัวละครนิ่ง...")
		next_turn = Turn.ENEMY
		current_state = Turn.WAITING_PHYSICS
	elif current_state == Turn.ENEMY:
		print("⏳ จบตาศัตรู! รอตัวละครนิ่ง...")
		next_turn = Turn.PLAYER
		current_state = Turn.WAITING_PHYSICS








# ฟังก์ชันสำหรับลดเลือดกองทัพเวลาตัวละครตาย (อัปเกรดให้ฉลาด แยกค่ายได้!)
func reduce_army_hp(unit: Node3D, amount: int):
	# 1. ขอดูชื่อหน่อยว่าใช่ศัตรูไหม?
	var is_enemy = false
	if unit and unit.get("unit_name") != null:
		var u_name = str(unit.get("unit_name")).to_lower()
		for data in army_list:
			if data["name"].to_lower() == u_name:
				# 🌟 แก้ตรงนี้ครับ! ใช้ begins_with เพื่อเหมาหมดทั้ง ตัวละคร/ปืน/บล็อก ของศัตรู
				is_enemy = str(data["category"]).begins_with("enemy")
				break
				
	# 2. หักเลือดให้ถูกฝั่ง!
	if is_enemy:
		total_enemy_hp -= amount
		if total_enemy_hp < 0: total_enemy_hp = 0
		print("💀 ศัตรูล้ม! หักเลือดกองทัพศัตรูเหลือ: ", total_enemy_hp)
	else:
		total_hp -= amount
		if total_hp < 0: total_hp = 0
		print("💀 ตัวละครเราล้ม! หักเลือดกองทัพเราเหลือ: ", total_hp)
		
	update_ui()

# ฟังก์ชันสำหรับคืนเลือดกองทัพเวลาตัวละครฟลุ๊คลุกขึ้นยืนได้
func restore_army_hp(unit: Node3D, amount: int):
	var is_enemy = false
	if unit and unit.get("unit_name") != null:
		var u_name = str(unit.get("unit_name")).to_lower()
		for data in army_list:
			if data["name"].to_lower() == u_name:
				# 🌟 แก้ตรงนี้ครับ! ใช้ begins_with เพื่อเช็คว่าเป็นศัตรูหมวดไหนก็ได้
				is_enemy = str(data["category"]).begins_with("enemy")
				break
				
	if is_enemy:
		total_enemy_hp += amount
		print("🧟 ศัตรูลุกขึ้นได้! คืนเลือดศัตรู: ", total_enemy_hp)
	else:
		total_hp += amount
		print("💖 ปาฏิหาริย์! ตัวละครเราลุกขึ้นได้! คืนเลือด: ", total_hp)
		
	update_ui()
	


func is_mouse_over_ui() -> bool:
	var m_pos = get_viewport().get_mouse_position()
	
	# 1. เช็ค Combat Menu (โหมดสู้)
	if combat_menu and combat_menu.visible:
		if combat_menu.get_global_rect().has_point(m_pos): return true
		
	# 2. เช็ค Action Menu (โหมดสร้าง)
	if action_menu and action_menu.visible:
		# เช็คกรอบแม่ก่อน
		if action_menu.get_global_rect().has_point(m_pos): return true
		
		# --- [หัวใจสำคัญ] วนลูปเช็คปุ่มลูกๆ ทุกปุ่ม เผื่อมันล้นกรอบแม่ ---
		for child in action_menu.get_children():
			if child is Control and child.visible:
				if child.get_global_rect().has_point(m_pos):
					return true
					
	# 3. เช็คแผงร้านค้าด้านข้าง
	var ui_panel = $HUD/VBoxContainer 
	if ui_panel and ui_panel.visible:
		if ui_panel.get_global_rect().has_point(m_pos): return true
		
	return false





# ==========================================
# 🌟 ฟังก์ชันสั่งกล้องสั่นตามชนิดปืนและความแรงลาก
# ==========================================
func trigger_camera_shake(gun_name: String, power: float):
	var cam = get_viewport().get_camera_3d()
	if not cam: return
	var cam_rig = cam.get_parent().get_parent().get_parent()
	if not cam_rig or not cam_rig.has_method("add_trauma"): return
	
	# 🌟 ดักไว้เลย: ต่อให้ลากเบาแค่ไหน ก็ต้องสั่นอย่างน้อย 30% ไม่งั้นมองไม่เห็น!
	var power_ratio = max(power / 100.0, 0.3) 
	
	var trauma_amount = 0.0
	var g_name = gun_name.to_lower()
	
	# 🌟 อัปเกรดแรงกระแทกให้ทุกปืน!
	if "sniper" in g_name: 
		trauma_amount = 1.25 * power_ratio # สไนเปอร์: หลอดเต็ม 100% สั่นจอแทบหลุด!
	elif "shotgun" in g_name: 
		trauma_amount = 0.8 * power_ratio # ลูกซอง: แรงกระแทกหนักมาก
	elif "spear" in g_name: 
		trauma_amount = 0.3 * power_ratio # หอก: โยกกลางๆ ให้ดูมีน้ำหนักพุ่ง
	elif "machine_gun" in g_name: 
		# 🌟 ปืนกล: ปรับเป็น 0.25 แปลว่าถ้ายิงรัวแค่ 4 นัด หน้าจอจะสั่นหลอดเต็ม 100% ทันที!
		trauma_amount = 0.4 
	elif "semi_auto" in g_name: 
		trauma_amount = 0.4 * power_ratio # เซมิ: โยกตึงๆ ทีละนัด
	else: 
		trauma_amount = 0.5 * power_ratio # ปืนพกทั่วไป
		
	cam_rig.add_trauma(trauma_amount)







func _on_charge_finished(power: float):
	print("🚀 ปล่อยสปริง! ความแรง: ", power)
	is_firing = true 
	
	if active_combat_unit:
		# 🔀 แยกทางแยกที่แท้จริง! (Shoot หรือ Walk)
		if combat_action_mode == "shoot":
			if active_combat_unit.has_meta("linked_gun"):
				var gun = active_combat_unit.get_meta("linked_gun")
				if gun and is_instance_valid(gun):
					var is_semi = false
					var g_name = str(gun.get("unit_name")).to_lower() if gun.get("unit_name") != null else gun.name.to_lower()
					if "semi" in g_name:
						is_semi = true
							
					if has_node("TrajectoryLine"):
						$TrajectoryLine.hide()
						
					# 🔫 [แก้บั๊กยิงกลับหลัง] ใช้ +basis.z (ไม่ใส่เครื่องหมายลบ)
					var base_dir = active_combat_unit.global_transform.basis.z.normalized()
					base_dir.y = 0.0
					base_dir = base_dir.normalized()
					var pitch = current_pitch_offset if "current_pitch_offset" in self else 0.0
					
					# โยนให้ฟิสิกส์จัดการยิง
					await execute_gun_physics(active_combat_unit, gun, base_dir, power, true, pitch)
					
					if not is_semi:
						if power_ui:
							power_ui.hide()
							power_ui.current_power = 0.0
					else:
						if power_ui: power_ui.show()
					
					is_firing = false 
					return
					
		elif combat_action_mode == "walk":
			# 🚶 เรียกฟังก์ชันเดิน!
			execute_player_walk(active_combat_unit, power)
			is_firing = false
			return
			
	cancel_combat_aim(true, "")


func _on_charge_canceled():
	print("❌ ยกเลิกการยิง (ลากไม่พอ หรือ กดทิ้ง)")
	cancel_combat_aim()









# ==========================================
# 🌟 ฟังก์ชันยิงปืนศูนย์กลาง (ผู้เล่นและ AI ใช้ร่วมกัน!)
# ==========================================
func execute_gun_physics(shooter: Node3D, gun: Node3D, base_dir: Vector3, power: float, is_player: bool, pitch_offset: float = 0.0, exact_target_pos: Vector3 = Vector3.ZERO):
	var pellets = []
	for child in gun.get_children():
		if child is RigidBody3D:
			pellets.append(child)
			
	var g_name = str(gun.get("unit_name")).to_lower() if gun.get("unit_name") != null else gun.name.to_lower()
	var clean_name = g_name.split("_id_")[0]
	# ==========================================
	# 🌟 [แก้บั๊กความจำเสื่อม] แปะป้ายที่ "ตัวละครหลัก" ห้ามแปะที่ปืนเด็ดขาด!
	if "sniper" in clean_name:
		var actual_char = null
		if gun.has_meta("linked_char"):
			actual_char = gun.get_meta("linked_char")
		else:
			actual_char = shooter # สำรองไว้เผื่อหาไม่เจอ
			
		if is_instance_valid(actual_char):
			actual_char.set_meta("sniper_wait_turn", true)
			print("🎯 Sniper [", actual_char.name, "] ยิงแล้ว! แปะป้ายคูลดาวน์ที่ตัวละครสำเร็จ")
	# ==========================================

	# ----------------------------------------------------
	# 🔫 กรณีที่ 1: ปืนกล (Machine Gun / Mini)
	# ----------------------------------------------------
	if "machine_gun" in clean_name and pellets.size() > 0:
		if is_player: is_spraying = true
		
		pellets.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)
		var tracking_pellet = pellets[0] 
		
		for i in range(pellets.size()):
			var pellet = pellets[i]
			var current_facing = shooter.global_transform.basis.z.normalized()
			
			if not is_player:
				var spray_width = 0.15 
				var spray_offset = Vector3(randf_range(-spray_width, spray_width), randf_range(-spray_width * 0.5, spray_width * 0.5), randf_range(-spray_width, spray_width))
				current_facing = (base_dir + spray_offset).normalized()
				
			var spacing = current_facing * (i * 0.5)
			pellet.reparent(shooter.get_parent(), true)
			pellet.freeze = false
			# ==========================================
			# 🌟 [เพิ่มตรงนี้!] สั่งให้กระสุนมองข้ามคนยิง (ทะลุตัวไปเลย ไม่ทำดามเมจตัวเอง)
			# ==========================================
			if shooter is CollisionObject3D:
				pellet.add_collision_exception_with(shooter)
				shooter.add_collision_exception_with(pellet)
			# ==========================================
			pellet.global_position = pellet.global_position - spacing
			
			var final_impulse = current_facing * power * 0.75
			pellet.apply_central_impulse(final_impulse)
			
			if has_method("trigger_camera_shake"): trigger_camera_shake(clean_name, power)
			
			# ==========================================
			# 🌟 [แก้ตรงนี้ครับ!] จัดการลบกระสุนลูกเมียน้อยของ AI
			# ถ้าเป็นผู้เล่น = ลบทุกเม็ดตามเวลา 10 วิ
			# ถ้าเป็น AI = ลบทุกเม็ดที่ "ไม่ใช่เม็ดแรก (i != 0)" ตามเวลา 10 วิ
			if is_player or i != 0:
				get_tree().create_timer(10.0).timeout.connect(pellet.queue_free)
			# ==========================================
		
			if i < pellets.size() - 1:
				if "mini" in clean_name: await get_tree().create_timer(0.1).timeout
				else: await get_tree().create_timer(0.15).timeout
		
		# 🌟 [ส่งข่าว AI] ยิงครบทุกนัดแล้วค่อยส่งแค่ลูกเดียวไปตรวจระยะ
		if not is_player and exact_target_pos != Vector3.ZERO:
			track_projectile_for_power(shooter, tracking_pellet, exact_target_pos)
					
		gun.queue_free() # ลบแค่ตัวปืน กระสุน (pellets) ถูกย้ายไปที่อื่นแล้ว
		shooter.set_meta("linked_gun", null)
		
		if is_player:
			await get_tree().create_timer(0.5).timeout 
			is_spraying = false
			cancel_combat_aim(true, clean_name)
		else:
			shooter.set("has_attacked_this_turn", true)
			shooter.set_meta("needs_reload", true)
		return # จบการทำงานของปืนกล
		
	# ----------------------------------------------------
	# กรณีที่ 2: ลูกซอง (Shotgun)
	# ----------------------------------------------------
	elif "shotgun" in clean_name and pellets.size() > 0:
		pellets.sort_custom(func(a, b): return a.position.z < b.position.z)
		var left_dir = base_dir.rotated(Vector3.UP, deg_to_rad(90))
		var right_dir = base_dir.rotated(Vector3.UP, deg_to_rad(-90))
		var tracking_pellet = pellets[0] # ใช้ลูกแรกเป็นตัวแทนกลุ่ม
		
		for i in range(pellets.size()):
			var pellet = pellets[i]
			pellet.reparent(shooter.get_parent(), true)
			pellet.freeze = false
			if shooter is CollisionObject3D:
				pellet.add_collision_exception_with(shooter)
				shooter.add_collision_exception_with(pellet)
			
			var final_impulse = base_dir * power * 2.0
			var constant_spread = 35.0
			
			if pellets.size() == 2:
				if i == 0: final_impulse += left_dir * constant_spread 
				else: final_impulse += right_dir * constant_spread 
			elif pellets.size() == 3:
				if i == 0: final_impulse += base_dir * (power * 0.5) 
				elif i == 1: final_impulse += left_dir * constant_spread 
				else: final_impulse += right_dir * constant_spread
			
			pellet.apply_central_impulse(final_impulse)
			pellet.apply_torque_impulse(Vector3(0.0, randf_range(-15.0, 15.0), 0.0))
			
			# ==========================================
			# 🌟 [แก้ตรงนี้ครับ!] จัดการลบกระสุนลูกเมียน้อยของ AI
			# ถ้าเป็นผู้เล่น = ลบทุกเม็ดตามเวลา 10 วิ
			# ถ้าเป็น AI = ลบทุกเม็ดที่ "ไม่ใช่เม็ดแรก (i != 0)" ตามเวลา 10 วิ
			if is_player or i != 0:
				get_tree().create_timer(10.0).timeout.connect(pellet.queue_free)
			# ==========================================
			
		# 🌟 [ส่งข่าว AI] ยิงกระจายเสร็จแล้ว ส่งข่าวแค่ลูกเดียวพอ
		if not is_player and exact_target_pos != Vector3.ZERO:
			track_projectile_for_power(shooter, tracking_pellet, exact_target_pos)
					
		if has_method("trigger_camera_shake"): trigger_camera_shake(clean_name, power)
		gun.queue_free() # ลบตัวปืนทิ้ง

	# ----------------------------------------------------
	# 🏹 กรณีที่ 3: หอก (Spear)
	# ----------------------------------------------------
	elif "spear" in clean_name:
		gun.freeze = false
		if shooter is CollisionObject3D:
			gun.add_collision_exception_with(shooter)
			shooter.add_collision_exception_with(gun)
		
		var right_axis = shooter.global_transform.basis.x.normalized()
		var aim_dir = base_dir.rotated(right_axis, -pitch_offset).normalized()
		
		# แรงพุ่งของหอก
		var final_impulse = aim_dir * (power * 0.1)
		gun.apply_central_impulse(final_impulse)
		gun.apply_torque_impulse(Vector3(randf_range(0.5, 1.5), 0, 0))
		
		if has_method("trigger_camera_shake"): trigger_camera_shake(clean_name, power)
		
		# 🌟 [จุดเปลี่ยน] แยกการลบกระสุน
		if not is_player and exact_target_pos != Vector3.ZERO:
			track_projectile_for_power(shooter, gun, exact_target_pos) # ให้สายลับดูแลและลบเอง
		else:
			get_tree().create_timer(10.0).timeout.connect(gun.queue_free) # ผู้เล่นยิง ลบตามเวลาปกติ

	# ----------------------------------------------------
	# 🔫 กรณีที่ 4: Semi-Auto (ปืนพกแบบมีกระสุนในแม็ก)
	# ----------------------------------------------------
	elif "semi_auto" in clean_name and pellets.size() > 0:
		pellets.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)
		var pellet = pellets[0]
		pellet.reparent(shooter.get_parent(), true)
		pellet.freeze = false
		if shooter is CollisionObject3D:
			pellet.add_collision_exception_with(shooter)
			shooter.add_collision_exception_with(pellet)
			
		pellet.apply_central_impulse(base_dir * power * 0.375)
		if has_method("trigger_camera_shake"): trigger_camera_shake(clean_name, power)
		
		# 🌟 [ส่งข่าว AI]
		if not is_player and exact_target_pos != Vector3.ZERO:
			track_projectile_for_power(shooter, pellet, exact_target_pos)
		else:
			get_tree().create_timer(10.0).timeout.connect(pellet.queue_free)
		
		if "bullets_left" in gun:
			gun.bullets_left -= 1 
			if gun.bullets_left > 0:
				if is_player: 
					await get_tree().create_timer(0.01).timeout 
					is_firing = false 
					if power_ui and power_ui.has_method("start_charging"):
						power_ui.start_charging(100) 
				return # ยังมีกระสุนเหลือ ไม่ลบปืน
			else:
				gun.queue_free() # กระสุนหมด ลบตัวปืนทิ้ง
	
	# ----------------------------------------------------
	# กรณีที่ 5: ปืนพก / สไนเปอร์ (ก้อนเดียวเพียวๆ)
	# ----------------------------------------------------
	elif gun is RigidBody3D:
		if gun.get_parent() != shooter.get_parent():
			var glob_trans = gun.global_transform
			gun.get_parent().remove_child(gun)
			shooter.get_parent().add_child(gun)
			gun.global_transform = glob_trans
			
		gun.freeze = false
		if shooter is CollisionObject3D:
			gun.add_collision_exception_with(shooter)
			shooter.add_collision_exception_with(gun)
		
		var final_power = power * 0.5 
		if "sniper" in clean_name:
			final_power = power * 2.5 
			
		gun.apply_central_impulse(base_dir * final_power)
		if has_method("trigger_camera_shake"): trigger_camera_shake(clean_name, power)
		
		# 🌟 [ส่งข่าว AI] แยกการลบกระสุนสไนเปอร์
		if not is_player and exact_target_pos != Vector3.ZERO:
			track_projectile_for_power(shooter, gun, exact_target_pos) # สายลับดูแลและลบเอง
		else:
			# ผู้เล่นยิง หรือกรณีทั่วไป ลบตามเวลาปกติ (10 วินาที)
			get_tree().create_timer(10.0).timeout.connect(gun.queue_free)

	# ====================================================
	# 🧹 เคลียร์สถานะตอนจบ (ย้ายมาไว้นอกสุดเพื่อให้รันทุกประเภทปืน)
	# ====================================================
	shooter.set_meta("linked_gun", null)
	if is_player:
		cancel_combat_aim(true, clean_name)
	else:
		shooter.set("has_attacked_this_turn", true)
		shooter.set_meta("needs_reload", true)











# 🌟 รับชื่อปืน (gun_name) เข้ามาเพื่อกำหนดรูปร่างและความยาวเส้น
# 🌟 ระบบคำนวณเส้นเล็งแบบฟิสิกส์จริง (รองรับน้ำหนักกระสุน และแรงโน้มถ่วงทุกปืน)
func update_trajectory_line(start_pos: Vector3, launch_impulse: Vector3, gun_name: String = "", gun_node: Node3D = null, is_enemy_line: bool = false):
	var mesh = $TrajectoryLine.mesh as ImmediateMesh
	if not mesh: return
	mesh.clear_surfaces()
	
	# ==========================================
	# 🌟 1. ดึงมวลที่แท้จริงของกระสุนจากฟิสิกส์เกม! 
	# ==========================================
	var real_mass = 1.0
	if is_instance_valid(gun_node):
		if "spear" in gun_name and "mass" in gun_node:
			real_mass = gun_node.mass
		else:
			# ถ้าเป็นปืน ให้เจาะไปดูกระสุน (RigidBody) ที่ซ่อนอยู่ข้างใน
			for child in gun_node.get_children():
				if child is RigidBody3D and "mass" in child:
					real_mass = child.mass
					break
					
	# คำนวณความเร็วเริ่มต้นจาก "แรงผลัก ÷ น้ำหนักจริง"
	var velocity = launch_impulse / real_mass
	
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	# ==========================================
	# 🎯 ตั้งค่า "ความยาวเส้น (max_steps)" ตามประเภทปืน
	# ==========================================
	var max_steps = 20 # ค่าเริ่มต้น
	var base_line_width = 0.5 
	var is_shotgun = false 
	
	if "sniper" in gun_name:
		max_steps = 128 # สไนเปอร์: เส้นยาวเฟื้อยยย ทะลวงแมพ
	elif "shotgun" in gun_name:
		max_steps = 3 # ลูกซอง: เส้นสั้นๆ แค่ให้เห็นทิศทางบานออก
		is_shotgun = true
	elif "machine_gun_mini" in gun_name:
		max_steps = 7 # ปืนกลมินิ
	elif "machine_gun" in gun_name:
		max_steps = 7.5 # ปืนกล
	elif "semi_auto_gun" in gun_name:
		max_steps = 3 # ปืนเซมิ
	elif "spear" in gun_name:
		max_steps = 50 # หอก
	elif "gun" in gun_name: 
		max_steps = 4 # ปืนพก
	# ==========================================

	var time_step = 0.05
	var current_time = Time.get_ticks_msec() / 1000.0 
	
	# 🌟 2. ดึงแรงโน้มถ่วงของจริงมาใช้กับ "ทุกอาวุธ" (เส้นจะย้อยตามธรรมชาติ)
	var gravity = abs(ProjectSettings.get_setting("physics/3d/default_gravity"))

	for i in range(max_steps):
		var t = i * time_step
		# 🌟 สมการวิถีโค้ง (มี -gravity ดึงลงเสมอ)
		var offset = (velocity * t) + (0.5 * Vector3(0, -gravity, 0) * t * t)
		var current_pos = start_pos + offset
		
		var next_t = (i + 1) * time_step
		var next_offset = (velocity * next_t) + (0.5 * Vector3(0, -gravity, 0) * next_t * next_t)
		var next_pos = start_pos + next_offset
		
		var forward = (next_pos - current_pos).normalized()
		if forward == Vector3.ZERO: forward = Vector3.FORWARD
		var right = forward.cross(Vector3.UP).normalized() 
		
		var progress = float(i) / max_steps
		
		# ==========================================
		# 🌟 ตั้งค่าการเฟด (Fade)
		# ==========================================
		var fade_speed = 6.0 
		var min_alpha = 0.0 
		
		if "spear" in gun_name:
			fade_speed = 2.0 
			min_alpha = 0.2 
			
		var base_alpha = max(pow(1.0 - progress, fade_speed), min_alpha)
		
		# ==========================================
		# 🌟 ระบบคลื่นพลังงาน (Smooth Pulse Laser)
		# ==========================================
		var scroll_speed = 5.0 
		var stripe_density = 0.8 
		
		var wave = sin((float(i) * stripe_density) - (current_time * scroll_speed))
		var smooth_wave = (wave + 1.0) / 2.0 
		
		var pulse_shape = 0.3 
		var final_intensity = pow(smooth_wave, pulse_shape)
		
		# ==========================================
		# 🌟 ระบบสีเส้นเล็ง (แยกฝ่ายผู้เล่นสีฟ้า / ศัตรูสีแดง)
		# ==========================================
		var bright_color = Color(0.2, 1.0, 1.0, base_alpha * 1.0) # สีฟ้าสว่าง (ผู้เล่น)
		var dark_color = Color(0.0, 0.4, 0.5, base_alpha * 0.05)  # สีฟ้าเข้ม
		
		# ถ้าเป็นศัตรู เปลี่ยนโทนสีเป็นสีแดงอันตราย!
		if is_enemy_line:
			bright_color = Color(1.0, 0.1, 0.1, base_alpha * 1.0) # สีแดงสว่างจ้า
			dark_color = Color(0.5, 0.0, 0.0, base_alpha * 0.05)  # สีแดงเข้มเลือด
		
		var final_color = dark_color.lerp(bright_color, final_intensity)
		
		var current_line_width = base_line_width
		
		if is_shotgun:
			current_line_width = base_line_width + (progress * 10.0) 
			
		mesh.surface_set_color(final_color)
		
		var left_point = current_pos - (right * (current_line_width / 2.0))
		var right_point = current_pos + (right * (current_line_width / 2.0))
		
		mesh.surface_add_vertex(left_point)
		mesh.surface_add_vertex(right_point)
		
	mesh.surface_end()




func save_level_scene():
	if is_game_started:
		print("❌ [DEV MODE] เซฟไม่ได้! ต้องอยู่ในโหมดเตรียมพร้อม (SETUP) เท่านั้น")
		if has_node("ErrorSoundPlayer"): $ErrorSoundPlayer.play()
		return
		
	print("⏳ [DEV MODE] กำลังรวบรวมข้อมูลเพื่อเซฟด่าน...")
	var root_node = get_tree().current_scene
	
	# ==========================================
	# 🌟 [แก้บั๊ก PRO ขั้นสุด] ตั้งชื่อใหม่ให้ไม่ซ้ำกัน & บังคับเซฟ!
	# ==========================================
	var unit_count = 0
	for child in get_children():
		# เช็คว่าเป็น ตัวละคร/บล็อก/ปืน หรือไม่?
		if "unit_name" in child:
			unit_count += 1
			
			# 1. 🌟 บังคับตั้งชื่อให้ใหม่ (แก้บั๊ก @RigidBody ชนกัน 100%)
			var safe_name = str(child.get("unit_name")).replace(" ", "_")
			child.name = safe_name + "_id_" + str(unit_count) + "_" + str(Time.get_ticks_msec())
			
			# 2. สั่งลงทะเบียนให้มันเซฟลงด่าน
			if child.owner != root_node:
				child.owner = root_node
	# ==========================================
	
	# ทำการแพ็คฉาก
	var packed_scene = PackedScene.new()
	var pack_err = packed_scene.pack(root_node)
	
	if pack_err == OK:
		var save_path = root_node.scene_file_path
		var s_name = save_path.to_lower()
		
		# ถ้าเป็นโรงงาน ให้ปั๊มเป็น Dev_SavedLevel
		if save_path == "" or "main" in s_name or "theme" in s_name or "factory" in s_name:
			save_path = "res://Dev_SavedLevel.tscn"
			
		var save_err = ResourceSaver.save(packed_scene, save_path)
		
		if save_err == OK:
			print("✅ [DEV MODE] บันทึกด่านสำเร็จ! เซฟทับไฟล์: ", save_path)
		else:
			print("❌ [DEV MODE] เซฟไฟล์ล้มเหลว Error code: ", save_err)
	else:
		print("❌ [DEV MODE] แพ็คฉากล้มเหลว Error code: ", pack_err)











func _on_btn_save_level_pressed():
	# เช็คกันเหนียวอีกรอบว่าเปิด Dev Mode อยู่จริงๆ
	if is_dev_mode:
		save_level_scene()
	else:
		print("❌ ต้องเปิด Dev Mode ก่อนถึงจะเซฟด่านได้!")



func _restore_saved_level_data():
	var found_units = 0
	var all_chars = []
	var all_guns = []

	# 1. รวบรวมข้อมูลและเคลียร์ Meta ผีหลอก
	for child in get_children():
		if "unit_name" in child:
			found_units += 1
			var key = get_tile_key(child.global_position)
			child.set("tile_key", key)
			occupied_tiles[key] = child

			toggle_collision(child, false)
			set_unit_preview_color(child, Color(1, 1, 1, 1))

			# 🌟 ถอดป้ายชื่อ Meta เก่าทิ้งให้หมด! (นี่คือตัวการทำบั๊กแดงเถือกและ AI เอ๋อ)
			if child.has_meta("linked_gun"): child.remove_meta("linked_gun")
			if child.has_meta("linked_char"): child.remove_meta("linked_char")
			if child.has_meta("gun_local_offset"): child.remove_meta("gun_local_offset")

			var u_name = str(child.get("unit_name")).to_lower()
			var is_enemy = false
			var is_gun = false
			# 🌟 1. เตรียมดึงทั้งค่า HP และ EN
			var hp_gain = child.get("hp_gain_on_place") if child.get("hp_gain_on_place") != null else 0
			var unit_cost = child.get("energy_cost") if child.get("energy_cost") != null else 0.0

			# ค้นหาข้อมูลจากสมุดบัญชี army_list
			for data in army_list:
				if data["name"].to_lower() == u_name:
					if str(data["category"]).begins_with("enemy"): is_enemy = true
					if "gun" in str(data["category"]) or "gun" in u_name: is_gun = true
					
					# 🌟 ดึงค่า EN จาก army_list มาช่วย (เผื่อในโมเดลลืมตั้งค่าไว้)
					if unit_cost == 0.0 and data.has("cost"):
						unit_cost = data["cost"]
					break
			
			# กันเหนียว ถ้าไม่มีข้อมูลเลยให้คิด 1.0 ไว้ก่อน
			if unit_cost == 0.0: unit_cost = 1.0

			# 🌟 2. หักบิลเข้าบัญชี (เพิ่มบรรทัด total_enemy_energy_used เข้าไป!)
			if is_enemy:
				total_enemy_hp += hp_gain
				total_enemy_energy_used += unit_cost # <--- ตัวการของบั๊กคือลืมบรรทัดนี้ครับ!
			else:
				total_hp += hp_gain

			if is_gun:
				all_guns.append(child)
			elif not "block" in u_name:
				all_chars.append(child)

	# 2. 🌟 จับคู่ปืนกับตัวละครใหม่แบบสดๆ (อิงจากระยะทางใกล้สุด)
	for gun in all_guns:
		var nearest_char = null
		var min_dist = 2.0
		for char_node in all_chars:
			var dist = gun.global_position.distance_to(char_node.global_position)
			if dist <= min_dist:
				if not char_node.has_meta("linked_gun"): # ถ้าคนนั้นยังไม่มีปืน
					min_dist = dist
					nearest_char = char_node

		if nearest_char:
			nearest_char.set_meta("linked_gun", gun)
			gun.set_meta("linked_char", nearest_char)
			var g_name = gun.get("unit_name") if gun.get("unit_name") != null else gun.name
			nearest_char.set_meta("saved_gun_name", str(g_name).to_lower())
			nearest_char.set_meta("saved_gun_local_pos", nearest_char.to_local(gun.global_position))
			
			# 🌟 ใช้ wrapf แก้องศาเพี้ยน ป้องกันปืนพับกึกตอนเดิน
			var correct_rot = wrapf(gun.global_rotation.y - nearest_char.global_rotation.y, -PI, PI)
			nearest_char.set_meta("saved_gun_local_rot", correct_rot)
			
			nearest_char.set_meta("needs_reload", false) # เริ่มเกมมายังไม่ต้องรีโหลด!

	if found_units > 0:
		print("💾 โหลดข้อมูลด่านสำเร็จ! กู้คืนระบบปืนและยูนิต: ", found_units, " ตัว")
		update_ui()

# ==========================================
# 🌟 ระบบฟิสิกส์และสลับเทิร์น (Turn & Physics Management)
# ==========================================

# 1. ฟังก์ชันเช็คว่าทุกคนหยุดกลิ้งหรือยัง?
func are_all_units_settled() -> bool:
	for unit in occupied_tiles.values():
		if is_instance_valid(unit) and unit is RigidBody3D:
			# ถ้าความเร็วการเคลื่อนที่ หรือความเร็วการหมุน ยังเกิน 0.1 แปลว่ายังขยับอยู่!
			if unit.linear_velocity.length() > 0.1 or unit.angular_velocity.length() > 0.1:
				return false
	return true

# 2. ฟังก์ชันเริ่มเทิร์นถัดไป (จะถูกเรียกเมื่อฟิสิกส์นิ่ง 100% แล้ว)
# 2. ฟังก์ชันเริ่มเทิร์นถัดไป (จะถูกเรียกเมื่อฟิสิกส์นิ่ง 100% แล้ว)
func proceed_to_next_turn():
	# 🛑 1. เช็คประตูก่อน! ถ้ามีคนกำลังเปลี่ยนเทิร์นอยู่ ให้เตะระบบฟิสิกส์ออกไปเลย!
	if is_changing_turn: return 
	
	is_changing_turn = true # 🔒 ล็อกประตู! ห้ามใครเข้ามายุ่งจนกว่าจะจัดของเสร็จ
	
	# 🔴 2. เช็ค Game Over ก่อนเลย!
	if total_hp <= 0 or total_enemy_hp <= 0:
		current_state = Turn.GAME_OVER
		check_game_over()
		is_changing_turn = false # ปลดล็อก
		return
		
	# 🟢 3. จัดกระดูกคนเป็นให้ยืนตรง
	snap_units_upright()
	
	# 🟡 4. รีโหลดกระสุน และ รีเซ็ตสิทธิ์การยิง (ใช้ await ได้อย่างปลอดภัย 100% แล้ว!)
	await reset_turn_actions(next_turn)
	
	# 🔵 5. สลับสวิตช์เข้าสู่เทิร์นถัดไป!
	current_state = next_turn
	is_changing_turn = false # 🔓 ปลดล็อกประตู! อนุญาตให้ระบบฟิสิกส์ทำงานต่อได้
	
	# ==========================================
	# 🌟 [เพิ่มตรงนี้!] จัดการการแสดงผลปุ่ม End Turn
	# ==========================================
	if btn_end_turn:
		if current_state == Turn.PLAYER:
			btn_end_turn.show() # โชว์แค่ตอนตาเรา
		else:
			btn_end_turn.hide() # ซ่อนตอนตาศัตรู และสถานะอื่นๆ
	
	if current_state == Turn.PLAYER:
		print("🛡️ ตาของคุณ! (PLAYER TURN)")
	elif current_state == Turn.ENEMY:
		print("👹 ตาศัตรู! (ENEMY TURN)")
		run_enemy_ai()

# 3. ฟังก์ชันจับยืนตรง
# 3. ฟังก์ชันจับยืนตรง
func snap_units_upright():
	for unit in occupied_tiles.values():
		if is_instance_valid(unit) and unit is RigidBody3D:
			
			# 🌟 [ยันต์กันผี!] เช็คชื่อก่อนเลย ถ้าเป็นตระกูล 'block' ให้ข้ามไปทันที!
			if "unit_name" in unit and "block" in str(unit.get("unit_name")).to_lower():
				continue
				
			# เช็คก่อนว่ามันยังไม่ตาย ถึงจะจับให้ยืน (ตัวละครปกติจะเข้าเงื่อนไขนี้)
			if unit.get("is_dead") != null and not unit.get("is_dead"):
				var current_rot = unit.rotation
				# บังคับแกน X และ Z เป็น 0 ให้ตั้งฉากกับพื้น (แกน Y หันหน้าทางเดิม)
				unit.rotation = Vector3(0, current_rot.y, 0)
				unit.angular_velocity = Vector3.ZERO
				unit.linear_velocity = Vector3.ZERO

# 4. ฟังก์ชันเตรียมพร้อมเมื่อเริ่มเทิร์น (รีโหลด & เติม Action)
# 4. ฟังก์ชันเตรียมพร้อมเมื่อเริ่มเทิร์น (รีโหลด & เติม Action)
# 4. ฟังก์ชันเตรียมพร้อมเมื่อเริ่มเทิร์น
# 4. ฟังก์ชันเตรียมพร้อมเมื่อเริ่มเทิร์น (เวอร์ชัน Optimised)
func reset_turn_actions(target_turn):
	var processed_count = 0 # 🌟 สร้างตัวนับไว้เช็คภาระงาน
	
	for unit in occupied_tiles.values():
		if is_instance_valid(unit) and "unit_name" in unit:
			
			if unit.get("is_dead") == true: continue
				
			var u_name = str(unit.get("unit_name")).to_lower()
			var is_my_turn = (is_enemy_char(u_name) and target_turn == Turn.ENEMY) or (is_player_char(u_name) and target_turn == Turn.PLAYER)
			
			if is_my_turn:
				# --- (ส่วนเช็คคูลดาวน์สไนเปอร์ เหมือนเดิมเป๊ะ) ---
				var is_cooling_down = false
				if unit.has_meta("sniper_wait_turn") and unit.get_meta("sniper_wait_turn") == true:
					is_cooling_down = true
				
				if is_cooling_down:
					unit.set_meta("has_attacked_this_turn", true)
					unit.set_meta("sniper_wait_turn", false) 
					set_unit_preview_color(unit, Color(0.2, 0.2, 0.2, 1.0)) 
				else:
					unit.set_meta("has_attacked_this_turn", false)
					set_unit_preview_color(unit, Color(1, 1, 1, 1))

				# --- (ส่วนรีโหลดปืน เหมือนเดิมเป๊ะ) ---
				if unit.has_meta("saved_gun_name"):
					var raw_g_name = str(unit.get_meta("saved_gun_name")).to_lower()
					var clean_g_name = raw_g_name.split("_id_")[0]
					
					if unit.has_meta("linked_gun"):
						var old_gun = unit.get_meta("linked_gun")
						if is_instance_valid(old_gun): old_gun.queue_free()
						
					var gun_scene = null
					for data in army_list:
						if str(data["name"]).to_lower() == clean_g_name:
							if "scene" in data: gun_scene = data["scene"]
							break
							
					if gun_scene:
						var new_gun = gun_scene.instantiate()
						get_tree().current_scene.add_child(new_gun)
						
						if unit.has_meta("saved_gun_local_pos"):
							var l_pos = unit.get_meta("saved_gun_local_pos")
							var l_rot = unit.get_meta("saved_gun_local_rot")
							new_gun.global_position = unit.to_global(l_pos)
							var default_x = new_gun.global_rotation.x
							var default_z = new_gun.global_rotation.z
							new_gun.global_rotation = Vector3(default_x, unit.global_rotation.y + l_rot, default_z)
						else:
							new_gun.global_position = unit.global_position
							var default_x = new_gun.global_rotation.x
							var default_z = new_gun.global_rotation.z
							new_gun.global_rotation = Vector3(default_x, unit.global_rotation.y + deg_to_rad(90), default_z)
						
						if new_gun is RigidBody3D: new_gun.freeze = false
						for child in new_gun.find_children("*", "RigidBody3D"): child.freeze = false
						
						unit.set_meta("linked_gun", new_gun)
						new_gun.set_meta("linked_char", unit)
						unit.set_meta("needs_reload", false) 
				# ==========================================
				# 🌟 จุดออฟติไมซ์: แบ่งงานทำเฟรมละ 3 ตัว
				# เอามาไว้ท้ายสุดของบล็อก if is_my_turn:
				# ==========================================
				processed_count += 1
				if processed_count % 3 == 0: 
					await get_tree().process_frame
				# ==========================================


# 5. ฟังก์ชันประกาศจบเกม!
func check_game_over():
	if total_hp <= 0 and total_enemy_hp <= 0:
		print("🤝 เสมอกัน! ตายเรียบทั้งกระดาน!")
	elif total_hp <= 0:
		print("💀 GAME OVER! กองทัพคุณพ่ายแพ้!")
	elif total_enemy_hp <= 0:
		print("🎉 YOU WIN! ปราบศัตรูสำเร็จ!")




# ==========================================
# 🌟 ระบบตรวจสอบหลังยิงเสร็จ (รองรับทั้งนัดเดียวและหลายนัด)
# ==========================================
func post_shoot_turn_check(unit: Node3D, is_last_shot: bool = true):
	if is_instance_valid(unit):
		if is_last_shot:
			unit.set("has_attacked_this_turn", true)
			unit.set_meta("needs_reload", true) 
			
			# 🌟 [เพิ่มตรงนี้!] ถ้าเป็นสไนเปอร์ ให้ติดป้าย "ต้องพักตาหน้า"
			if unit.has_meta("saved_gun_name"):
				var g_name = str(unit.get_meta("saved_gun_name")).to_lower()
				if "sniper" in g_name:
					unit.set_meta("sniper_wait_turn", true)
					print("🎯 Sniper [", unit.name, "] ยิงแล้ว! ติดสถานะรอคูลดาวน์ตาหน้า")
			
			current_state = Turn.WAITING_PHYSICS
			next_turn = Turn.ENEMY
		else:
			print("🔫 ยิงออกไปหนึ่งนัด (ยังมีนัดถัดไปในชุดเดียวกัน)")




# ==========================================
# 🌟 ระบบสมองกลศัตรู (Enemy AI Core - Phase 3 อัปเกรด)
# ==========================================
func run_enemy_ai():
	print("🤖 AI กำลังสแกนระยะยิงแบบกลุ่ม...")
	var can_shoot_units = []
	var need_move_units = [] 
	var unarmed_units = []  
	
	# 1. คัดแยกประเภทศัตรูทั้งหมด
	for unit in occupied_tiles.values():
		if is_instance_valid(unit) and "unit_name" in unit:
			var u_name = str(unit.get("unit_name")).to_lower()
			
			# 🌟 ให้ AI อ่านโพสต์อิทว่าโดนล็อคอยู่ไหม
			var already_shot = false
			if unit.has_meta("has_attacked_this_turn"):
				already_shot = unit.get_meta("has_attacked_this_turn")
				
			if is_enemy_char(u_name) and not unit.get("is_dead") and already_shot != true:
				
				var target = get_closest_player_unit(unit.global_position)
				if not target: continue
				
				var dist = unit.global_position.distance_to(target.global_position)
				
				if unit.has_meta("linked_gun") and is_instance_valid(unit.get_meta("linked_gun")):
					var gun = unit.get_meta("linked_gun")
					
					# 1. ดึงชื่อปืนมาให้เป๊ะ 100%
					var gun_name = ""
					if "unit_name" in gun:
						gun_name = str(gun.unit_name).to_lower()
					else:
						gun_name = gun.name.to_lower()
						
					var clean_name = gun_name.split("_id_")[0]
					
					# 2. ตั้งค่าระยะยิงพื้นฐาน (เผื่อลืมใส่ในสมุด)
					var gun_max_range = 10.0 
					
					# 🌟 3. ไอเดียพี่แว่น: ดึงระยะยิงจากสมุด army_list โดยตรง! ไม่ต้องมี if ดักชื่อปืนแล้ว!
					for data in army_list:
						if data["name"].to_lower() == clean_name and "max_range" in data:
							gun_max_range = data["max_range"]
							break
					
					# ----------------------------------------------------
					# ลบ if "sniper" บ้าบอพวกนั้นทิ้งไปได้เลยครับ! ระบบเราสมบูรณ์แล้ว
					# ----------------------------------------------------
					
					if dist <= gun_max_range:
						can_shoot_units.append({"unit": unit, "target": target, "range": gun_max_range})
					else:
						need_move_units.append({"unit": unit, "target": target})
					
				# 🌟 [เพิ่มตรงนี้!] ถ้าไม่มีปืน ให้โยนเข้ากลุ่ม unarmed_units ทันที
				else:
					print("👊 ", u_name, " ไม่มีอาวุธ! เตรียมวิ่งไปชน")
					unarmed_units.append({"unit": unit, "target": target})

	if can_shoot_units.is_empty() and need_move_units.is_empty() and unarmed_units.is_empty():
		current_state = Turn.WAITING_PHYSICS
		next_turn = Turn.PLAYER
		return

	# ==========================================
	# 🏃 2. สั่งเคลื่อนพล (อัปเกรด: 1 เป้าหมาย ต่อ 1 ตัวแทนกระโดด)
	# ==========================================
	var movers = unarmed_units + need_move_units
	if movers.size() > 0:
		# 🌟 1. สร้างสมุดจด: ใครคือตัวแทนที่ดีที่สุดของแต่ละเป้าหมาย
		# โครงสร้าง: { target_node: { "unit": unit_node, "dist": float } }
		var target_assignments = {}
		
		for k in unarmed_units:
			var unit = k["unit"]
			var target = k["target"]
			var dist = unit.global_position.distance_to(target.global_position)
			
			# ถ้าเป้าหมายนี้ยังไม่มีใครจอง หรือ เราอยู่ใกล้กว่าคนที่จองไว้เดิม
			if not target_assignments.has(target) or dist < target_assignments[target]["dist"]:
				target_assignments[target] = {"unit": unit, "dist": dist}
		
		# 🌟 2. ดึงรายชื่อ "ผู้โชคดี" ที่ได้รับอนุมัติให้กระโดดออกมาเป็น List
		var authorized_jumpers = []
		for data in target_assignments.values():
			authorized_jumpers.append(data["unit"])
			
		print("🏃 สั่งเคลื่อนพล ", movers.size(), " ยูนิต (อนุมัติให้กระโดด ", authorized_jumpers.size(), " ตัว)")
		
		var move_count = 0
		for m in movers:
			# 🌟 3. เช็คว่า Unit นี้คือตัวแทนที่ได้รับเลือกของเป้าหมายใดเป้าหมายหนึ่งหรือไม่
			var can_jump = m["unit"] in authorized_jumpers
			
			# ส่งไปทำงาน (ถ้า can_jump เป็น true และระยะถึง มันจะโดดเอง)
			enemy_kamikaze(m["unit"], m["target"], can_jump)
			
			move_count += 1
			if move_count % 3 == 0:
				await get_tree().process_frame 
		
		if can_shoot_units.is_empty():
			await get_tree().create_timer(1.2).timeout
	# ==========================================
	# 🔫 3. สั่งยิง (ระบบ AI เลือกลำดับความสำคัญในการยิง)
	if can_shoot_units.size() > 0:
		await get_tree().create_timer(0.5).timeout
		
		# สลับตำแหน่งแบบสุ่ม เพื่อให้แต่ละเทิร์นกระจายการเช็ค ไม่ซ้ำตัวเดิม
		can_shoot_units.shuffle() 
		
		var final_shooter = null
		var final_target = null
		var fallback_shooter = null # แผนสำรอง: จำใจต้องยิงอัดบล็อก/เพื่อน
		
		# 🧠 AI ลองเช็คระยะทีละตัว หาคนที่ "ทางสะดวกที่สุด" (อัปเกรดระบบ "กรวย 3 มิติ")
		for shooter_data in can_shoot_units:
			var current_shooter = shooter_data["unit"]
			var target = shooter_data["target"]
			var current_final_shooter = current_shooter
			var is_blocked = false
			
			var space_state = get_world_3d().direct_space_state
			
			for attempt in range(3): 
				var start_pos = current_final_shooter.global_position + Vector3(0, 0.75, 0)
				var end_pos = target.global_position + Vector3(0, 0.75, 0)
				var base_dir = (end_pos - start_pos).normalized()
				var target_dist = start_pos.distance_to(end_pos)
				
				# 🌟 1. ยิงเรดาร์เส้นหลัก 1 เส้นตรงๆ
				var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
				query.hit_from_inside = true
				
				var excludes = [current_final_shooter.get_rid()]
				var gun_name = ""
				if current_final_shooter.has_meta("linked_gun"):
					var g = current_final_shooter.get_meta("linked_gun")
					if is_instance_valid(g):
						gun_name = str(g.get("unit_name")).to_lower()
						if g is CollisionObject3D: excludes.append(g.get_rid())
						for child in g.find_children("*", "CollisionObject3D"):
							excludes.append(child.get_rid())
				query.exclude = excludes
				
				var result = space_state.intersect_ray(query)
				var hit_friendly_node = null
				
				if result and result.collider:
					var hit_node = result.collider
					if not "tile_key" in hit_node and hit_node.get_parent() != null:
						if "tile_key" in hit_node.get_parent(): hit_node = hit_node.get_parent()
						
					if "unit_name" in hit_node and is_enemy_unit(str(hit_node.get("unit_name")).to_lower()):
						# 🌟 [อัปเกรด!] ถ้าเป็นศพเพื่อน ให้มองข้ามไปเลย ไม่นับว่าบัง!
						if hit_node.get("is_dead") != true:
							hit_friendly_node = hit_node 
				
				# ==========================================
				# 🌟 2. สแกนหาเพื่อนใน "กรวย 3 มิติ"
				# ==========================================
				if hit_friendly_node == null and ("shotgun" in gun_name or "machine_gun" in gun_name):
					var cone_angle = deg_to_rad(15.0) 
					var closest_friend_dist = target_dist
					
					for unit in occupied_tiles.values():
						if is_instance_valid(unit) and unit != current_final_shooter and "unit_name" in unit:
							# 🌟 [อัปเกรด!] กรองหาเพื่อนเฉพาะคนที่ "ยังมีชีวิตอยู่" เท่านั้น
							if is_enemy_unit(str(unit.get("unit_name")).to_lower()) and unit.get("is_dead") != true:
								var friend_pos = unit.global_position + Vector3(0, 0.75, 0)
								var vec_to_friend = friend_pos - start_pos
								var dist_to_friend = vec_to_friend.length()
								
								if dist_to_friend < closest_friend_dist:
									var dir_to_friend = vec_to_friend.normalized()
									var angle_to_friend = base_dir.angle_to(dir_to_friend) 
									
									if angle_to_friend <= cone_angle:
										hit_friendly_node = unit
										closest_friend_dist = dist_to_friend 
				# ==========================================

				# 3. ตัดสินใจ: ไม่ว่าจะโดนจากเรดาร์เส้นหลัก หรืออยู่ในกรวย ก็เข้าสู่ระบบส่งไม้ต่อ
				if hit_friendly_node != null:
					var can_delegate = hit_friendly_node.has_meta("linked_gun") and not hit_friendly_node.get("is_dead") and not hit_friendly_node.get("has_attacked_this_turn")
					
					if can_delegate:
						current_final_shooter = hit_friendly_node
						continue 
					else:
						is_blocked = true
						break
				
				# ทางสะดวก 100% 
				break
				
			if is_blocked:
				continue 
			else:
				final_shooter = current_final_shooter
				final_target = target
				break
				
		# ==========================================
		# 🎯 ตัดสินใจขั้นเด็ดขาด!
		if final_shooter == null:
			print("⚠️ AI: โดนบังมิดหมดเลย! ช่างมัน ยิงอัดไปเลยละกัน ถอยไม่ได้แล้ว!")
			# 🌟 [อัปเกรด!] ดึงแผนสำรอง (หยิบศัตรูตัวแรกสุดในคิวที่พร้อมยิง) มาลั่นไกแบบไม่สนโลก! ยิงทะลวงศพหรือบล็อกไปเลย!
			if can_shoot_units.size() > 0:
				final_shooter = can_shoot_units[0]["unit"]
				final_target = can_shoot_units[0]["target"]
			else:
				# เผื่อกรณีคิวว่างจริงๆ จะได้ไม่ Error
				current_state = Turn.WAITING_PHYSICS
				next_turn = Turn.PLAYER
				return
			
		print("🎯 ", final_shooter.name, " รับหน้าที่ลั่นไก!")
		var gun = final_shooter.get_meta("linked_gun")
		
		# 🌟 จดจำทิศทางหันหน้าเดิมของศัตรูเอาไว้ก่อน!
		var original_rot_y = final_shooter.global_rotation.y
		
		# หันหน้าเข้าหาเป้าหมาย
		final_shooter.global_rotation.y = atan2(final_target.global_position.x - final_shooter.global_position.x, final_target.global_position.z - final_shooter.global_position.z)
		
		if is_instance_valid(gun):
			gun.global_rotation.y = final_shooter.global_rotation.y + final_shooter.get_meta("saved_gun_local_rot")
			
		# 🌟 [แก้ตรงนี้!] ใส่คำว่า await นำหน้า เพื่อรอให้ AI เล็งและรัวปืนจนจบจริงๆ ก่อน!
		await enemy_fire_weapon(final_shooter, final_target)
		
		# 🌟 [แก้ตรงนี้!] ลดเวลาลงเหลือ 0.5 เพราะมันเสียเวลารอในฟังก์ชันยิงไปแล้ว
		await get_tree().create_timer(0.5).timeout
		
		# 🌟 พอยิงเสร็จ สั่งให้หมุนตัวกลับมาที่เดิมอย่างนุ่มนวล!
		if is_instance_valid(final_shooter):
			# 1. ดึงมุมปัจจุบันออกมา
			var current_rot = final_shooter.global_rotation.y
			
			# 2. 🌟 คาถาแก้หมุนติ้ว: ใช้ wrapf บังคับหา "ส่วนต่างที่สั้นที่สุด" (ไม่เกิน 180 องศา หรือ PI)
			var shortest_diff = wrapf(original_rot_y - current_rot, -PI, PI)
			var target_rot = current_rot + shortest_diff
			
			# 3. สั่ง Tween ให้หมุนไปหาตัวเลขเป้าหมายใหม่ ที่เป็นทางลัด!
			var tween = create_tween()
			tween.tween_property(final_shooter, "global_rotation:y", target_rot, 0.3).set_trans(Tween.TRANS_SINE)
		
		
	for unit in occupied_tiles.values():
		if is_instance_valid(unit) and unit.has_meta("linked_gun"):
			var gun = unit.get_meta("linked_gun")
			if is_instance_valid(gun) and gun is RigidBody3D:
				if gun.angular_velocity.length() > 5.0:
					gun.angular_velocity = Vector3.ZERO
					gun.linear_velocity = Vector3.ZERO
					
	current_state = Turn.WAITING_PHYSICS
	next_turn = Turn.PLAYER


# ฟังก์ชันหาเหยื่อที่ใกล้ที่สุด (เรดาร์ AI)
func get_closest_player_unit(from_pos: Vector3) -> Node3D:
	var closest_unit = null
	var min_dist = 9999.0
	
	for unit in get_children():
		if is_instance_valid(unit) and "unit_name" in unit:
			var u_name = str(unit.get("unit_name"))
			
			if is_player_char(u_name):
				# 💀 ข้ามคนที่ตายแล้วแบบเด็ดขาด!
				if unit.get("is_dead") != null and unit.get("is_dead") == true:
					continue
					
				var dist = from_pos.distance_to(unit.global_position)
				if dist < min_dist:
					min_dist = dist
					closest_unit = unit
					
	return closest_unit





# ฟังก์ชันยิงปืนของ AI (รวมระบบความแม่นยำ)
# ฟังก์ชันยิงปืนของ AI
# 🎯 ฟังก์ชันยิงปืนของ AI (ระบบล็อกเป้า Aimbot 100% เลิกเอ๋อ เลิกยิงมั่ว)
# 🎯 ฟังก์ชันยิงปืนของ AI (ระบบ Aimbot แก้บั๊กกลับหัว 100%)
# 🎯 ฟังก์ชันยิงปืนของ AI (ระบบ Aimbot เปลี่ยนเป้าหมายทุกนัดแบบ John Wick)
func enemy_fire_weapon(enemy: Node3D, target: Node3D):
	var gun = enemy.get_meta("linked_gun")
	if not is_instance_valid(gun) or not is_instance_valid(target): return
		
	var gun_name = str(gun.get("unit_name")).to_lower() if gun.get("unit_name") != null else gun.name.to_lower()
	
	# 🌟 1. เช็คว่ามีกระสุนกี่นัด
	var shots_to_fire = 1
	if "semi_auto" in gun_name and gun.get("bullets_left") != null:
		shots_to_fire = gun.get("bullets_left")
		
	var current_target = target
	var targeted_list = [] # สมุดจดว่า AI เล็งใครไปแล้วบ้าง
	
	# 🌟 2. เริ่มลูปยิงทีละนัด (คำนวณวิถีโค้งใหม่ทุกนัด!)
	for i in range(shots_to_fire):
		if not is_instance_valid(enemy) or not is_instance_valid(gun): break
		
		# 🔄 ถ้านัดที่ 2 เป็นต้นไป ให้หาเหยื่อรายใหม่!
		if i > 0:
			var next_target = null
			var min_dist = 9999.0
			# สแกนหาตัวละครฝั่งเราทั้งหมดในฉาก
			for unit in get_children():
				if is_instance_valid(unit) and "unit_name" in unit:
					if is_player_char(str(unit.get("unit_name"))) and not unit.get("is_dead"):
						# กรองหาคนที่ "ยังไม่โดนเล็งในเทิร์นนี้" และอยู่ใกล้ที่สุด
						if not unit in targeted_list:
							var dist = enemy.global_position.distance_to(unit.global_position)
							if dist < min_dist:
								min_dist = dist
								next_target = unit
			
			# ถ้าเจอเหยื่อรายใหม่ ให้สลับเป้า! (ถ้าไม่เจอใครเลย ก็ยิงซ้ำตัวเดิม)
			if next_target:
				current_target = next_target
				print("🔄 สลับเป้าหมาย! นัดต่อไป AI หันไปยิง: ", current_target.name)
				
		# จดชื่อลงสมุดว่าเล็งคนนี้ไปแล้วนะ (นัดหน้าจะได้ไม่ยิงซ้ำ)
		targeted_list.append(current_target)

		# ==========================================
		# 🌟 3. โค้ดคำนวณวิถีโค้ง (อยู่ใน Loop แล้ว!)
		# ==========================================
		var true_target_pos = current_target.global_position + Vector3(0, 0.75, 0)
		var start_pos = gun.global_position
		
		# หันหน้าและหันปืนเข้าหาเป้าหมายใหม่ทุกครั้งที่ลั่นไก
		enemy.global_rotation.y = atan2(current_target.global_position.x - enemy.global_position.x, current_target.global_position.z - enemy.global_position.z)
		if is_instance_valid(gun):
			gun.global_rotation.y = enemy.global_rotation.y + enemy.get_meta("saved_gun_local_rot")
		
		# หาระยะแนวราบ (แกน XZ) และแนวดิ่ง (แกน Y)
		var h_diff = Vector3(true_target_pos.x - start_pos.x, 0, true_target_pos.z - start_pos.z)
		var x = h_diff.length()
		var y = true_target_pos.y - start_pos.y
		var h_dir = h_diff.normalized()
		if h_dir == Vector3.ZERO: h_dir = Vector3.FORWARD
		
		var power_adj = enemy.get_meta("power_adjustment") if enemy.has_meta("power_adjustment") else 1.0
		var ai_power = 100.0 * power_adj 
		
		if y >= -0.5 and not "spear" in gun_name:
			ai_power = 100.0
			enemy.set_meta("power_adjustment", 1.0)
			
		var impulse_mult = 0.5
		if "spear" in gun_name: impulse_mult = 0.1
		elif "sniper" in gun_name: impulse_mult = 2.5
		elif "shotgun" in gun_name: impulse_mult = 2.0
		elif "semi_auto" in gun_name: impulse_mult = 0.375
		elif "machine_gun" in gun_name: impulse_mult = 0.75
		
		var mass = 1.0
		if "spear" in gun_name and "mass" in gun:
			mass = gun.mass
		else:
			for child in gun.get_children():
				if child is RigidBody3D and "mass" in child:
					mass = child.mass
					break
					
		var g = abs(ProjectSettings.get_setting("physics/3d/default_gravity"))
		var actual_force = ai_power * impulse_mult
		
		if x > 0.1:
			var v_min = sqrt(g * (y + sqrt(x * x + y * y)))
			var required_force = v_min * mass
			if actual_force < required_force:
				actual_force = required_force * 1.02
				ai_power = actual_force / impulse_mult
				
		var v = actual_force / mass
		var pitch_angle = 0.0
		
		if x < 0.1:
			pitch_angle = deg_to_rad(-89.0) if y < 0 else deg_to_rad(89.0)
		else:
			var root_term = pow(v, 4) - g * (g * x * x + 2 * y * v * v)
			if root_term < 0:
				var v_needed = sqrt(g * (y + sqrt(x * x + y * y)))
				v = v_needed * 1.05
				actual_force = v * mass
				ai_power = actual_force / impulse_mult
				root_term = pow(v, 4) - g * (g * x * x + 2 * y * v * v)
			pitch_angle = atan((pow(v, 2) - sqrt(max(0, root_term))) / (g * x))
			
		var max_allowed_angle = deg_to_rad(1.0) 
		if not "spear" in gun_name and pitch_angle > max_allowed_angle:
			pitch_angle = deg_to_rad(0.5)
			var new_v = sqrt((g * x * x) / (2 * pow(cos(pitch_angle), 2) * (x * tan(pitch_angle) - y)))
			if is_finite(new_v):
				v = new_v
				actual_force = v * mass
				ai_power = actual_force / impulse_mult
				
		var final_aim_dir = h_dir * cos(pitch_angle)
		final_aim_dir.y = sin(pitch_angle)
		final_aim_dir = final_aim_dir.normalized()
		var launch_impulse = final_aim_dir * actual_force

		# ==========================================
		# 🎯 4. เล็งและลั่นไก! (ทำซ้ำทุกนัด)
		# ==========================================
		if has_node("TrajectoryLine"):
			$TrajectoryLine.show()
			update_trajectory_line(start_pos, launch_impulse, gun_name, gun, true)
			# หน่วงเวลา 1 วินาที ให้เห็นว่าเส้นเล็งทาบตัวใครอยู่
			await get_tree().create_timer(1.0).timeout
			$TrajectoryLine.hide()
			
		# ลั่นไกตรงตามที่วาดเส้นไว้เป๊ะๆ!
		execute_gun_physics(enemy, gun, final_aim_dir, ai_power, false, 0.0, true_target_pos)

		# ⏳ รอนัดต่อไป (หน่วงเวลาให้ AI ดึงสไลด์ปืนแป๊บนึง ก่อนจะวนกลับไปหันหน้าหาคนใหม่)
		if i < shots_to_fire - 1:
			await get_tree().create_timer(0.5).timeout



	
	
	
# ฟังก์ชันสายลุย (เดินเข้าหา / พุ่งชน)
# ฟังก์ชันสายลุย (เดินเข้าหา / พุ่งชน)
func enemy_kamikaze(enemy: Node3D, target: Node3D, can_jump: bool = false):
	if not is_instance_valid(enemy) or not enemy is RigidBody3D: return
	if not is_instance_valid(target) or not target.is_inside_tree() or not enemy.is_inside_tree(): return
	
	# 1. เริ่มเดิน: เปิดสวิตช์ "เชื่อมปืน" และ Freeze ปืนไว้กันหลุด
	enemy.set_meta("is_moving_ai", true)
	enemy.axis_lock_angular_x = true
	enemy.axis_lock_angular_y = true
	enemy.axis_lock_angular_z = true
	enemy.angular_velocity = Vector3.ZERO
	
	if enemy.has_meta("linked_gun"):
		var gun = enemy.get_meta("linked_gun")
		if is_instance_valid(gun) and gun is RigidBody3D:
			gun.freeze = true
			# 🌟 [เพิ่มตรงนี้!] แปะกาวก่อนพุ่งตัวเหมือนกัน
			var local_trans = enemy.global_transform.affine_inverse() * gun.global_transform
			enemy.set_meta("ai_slide_transform", local_trans)
		
	var dist = enemy.global_position.distance_to(target.global_position)
	var dir = (target.global_position - enemy.global_position).normalized()
	
	# หันหน้าเข้าหาเป้าหมาย
	enemy.global_rotation.y = atan2(dir.x, dir.z)
	
	# --- ตัดสินใจ: จะโดด หรือ จะเดิน ---
	# 🌟 [แก้ตรงนี้!] เพิ่มเงื่อนไข can_jump เข้าไปดักไว้
	if can_jump and dist <= 24.0:
		print("💣 ", enemy.name, " พุ่งหลาวแบบกำหนดเวลา (Fast & Accurate!)")
		
		enemy.axis_lock_angular_x = false
		enemy.axis_lock_angular_y = true
		enemy.axis_lock_angular_z = true
		
		# 🌟 1. ตั้งค่า "เวลาที่ต้องการให้ถึงเป้าหมาย" (ยิ่งน้อย ยิ่งพุ่งแรง!)
		# ลองปรับระหว่าง 0.4 (แรงมาก) ถึง 0.7 (กำลังดี) ครับ
		var time_to_reach = 0.5 
		
		# 2. คำนวณความเร็วที่ต้องใช้เพื่อให้ถึงเป้าหมายในเวลาที่กำหนด
		var gravity = abs(ProjectSettings.get_setting("physics/3d/default_gravity"))
		var diff = target.global_position - enemy.global_position
		
		# ความเร็วแนวราบ (XZ)
		var velocity_xz = Vector2(diff.x, diff.z) / time_to_reach
		
		# ความเร็วแนวดิ่ง (Y) เพื่อสู้กับแรงโน้มถ่วงให้ตกพอดีเป๊ะ
		var velocity_y = (diff.y / time_to_reach) + (0.5 * gravity * time_to_reach)
		
		# รวมเป็น Vector แรงพุ่ง
		var launch_velocity = Vector3(velocity_xz.x, velocity_y, velocity_xz.y)
		var enemy_mass = enemy.mass if "mass" in enemy else 1.0
		var final_impulse = launch_velocity * enemy_mass
		
		# 🌟 3. คำนวณมุมโหม่ง (ให้ก้มหน้าตามทิศทางพุ่ง)
		var angle_to_target = atan2(diff.y, Vector2(diff.x, diff.z).length())
		var target_tilt = 1.125 - angle_to_target # ปรับ 1.3 ให้ก้มมาก/น้อยตามใจชอบ
		var rotation_tween = create_tween()
		rotation_tween.tween_property(enemy, "global_rotation:x", clamp(target_tilt, 0.5, 2.0), 0.1)
		
		# 🚀 ลั่นไก! (ใช้แรงพุ่งที่คำนวณมาใหม่)
		enemy.apply_central_impulse(final_impulse)
		
	else:
		# 🚶 ถ้าไม่มีตั๋วให้โดด หรือระยะยังไม่ถึง ให้ "เดิน" ปกติ (ทุกคนที่เหลือจะมาตกที่นี่)
		var move_dir = dir
		move_dir.y = 0.0
		enemy.apply_central_impulse(move_dir.normalized() * 13.0)

	# --- ระบบปลดล็อกหลังเคลื่อนที่เสร็จ (1.5 วินาที) ---
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(enemy):
			enemy.set_meta("is_moving_ai", false) 
			enemy.axis_lock_angular_x = false
			enemy.axis_lock_angular_y = false
			enemy.axis_lock_angular_z = false
			
			if enemy.has_meta("linked_gun"):
				var gun = enemy.get_meta("linked_gun")
				if is_instance_valid(gun) and gun is RigidBody3D:
					gun.freeze = false
	)


# ==========================================
# 🌟 ระบบจำแนกประเภทตัวละครอัตโนมัติ (ฉบับสมบูรณ์!)
# ==========================================
func is_player_char(u_name: String) -> bool:
	var clean_name = u_name.to_lower()
	for data in army_list:
		if data["name"].to_lower() == clean_name:
			return data["category"] == "character"
	return false

func is_enemy_char(u_name: String) -> bool:
	var clean_name = u_name.to_lower()
	for data in army_list:
		if data["name"].to_lower() == clean_name:
			return data["category"] == "enemy_character" # 🌟 เช็คแค่ว่าเป็นคาแรคเตอร์ศัตรูไหม จบเลย!
	return false

# เช็คว่ายูนิตนี้เป็นของศัตรูหรือไม่ (รวมหมดทั้งตัวละคร, ปืน, บล็อก)
func is_enemy_unit(u_name: String) -> bool:
	var clean_name = u_name.to_lower()
	for data in army_list:
		if data["name"].to_lower() == clean_name:
			# 🌟 ถ้าหมวดหมู่ขึ้นต้นด้วยคำว่า enemy_ ถือว่าเป็นของศัตรูทั้งหมด!
			return str(data["category"]).begins_with("enemy")
	return false





# 🌟 ฟังก์ชันสายลับ: ตรวจจับระยะตก เพื่อปรับแรงยิงนัดถัดไป (ปรับแค่แรง ไม่ยุ่งกับเส้นเล็ง)
# 🌟 ฟังก์ชันสายลับ (เวอร์ชันแก้บั๊กเลิกตามกลางคัน)
# 🌟 ฟังก์ชันสายลับ (เวอร์ชันป้องกัน Error: !v.is_finite)
func track_projectile_for_power(shooter: Node3D, projectile: Node3D, target_pos: Vector3):
	if not is_instance_valid(shooter) or not is_instance_valid(projectile): return
	
	var start_pos = shooter.global_position
	# ทิศทางจากคนยิงไปหาเป้าหมาย (แนวระนาบ)
	var shoot_vec = Vector2(target_pos.x - start_pos.x, target_pos.z - start_pos.z)
	var target_h_dist = shoot_vec.length()
	var shoot_dir = shoot_vec.normalized()
	
	await get_tree().create_timer(0.2).timeout
	var last_valid_pos = start_pos
	var safety_timeout = 0
	
	while safety_timeout < 100:
		if is_instance_valid(projectile) and projectile.global_position.is_finite():
			last_valid_pos = projectile.global_position
			if projectile is RigidBody3D and projectile.linear_velocity.length() < 0.4:
				break
		else: break
		safety_timeout += 1
		await get_tree().create_timer(0.05).timeout
	
	if is_instance_valid(projectile): projectile.queue_free()
	if not is_instance_valid(shooter) or last_valid_pos == start_pos: return

	# 🎯 [คำนวณหาระยะตกจริงตามแนวดิ่งของวิถียิง]
	var hit_vec = Vector2(last_valid_pos.x - start_pos.x, last_valid_pos.z - start_pos.z)
	# ใช้ Dot Product เพื่อหาระยะที่โปรเจคลงบนเส้นทางยิง (ไม่สนใจว่าเบี้ยวซ้ายขวาแค่ไหน)
	var final_h_dist = hit_vec.dot(shoot_dir) 
	
	var current_adj = shooter.get_meta("power_adjustment") if shooter.has_meta("power_adjustment") else 1.0
	var tolerance = 2.0 # ระยะยอมรับได้ 2 เมตร
	
	# ถ้าตกสั้นไปหรือยาวไป (ในแนวดิ่งจากกระบอกปืน) ถึงจะปรับแรง
	if abs(final_h_dist - target_h_dist) > tolerance:
		var error_ratio = target_h_dist / max(0.1, final_h_dist)
		var new_adj = (current_adj + (current_adj * error_ratio)) / 2.0
		new_adj = clamp(new_adj, 0.1, 1.0)
		
		shooter.set_meta("power_adjustment", new_adj)
		print("🚀 AI [", shooter.name, "] ระยะตกจริง: ", snapped(final_h_dist, 0.1), "m (เป้า: ", snapped(target_h_dist, 0.1), "m) -> ปรับแรงนัดหน้า: ", snapped(new_adj * 100, 1), "%")
	else:
		print("🎯 ระยะตกอยู่ในเกณฑ์ (ห่างแค่ ", snapped(abs(final_h_dist - target_h_dist), 0.1), "m) ไม่ต้องปรับแรง")







# ==========================================
# 🌟 ฟังก์ชันคำนวณวิถีโค้ง (Projectile Arc Math)
# ==========================================
func calculate_arc_impulse(start_pos: Vector3, end_pos: Vector3, mass: float) -> Vector3:
	var displacement = end_pos - start_pos
	
	# 1. กำหนดเวลาลอยตัว (ยิ่งไกล ยิ่งลอยนาน)
	var time_to_target = max(0.5, displacement.length() / 15.0) 
	var gravity = abs(ProjectSettings.get_setting("physics/3d/default_gravity"))
	
	# 2. คำนวณความเร็วแกนระนาบ (X และ Z) 
	var velocity_xz = Vector3(displacement.x, 0, displacement.z) / time_to_target
	
	# 3. คำนวณความเร็วแกนดิ่ง (Y) + แอบบวกความสูงเผื่อไว้ 1.5 เมตร ให้มันโค้งข้ามหัวบล็อกสวยๆ
	var height_boost = 1.5 
	var velocity_y = ((displacement.y + height_boost) + (0.5 * gravity * time_to_target * time_to_target)) / time_to_target
	
	# 4. รวมเป็นความเร็วทั้งหมด แล้วคูณด้วยน้ำหนักตัว (Mass) เพื่อแปลงเป็นแรง Impulse
	var final_velocity = Vector3(velocity_xz.x, velocity_y, velocity_xz.z)
	return final_velocity * mass

















#========================================================================================================================================================================
#=====================================================เฟส2===================================================================================================================
#========================================================================================================================================================================






















# ==========================================
# 🌟 ฟังก์ชันจัดการระบบลากคลุม (Drag Selection System)
# ==========================================

func _update_selection_box(current_pos: Vector2):
	if not selection_box: return
	# คำนวณขนาดกล่อง (ใช้ min และ abs เพื่อรองรับการลากเมาส์ย้อนกลับไปด้านซ้ายบน)
	selection_box.position = Vector2(min(drag_start_pos.x, current_pos.x), min(drag_start_pos.y, current_pos.y))
	selection_box.size = Vector2(abs(current_pos.x - drag_start_pos.x), abs(current_pos.y - drag_start_pos.y))


func _execute_multi_selection(release_pos: Vector2):
	if drag_start_pos.distance_to(release_pos) < 10.0: return
	var cam = get_viewport().get_camera_3d()
	if not cam: return
	
	var rect_pos = drag_start_pos
	var rect_size = Vector2.ZERO
	if selection_box:
		rect_pos = selection_box.position
		rect_size = selection_box.size
	else:
		rect_pos = Vector2(min(drag_start_pos.x, release_pos.x), min(drag_start_pos.y, release_pos.y))
		rect_size = Vector2(abs(release_pos.x - drag_start_pos.x), abs(release_pos.y - drag_start_pos.y))
	
	var selection_rect = Rect2(rect_pos, rect_size)
	
	for unit in occupied_tiles.values():
		if is_instance_valid(unit):
			var screen_pos = cam.unproject_position(unit.global_position)
			if cam.is_position_behind(unit.global_position): continue
			
			if selection_rect.has_point(screen_pos):
				# ==========================================
				# 🛡️ ระบบรักษาความปลอดภัย: เช็คศัตรู & Dev Mode
				# ==========================================
				var u_name = unit.get("unit_name").to_lower() if unit.get("unit_name") != null else unit.name.to_lower()
				
				# ถ้าเป็นยูนิตศัตรู และ "ไม่ได้" เปิด Dev Mode อยู่ -> ให้ข้ามไปเลย ห้ามเลือก!
				if is_enemy_unit(u_name) and not is_dev_mode:
					continue 
				# ==========================================

				multi_selected_units.append(unit)
				set_unit_preview_color(unit, Color(0.0, 1.0, 1.0, 0.502)) 
				
	print("📦 ลากคลุมสำเร็จ! เลือกไปทั้งหมด ", multi_selected_units.size(), " ยูนิต")
	
	# 🌟 ถ้าจับยูนิตได้มากกว่า 0 ตัว ให้โชว์เมนู Multi-Action
	if multi_selected_units.size() > 0:
		selected_unit = null
		if action_menu: action_menu.hide()
		
		if multi_action_menu:
			multi_action_menu.show()


func _clear_multi_selection():
	for unit in multi_selected_units:
		if is_instance_valid(unit):
			set_unit_preview_color(unit, Color(1, 1, 1, 1)) 
	multi_selected_units.clear()
	
	# ปิดเมนูตอนเคลียร์การเลือก
	if multi_action_menu: multi_action_menu.hide()





#=============================================================================
func _on_btn_multi_rotate_pressed():
	# ==========================================
	# 🌟 1. หมุนของที่ "กำลังลอยติดเมาส์" ( Blueprint / Copy )
	# ==========================================
	if dragging_multi_units.size() > 0:
		for i in range(dragging_multi_units.size()):
			var clone = dragging_multi_units[i]
			var old_offset = multi_drag_offsets[i]
			
			var new_offset = Vector3(old_offset.z, old_offset.y, -old_offset.x)
			multi_drag_offsets[i] = new_offset
			
			if is_instance_valid(clone):
				clone.rotation_degrees.y -= 90 
				
		last_drag_grid_pos = Vector3.INF 
		print("🔄 หมุนพิมพ์เขียว/ของก๊อปปี้ สำเร็จ!")
		return 


	# ==========================================
	# 🌟 2. หมุนของที่ "วางอยู่บนพื้นแล้ว" (รวมแก้บั๊กเขตแดนศัตรู)
	# ==========================================
	if multi_selected_units.size() == 0: return
	
	print("🔄 กำลังหมุนกลุ่มยูนิตบนพื้น...")
	
	var center_pos = Vector3.ZERO
	var valid_count = 0
	for u in multi_selected_units:
		if is_instance_valid(u):
			center_pos += u.global_position
			valid_count += 1
			
	if valid_count == 0: return
	center_pos /= valid_count
	
	var old_transforms = {}
	var old_keys = {}
	
	for u in multi_selected_units:
		if is_instance_valid(u):
			old_transforms[u] = u.global_transform
			old_keys[u] = u.tile_key
			if occupied_tiles.has(u.tile_key):
				occupied_tiles.erase(u.tile_key)
				
	var angle = deg_to_rad(90)
	var all_safe = true
	
	for u in multi_selected_units:
		if is_instance_valid(u):
			var offset = u.global_position - center_pos
			var rotated_offset = offset.rotated(Vector3.UP, angle)
			
			u.global_position = center_pos + rotated_offset
			u.global_position.x = snapped(u.global_position.x, snap_step)
			u.global_position.z = snapped(u.global_position.z, snap_step)
			
			u.global_rotate(Vector3.UP, angle)
			u.rotation_degrees = u.rotation_degrees.snapped(Vector3(90, 90, 90))
			u.force_update_transform()
			
			# ==========================================
			# 🌟 [แก้บั๊ก] ดักเช็คว่าเป็นศัตรูไหม จะได้ให้ทะลุเขตแดนได้!
			# ==========================================
			var is_enemy = false
			var u_name = u.get("unit_name").to_lower() if u.get("unit_name") != null else u.name.to_lower()
			for data in army_list:
				if data["name"].to_lower() == u_name:
					if str(data["category"]).begins_with("enemy"):
						is_enemy = true
					break
					
			var within_bounds = true
			if not is_enemy:
				within_bounds = is_within_boundary(u.global_position)
			# ==========================================
			
			# เช็คความปลอดภัย
			if not is_position_safe(u.global_position, u) or not within_bounds:
				all_safe = false
				break
				
	if all_safe:
		print("✅ หมุนกลุ่มบนพื้นสำเร็จ!")
		for u in multi_selected_units:
			if is_instance_valid(u):
				u.tile_key = get_tile_key(u.global_position)
				occupied_tiles[u.tile_key] = u 
	else:
		print("❌ หมุนไม่ได้ ติดสิ่งกีดขวาง! ย้อนกลับท่าเดิม")
		if error_sound_player: error_sound_player.play()
		for u in multi_selected_units:
			if is_instance_valid(u):
				u.global_transform = old_transforms[u] 
				occupied_tiles[old_keys[u]] = u 
				flash_red_effect(u)
#=============================================================================
func _on_btn_multi_delete_pressed():
	print("🗑️ กำลังลบยูนิตที่เลือกทั้งหมด...")
	
	# 🌟 สมุดบัญชีจดรายชื่อคนที่รับเงินคืนไปแล้ว (ป้องกันการคืนเงินซ้ำซ้อน)
	var processed_nodes = [] 
	
	for unit in multi_selected_units:
		# ถ้าตัวนี้พังไปแล้ว หรือรับเงินคืนไปแล้ว ให้ข้ามคิวไปเลย!
		if not is_instance_valid(unit) or unit in processed_nodes: 
			continue
			
		processed_nodes.append(unit) # จดชื่อลงสมุดว่าคนนี้รับเงินแล้ว
		
		# 1. หาชื่อเพื่อไปดึงราคาจริง
		var u_name = unit.get("unit_name").to_lower() if unit.get("unit_name") != null else unit.name.to_lower()
		var is_selected_enemy = false
		
		# 🌟 [แก้ตรงนี้!] ดึงค่า Cost และ HP จากโมเดลที่กำลังจะลบโดยตรง
		var true_cost = unit.get("energy_cost") if unit.get("energy_cost") != null else 1.0
		var true_hp = unit.get("hp_gain_on_place") if unit.get("hp_gain_on_place") != null else 0
		
		for data in army_list:
			if data["name"].to_lower() == u_name:
				is_selected_enemy = str(data["category"]).begins_with("enemy")
				break
				
		# --- 2. จัดการปืนที่ติดมากับตัวละคร ---
		if unit.has_meta("linked_gun"):
			var attached_gun = unit.get_meta("linked_gun")
			
			# 🌟 เช็คก่อนว่าปืนกระบอกนี้ รับเงินคืนไปหรือยัง?
			if is_instance_valid(attached_gun) and not attached_gun in processed_nodes:
				processed_nodes.append(attached_gun) # จดชื่อปืนลงสมุดด้วย!
				
				var g_name = attached_gun.get("unit_name").to_lower() if attached_gun.get("unit_name") != null else attached_gun.name.to_lower()
				var is_gun_enemy = false
				
				# 🌟 [แก้ตรงนี้!] ดึงค่า Cost และ HP จากโมเดลปืนโดยตรง
				var gun_cost = attached_gun.get("energy_cost") if attached_gun.get("energy_cost") != null else 2.0
				var gun_hp = attached_gun.get("hp_gain_on_place") if attached_gun.get("hp_gain_on_place") != null else 0
				
				for data in army_list:
					if data["name"].to_lower() == g_name:
						is_gun_enemy = str(data["category"]).begins_with("enemy")
						break
						
				if is_gun_enemy:
					total_enemy_energy_used -= gun_cost
					total_enemy_hp -= gun_hp
				else:
					current_energy += gun_cost
					total_hp -= gun_hp
					
				if occupied_tiles.has(attached_gun.tile_key):
					occupied_tiles.erase(attached_gun.tile_key)
				attached_gun.queue_free()
				
		# --- 3. จัดการเคลียร์ปืน (ถ้าตัวที่โดนลบคือปืนซะเอง) ---
		if unit.has_meta("linked_char"):
			var owner_char = unit.get_meta("linked_char")
			if is_instance_valid(owner_char):
				owner_char.set_meta("linked_gun", null)
				
		# --- 4. คืนเงินตัวหลัก และลบออกจาก Grid ---
		if is_selected_enemy:
			total_enemy_energy_used -= true_cost
			total_enemy_hp -= true_hp
		else:
			current_energy += true_cost
			total_hp -= true_hp
			
		if occupied_tiles.has(unit.tile_key):
			occupied_tiles.erase(unit.tile_key)
			
		unit.queue_free()
		
	# ล้างขยะและเคลียร์สมุดบัญชี
	multi_selected_units.clear()
	processed_nodes.clear()
	
	# ไม้ตายกันทะลุหลอด
	if current_energy > max_energy:
		current_energy = max_energy
		
	if multi_action_menu: multi_action_menu.hide()
	update_ui()
	print("✅ ลบยกแผงและคืน Energy เรียบร้อย! (สมดุลบัญชีถูกต้อง 100%)")
#=============================================================================
func _on_btn_multi_copy_pressed():
	if multi_selected_units.size() == 0: return
	
	var player_cost = 0.0
	var enemy_cost = 0.0
	var valid_units = []
	
	# 🌟 [เพิ่มใหม่] สมุดจดโควต้า (นับว่ากำลังจะก๊อปตัวที่มีลิมิตไปกี่ตัวแล้ว)
	var unit_spawn_tracker = {}
	
	# 1. คำนวณราคาและหาข้อมูลต้นฉบับ
	for unit in multi_selected_units:
		if not is_instance_valid(unit): continue
		var u_name = unit.get("unit_name").to_lower() if unit.get("unit_name") != null else unit.name.to_lower()
		
		# 🌟 ดักจับอาวุธที่ติดอยู่กับฮีโร่ (ถ้าฮีโร่มีลิมิต ปืนก็ห้ามก๊อปไปด้วย)
		if unit.has_meta("linked_char"):
			var owner_char = unit.get_meta("linked_char")
			if is_instance_valid(owner_char):
				var owner_name = owner_char.get("unit_name").to_lower() if owner_char.get("unit_name") != null else owner_char.name.to_lower()
				var owner_limit = -1
				for d in army_list:
					if d["name"].to_lower() == owner_name:
						owner_limit = d.get("max_count", -1)
						break
				if owner_limit != -1:
					print("🚫 ข้ามการก๊อปปี้อาวุธประจำตัวของยูนิตจำกัดจำนวน")
					continue
					
		var target_data = null
		for data in army_list:
			if data["name"].to_lower() == u_name:
				target_data = data
				break
				
		if target_data != null:
			# 🌟 [ระบบจำกัดโควต้าอัจฉริยะ] รองรับยูนิตในอนาคตทุกตัว!
			var max_c = target_data.get("max_count", -1)
			if max_c != -1:
				var current_field_count = get_unit_count_on_field(target_data["name"])
				var currently_adding = unit_spawn_tracker.get(target_data["name"], 0)
				
				# ถ้ารวมของเก่าบนฟิลด์ + ของใหม่ที่เพิ่งลากเข้ากลุ่ม แล้วมันเกินแม็กซ์ = ข้าม!
				if (current_field_count + currently_adding) >= max_c:
					print("🚫 ข้ามการก๊อปปี้ ", u_name, " เพราะถึงขีดจำกัดแล้ว (Max: ", max_c, ")")
					continue
				else:
					unit_spawn_tracker[target_data["name"]] = currently_adding + 1
					
			# แยกบิลเงินล่วงหน้า
			if str(target_data["category"]).begins_with("enemy"):
				enemy_cost += target_data.get("cost", 0.0)
			else:
				player_cost += target_data.get("cost", 0.0)
				
			valid_units.append({"unit": unit, "data": target_data})
			
	# 2. 🌟 เช็คบิลว่าเงิน "ผู้เล่น" พอซื้อของ "ฝั่งผู้เล่น" ไหม? (ของศัตรูก๊อปฟรีไม่สนเงินเรา!)
	if current_energy >= player_cost:
		multi_action_menu.hide()
		
		if dragging_multi_units.size() > 0:
			for old in dragging_multi_units:
				if is_instance_valid(old): old.queue_free()
		if dragging_unit and is_instance_valid(dragging_unit):
			dragging_unit.queue_free()
		
		# 1. หาจุดศูนย์กลาง และหา "จุดที่ต่ำที่สุด" 
		var center_pos = Vector3.ZERO
		var min_aabb_y = 99999.0 # 🌟 เรดาร์ความสูง
		
		if valid_units.size() == 0:
			_clear_multi_selection()
			return 
			
		for item in valid_units:
			var u = item["unit"]
			center_pos += Vector3(u.global_position.x, 0.0, u.global_position.z)
			var aabb = get_unit_global_aabb(u.global_position, u.global_transform.basis, u, true)
			if aabb.position.y < min_aabb_y:
				min_aabb_y = aabb.position.y
			
		center_pos /= valid_units.size()
		center_pos = Vector3(snapped(center_pos.x, snap_step), 0.0, snapped(center_pos.z, snap_step))
		
		dragging_multi_units.clear()
		multi_drag_offsets.clear()
		
		# 3. สร้างของโคลนนิ่ง
		for item in valid_units:
			var orig_unit = item["unit"]
			var new_unit = item["data"]["scene"].instantiate()
			
			new_unit.set_meta("orig_unit", orig_unit)
			add_child(new_unit)
			
			new_unit.global_transform.basis = orig_unit.global_transform.basis
			
			var offset = orig_unit.global_position - center_pos
			# 🌟 ล็อกร่างโคลนคนที่อยู่ล่างสุด ให้ติดพื้นเสมอ!
			offset.y = orig_unit.global_position.y - min_aabb_y 
			
			multi_drag_offsets.append(offset)
			dragging_multi_units.append(new_unit)
			
			toggle_collision(new_unit, true)
			set_unit_preview_color(new_unit, Color(0.0, 1.0, 1.0, 0.502))
			
		_clear_multi_selection()
		print("📦 เตรียมก๊อปปี้! บิลผู้เล่น: ", player_cost, " | บิลศัตรู: ", enemy_cost)
	else:
		if error_sound_player: error_sound_player.play()
		for unit in multi_selected_units:
			if is_instance_valid(unit):
				flash_red_effect(unit)
		print("❌ Energy ไม่พอก๊อปปี้ยูนิตฝ่ายเรา! ขาดอีก: ", player_cost - current_energy)

#=============================================================================
func _on_btn_multi_save_pressed():
	if multi_selected_units.size() == 0:
		print("❌ ไม่มีอะไรให้เซฟ! กรุณาลากคลุมยูนิตก่อน")
		return
		
	# ==========================================
	# 🌟 1. คัดกรองยูนิต (ผู้เล่นเซฟได้แค่ Block และ Shield / Dev เซฟได้หมด)
	# ==========================================
	var valid_blueprint_units = []
	
	for unit in multi_selected_units:
		if not is_instance_valid(unit): continue
		
		var u_name = unit.get("unit_name").to_lower() if unit.get("unit_name") != null else unit.name.to_lower()
		var u_cat = ""
		
		# ค้นหาหมวดหมู่ของยูนิตนี้จาก army_list
		for data in army_list:
			if data["name"].to_lower() == u_name:
				u_cat = str(data.get("category")).to_lower()
				break
				
		# 🎯 เงื่อนไข: ถ้าเปิด Dev Mode (เซฟผ่านหมด) 
		# หรือ ถ้าไม่ใช่ Dev Mode ก็ต้องเป็นหมวด "block" หรือ "shield" เท่านั้น
		if is_dev_mode or u_cat == "block" or u_cat == "shield":
			valid_blueprint_units.append(unit)
		else:
			# ตัวไหนไม่ผ่านเงื่อนไข ให้กระพริบสีแดงเตือนผู้เล่น และข้ามไป
			flash_red_effect(unit)
			print("🚫 ข้ามการเซฟ: ", u_name, " (อนุญาตแค่โครงสร้าง Block และ Shield)")
			
	# ถ้าคัดไปคัดมา แล้วไม่เหลืออะไรให้เซฟเลย (เช่น ลากคลุมแต่ตัวละคร)
	if valid_blueprint_units.size() == 0:
		if has_node("ErrorSoundPlayer"): $ErrorSoundPlayer.play()
		print("❌ ไม่มีบล็อกหรือโล่ในกลุ่มที่เลือกเลย! ยกเลิกการเซฟพิมพ์เขียว")
		return

	# ==========================================
	# 🌟 2. หาจุดศูนย์กลางของกลุ่ม (คำนวณเฉพาะตัวที่ผ่านการคัดกรองแล้ว)
	# ==========================================
	var center_pos = Vector3.ZERO
	for u in valid_blueprint_units:
		center_pos += u.global_position
	center_pos /= valid_blueprint_units.size()
	center_pos = Vector3(snapped(center_pos.x, snap_step), 0, snapped(center_pos.z, snap_step))
	
	# 🌟 3. จำข้อมูลเอาไว้ก่อน รอผู้เล่นพิมพ์ชื่อ (ใช้ข้อมูลที่กรองแล้ว!)
	pending_blueprint_units = valid_blueprint_units.duplicate()
	pending_blueprint_center = center_pos
	
	# 🌟 4. โชว์ Popup ถามชื่อ
	if multi_action_menu: multi_action_menu.hide()
	if blueprint_save_ui:
		blueprint_input_name.text = "" 
		blueprint_save_ui.show()
		blueprint_input_name.grab_focus()





func _start_multi_drag_from_world():
	# จำลองการกดปุ่ม Copy เพื่อเริ่มโหมดลากกลุ่ม
	_on_btn_multi_copy_pressed()
	# ซ่อนเมนูไปเลยเพราะเราเริ่มลากแล้ว
	if multi_action_menu: multi_action_menu.hide()


func get_unit_under_mouse() -> Node3D:
	var pos = get_ground_position()
	var key = get_tile_key(pos)
	if occupied_tiles.has(key):
		return occupied_tiles[key]
	return null





func _start_multi_move_from_world():
	if multi_selected_units.size() == 0: return
	
	print("🚚 เริ่มลากย้ายกลุ่มยูนิต (ฟรี! ไม่เสีย Energy)")
	
	# 1. หาจุดศูนย์กลาง และหา "จุดที่ต่ำที่สุด (AABB)" ของกลุ่ม
	var center_pos = Vector3.ZERO
	var min_aabb_y = 99999.0 # 🌟 สร้างตัวแปรดักจับความสูง
	
	for u in multi_selected_units:
		if is_instance_valid(u):
			center_pos += Vector3(u.global_position.x, 0.0, u.global_position.z)
			
			# 🌟 ใช้เรดาร์ AABB หาจุดต่ำสุดของโมเดล (กันตัวจมดิน)
			var aabb = get_unit_global_aabb(u.global_position, u.global_transform.basis, u, true)
			if aabb.position.y < min_aabb_y:
				min_aabb_y = aabb.position.y
				
	center_pos /= multi_selected_units.size()
	center_pos = Vector3(snapped(center_pos.x, snap_step), 0.0, snapped(center_pos.z, snap_step))
	
	multi_drag_cost = 0.0 
	multi_drag_hp = 0
	dragging_multi_units.clear()
	multi_drag_offsets.clear()
	
	# 2. ถอนรากถอนโคนของทุกตัวในกลุ่มให้มาลอยติดเมาส์
	for unit in multi_selected_units:
		if is_instance_valid(unit):
			if occupied_tiles.has(unit.tile_key):
				occupied_tiles.erase(unit.tile_key)
				
			var offset = unit.global_position - center_pos
			# 🌟 พระเอกอยู่ตรงนี้! เซ็ตให้คนต่ำสุดมีค่า offset Y เป็นศูนย์ (แตะพื้นเสมอ)
			offset.y = unit.global_position.y - min_aabb_y 
			
			multi_drag_offsets.append(offset)
			dragging_multi_units.append(unit)
			
			toggle_collision(unit, true) 
			set_unit_preview_color(unit, Color(0.0, 1.0, 1.0, 0.502)) 
			
	multi_selected_units.clear()
	if multi_action_menu: multi_action_menu.hide()








func _on_blueprint_cancel_save_pressed():
	blueprint_save_ui.hide()
	pending_blueprint_units.clear()
	print("❌ ยกเลิกการบันทึก Blueprint")



func _on_blueprint_confirm_save_pressed():
	var file_name = blueprint_input_name.text.strip_edges()
	
	# ดักกันคนไม่พิมพ์ชื่อ หรือพิมพ์อักขระแปลกๆ
	if file_name == "":
		file_name = "blueprint_unnamed"
		
	# แทนที่ช่องว่างด้วย _ เพื่อความปลอดภัยของระบบไฟล์
	file_name = file_name.replace(" ", "_")
	
	print("💾 เริ่มกระบวนการบันทึก Blueprint ชื่อ: ", file_name)
	
	var blueprint_root = Node3D.new()
	blueprint_root.name = "BlueprintRoot"
	
	for unit in pending_blueprint_units:
		if not is_instance_valid(unit): continue
		
		var u_name = unit.get("unit_name").to_lower() if unit.get("unit_name") != null else unit.name.to_lower()
		var target_data = null
		for data in army_list:
			if data["name"].to_lower() == u_name:
				target_data = data
				break
				
		if target_data:
			var clone = target_data["scene"].instantiate()
			blueprint_root.add_child(clone)
			
			clone.position = unit.global_position - pending_blueprint_center
			clone.transform.basis = unit.global_transform.basis 
			clone.owner = blueprint_root 
			
	var path = "user://blueprints"
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)
		
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(blueprint_root)
	
	if result == OK:
		var final_path = path + "/" + file_name + ".tscn"
		var save_err = ResourceSaver.save(packed_scene, final_path)
		
		if save_err == OK:
			print("✅ บันทึกสำเร็จ! ไฟล์อยู่ที่: ", final_path)
			for u in pending_blueprint_units:
				if is_instance_valid(u):
					set_unit_preview_color(u, Color(0, 1, 1, 1))
		else:
			print("❌ เซฟไฟล์ล้มเหลว: ", save_err)
	else:
		print("❌ แพ็ก Scene ล้มเหลว: ", result)
		
	blueprint_root.queue_free()
	blueprint_save_ui.hide()
	pending_blueprint_units.clear()











func _on_btn_open_library_pressed():
	if blueprint_library_ui:
		blueprint_library_ui.show()
		refresh_blueprint_list() # สั่งรีเฟรชรายชื่อทุกครั้งที่เปิดหน้าต่าง

func _on_btn_close_library_pressed():
	if blueprint_library_ui:
		blueprint_library_ui.hide()

func refresh_blueprint_list():
	# 1. ล้างปุ่มเก่าๆ ทิ้งให้หมดก่อน
	for child in blueprint_list.get_children():
		child.queue_free()
		
	var path = "user://blueprints"
	
	# 2. เช็คว่ามีโฟลเดอร์ไหม ถ้าไม่มีแปลว่ายังไม่เคยเซฟอะไรเลย ให้จบการทำงาน
	if not DirAccess.dir_exists_absolute(path):
		print("📂 ยังไม่มีโฟลเดอร์พิมพ์เขียว")
		return
		
	# 3. เปิดโฟลเดอร์และสแกนหาไฟล์
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var found_files = 0
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				found_files += 1
				
				# 4. เสกปุ่มรายชื่อขึ้นมา
				var btn = Button.new()
				btn.text = file_name.replace(".tscn", "") # ตัดนามสกุลไฟล์ออกให้ดูสวยๆ
				btn.custom_minimum_size = Vector2(0, 40) # ตั้งความสูงปุ่มหน่อย จะได้กดง่าย
				
				# 🌟 เพิ่ม 2 บรรทัดนี้เข้าไปครับ!
				btn.add_theme_font_size_override("font_size", 16) # บังคับขนาดฟอนต์ (เปลี่ยนเลข 18 เล็กใหญ่ได้ตามชอบเลยครับ)
				btn.clip_text = true # กันเหนียว เผื่อชื่อยาวเกินไป มันจะได้ไม่ล้นทะลุกรอบปุ่ม
				
				# 🌟 ผูกปุ่มนี้เข้ากับฟังก์ชัน เตรียมไว้สำหรับการคลิกเพื่อ "โหลดไปวาง"
				btn.pressed.connect(_on_blueprint_item_selected.bind(file_name))
				
				# 🌟 [เพิ่มใหม่] ผูกปุ่มเข้ากับฟังก์ชัน (คลิกขวา = เปิดเมนูย่อย Rename/Delete)
				btn.gui_input.connect(_on_blueprint_gui_input.bind(file_name))
				
				blueprint_list.add_child(btn)
				
			file_name = dir.get_next()
			
		dir.list_dir_end()
		print("📂 ค้นพบพิมพ์เขียวทั้งหมด: ", found_files, " ไฟล์")
	else:
		print("❌ เปิดโฟลเดอร์ Blueprint ไม่สำเร็จ!")







func _on_blueprint_item_selected(file_name: String):
	print("🎯 กำลังโหลดพิมพ์เขียว: ", file_name)
	blueprint_library_ui.hide() # ปิดหน้าต่างคลัง
	
	var path = "user://blueprints/" + file_name
	if not ResourceLoader.exists(path):
		print("❌ ไม่พบไฟล์: ", path)
		return
		
	# 1. โหลดไฟล์ขึ้นมา
	var packed_scene = ResourceLoader.load(path)
	if not packed_scene:
		print("❌ โหลดไฟล์ไม่สำเร็จ")
		return
		
	# 2. เสกออกมาเป็นตัวตนชั่วคราวก่อน (เพื่อสแกนและคิดเงิน)
	var blueprint_root = packed_scene.instantiate()
	get_tree().current_scene.add_child(blueprint_root) 
	
	var player_cost = 0.0
	var player_hp = 0
	var enemy_cost = 0.0
	var valid_clones = []
	
	# 🌟 [เพิ่มใหม่] สมุดจดโควต้าเหมือนตอนก๊อปปี้
	var unit_spawn_tracker = {}
	
	# 3. สแกนลูกสมุนในพิมพ์เขียว 
	for child in blueprint_root.get_children():
		var u_name = child.get("unit_name").to_lower() if child.get("unit_name") != null else child.name.to_lower()
		var target_data = null
		
		for data in army_list:
			if data["name"].to_lower() == u_name:
				target_data = data
				break
				
		if target_data:
			# 🌟 [ระบบจำกัดโควต้าอัจฉริยะ]
			var max_c = target_data.get("max_count", -1)
			if max_c != -1:
				var current_field_count = get_unit_count_on_field(target_data["name"])
				var currently_adding = unit_spawn_tracker.get(target_data["name"], 0)
				
				if (current_field_count + currently_adding) >= max_c:
					print("🚫 ตัด ", u_name, " ออกจากพิมพ์เขียว! (เกินโควต้า Max: ", max_c, ")")
					child.queue_free() # เตะทิ้งออกไปเลย จะได้ไม่ลอยมาเกะกะ
					continue
				else:
					unit_spawn_tracker[target_data["name"]] = currently_adding + 1
					
			# แยกบิล
			if str(target_data["category"]).begins_with("enemy"):
				enemy_cost += target_data.get("cost", 0.0)
			else:
				player_cost += target_data.get("cost", 0.0)
				player_hp += target_data.get("hp_gain", 0)
				
			valid_clones.append({"node": child, "data": target_data})
			
	# 4. เช็คบิลว่าเงินฝั่งผู้เล่นพอไหม? (ศัตรูโหลดฟรี)
	if current_energy >= player_cost:
		# ล้างของเก่าที่ติดเมาส์อยู่ (ถ้ามี)
		if dragging_multi_units.size() > 0:
			for old in dragging_multi_units:
				if is_instance_valid(old): old.queue_free()
		if dragging_unit and is_instance_valid(dragging_unit):
			dragging_unit.queue_free()
			
		# ตั้งค่าระบบตัวแปรลากกลุ่ม
		multi_drag_cost = player_cost
		multi_drag_hp = player_hp
		dragging_multi_units.clear()
		multi_drag_offsets.clear()
		
		# 5. ถอดลูกๆ ออกจากราก แล้วเอามาแปะติดเมาส์
		for item in valid_clones:
			var clone = item["node"]
			var offset = clone.position # ตำแหน่งนี้คือระยะห่างที่มันจำไว้ตอนเราเซฟ!
			
			clone.reparent(get_tree().current_scene) # ย้ายมาอยู่โลกหลัก
			
			# 🌟 [เพิ่มบรรทัดนี้!] แปะป้ายบอกว่าตัวนี้ดึงมาจากพิมพ์เขียวนะ!
			clone.set_meta("from_blueprint", true) 
			
			multi_drag_offsets.append(offset)
			dragging_multi_units.append(clone)
			
			toggle_collision(clone, true) 
			set_unit_preview_color(clone, Color(0.0, 1.0, 1.0, 0.502)) # ทำสีฟ้าโปร่งแสง
			
		blueprint_root.queue_free() # ลบรากที่ว่างเปล่าทิ้ง
		print("📦 โหลดเสร็จสิ้น! ของลอยติดเมาส์แล้ว | บิลผู้เล่น: ", player_cost, " บิลศัตรู: ", enemy_cost)
	else:
		if error_sound_player: error_sound_player.play()
		blueprint_root.queue_free() # เงินไม่พอ ลบพิมพ์เขียวที่แอบเสกมาทิ้ง
		print("❌ Energy ไม่พอสร้างพิมพ์เขียวนี้! ขาดอีก: ", player_cost - current_energy)










# ==========================================
# 🌟 ฟังก์ชันระบบจัดการพิมพ์เขียว (คลิกขวา)
# ==========================================

# 1. เมื่อคลิกขวาที่ชื่อไฟล์ในคลัง
func _on_blueprint_gui_input(event: InputEvent, file_name: String):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		item_to_manage = file_name
		
		# วาร์ปเมนูไปที่ตำแหน่งเมาส์ปัจจุบันบนจอ!
		blueprint_context_menu.global_position = get_viewport().get_mouse_position()
		
		blueprint_context_menu.show()
		delete_confirm_ui.hide() # ปิดหน้าต่างลบไว้ก่อน (เผื่อเปิดค้างไว้จากรอบที่แล้ว)


# 2. เมื่อกดปุ่ม "เปลี่ยนชื่อ" ในเมนูเล็ก
func _on_btn_menu_rename_pressed():
	blueprint_context_menu.hide() # ปิดเมนูคลิกขวา
	rename_input.text = item_to_manage.replace(".tscn", "")
	rename_popup.show() # เปิดหน้าต่างเปลี่ยนชื่อตรงกลางจอ
	rename_input.grab_focus()


# 3. เมื่อกดปุ่ม "Delete" ในเมนูเล็ก
func _on_btn_menu_delete_pressed():
	blueprint_context_menu.hide() # คราวนี้ปิดเมนูได้แล้ว!
	delete_confirm_ui.global_position = get_viewport().get_mouse_position() # วาร์ปหน้าต่างถามลบมาตรงเมาส์
	delete_confirm_ui.show()


# 4. เมื่อกดปุ่ม "Yes" ยืนยันการลบ
func _on_delete_confirmed():
	var path = "user://blueprints/" + item_to_manage
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("🗑️ ลบไฟล์เรียบร้อย: ", item_to_manage)
		delete_confirm_ui.hide()      # 🌟 [เพิ่มตรงนี้!] สั่งปิดหน้าต่างถาม Yes/No
		blueprint_context_menu.hide() # ปิดเมนูทั้งหมดทิ้ง
		refresh_blueprint_list()


# 5. เมื่อกดปุ่ม "Confirm" ยืนยันการเปลี่ยนชื่อ
func _on_confirm_rename_pressed():
	var new_name = rename_input.text.strip_edges().replace(" ", "_")
	if new_name == "": return
	
	var old_path = "user://blueprints/" + item_to_manage
	var new_path = "user://blueprints/" + new_name + ".tscn"
	
	if FileAccess.file_exists(new_path):
		print("❌ ชื่อนี้มีอยู่แล้ว!")
		return
		
	var dir = DirAccess.open("user://blueprints")
	if dir:
		dir.rename(item_to_manage, new_name + ".tscn")
		print("📝 เปลี่ยนชื่อสำเร็จ: ", new_name)
		rename_popup.hide()
		refresh_blueprint_list()


















# ========================================================================================================================================================================
# 🎯 ระบบ Snap & Walk (Phase 1: Auto-Aim & UI)
# ========================================================================================================================================================================

func select_unit_for_combat(unit: Node3D):
	if not is_game_started or unit.is_dead: return
	
	active_combat_unit = unit
	
	# ==========================================
	# 🌟 1. จำท่าทางเดิมเอาไว้ (เพื่อที่พอยกเลิก จะได้หันกลับมาท่านี้เป๊ะๆ!)
	# ==========================================
	initial_aim_rotation = unit.rotation.y
	if unit.has_meta("linked_gun"):
		var gun = unit.get_meta("linked_gun")
		if is_instance_valid(gun):
			initial_gun_rotation = gun.global_rotation.y
	# ==========================================
	
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_rig = cam.get_parent().get_parent().get_parent()
		
		# 🌟 2. ดักเซฟค่ากล้อง RTS (ดึงกล้องกลับจะได้ไม่คอหัก)
		if cam_rig.get("ots_unit") == null:
			saved_rig_pos = cam_rig.global_position
			saved_rig_rot = cam_rig.global_rotation
			saved_zoom = cam.position.z 
			if "pitch_target" in cam_rig:
				original_cam_tilt = cam_rig.pitch_target
				
		# 🌟 3. สั่งซูมกล้องเข้าตัวละคร
		if cam_rig.has_method("set_ots_mode"):
			var target_for_camera = unit
			if unit.has_meta("linked_gun"):
				var attached_gun = unit.get_meta("linked_gun")
				if is_instance_valid(attached_gun):
					if unit.has_meta("cam_dummy"):
						var old_dummy = unit.get_meta("cam_dummy")
						if is_instance_valid(old_dummy): old_dummy.queue_free()
						
					var dummy = Node3D.new()
					unit.add_child(dummy)
					dummy.global_position = attached_gun.global_position
					dummy.global_rotation = unit.global_rotation
					target_for_camera = dummy
					unit.set_meta("cam_dummy", dummy)
					
			cam_rig.set_ots_mode(target_for_camera)
			# 🌟 [เพิ่ม 2 บรรทัดนี้ต่อท้าย!] เพื่อให้คลิกตัวละครปุ๊บ กล้องดึงกลับมาระยะยิงปกติทันที
			if "pitch_target" in cam_rig: cam_rig.pitch_target = 25.0
			if "zoom_target" in cam_rig: cam_rig.zoom_target = 4.5

	# 4. โชว์เมนู UI
	if combat_menu:
		combat_menu.show()










# ==========================================
# 🔵 ปุ่ม Snap (เตรียมpeek)
# ==========================================
func _on_btn_combat_snap_pressed():
	if not is_instance_valid(selected_unit): return
	print("🔀 เข้าสู่โหมดตั้งค่าจุดยัก (Snap Setup)...")
	
	if combat_menu: combat_menu.hide()
	
	active_combat_unit = selected_unit
	is_combat_aiming = true
	combat_action_mode = "snap_setup" 
	
	draw_snap_grid(active_combat_unit.global_position, 7.0)
	
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_rig = cam.get_parent().get_parent().get_parent()
		if cam_rig.has_method("set_ots_mode"):
			if active_combat_unit.has_meta("cam_dummy"):
				var old = active_combat_unit.get_meta("cam_dummy")
				if is_instance_valid(old): old.queue_free()
				
			var dummy = Node3D.new()
			active_combat_unit.add_child(dummy)
			
			# 🌟 [แก้ตรงนี้!] วางจุดศูนย์กลางไว้ที่เท้าตัวละครเป๊ะๆ เลย กลางหัวแน่นอน!
			dummy.position = Vector3.ZERO 
			
			active_combat_unit.set_meta("cam_dummy", dummy)
			cam_rig.set_ots_mode(dummy)
			
			# 🌟 ก้มหน้าจอ -85 องศา แล้วซูมถอยออกมาให้เห็นมุมกว้าง (ถ้า 20 ไกลไป ปรับเหลือ 15 ได้ครับ)
			if "pitch_target" in cam_rig: cam_rig.pitch_target = 5.0 
			if "zoom_target" in cam_rig: cam_rig.zoom_target = 10.0







# ==========================================
# 🟢 ปุ่ม Walk (เตรียมเดิน)
# ==========================================
func _on_btn_combat_walk_pressed():
	if not is_instance_valid(selected_unit): return
	
	# 🌟 [เพิ่มบรรทัดนี้!] เปิดโชว์ตารางสีฟ้า (บอกเขตแดน)
	if has_node("GridVisualizer"):
		$GridVisualizer.show()
	
	# 🌟 [เพิ่มบรรทัดนี้!] เปิดกำแพงล่องหนกั้นเขตแดน
	toggle_invisible_walls(true)
	
	active_combat_unit = selected_unit
	is_combat_aiming = true
	combat_action_mode = "walk" # 🌟 สับสวิตช์เป็นโหมดเดิน!
	combat_menu.hide()
	
	initial_aim_rotation = active_combat_unit.rotation.y
	current_aim_offset = 0
	
	# บังคับเปิด UI ชาร์จพลัง สำหรับโหมดเดิน!
	if power_ui: power_ui.start_charging(100)
	
	# ==========================================
	# 🌟 [จุดแก้บั๊กปืนฟาดหน้าล้ม!]
	# ต้องสั่งให้มันจำ "ระยะห่างของปืน" (Offset) เหมือนตอนกดปุ่ม Shoot เป๊ะๆ
	# ไม่งั้น _process จะไม่รู้ว่าต้องเอาปืนไปโคจรรอบๆ ที่พิกัดไหนครับ
	# ==========================================
	if active_combat_unit.has_meta("linked_gun"):
		var attached_gun = active_combat_unit.get_meta("linked_gun")
		if is_instance_valid(attached_gun):
			initial_gun_rotation = attached_gun.global_rotation.y
			var local_trans = active_combat_unit.global_transform.affine_inverse() * attached_gun.global_transform
			active_combat_unit.set_meta("walk_local_transform", local_trans)
	# ==========================================

	# --- ซูมกล้องเข้าหัว (โค้ดเดิมของพี่แว่น) ---
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_rig = cam.get_parent().get_parent().get_parent()
		if cam_rig.has_method("set_ots_mode"):
			var head_dummy = Node3D.new()
			active_combat_unit.add_child(head_dummy)
			head_dummy.position = Vector3(0, 1.2, 0)
			cam_rig.set_ots_mode(head_dummy)
			active_combat_unit.set_meta("cam_dummy", head_dummy)
			if "pitch_target" in cam_rig: cam_rig.pitch_target = 25.0
			if "zoom_target" in cam_rig: cam_rig.zoom_target = 6.0 # 🌟 ระยะซูมตอนเดิน เอาให้ถอยออกมากว่าตอนยิงนิดนึง









# ==========================================
# 🌟 ฟังก์ชันยกเลิกการเลือกตัวละคร (คลิกขวาแล้วดึงกล้องกลับ RTS)
# ==========================================
func deselect_combat_unit():
	selected_unit = null
	active_combat_unit = null
	if combat_menu: combat_menu.hide()
	
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_rig = cam.get_parent().get_parent().get_parent()
		if cam_rig.has_method("set_ots_mode"):
			cam_rig.set_ots_mode(null)
			
		# 🌟 ส่งค่าเป้าหมาย (Target) ให้กล้องไหลกลับไปเองแบบสมูทๆ ห้ามบังคับ global_position!
		if saved_rig_pos != Vector3.ZERO:
			if "move_target" in cam_rig: cam_rig.move_target = saved_rig_pos
			if "rotate_keys_target" in cam_rig: cam_rig.rotate_keys_target = rad_to_deg(saved_rig_rot.y)
			if "zoom_target" in cam_rig: cam_rig.zoom_target = saved_zoom
			if "pitch_target" in cam_rig: cam_rig.pitch_target = original_cam_tilt







func execute_player_walk(unit: Node3D, power: float):
	if has_node("HUD/ShootingPowerUI"): $HUD/ShootingPowerUI.hide()
	
	unit.set_meta("is_moving_ai", true) 
	
	# 🌟 [จุดแก้ล้ม!] ล็อกแกน X, Y, Z ไว้ตลอดการเดินทาง ห้ามหน้าทิ่ม ห้ามตีลังกา!
	unit.axis_lock_angular_x = true
	unit.axis_lock_angular_y = true
	unit.axis_lock_angular_z = true
	unit.linear_velocity = Vector3.ZERO
	unit.angular_velocity = Vector3.ZERO
	
	if unit.has_meta("linked_gun"):
		var gun = unit.get_meta("linked_gun")
		if is_instance_valid(gun): 
			gun.freeze = true 
			toggle_collision(gun, true) 
			
			# 🌟 [เพิ่มตรงนี้!] แปะกาวก่อนพุ่งตัว
			var local_trans = unit.global_transform.affine_inverse() * gun.global_transform
			unit.set_meta("ai_slide_transform", local_trans)

	var forward = unit.global_transform.basis.z.normalized()
	
	# 🌟 [ปรับบาลานซ์ความแรง]
	if power <= 30.0: 
		# 🚶 เดินสไลด์: ปรับแรงให้เบาลงและสมูทขึ้น (3.0 ถึง 8.0)
		var walk_force = clamp(power * 0.25, 3.0, 8.0)
		unit.apply_central_impulse(forward * walk_force)
	else: 
		# 🚀 พุ่งกระโดด: ลดระยะทางลงมา (ชาร์จ 100 เต็ม = พุ่งไป 15 เมตรพอ จะได้ไม่ลอยเคว้ง)
		var jump_dist = power * 0.15 
		var target_pos = unit.global_position + (forward * jump_dist)
		
		# คำนวณวิถีโค้ง
		var jump = calculate_arc_impulse(unit.global_position, target_pos, unit.mass)
		unit.apply_central_impulse(jump)
		# ❌ เอา apply_torque_impulse (แรงบิดสุ่ม) ออกไปเลย ตัวจะได้ไม่หมุนติ้ว!
	
	# 🌟 ถ้าย้ายตำแหน่งเดิน ให้ลบตำแหน่ง Snap ทิ้งเลย! ต้องตั้งใหม่
	unit.remove_meta("snap_pos")
	unit.remove_meta("base_pos")
	clear_snap_ghost(unit)
	
	cancel_combat_aim(true, "walk")

	# 🚩 รอหยุดนิ่ง (1.8 วิ) -> จบเทิร์น
	get_tree().create_timer(1.8).timeout.connect(func():
		if is_instance_valid(unit):
			unit.set_meta("is_moving_ai", false)
			
			unit.axis_lock_angular_x = false
			unit.axis_lock_angular_y = false
			unit.axis_lock_angular_z = false
			
			# 🌟 ดึงตัวให้ตั้งตรง และสั่งหยุดไถลแบบ 100%
			unit.rotation.x = 0
			unit.rotation.z = 0 
			# 🌟 [เพิ่มบรรทัดนี้!] หันหน้ากลับไปทิศทางเดิมก่อนเริ่มเล็งเดิน
			unit.rotation.y = initial_aim_rotation 
			
			unit.linear_velocity = Vector3.ZERO
			unit.angular_velocity = Vector3.ZERO
			
			if unit.has_meta("linked_gun"):
				var gun = unit.get_meta("linked_gun")
				if is_instance_valid(gun): 
					gun.freeze = false
					toggle_collision(gun, false)
			# 🌟 [เพิ่มบรรทัดนี้!] ซ่อนตารางสีฟ้าเมื่อเดินเสร็จ
			if has_node("GridVisualizer"):
				$GridVisualizer.hide()
			
			# 🌟 [เพิ่มบรรทัดนี้!] ตัวละครหยุดนิ่งแล้ว สลายกำแพงทิ้งได้!
			toggle_invisible_walls(false)
			
			print("🚶 เดินเสร็จ! จบเทิร์น")
			if has_method("post_shoot_turn_check"):
				post_shoot_turn_check(unit) 
	)








# ==========================================
# 🌟 ระบบวาดตาราง Snap และโฮโลแกรม (Phase 1)
# ==========================================
func draw_snap_grid(center_pos: Vector3, radius: float):
	var snap_vis = get_node_or_null("SnapVisualizer")
	if not snap_vis:
		snap_vis = MeshInstance3D.new()
		snap_vis.name = "SnapVisualizer"
		var mesh = ImmediateMesh.new()
		snap_vis.mesh = mesh
		snap_vis.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		var mat = StandardMaterial3D.new()
		mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		snap_vis.material_override = mat
		add_child(snap_vis)
		
	snap_vis.show()
	var mesh = snap_vis.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# 🎨 [ส่วนเปลี่ยนสี - คราวนี้จะมีช่องสีขึ้นมาให้คลิกแล้วครับ!] 🌟
	# พี่สามารถกดที่ช่องสีใน Godot เพื่อเลือกสีที่ชอบได้เลย
	var bound_color = Color(0.0, 0.752, 0.842, 1.0) # 👈 ช่องสีจะโผล่ตรงนี้ (สีขอบ)
	var grid_line_color = Color(0.0, 0.798, 0.86, 0.149) # 👈 ช่องสีจะโผล่ตรงนี้ (สีตาราง)
	
	# ถ้าอยากให้มันเรืองแสงจ้าๆ (HDR) พี่ค่อยเอาค่า glow มาคูณตรงนี้ครับ
	var glow = 4.0 
	var final_bound = bound_color * glow
	var final_grid = grid_line_color * 1.2 # ตารางข้างในไม่ต้องจ้ามาก
	
	var fixed_y = 0.0 # ความสูง
	
	# ---------------------------------------------------------
	# 1. วาดเส้นตารางภายใน
	# ---------------------------------------------------------
	var x_start = snapped(center_pos.x - radius, snap_step)
	var x_end = center_pos.x + radius
	var curr_x = x_start
	while curr_x <= x_end + 0.01:
		var dx = curr_x - center_pos.x
		if abs(dx) < radius:
			var dz = sqrt(radius * radius - dx * dx)
			mesh.surface_set_color(final_grid) # ใช้สีที่คำนวณแล้ว
			mesh.surface_add_vertex(Vector3(curr_x, fixed_y, center_pos.z - dz))
			mesh.surface_set_color(final_grid)
			mesh.surface_add_vertex(Vector3(curr_x, fixed_y, center_pos.z + dz))
		curr_x += snap_step
		
	var z_start = snapped(center_pos.z - radius, snap_step)
	var z_end = center_pos.z + radius
	var curr_z = z_start
	while curr_z <= z_end + 0.01:
		var dz = curr_z - center_pos.z
		if abs(dz) < radius:
			var dx = sqrt(radius * radius - dz * dz)
			mesh.surface_set_color(final_grid)
			mesh.surface_add_vertex(Vector3(center_pos.x - dx, fixed_y, curr_z))
			mesh.surface_set_color(final_grid)
			mesh.surface_add_vertex(Vector3(center_pos.x + dx, fixed_y, curr_z))
		curr_z += snap_step

	# ---------------------------------------------------------
	# 2. วาดเส้นขอบวงกลม
	# ---------------------------------------------------------
	var segments = 64 
	for i in range(segments):
		var angle1 = i * TAU / segments
		var angle2 = (i + 1) * TAU / segments
		
		var p1 = center_pos + Vector3(cos(angle1) * radius, 0, sin(angle1) * radius)
		var p2 = center_pos + Vector3(cos(angle2) * radius, 0, sin(angle2) * radius)
		
		mesh.surface_set_color(final_bound) # ใช้สีขอบที่จ้าๆ
		mesh.surface_add_vertex(Vector3(p1.x, fixed_y + 0.01, p1.z))
		mesh.surface_set_color(final_bound)
		mesh.surface_add_vertex(Vector3(p2.x, fixed_y + 0.01, p2.z))
		
	mesh.surface_end()

func create_snap_ghost(unit: Node3D, pos: Vector3):
	clear_snap_ghost(unit) 
	
	# ดึงชื่อโมเดลต้นฉบับ
	var raw_name = unit.get("unit_name").to_lower() if unit.get("unit_name") != null else unit.name.to_lower()
	var clean_name = raw_name.split("_id_")[0]
	
	var ghost = null
	for data in army_list:
		if data["name"].to_lower() == clean_name:
			ghost = data["scene"].instantiate()
			break
			
	if not ghost: return
	get_tree().current_scene.add_child(ghost)
	
	# วางตำแหน่งและปิดระบบที่ไม่จำเป็น
	ghost.global_position = pos
	ghost.global_rotation = unit.global_rotation
	toggle_collision(ghost, true) # ปิด Collision กันบั๊กตัวจริงเดินชนตัวปลอม
	
	if ghost is RigidBody3D: ghost.freeze = true
	
	# 🌟 ใช้สีฟ้าโปร่งแสงแบบโหมดก่อสร้าง (Cyan 0.5 Alpha)
	set_unit_preview_color(ghost, Color(0.0, 1.0, 1.0, 0.5))
	
	# 🌟 ติดตั้งปืนให้ร่างโคลนด้วย
	if unit.has_meta("linked_gun"):
		var real_gun = unit.get_meta("linked_gun")
		if is_instance_valid(real_gun):
			var g_name = (real_gun.get("unit_name") if real_gun.get("unit_name") != null else real_gun.name).to_lower()
			var clean_g_name = g_name.split("_id_")[0]
			var ghost_gun = null
			
			for data in army_list:
				if data["name"].to_lower() == clean_g_name:
					ghost_gun = data["scene"].instantiate()
					break
			
			if ghost_gun:
				get_tree().current_scene.add_child(ghost_gun)
				
				# ==========================================
				# 🌟 [จุดแก้บั๊ก!] คัดลอกตำแหน่ง+องศาปืน จากตัวจริงมาใส่ตัวผีแบบเป๊ะทุกแกน
				# ==========================================
				var relative_transform = unit.global_transform.affine_inverse() * real_gun.global_transform
				ghost_gun.global_transform = ghost.global_transform * relative_transform
				# ==========================================
					
				toggle_collision(ghost_gun, true)
				if ghost_gun is RigidBody3D: ghost_gun.freeze = true
				set_unit_preview_color(ghost_gun, Color(0.0, 1.0, 1.0, 0.5))
				
				# ฝากปืนไว้กับผี
				ghost.set_meta("ghost_gun", ghost_gun)

	unit.set_meta("snap_ghost", ghost)

func clear_snap_ghost(unit: Node3D):
	if unit.has_meta("snap_ghost"):
		var ghost = unit.get_meta("snap_ghost")
		if is_instance_valid(ghost):
			# 🌟 ลบปืนโคลนทิ้งด้วย
			if ghost.has_meta("ghost_gun"):
				var g_gun = ghost.get_meta("ghost_gun")
				if is_instance_valid(g_gun): g_gun.queue_free()
			ghost.queue_free()
		unit.remove_meta("snap_ghost")
