extends Label3D

var duration: float = 1.6
var elapsed: float = 0.0
var dot_timer: float = 0.0
var dot_count: int = 1

func _ready():
	# Set billboard mode (1 corresponds to BaseMaterial3D.BILLBOARD_ENABLED)
	billboard = 1 
	
	# Load the Jersey 10 pixel font
	var pixel_font = load("res://assets/Font/Jersey_10/Jersey10-Regular.ttf")
	if pixel_font:
		font = pixel_font
	
	# Style the 3D text in retro orange style with black outline
	font_size = 64
	outline_size = 12
	outline_modulate = Color.BLACK
	modulate = Color(1.0, 0.502, 0.0, 1.0) # Vibrant orange
	
	# Position the label locally above the character's head
	position = Vector3(0, 2.2, 0)
	
	text = "RELOADING."

func _process(delta: float):
	elapsed += delta
	if elapsed >= duration:
		# Smoothly fade out over 0.2 seconds
		var fade_t = elapsed - duration
		if fade_t < 0.2:
			modulate.a = 1.0 - (fade_t / 0.2)
			outline_modulate.a = 1.0 - (fade_t / 0.2)
		else:
			queue_free()
			return
			
	# Looping dot animation (adds . -> .. -> ... every 0.4s)
	dot_timer += delta
	if dot_timer >= 0.4:
		dot_timer = 0.0
		dot_count += 1
		if dot_count > 3:
			dot_count = 1
		text = "RELOADING" + ".".repeat(dot_count)
		
	# รักษาขนาดตัวหนังสือให้เท่ากันทุกระยะสายตา (Constant Screen-Space Size)
	var camera = get_viewport().get_camera_3d()
	if camera:
		var dist = global_position.distance_to(camera.global_position)
		# ใช้ระยะทาง 10.0 หน่วยเป็นระยะอ้างอิง (ที่สเกล 1.0)
		# เมื่อกล้องไกลขึ้น ขนาดโมเดลจะเพิ่มขึ้นตาม เพื่อชดเชยทัศนมิติ (perspective)
		var ref_dist = 10.0
		var target_scale = dist / ref_dist
		# จำกัดสเกลไม่ให้เล็กหรือใหญ่จนเกินไปหากกล้องอยู่ใกล้หรือไกลสุดขอบขั้ว
		target_scale = clamp(target_scale, 0.3, 10.0)
		scale = Vector3.ONE * target_scale
