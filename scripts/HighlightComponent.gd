extends Node
# ==========================================
# HighlightPulsingComponent.gd — Post-Process Outline (Professional Version)
# ใช้ SubViewport Silhouette + 2D Dilation Shader
# = outline สวยงามเหมือนเกม AAA ทำงานได้กับทุกรูปทรง
# ==========================================

@export var base_material: ShaderMaterial  # ไม่ต้องใช้แล้ว (legacy export)

# Silhouette shader resource (โหลดครั้งเดียว shared ทุก instance)
static var _sil_res: ShaderMaterial = null

# Per-instance duplicated material (แยก instance กัน เพื่อ animate alpha ได้อิสระ)
var _inst_mat: ShaderMaterial = null

# Duplicate MeshInstance3D ที่เราสร้างไว้ใน layer 20
var _duplicates: Array[MeshInstance3D] = []

# State
var _is_active: bool    = false
var _is_blinking: bool  = false
var _t: float           = 0.0
var _hl_color: Color    = Color.WHITE
var _hl_speed: float    = 1.0
var _hl_min_a: float    = 0.2
var _flash_dur: float   = 0.0
var _flash_t: float     = 0.0


func _ready() -> void:
	set_process(false)
	# โหลด silhouette material resource ครั้งเดียว
	if not _sil_res:
		_sil_res = load("res://Shader/SilhouetteMaterial.tres") as ShaderMaterial
	
	# เรียกแบบ deferred เพื่อป้องกันความขัดแย้งขณะที่ Scene Tree กำลังทำความสะอาด/สร้างโหนด
	_ensure_highlight_system_setup.call_deferred()


# ============================================================
# DYNAMIC SETUP (ระบบสร้าง Viewport / Camera อัตโนมัติ เพื่อรองรับทุกด่าน)
# ============================================================
func _ensure_highlight_system_setup() -> void:
	var current_scene = get_tree().current_scene
	if not current_scene:
		return

	# 1. ค้นหากล้องหลักของฉาก และคัดแกน Layer 20 ออก เพื่อไม่ให้เกิดภาพซ้อนหรือสีขาวทึบ
	var main_cam := get_tree().root.get_camera_3d()
	if is_instance_valid(main_cam) and main_cam != self:
		main_cam.cull_mask = main_cam.cull_mask & ~(1 << 19)

	# 2. ค้นหาหรือสร้าง HighlightLayer ลำดับ 100
	var hl_layer = current_scene.get_node_or_null("HighlightLayer")
	if not hl_layer:
		# สร้าง CanvasLayer สำหรับโชว์ Outline วาดทับหน้าจอ
		hl_layer = CanvasLayer.new()
		hl_layer.name = "HighlightLayer"
		hl_layer.layer = 100
		current_scene.add_child(hl_layer)

		# สร้าง SubViewportContainer แบบขยายเต็มหน้าจอ และไม่บังปุ่มหรือขัดขวางการคลิกเมาส์
		var container = SubViewportContainer.new()
		container.name = "HighlightViewportContainer"
		container.anchors_preset = Control.PRESET_FULL_RECT
		container.anchor_right = 1.0
		container.anchor_bottom = 1.0
		container.grow_horizontal = Control.GROW_DIRECTION_BOTH
		container.grow_vertical = Control.GROW_DIRECTION_BOTH
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.stretch = true
		hl_layer.add_child(container)

		# โหลด Shader 2D Dilation เพื่อเบ่งสี Silhouette ให้ขยายเป็นขอบ
		var outline_shader = load("res://Shader/Outline2D.gdshader") as Shader
		if outline_shader:
			var outline_mat = ShaderMaterial.new()
			outline_mat.shader = outline_shader
			outline_mat.set_shader_parameter("outline_width", 4.0)
			container.material = outline_mat

		# สร้าง SubViewport ที่แชร์ World 3D ร่วมกับด่านหลัก
		var viewport = SubViewport.new()
		viewport.name = "HighlightViewport"
		viewport.transparent_bg = true
		viewport.own_world_3d = false
		viewport.size = Vector2i(1920, 1080)
		container.add_child(viewport)

		# สร้าง HighlightCamera เพื่อถ่ายทำเฉพาะ Layer 20
		var hl_cam = Camera3D.new()
		hl_cam.name = "HighlightCamera"
		hl_cam.cull_mask = (1 << 19) # Layer 20 เท่านั้น
		var sync_script = load("res://scenes/HighlightCameraSync.gd") as Script
		if sync_script:
			hl_cam.set_script(sync_script)
		viewport.add_child(hl_cam)


# ============================================================
# PUBLIC API (เหมือนเดิมทุก signature — MainManager.gd ไม่ต้องแก้)
# ============================================================

