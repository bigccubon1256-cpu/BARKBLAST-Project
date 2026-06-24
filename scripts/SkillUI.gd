extends Control

# ข้อมูลคิวงานปุ่มสกิลทั้งหมดที่กำลังแสดง
var active_buttons = {} # key: instance_id, value: { "button": TextureButton, "progress": TextureProgressBar, "unit": Node3D }

@onready var manager = get_parent() # สมมติว่าสร้างและแอดเข้ามาเป็นลูกของ HUD ใน MainManager
@onready var main_manager = get_parent().get_parent()

# โหนดตำแหน่ง Anchor จากระดับวิชวลเอดิเตอร์
@onready var anchor_normal = get_node_or_null("SkillButtonAnchorNormal")
@onready var anchor_selected = get_node_or_null("SkillButtonAnchorSelected")

# Popup แสดงรายละเอียดสกิล
@onready var detail_panel = get_node_or_null("SkillDetailPopup")
var active_detail_unit_id: int = -1

# ระบบเปลี่ยนหน้าสำหรับปุ่มสกิลที่เกิน 5 ปุ่ม
var current_page: int = 0
var btn_prev: Button = null
var btn_next: Button = null

# ตัวแปรสำหรับลดภาระ _process
var scan_timer: float = 0.0
var cached_skill_units: Array = []

func _ready():
	if detail_panel:
		detail_panel.hide()

