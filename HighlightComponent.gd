extends Node
# ==========================================
# 🧹 HighlightPulsingComponent.gd
# อัปเกรดให้เปลี่ยนสีได้อิสระ และกะพริบได้ตามจังหวะ
# ==========================================

@export var base_material: StandardMaterial3D # ลาก HighlightMaterial.tres ต้นแบบมาใส่ใน Inspector

var _active_material: StandardMaterial3D # Material ส่วนตัวของยูนิตนี้
var _highlighted_meshes: Array[MeshInstance3D] = []
var _current_tween: Tween # เอาไว้เก็บ Tween การกะพริบ

func _ready():
	# 🌟 สำคัญมาก! ก๊อปปี้ Material ต้นแบบมาเป็นของตัวเอง 
	# เวลาเปลี่ยนสี ตัวอื่นในฉากจะได้ไม่เปลี่ยนตาม
	if base_material:
		_active_material = base_material.duplicate() as StandardMaterial3D

# ==========================================
# 🌟 ฟังก์ชันเปิดไฮไลท์แบบกะพริบ (Pulsing Highlight)
# custom_color: สีเริ่มต้นที่ต้องการ
# start_blink: ให้เริ่มกะพริบเลยไหม
# blink_speed: ความเร็วในการกะพริบ (1.0 = ปกติ)
# min_alpha: ความโปร่งใสต่ำสุดตอนกะพริบ
# ==========================================
func enable_highlight(custom_color: Color = Color.WHITE, start_blink: bool = true, blink_speed: float = 1.0, min_alpha: float = 0.2):
	if not _active_material: return
	
	# ป้องกันการเปิดซ้ำซ้อน
	if _highlighted_meshes.size() > 0:
		return 
		
	var parent = get_parent()
	_find_and_highlight_meshes(parent)
	
	# ตั้งค่าสีและเริ่มกะพริบ
	_active_material.albedo_color = custom_color
	
	# สั่งเริ่มกะพริบ
	if start_blink:
		_start_pulsing(blink_speed, min_alpha)

# ==========================================
# 🌟 ฟังก์ชันปิดไฮไลท์และหยุดกะพริบ
# ==========================================
func disable_highlight():
	# 1. ปิดเอฟเฟกต์กะพริบ
	_stop_pulsing()
	
	# 2. เอาตัวเคลือบออก
	for mesh in _highlighted_meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = null 
			
	_highlighted_meshes.clear()

# ==========================================
# 🌟 ฟังก์ชันเปลี่ยนสีไฮไลท์สดๆ (ใช้ตอนไฮไลท์เปิดอยู่แล้ว)
# ==========================================
func set_color(new_color: Color):
	if _active_material:
		_active_material.albedo_color = new_color

# ==========================================
# 🔍 ระบบค้นหาโมเดลแบบทะลวงไส้ (Mesh finding)
# ==========================================
func _find_and_highlight_meshes(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D:
			# เคลือบ Material ทับลงไป!
			child.material_overlay = _active_material
			_highlighted_meshes.append(child)
			
		_find_and_highlight_meshes(child)

# ==========================================
# ⏱️ ระบบกะพริบ (Pulsing Animation Logic)
# ==========================================
func _start_pulsing(speed: float = 1.0, min_a: float = 0.2):
	# หยุด Tween เก่าก่อนเผื่อมีค้างอยู่
	_stop_pulsing()
	
	var max_a = _active_material.albedo_color.a
	var duration = 1.0 / speed
	
	# สร้าง Tween ใหม่
	_current_tween = create_tween()
	_current_tween.set_loops() # กะพริบวนไป
	
	# ค่อยๆ ลดความโปร่งใสลง
	_current_tween.tween_property(_active_material, "albedo_color:a", min_a, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# แล้วค่อยๆ เพิ่มความโปร่งใสกลับมา
	_current_tween.tween_property(_active_material, "albedo_color:a", max_a, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_pulsing():
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