func enable_highlight(custom_color: Color = Color.WHITE,
		start_blink: bool = true,
		blink_speed: float = 1.0,
		min_alpha: float = 0.2) -> void:

	var color_changed = (_hl_color != custom_color)
	var speed_changed = (_hl_speed != blink_speed)
	var min_a_changed = (_hl_min_a != min_alpha)

	_hl_color   = custom_color
	_is_blinking = start_blink
	_hl_speed   = blink_speed
	_hl_min_a   = min_alpha
	_flash_dur  = 0.0
	_flash_t    = 0.0
	
	# รีเซ็ตอนิเมชันคลื่นเฉพาะเมื่อเปิดใช้งานครั้งแรก หรือมีการเปลี่ยนค่าสปีด/สีอย่างมีนัยสำคัญ
	# ช่วยป้องกันอาการไฟค้างหรือดับลงไปสนิทตอนเมาส์ลากผ่านในทุกๆ เฟรม
	if not _is_active or color_changed or speed_changed or min_a_changed:
		_t = 0.0

	_ensure_highlight_system_setup()

	if _is_active:
		# แค่อัปเดตสีใหม่ ไม่ต้อง rebuild
		if _inst_mat:
			_inst_mat.set_shader_parameter("silhouette_color", custom_color)
		if start_blink:
			set_process(true)
		return

	_build_duplicates(custom_color)
	_is_active = true
	if start_blink:
		set_process(true)


func disable_highlight() -> void:
	if not _is_active:
		return
	_is_active   = false
	_is_blinking = false
	_flash_t     = 0.0
	_flash_dur   = 0.0
	set_process(false)

	for dup in _duplicates:
		if is_instance_valid(dup):
			dup.queue_free()
	_duplicates.clear()
	_inst_mat = null


func flash_highlight(duration: float,
		color: Color,
		blink_speed: float = 2.0,
		min_alpha: float = 0.1) -> void:

	enable_highlight(color, true, blink_speed, min_alpha)
	_flash_dur = duration
	_flash_t   = duration
	set_process(true)


# ============================================================
# PROCESS (ทำงานเฉพาะตอน highlight เปิดอยู่)
# ============================================================

func _process(delta: float) -> void:
	if not _is_active:
		set_process(false)
		return

	# ซิงค์ transform ให้ duplicate ตามตัวละคร (รองรับ physics movement)
	for dup in _duplicates:
		if is_instance_valid(dup) and is_instance_valid(dup.get_parent()):
			# Duplicate เป็น child ของ mesh → ไม่ต้องซิงค์ (inherit transform อัตโนมัติ)
			pass

	# นับถอยหลัง flash
	if _flash_dur > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			disable_highlight()
			return

	# Pulse/Blinking animation (สไตล์ AAA ค่อยๆ สว่างขึ้นและดับลงสมบูรณ์แบบ)
	if _is_blinking and _inst_mat:
		_t += delta
		# ใช้ลบโคไซน์ (-cos) เพื่อให้ค่าคลื่นเริ่มจาก 0.0 (ดับสนิท) ขึ้นไปสูงสุด และจบที่ 0.0 (ดับสนิท) เสมอ
		var s = (-cos(_t * _hl_speed * TAU) + 1.0) * 0.5
		var a = lerp(_hl_min_a, _hl_color.a, s)
		_inst_mat.set_shader_parameter("silhouette_color",
			Color(_hl_color.r, _hl_color.g, _hl_color.b, a))


# ============================================================
# PRIVATE
# ============================================================

func _build_duplicates(color: Color) -> void:
	_duplicates.clear()

	if not _sil_res:
		push_error("HighlightComponent: ไม่พบ SilhouetteMaterial.tres")
		return

	_ensure_highlight_system_setup()

	# Duplicate material ใหม่ต่อ instance เพื่อ animate ได้อิสระ
	_inst_mat = _sil_res.duplicate() as ShaderMaterial
	_inst_mat.set_shader_parameter("silhouette_color", color)

	# ค้นหา MeshInstance3D ทั้งหมดใน parent (ตัวละคร/ปืน)
	var meshes: Array[MeshInstance3D] = []
	_find_meshes(get_parent(), meshes)

	for mesh in meshes:
		if not is_instance_valid(mesh) or not mesh.mesh or not mesh.is_visible_in_tree():
			continue

		# สร้าง duplicate ที่มี mesh เดียวกัน (share mesh resource)
		var dup := MeshInstance3D.new()
		dup.mesh            = mesh.mesh
		dup.layers          = (1 << 19)        # Layer 20 → HighlightCamera เห็น, Main camera ไม่เห็น
		dup.material_override = _inst_mat       # ใช้ silhouette material ทับทั้งหมด
		dup.cast_shadow     = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		# เพิ่มเป็น child ของ mesh ต้นฉบับ → inherit transform อัตโนมัติ
		mesh.add_child(dup)
		_duplicates.append(dup)


func _find_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		# ข้าม HighlightPulsingComponent ของตัวเอง
		if child.name == "HighlightPulsingComponent":
			continue
		# ข้าม node ที่มี component ของตัวเอง (เช่น ปืนที่ติดกับตัวละคร)
		if child.has_node("HighlightPulsingComponent"):
			continue
		# ข้าม AnimatedSprite3D (ไม่ใช่ 3D mesh จริง)
		if child is AnimatedSprite3D:
			continue
		if child is MeshInstance3D and child.mesh != null:
			result.append(child as MeshInstance3D)
		_find_meshes(child, result)