func _process(_delta):
	# เช็กความพร้อมของเมเนเจอร์และการต่อสู้
	if not is_instance_valid(main_manager) or not main_manager.is_game_started:
		_clear_all_buttons()
		_hide_detail_panel()
		return
		
	var is_player_turn = (main_manager.get("current_state") == main_manager.Turn.PLAYER)
	var is_kael_skill_active = (main_manager.get("is_max_kael_skill_active") == true)
	var is_tabitha_targeting = (main_manager.get("is_tabitha_targeting_mode") == true)
	var selected_unit = main_manager.get("selected_unit")
	var is_combat_aiming = (main_manager.get("is_combat_aiming") == true)
	
	if not is_player_turn or is_kael_skill_active or is_tabitha_targeting or is_combat_aiming:
		# ซ่อนปุ่มทั้งหมดเมื่อไม่ใช่เทิร์นของเรา หรือเมื่อสกิลของ Kael ทำงานอยู่ หรือเมื่อกำลังเล็งสกิล Tabitha หรือเมื่อเลือกปุ่มคอมแบท (เดิน/ยิง/สแน็ป)
		for btn_data in active_buttons.values():
			if is_instance_valid(btn_data.get("button")):
				btn_data["button"].hide()
		if is_instance_valid(btn_prev): btn_prev.hide()
		if is_instance_valid(btn_next): btn_next.hide()
		_hide_detail_panel()
		return
		
	# สแกนหาตัวละครในสนามที่มีสกิล (ทำแค่ 4 ครั้งต่อวินาที แทนการทำทุกเฟรม)
	scan_timer -= _delta
	if scan_timer <= 0.0:
		scan_timer = 0.25
		var temp_skill_units = []
		for unit in main_manager.occupied_tiles.values():
			if is_instance_valid(unit) and not unit.get("is_dead") and unit.get("skill_name") != null:
				# ตรวจสอบว่าเป็นยูนิตฝั่งเรา (ไม่ใช่ enemy)
				var u_name = str(unit.get("unit_name")).to_lower()
				if main_manager.has_method("is_player_char") and main_manager.is_player_char(u_name):
					temp_skill_units.append(unit)
					
		# เรียงลำดับตามเวลาสร้าง/วางตัวละคร (ตัวที่วางก่อนจะอยู่ซ้ายสุด)
		temp_skill_units.sort_custom(func(a, b):
			return a.get_instance_id() < b.get_instance_id()
		)
		cached_skill_units = temp_skill_units
					
		# กวาดล้างปุ่มที่ยูนิตตาย หรือไม่อยู่ในสนามแล้ว
		var current_ids = []
		for unit in cached_skill_units:
			current_ids.append(unit.get_instance_id())
			
		var ids_to_remove = []
		for id in active_buttons.keys():
			if not id in current_ids:
				ids_to_remove.append(id)
				
		for id in ids_to_remove:
			_remove_button(id)
			if active_detail_unit_id == id:
				_hide_detail_panel()
				active_detail_unit_id = -1

	var current_skill_units = cached_skill_units
	# คำนวณหน้าของการแสดงผลสกิล
	var total_skills = current_skill_units.size()
	var max_page = max(0, ceil(total_skills / 5.0) - 1)
	if current_page > max_page:
		current_page = max_page
		
	var start_idx = current_page * 5
	var end_idx = start_idx + 5
	
	# สร้าง/อัปเดตปุ่มสกิลสำหรับยูนิตที่ตรวจพบ
	var index = 0
	var last_base_pos = Vector2.ZERO
	var last_button_size = Vector2(80, 80)
	
	for unit in current_skill_units:
		var id = unit.get_instance_id()
		var btn_data
		if not active_buttons.has(id):
			btn_data = _create_button_for_unit(unit)
			if btn_data.is_empty():
				continue
			active_buttons[id] = btn_data
		else:
			btn_data = active_buttons[id]
			
		var button = btn_data["button"]
		
		var is_selected_unit = (selected_unit == unit)
		
		# เช็กว่าตัวนี้อยู่ในหน้าปัจจุบันหรือไม่ และถ้ามีการเลือกตัวละครอยู่ ให้แสดงเฉพาะตัวที่เลือก!
		var should_show = false
		if selected_unit != null:
			# ถ้ามีตัวละครถูกเลือก (เช่นเปิดเมนูคอมแบท) โชว์แค่ปุ่มของตัวที่เลือก
			should_show = is_selected_unit
		else:
			# ถ้าไม่ได้เลือกใคร โชว์ตามหน้า Pagination ปกติ
			should_show = (index >= start_idx and index < end_idx)
			
		if not should_show:
			button.hide()
			if not is_selected_unit: # ยังต้องรัน index++ สำหรับตัวที่ไม่ถูกเลือกในโหมดปกติ
				index += 1
			continue
			
		button.show()
		var local_index = index - start_idx
		if selected_unit != null:
			local_index = 0 # ถ้าโชว์เดี่ยวๆ ให้มันอยู่ตำแหน่งแรกเสมอ
		
		# เช็กว่า Max Kael ถูกเลือกเล็งอยู่ในระบบต่อสู้หรือไม่
		# เคลียร์ anchors เพื่อจัดตำแหน่งแบบ absolute ด้วย global_position ได้แม่นยำ 100%
		button.anchor_left = 0.0
		button.anchor_right = 0.0
		button.anchor_top = 0.0
		button.anchor_bottom = 0.0
		
		# คำนวณพิกัดการจัดวางโดยอิงจาก Anchors
		var base_pos = Vector2.ZERO
		var target_anchor = null
		if is_selected_unit and anchor_selected:
			target_anchor = anchor_selected
			base_pos = anchor_selected.global_position
		elif anchor_normal:
			target_anchor = anchor_normal
			base_pos = anchor_normal.global_position
		else:
			var screen_size = get_viewport_rect().size
			base_pos = Vector2(screen_size.x - 130, screen_size.y - 130)
				
		last_base_pos = base_pos
		
		# ซิงก์ ขนาด, องศาหมุน, และตำแหน่งจุดหมุน (Pivot Offset) จาก Anchor ก่อนจัดตำแหน่ง
		if target_anchor:
			button.custom_minimum_size = target_anchor.size
			button.size = target_anchor.size
			button.rotation = target_anchor.rotation
			if target_anchor.pivot_offset != Vector2.ZERO:
				button.pivot_offset = target_anchor.pivot_offset
			else:
				button.pivot_offset = target_anchor.size / 2.0
		else:
			button.custom_minimum_size = Vector2(80, 80)
			button.size = Vector2(80, 80)
			button.rotation = 0.0
			button.pivot_offset = Vector2(40, 40)
			
		last_button_size = button.size
 
		# คำนวณหาจุดหมุนกึ่งกลาง (Pivot Center) ในระดับพิกัด Global เพื่อป้องกันไม่ให้จุดหมุนยับ/กระตุกเวลาขยายสเกล
		var global_center = Vector2.ZERO
		if target_anchor:
			global_center = target_anchor.global_position + target_anchor.pivot_offset.rotated(target_anchor.rotation)
		else:
			global_center = base_pos + Vector2(40, 40)
			
		# คำนวณ Offset ขยับปุ่มตาม index ในคิว (จากซ้ายไปขวา โดยอิงตามจำนวนยูนิตบนหน้าปัจจุบัน)
		if selected_unit == null:
			var total_on_page = min(5, total_skills - start_idx)
			global_center -= Vector2((total_on_page - 1 - local_index) * 100, 0)
		
		# คำนวณ global_position ของปุ่มย้อนกลับจากจุดหมุน โดยอิงตามสเกลและมุมหมุนปัจจุบันของปุ่ม
		button.global_position = global_center - (button.pivot_offset * button.scale).rotated(button.rotation)
		
		# อัปเดตสถานะความแรง/เกจพลัง
		var progress = 0.0
		if unit.has_method("check_skill_progress"):
			progress = unit.check_skill_progress(main_manager)
			
		if button.has_method("update_progress"):
			button.update_progress(progress)
		
		# ส่งค่าสถานะต่างๆ ให้ปุ่มเป็นผู้คำนวณและปรับขนาดเองเพื่อให้อนิเมชันมีความสมูทและทำงานร่วมกับ Tween ได้ดี
		button.base_scale = target_anchor.scale if target_anchor else Vector2(1.0, 1.0)
		button.is_viewing_detail = (active_detail_unit_id == id)
		button.is_selected_unit = is_selected_unit
			
		index += 1
		
	# วาด/อัปเดตปุ่มลูกศร pagination
	_update_pagination_arrows(total_skills, max_page, last_base_pos, last_button_size)
		
	# วาด/อัปเดต Popup ข้อมูลสกิล (ถ้าเปิดอยู่)
	if detail_panel and detail_panel.visible and active_detail_unit_id != -1:
		var target_unit = instance_from_id(active_detail_unit_id)
		if is_instance_valid(target_unit):
			_update_detail_text(target_unit)

