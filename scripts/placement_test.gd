extends Node3D

@onready var hp_display = $HUD/HPLabel
@onready var energy_bar = $HUD/EnergyBar

# --- สถานะระบบ ---
var total_hp: int = 0
var current_energy: float = 10.0
var occupied_tiles = {}
var dragging_unit: Node3D = null

func _process(_delta):
	# ระบบลากตัวละครให้ตามเมาส์ (ถ้ามีการลากอยู่)
	if dragging_unit:
		var pos = get_ground_position()
		if pos != Vector3.ZERO:
			# Snap to Grid และตั้งความสูงที่ 1.9 ตามที่คุณเคยใช้
			dragging_unit.global_position = Vector3(floor(pos.x)+0.5, 1.9, floor(pos.z)+0.5)
			
			# เช็คว่าวางได้ไหม (สีเขียว/แดง)
			var tile_key = str(dragging_unit.global_position.x) + "," + str(dragging_unit.global_position.z)
			if occupied_tiles.has(tile_key):
				set_unit_preview_color(dragging_unit, Color(1, 0, 0, 0.5))
			else:
				set_unit_preview_color(dragging_unit, Color(0, 1, 0, 0.5))

func _input(event):
	# เมื่อปล่อยเมาส์ = ทำการวาง
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dragging_unit:
			finalize_placement()

# --- ฟังก์ชันหลัก ---

func finalize_placement():
	var pos = dragging_unit.global_position
	var tile_key = str(pos.x) + "," + str(pos.z)
	
	if not occupied_tiles.has(tile_key) and current_energy >= dragging_unit.energy_cost:
		# 1. วางสำเร็จ: หัก Energy และ "บวก" HP ตามค่าตอนวาง
		current_energy -= dragging_unit.energy_cost
		total_hp += dragging_unit.hp_gain_on_place # ใช้ค่า HP ตอนวาง
		
		# 2. เก็บลง Dictionary และเปิดการทำงานตัวละคร
		occupied_tiles[tile_key] = dragging_unit
		dragging_unit.activate_unit(tile_key)
		
		# 3. เชื่อมต่อสัญญาณตอนตาย (สำคัญมาก!)
		dragging_unit.character_down.connect(_on_unit_died)
		
		# 4. คืนสีปกติและล้างสถานะลาก
		set_unit_preview_color(dragging_unit, Color(1, 1, 1, 1))
		dragging_unit = null
	else:
		# วางไม่ได้ให้ลบทิ้ง
		dragging_unit.queue_free()
		dragging_unit = null
	
	update_ui()

func _on_unit_died(hp_to_loss, key):
	# เมื่อตัวละครตาย: "ลบ" HP ตามค่าตอนตายที่ตัวละครส่งมา
	total_hp -= hp_to_loss
	if occupied_tiles.has(key):
		occupied_tiles.erase(key)
	
	update_ui()
	print("กองทัพเสีย HP: ", hp_to_loss, " | HP คงเหลือ: ", total_hp)

func update_ui():
	hp_display.text = "ARMY HP: " + str(total_hp)
	energy_bar.value = current_energy
	




# --- ฟังก์ชันช่วย (Helper) ---
func get_ground_position():
	var m_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	var ray_origin = camera.project_ray_origin(m_pos)
	var ray_end = ray_origin + camera.project_ray_normal(m_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 1 # พื้นอยู่ Layer 1
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	return result.position if result else Vector3.ZERO

func set_unit_preview_color(unit, color):
	var mesh = unit.get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
