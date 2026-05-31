extends BaseButton # รองรับทั้ง Button และ TextureButton

@onready var label = $Label # ดึง Label ที่อยู่ข้างในมาใช้งาน

# 🌟 ตัวแปรพวกนี้จะไปโผล่ใน Inspector ให้ลูกพี่ปรับแยกแต่ละปุ่มได้เลย
@export var press_offset_y: float = 2.0 # เวลากดให้ตัวหนังสือเลื่อนลงกี่พิกเซล
@export var hover_scale: float = 1.05 # เวลาเมาส์ชี้ให้ตัวหนังสือขยายกี่เปอร์เซ็นต์
@export var hover_color: Color = Color(1.2, 1.2, 1.2) # สีสว่างขึ้นเวลาเอาเมาส์ชี้

var original_pos: Vector2
var original_scale: Vector2
var is_initialized: bool = false

var hover_tween: Tween
var press_tween: Tween

func _ready():
	# ตรวจสอบก่อนว่ามี Label จริงๆ ไหม จะได้ไม่ Error
	if not label:
		set_process(false)
		return
		
	# เชื่อม Signal จังหวะต่างๆ ของปุ่มด้วยโค้ด
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# เรียกใช้การตั้งค่าขนาดให้มั่นใจว่าได้ขนาดที่ถูกต้องที่สุดหลังจากผ่านเฟรมแรก
	call_deferred("ensure_initialized")

func ensure_initialized():
	if is_initialized:
		return
	
	if not label:
		return
		
	# บังคับอัปเดต transform ของ Label เพื่อให้ได้ขนาดที่แท้จริง
	label.force_update_transform()
	
	# ชดเชยการเปลี่ยน pivot_offset เพื่อป้องกันไม่ให้ตำแหน่ง Label เลื่อนเพี้ยน
	var old_pivot = label.pivot_offset
	var new_pivot = label.size / 2.0
	label.pivot_offset = new_pivot
	label.position -= (new_pivot - old_pivot) * (Vector2.ONE - label.scale)
	
	original_pos = label.position
	original_scale = label.scale
	is_initialized = true

func _on_button_down():
	ensure_initialized()
	if press_tween and press_tween.is_valid():
		press_tween.kill()
	
	# ปรับระยะขยับตามขนาดสเกลของตัวหนังสือจริงเพื่อให้สมส่วนกันทุกปุ่ม
	var actual_offset = press_offset_y * original_scale.y
	
	# จังหวะ "กดปุ่ม" -> ให้ตัวหนังสือเลื่อนลงตามภาพปุ่มที่บุ๋มลงไป
	press_tween = create_tween()
	press_tween.tween_property(label, "position:y", original_pos.y + actual_offset, 0.05)

func _on_button_up():
	ensure_initialized()
	if press_tween and press_tween.is_valid():
		press_tween.kill()
		
	# จังหวะ "ปล่อยปุ่ม" -> เช็คว่าเมาส์ยังอยู่บนปุ่มไหมเพื่อเลือกแอนิเมชันคืนค่า
	press_tween = create_tween()
	if is_hovered():
		# ถ้าปล่อยเมาส์ในปุ่ม -> ให้เด้งกลับที่เดิม (ใส่ Ease Out Bounce ให้ดูเด้งดึ๋งสวยงาม)
		press_tween.tween_property(label, "position:y", original_pos.y, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	else:
		# ถ้าปล่อยเมาส์นอกปุ่ม (ลากออกไปแล้วปล่อย) -> คืนตำแหน่งปกติแบบนุ่มนวลธรรมดา
		press_tween.tween_property(label, "position:y", original_pos.y, 0.1)

func _on_mouse_entered():
	ensure_initialized()
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	# จังหวะ "เมาส์ชี้" -> ขยายขนาดนิดนึง และเปลี่ยนสีให้สว่างขึ้น
	hover_tween = create_tween()
	hover_tween.tween_property(label, "scale", original_scale * hover_scale, 0.1)
	hover_tween.parallel().tween_property(label, "modulate", hover_color, 0.1)
	
	# ถ้าลากเมาส์กลับเข้ามาในปุ่มในขณะที่ยังกดปุ่มแช่อยู่ -> ให้ตัวหนังสือยุบลงไปอีกครั้งให้สมดุล
	if is_pressed():
		if press_tween and press_tween.is_valid():
			press_tween.kill()
		var actual_offset = press_offset_y * original_scale.y
		press_tween = create_tween()
		press_tween.tween_property(label, "position:y", original_pos.y + actual_offset, 0.05)

func _on_mouse_exited():
	ensure_initialized()
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	if press_tween and press_tween.is_valid():
		press_tween.kill()
		
	# จังหวะ "เมาส์ออก" -> คืนค่าสี สเกล และตำแหน่ง Y กลับเป็นปกติ (เพราะเทกเจอร์ปุ่มยกตัวคืนแล้ว)
	hover_tween = create_tween()
	hover_tween.tween_property(label, "scale", original_scale, 0.1)
	hover_tween.parallel().tween_property(label, "modulate", Color.WHITE, 0.1)
	
	press_tween = create_tween()
	press_tween.tween_property(label, "position:y", original_pos.y, 0.1)