func _create_button_for_unit(unit: Node3D) -> Dictionary:
	var btn_scene = load("res://scenes/skill_button.tscn")
	if btn_scene:
		var btn = btn_scene.instantiate()
		add_child(btn)
		btn.setup(unit)
		btn.pressed.connect(_on_skill_pressed.bind(unit.get_instance_id()))
		return { "button": btn, "progress": btn.progress_bar, "unit": unit }
	else:
		print("❌ ERROR: Cannot load res://scenes/skill_button.tscn")
		return {}

func _remove_button(id: int):
	if active_buttons.has(id):
		var btn_data = active_buttons[id]
		if is_instance_valid(btn_data["button"]): 
			btn_data["button"].queue_free()
		active_buttons.erase(id)

func _clear_all_buttons():
	for id in active_buttons.keys():
		_remove_button(id)
	active_buttons.clear()
	if is_instance_valid(btn_prev): btn_prev.queue_free()
	if is_instance_valid(btn_next): btn_next.queue_free()

func _show_detail_panel():
	if detail_panel:
		detail_panel.show()
		if is_instance_valid(main_manager) and main_manager.get("btn_end_turn"):
			main_manager.btn_end_turn.hide()

func _hide_detail_panel():
	if detail_panel:
		detail_panel.hide()
		if is_instance_valid(main_manager) and main_manager.get("btn_end_turn"):
			# แสดงปุ่ม End Turn กลับมาถ้าตาผู้เล่นและไม่มีตัวละครเล็งยิง/เลือกอยู่ และต้องไม่ใช่ระหว่างใช้สกิล
			if not main_manager.get("selected_unit") and not main_manager.get("active_combat_unit") and main_manager.get("current_state") == main_manager.Turn.PLAYER and not main_manager.get("is_max_kael_skill_active"):
				main_manager.btn_end_turn.show()

