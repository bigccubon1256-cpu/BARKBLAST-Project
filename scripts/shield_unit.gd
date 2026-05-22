extends RigidBody3D

@export var unit_name: String = "shield_block"
@export var energy_cost: float = 2.5
@export var max_hp: int = 2
@export var glint_tex: Texture2D # 🌟 [เพิ่มบรรทัดนี้!] สร้างช่องใส่รูปลายนอนรอไว้เลย
@export_range(0.0, 0.2) var outline_size: float = 0.02
# 🌟 [เพิ่มตรงนี้!] สร้างกล่องจิ้มสี 2 กล่อง ลากเปลี่ยนสีใน Inspector ได้เลย
@export var outline_color: Color = Color(0.8, 0.4, 1.0, 1.0) # สีเส้นขอบ (ม่วงสว่าง)
@export var glint_color: Color = Color(0.9, 0.5, 1.0, 1.0)   # สีลายแสงวิบวับ
# 🌟 [เพิ่มตรงนี้!] ตัวปรับขนาดลายและความเร็วในการไหล
@export var glint_scale: float = 1.0 # 💡 ทริค: ค่ายิ่งน้อย ลายยิ่งซูมใหญ่ (เช่น 0.5 หรือ 0.2)
@export var glint_speed: Vector2 = Vector2(0.5, 0.5) # ปรับทิศทางแกน X, Y ได้อิสระ
# 🌟 [เพิ่มบรรทัดนี้!] สีตอนเกราะใกล้แตก (แดงเตือนภัย)
@export var damage_color: Color = Color(1.0, 0.0, 0.0, 1.0)


@onready var real_hp: int = max_hp 

var tile_key: String = ""
var is_dead: bool = false
var shield_shader_mat: ShaderMaterial
var outline_shader_mat: ShaderMaterial # 🌟 [เพิ่มบรรทัดนี้!] สร้างตัวแปรมาจดจำเส้นขอบเอาไว้สั่งหรี่แสง


var shield_shader = preload("res://Shader/shield_glow.gdshader")
var outline_shader = preload("res://Shader/shield_outline.gdshader")



func _ready():
	# 🌟 คาถาความนิ่ง: แช่แข็งไว้ตลอดกาล ไม่ต้องปลดออก!
	freeze = true 
	
	# เปิดแค่ระบบรับสัมผัส เพื่อให้รู้ว่าโดนกระสุนยิง
	contact_monitor = true
	max_contacts_reported = 5
	
	body_entered.connect(_on_body_entered)
	setup_shield_shader()

func activate_unit(key: String):
	tile_key = key



func setup_shield_shader():
	var meshes = find_children("*", "MeshInstance3D")
	if meshes.size() > 0:
		var mesh_node = meshes[0]
		
		# 1. สร้างชั้นนอกสุด (เส้นขอบหนาๆ)
		outline_shader_mat = ShaderMaterial.new() # 🌟 [แก้ตรงนี้!] เอาคำว่า var ออก เพื่อเก็บลงตัวแปรของคลาส
		outline_shader_mat.shader = outline_shader
		outline_shader_mat.set_shader_parameter("outline_thickness", outline_size)
		outline_shader_mat.set_shader_parameter("outline_color", outline_color)
		
		# 🌟 [เพิ่มโค้ด 3 บรรทัดนี้!] สั่งให้เอนจิ้นหาจุดศูนย์กลางของกล่อง แล้วโยนให้ Shader
		if mesh_node.mesh:
			var center_pos = mesh_node.mesh.get_aabb().get_center()
			outline_shader_mat.set_shader_parameter("mesh_center", center_pos)
		
		# 2. สร้างชั้นกลาง (ลายแสงวิบวับ)
		shield_shader_mat = ShaderMaterial.new()
		shield_shader_mat.shader = shield_shader
		
		# ดึงรูปจากช่อง Inspector (ที่ทำไว้เมื่อวาน) มาใส่
		if glint_tex != null:
			shield_shader_mat.set_shader_parameter("glint_texture", glint_tex)
			
			# 🌟 [เพิ่ม 2 บรรทัดนี้!] ส่งค่าซูมและความเร็วเข้าไป!
		shield_shader_mat.set_shader_parameter("glint_scale", glint_scale)
		shield_shader_mat.set_shader_parameter("glint_scroll_speed", glint_speed)
			
			# 🌟 [เพิ่มบรรทัดนี้!] ส่งสีลายแสงเวทมนตร์เข้าไป
		shield_shader_mat.set_shader_parameter("glint_color", glint_color)
			
		# 3. ประกอบร่างแฮมเบอร์เกอร์! (ลายแสง -> โยนต่อไปที่เส้นขอบ)
		shield_shader_mat.next_pass = outline_shader_mat # 🌟 [เพิ่มคำว่า _shader_ เข้าไปให้ตรงกันครับ!]
		
		# 4. เอาแฮมเบอร์เกอร์ไปทับบนลายไม้เดิม! (ลายไม้ -> โยนต่อไปที่ลายแสง)
		var original_mat = mesh_node.get_active_material(0)
		if original_mat:
			var mat_copy = original_mat.duplicate()
			mat_copy.next_pass = shield_shader_mat
			mesh_node.set_surface_override_material(0, mat_copy)
		
		update_shield_glow()


