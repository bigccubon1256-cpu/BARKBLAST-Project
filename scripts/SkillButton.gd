extends TextureButton

@onready var progress_bar: TextureProgressBar = $ProgressBar
@onready var glow_aura: ColorRect = $GlowAura

var character_theme_color: Color = Color(0.0, 0.9, 1.0, 1.0)

# 🌟 เพิ่มตัวแปรสำหรับควบคุมสเกลและอนิเมชันของปุ่มสกิลให้สมูทเหมือนปุ่มคอมแบทอื่นๆ
var base_scale: Vector2 = Vector2(1.0, 1.0)
var is_viewing_detail: bool = false
var is_selected_unit: bool = false
var progress_value: float = 0.0
var is_hovered: bool = false
var click_scale: float = 1.0
var click_tween: Tween = null

func setup(unit: Node3D):
	# ทำซ้ำ Material ให้เป็นของแต่ละปุ่มโดยเฉพาะ ป้องกันบั๊กแย่งการแชร์ค่ากัน
	if is_instance_valid(progress_bar) and progress_bar.material:
		progress_bar.material = progress_bar.material.duplicate()
	if is_instance_valid(glow_aura) and glow_aura.material:
		glow_aura.material = glow_aura.material.duplicate()

	# โหลดรูปพื้นหลังสกิลของตัวละคร
	var icon_path = "res://assets/foto/Max Kael-Skill.png"
	if "skill_icon_path" in unit:
		icon_path = unit.skill_icon_path
		
	var normal_tex = load(icon_path)
	if normal_tex:
		texture_normal = normal_tex
		
	var fill_path = "res://assets/foto/Max Kael-Skill-Fill.png"
	if "skill_fill_icon_path" in unit:
		fill_path = unit.skill_fill_icon_path
		
	var fill_tex = load(fill_path)
	if fill_tex:
		progress_bar.texture_progress = fill_tex
		if is_instance_valid(glow_aura) and glow_aura.material:
			glow_aura.material.set_shader_parameter("progress_texture", fill_tex)
		
	# ดึงค่าสีธีมประจำตัวละคร
	if "skill_theme_color" in unit:
		character_theme_color = unit.skill_theme_color
		
	# ตั้งค่าสีเริ่มต้นให้กับ Shader ทั้ง progress และ glow
	_apply_shader_tint(character_theme_color)
	_apply_glow_color(character_theme_color)

func _ready():
	# เชื่อมต่อสัญญาณเพื่อทำเอฟเฟกต์โฮเวอร์และคลิก
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _on_mouse_entered():
	is_hovered = true

func _on_mouse_exited():
	is_hovered = false

func _on_pressed():
	animate_click()

func animate_click():
	if click_tween and click_tween.is_valid():
		click_tween.kill()
	click_tween = create_tween()
	click_scale = 0.85
	click_tween.tween_property(self, "click_scale", 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _process(delta: float):
	# คำนวณหา Target Scale จากปัจจัยต่างๆ
	var hover_mult = 1.15 if is_hovered else 1.0
	var detail_mult = 1.15 if is_viewing_detail else 1.0
	var pulse_mult = 1.0
	if progress_value >= 100.0:
		# สั่นไหว/พัลส์ เมื่อชาร์จเต็ม
		pulse_mult = 1.0 + sin(Time.get_ticks_msec() * 0.007) * 0.04
		
	var target = base_scale * hover_mult * detail_mult * pulse_mult * click_scale
	
	# ทำการ Lerp ขนาดอย่างนุ่มนวลเพื่อแก้ปัญหากลไกทับซ้อน Tween
	scale = scale.lerp(target, delta * 18.0)

func _apply_shader_tint(theme_color: Color):
	if is_instance_valid(progress_bar) and progress_bar.material:
		progress_bar.material.set_shader_parameter("tint", Color(theme_color.r, theme_color.g, theme_color.b, 0.95))

func _apply_glow_color(theme_color: Color):
	if is_instance_valid(glow_aura) and glow_aura.material:
		# ตั้งสี glow ตามสีธีมตัวละคร — shader จะ boost เป็น HDR เอง
		glow_aura.material.set_shader_parameter("glow_color", theme_color)

func update_progress(progress: float):
	progress_value = progress
	var ratio = clamp(progress / 100.0, 0.0, 1.0)
	if is_instance_valid(progress_bar) and progress_bar.material:
		progress_bar.material.set_shader_parameter("progress", ratio)
		# ปรับค่าความเรืองแสง: ตอนชาร์จไม่เต็มให้เกจเรืองแสงระดับ 1.3 ตอนชาร์จเต็มดึงกลับลงมา 1.0 เพื่อไม่ให้ Kael บลูมจนขาวโพลน
		if progress >= 100.0:
			progress_bar.material.set_shader_parameter("glow_strength", 1.0)
		else:
			progress_bar.material.set_shader_parameter("glow_strength", 1.3)
		
	if is_instance_valid(glow_aura) and glow_aura.material:
		glow_aura.material.set_shader_parameter("progress", ratio)
		
		# คำนวณอัตราส่วนการสเกลระหว่างปุ่มกับโหนดออร่าเรืองแสง (เพราะออร่ามี offset ขยายออกไปข้างละ 60 พิกเซล)
		var scale_factor = 0.4
		if size.x > 0.0:
			scale_factor = size.x / (size.x + 120.0)
		elif custom_minimum_size.x > 0.0:
			scale_factor = custom_minimum_size.x / (custom_minimum_size.x + 120.0)
		glow_aura.material.set_shader_parameter("button_scale", scale_factor)
		
		# ปรับระดับความเรืองแสงออร่ารอบปุ่ม: ชาร์จเต็มจะสว่างกว่าตอนกำลังชาร์จ
		if progress >= 100.0:
			glow_aura.material.set_shader_parameter("intensity", 1.2)
		else:
			glow_aura.material.set_shader_parameter("intensity", 0.5)
			
	# แสดง/ซ่อน GlowAura ตามสถานะชาร์จ (แสดงเมื่อเริ่มมีการชาร์จ)
	if glow_aura:
		if progress > 0.0:
			glow_aura.show()
		else:
			glow_aura.hide()
			
	# ย้อมสีปุ่มสกิลเมื่อพร้อมใช้ / ยังชาร์จไม่เต็ม (self_modulate ย้อมเฉพาะตัวปุ่มหลัก ไม่ทับ progressBar)
	if progress >= 100.0:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		self_modulate = Color(0.3, 0.3, 0.35, 1.0)
		modulate = Color(1.0, 1.0, 1.0, 1.0)