func _on_skill_pressed(unit_id: int):
	var unit = instance_from_id(unit_id)
	if not is_instance_valid(unit) or not detail_panel: return
	
	# 🚫 ดักตรวจสอบสถานะโหลดกระสุน / รีโหลด ก่อนเปิดใช้สกิล (ยกเว้น Tabitha ที่จะสามารถใช้สกิลชุบเพื่อนได้เสมอแม้จะติดสถานะรีโหลด)
	var is_tabitha = (unit.get("unit_name") == "tabitha")
	if not is_tabitha and unit.has_meta("has_attacked_this_turn") and unit.get_meta("has_attacked_this_turn") == true:
		if is_instance_valid(main_manager):
			if main_manager.has_method("show_reload_notification"):
				main_manager.show_reload_notification(unit)
			var err_sound = main_manager.get_node_or_null("ErrorSoundPlayer")
			if err_sound:
				err_sound.play()
		return # ❌ ป้องกันการใช้งานสกิลและไม่เปิดรายละเอียดใดๆ
	
	var progress = 0.0
	if unit.has_method("check_skill_progress"):
		progress = unit.check_skill_progress(main_manager)
		
	if active_detail_unit_id != unit_id:
		# คลิกครั้งแรก หรือเปลี่ยนไปคลิกตัวละครอื่น -> เปิด/ย้าย Popup ข้อมูลสกิล
		active_detail_unit_id = unit_id
		_update_detail_text(unit)
		
		# จัดตำแหน่ง Popup ให้อยู่เหนือปุ่มสกิลนั้นๆ (เลื่อนขึ้นเหนือปุ่มพอดีจอ) และป้องกันไม่ให้ออกนอกจอ
		if active_buttons.has(unit_id):
			var btn = active_buttons[unit_id]["button"]
			var target_pos = btn.global_position + Vector2(-520, -360)
			var viewport_size = get_viewport_rect().size
			target_pos.x = clamp(target_pos.x, 10, viewport_size.x - detail_panel.size.x - 10)
			target_pos.y = clamp(target_pos.y, 10, viewport_size.y - detail_panel.size.y - 10)
			detail_panel.global_position = target_pos
			
		_show_detail_panel()
	else:
		# คลิกครั้งที่สองที่ปุ่มเดิม
		if progress >= 100.0:
			# ใช้สกิล!
			_hide_detail_panel()
			active_detail_unit_id = -1
			if unit.has_method("activate_skill"):
				unit.activate_skill(main_manager)
		else:
			# ถ้าเกจไม่เต็ม กดรอบสองจะปิดป๊อปอัปแทน
			_hide_detail_panel()
			active_detail_unit_id = -1

func _update_detail_text(unit: Node3D):
	if not detail_panel: return
	var skill_name = unit.get("skill_name") if unit.get("skill_name") != null else "Skill"
	var skill_desc = unit.get("skill_description") if unit.get("skill_description") != null else ""
	var skill_cond = unit.get("skill_conditions") if unit.get("skill_conditions") != null else ""
	var theme_color = unit.get("skill_theme_color") if unit.get("skill_theme_color") != null else Color(0.0, 0.9, 1.0, 1.0)
	
	var progress = 0.0
	if unit.has_method("check_skill_progress"):
		progress = unit.check_skill_progress(main_manager)
		
	if detail_panel.has_method("update_text"):
		detail_panel.update_text(skill_name, skill_desc, skill_cond, progress, theme_color)

func _input(event):
	# ดักจับการคลิกนอกกรอบป๊อปอัปเพื่อสั่งปิด
	if event is InputEventMouseButton and event.pressed and detail_panel:
		if detail_panel.visible:
			# ใช้ make_input_local เพื่อให้คำนวณตำแหน่งเมาส์รวมการหมุนและสเกลได้อย่างแม่นยำ
			var local_popup_event = detail_panel.make_input_local(event)
			var is_click_on_popup = Rect2(Vector2.ZERO, detail_panel.size).has_point(local_popup_event.position)
			
			# เช็กว่าเป็นการคลิกโดนปุ่มสกิลปุ่มใดปุ่มหนึ่งหรือไม่
			var is_click_on_button = false
			for btn_data in active_buttons.values():
				var btn = btn_data["button"]
				var local_btn_event = btn.make_input_local(event)
				if Rect2(Vector2.ZERO, btn.size).has_point(local_btn_event.position):
					is_click_on_button = true
					break
					
			if not is_click_on_popup and not is_click_on_button:
				_hide_detail_panel()
				active_detail_unit_id = -1