func update_shield_glow():
	var hp_ratio = float(real_hp) / float(max_hp)
	
	# 🌟 1. ดัดแปลงแค่สี: ผสมสีเตือนภัย (แดง) เข้ากับสีเดิม 
	var current_glint_color = damage_color.lerp(glint_color, hp_ratio)
	var current_outline_color = damage_color.lerp(outline_color, hp_ratio)
	
	# 🌟 2. อัปเดตชั้นลายเวทมนตร์
	if shield_shader_mat:
		shield_shader_mat.set_shader_parameter("glint_color", current_glint_color)
		# ล็อกความสว่างไว้ที่ค่าคงที่ (เช่น 3.0) จะได้สว่างจ้าตลอดเวลา ไม่ดับแล้ว!
		shield_shader_mat.set_shader_parameter("emission_intensity", 3.0) 
		
	# 🌟 3. อัปเดตชั้นเส้นขอบ
	if outline_shader_mat:
		outline_shader_mat.set_shader_parameter("outline_color", current_outline_color)
		# ล็อกความหนาให้ดึงค่ามาจาก Inspector ตลอดเวลา (ไม่หดแล้ว!)
		outline_shader_mat.set_shader_parameter("outline_thickness", outline_size)
		# ล็อกความสว่างขอบไว้ที่ 1.0 (สว่างเต็มที่ตลอดเวลา)
		outline_shader_mat.set_shader_parameter("outline_brightness", 1.0)



func _on_body_entered(body):
	if is_dead: return
	var main_script = get_tree().current_scene
	if main_script and "is_game_started" in main_script:
		if not main_script.is_game_started: return
	
	if body is RigidBody3D:
		# 🌟 1. ดักแก๊งค์อาวุธ: ถ้าเป็นอาวุธที่ "อยู่ในมือ (freeze = true)" ห้ามทำดาเมจ!
		if "gun" in body.name.to_lower() and body.freeze:
			return
			
		# 🌟 2. ตั้งค่าความทนทาน: ถ้าตกลงมาทับเบาๆ จะไม่พัง ต้องโดนกระแทกแรงๆ (เกิน 4.0) เท่านั้น
		var is_fast_impact = body.linear_velocity.length() > 4.0
		
		# 🌟 3. กรณีพิเศษ: ถ้าเป็นหอกหรือปืนที่ "ถูกขว้าง/ยิงมา (ไม่ได้ freeze)" แค่แตะเบาๆ ก็เจาะเข้า
		var is_flying_weapon = "gun" in body.name.to_lower() and body.linear_velocity.length() > 1.0
		
		if is_fast_impact or is_flying_weapon:
			take_hit()


func take_hit():
	if is_dead: return
	real_hp -= 1
	update_shield_glow()
	if real_hp <= 0:
		die()

func die():
	is_dead = true
	wake_up_neighbors()
	var main_script = get_tree().current_scene
	if main_script and "occupied_tiles" in main_script:
		main_script.occupied_tiles.erase(tile_key)
	queue_free()

func wake_up_neighbors():
	var bodies = get_colliding_bodies()
	for b in bodies:
		# 🌟 ปลุกเฉพาะตัวที่ขยับได้ (ถ้าเป็นบล็อกด้วยกันจะได้ไม่พัง)
		if b is RigidBody3D and not b.freeze:
			b.sleeping = false
			b.apply_central_impulse(Vector3(0, -0.1, 0))
