extends Control

@onready var progress_bar = $ProgressBar
# อ้างอิงโหนดตัวหนังสือที่ลูกพี่เอาไว้โชว์คำว่า LOADING อย่างเดียว
@onready var loading_label = $LoadingLabel 

# ==========================================
# 🌟 ตัวแปรสำหรับแอนิเมชันจุด (Dot Animation)
# ==========================================
var dot_timer: float = 0.0
var dot_count: int = 1

func _ready():
	ResourceLoader.load_threaded_request(Global.next_scene_path)

func _process(delta):
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(Global.next_scene_path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# 1. อัปเดตหลอดเปอร์เซ็นต์ (ปล่อยให้มันโชว์ตัวเลขเองตามที่ตั้งค่าใน Inspector)
		if progress_bar:
			progress_bar.value = progress[0] * 100
			
		# ==========================================
		# 🌟 2. ระบบคำนวณจุดไข่ปลา (แยกทำเฉพาะตัวหนังสือ)
		# ==========================================
		dot_timer += delta 
		
		if dot_timer >= 0.4:
			dot_timer = 0.0
			dot_count += 1
			if dot_count > 3: 
				dot_count = 1
				
		var dots = ".".repeat(dot_count)
			
		if loading_label:
			# อัปเดตแค่คำว่า LOADING แล้วต่อด้วยจุด 
			# (ไม่มีเปอร์เซ็นต์มาปนแล้ว เพราะให้หลอดโหลดมันจัดการเอง)
			loading_label.text = "LOADING" + dots
			
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		if loading_label:
			loading_label.text = "LOADING..."
			
		var next_scene = ResourceLoader.load_threaded_get(Global.next_scene_path)
		get_tree().change_scene_to_packed(next_scene)
		
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		print("❌ บั๊ก! โหลดฉากไม่สำเร็จ")