# ==========================================
# 🌟 ระบบ Pagination สำหรับปุ่มสกิลที่เกิน 5 ปุ่ม
# ==========================================
func _update_pagination_arrows(total_skills: int, max_page: int, base_pos: Vector2, button_size: Vector2):
	if total_skills <= 5 or base_pos == Vector2.ZERO:
		if is_instance_valid(btn_prev): btn_prev.hide()
		if is_instance_valid(btn_next): btn_next.hide()
		return
		
	# สร้างปุ่ม prev ถ้ายังไม่มี
	if not is_instance_valid(btn_prev):
		btn_prev = Button.new()
		btn_prev.text = "◀"
		add_child(btn_prev)
		btn_prev.pressed.connect(_on_prev_page_pressed)
		_style_nav_button(btn_prev)
		
	# สร้างปุ่ม next ถ้ายังไม่มี
	if not is_instance_valid(btn_next):
		btn_next = Button.new()
		btn_next.text = "▶"
		add_child(btn_next)
		btn_next.pressed.connect(_on_next_page_pressed)
		_style_nav_button(btn_next)
		
	btn_prev.show()
	btn_next.show()
	
	# จัดตำแหน่งปุ่ม prev และ next ให้โอบล้อมปุ่มสกิลทั้ง 5 ปุ่ม
	var prev_center = base_pos + Vector2(40, 40) - Vector2(5 * 100, 0)
	var next_center = base_pos + Vector2(40, 40) - Vector2(-1 * 100, 0)
	
	btn_prev.size = Vector2(40, 60)
	btn_prev.pivot_offset = btn_prev.size / 2.0
	btn_prev.global_position = prev_center - btn_prev.pivot_offset
	
	btn_next.size = Vector2(40, 60)
	btn_next.pivot_offset = btn_next.size / 2.0
	btn_next.global_position = next_center - btn_next.pivot_offset
	
	# กำหนดสถานะปุ่ม disabled
	btn_prev.disabled = (current_page == 0)
	btn_next.disabled = (current_page == max_page)
	
	btn_prev.modulate.a = 0.3 if btn_prev.disabled else 1.0
	btn_next.modulate.a = 0.3 if btn_next.disabled else 1.0

func _style_nav_button(btn: Button):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.01, 0.08, 0.15, 0.75) # Cyber dark blue
	style_normal.border_color = Color(0.0, 0.8, 1.0, 0.8) # Neon cyan border
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.02, 0.2, 0.35, 0.85)
	style_hover.border_color = Color(0.0, 1.0, 1.0, 1.0)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.03, 0.35, 0.55, 0.95)
	style_pressed.border_color = Color(0.0, 1.0, 1.0, 1.0)
	
	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color(0.05, 0.05, 0.05, 0.3)
	style_disabled.border_color = Color(0.2, 0.2, 0.2, 0.4)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	
	btn.add_theme_color_override("font_color", Color(0.0, 0.8, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.3, 0.3, 0.5))
	btn.add_theme_font_size_override("font_size", 22)
	
	var jersey_font = load("res://assets/Font/Jersey_10/Jersey10-Regular.ttf") as Font
	if jersey_font:
		btn.add_theme_font_override("font", jersey_font)

func _on_prev_page_pressed():
	if current_page > 0:
		current_page -= 1
		_hide_detail_panel()
		active_detail_unit_id = -1

func _on_next_page_pressed():
	var current_skill_units = []
	for unit in main_manager.occupied_tiles.values():
		if is_instance_valid(unit) and not unit.get("is_dead") and unit.get("skill_name") != null:
			var u_name = str(unit.get("unit_name")).to_lower()
			if main_manager.has_method("is_player_char") and main_manager.is_player_char(u_name):
				current_skill_units.append(unit)
				
	var max_page = max(0, ceil(current_skill_units.size() / 5.0) - 1)
	if current_page < max_page:
		current_page += 1
		_hide_detail_panel()
		active_detail_unit_id = -1
