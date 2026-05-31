extends CanvasLayer

var mouse_sprite: Sprite2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128
	mouse_sprite = Sprite2D.new()
	add_child(mouse_sprite)
	
	# 1. [เปลี่ยนรูป] เอาไฟล์เมาส์ของพี่มาใส่ตรงนี้แทน icon.svg
	# เช่น mouse_sprite.texture = load("res://my_cursor.png")
	mouse_sprite.texture = load("res://assets/foto/mouseUI04.png") 
	
	# 2. [ปรับขนาด] เลขน้อย = ตัวเล็ก / เลขมาก = ตัวใหญ่
	# ลองปรับเป็น 0.2 หรือ 0.3 ดูครับถ้ามันใหญ่ไป
	mouse_sprite.scale = Vector2(0.3, 0.3) 
	
	# 3. [ปรับจุดคลิก] ถ้าเมาส์พี่เป็นรูปลูกศร 
	# ให้ตั้งค่า offset เพื่อให้ปลายลูกศรตรงกับจุดคลิกจริง
	# mouse_sprite.offset = Vector2(20, 20) 
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta: float) -> void:
	var viewport_rect = get_viewport().get_visible_rect()
	var target_pos = get_viewport().get_mouse_position()
	
	# จำกัดตำแหน่งเมาส์ไม่ให้หลุดขอบหน้าจอเด็ดขาด (แก้ปัญหาเมาส์ปลิวหาย)
	target_pos.x = clamp(target_pos.x, 0.0, viewport_rect.size.x)
	target_pos.y = clamp(target_pos.y, 0.0, viewport_rect.size.y)
	
	# สแนปตรงตามการเคลื่อนไหวทันที (Instant Snap) ป้องกันอาการหน่วง สั่น หรือกระตุก
	mouse_sprite.global_position = target_pos
	
	# ส่วนเสริม: เอฟเฟกต์สี (ลบทิ้งได้ถ้าไม่ชอบครับ)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		mouse_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0) # เปลี่ยนสีนิดๆ ตอนคลิก
		mouse_sprite.scale = mouse_sprite.scale.lerp(Vector2(0.25, 0.25), 0.2)
	else:
		mouse_sprite.modulate = Color.WHITE
		mouse_sprite.scale = mouse_sprite.scale.lerp(Vector2(0.3, 0.3), 0.2)

