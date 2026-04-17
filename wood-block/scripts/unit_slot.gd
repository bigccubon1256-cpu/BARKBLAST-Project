extends Button

var unit_data: Dictionary 

# 🌟 ประกาศโหนด NameLabel ที่เราเพิ่งสร้างเพิ่มเข้าไป
@onready var icon_node = $Icon
@onready var cost_label = $CostLabel
@onready var name_label = $NameLabel 

func setup(data: Dictionary):
	unit_data = data 
	
	if cost_label:
		cost_label.text = "EN: " + str(data["cost"])
		
	# 🌟 ระบบโชว์ชื่อ: ดึง display_name มาใช้ ถ้าไม่มีให้เอา name ปกติมาทำตัวพิมพ์ใหญ่
	if name_label:
		var d_name = data.get("display_name", str(data["name"]).to_upper())
		name_label.text = d_name

	# ถ้ามีรูปให้เปลี่ยน
	if data.has("icon") and icon_node:
		icon_node.texture = data["icon"]

func update_count_display(current_placed: int):
	# 1. ดึงค่า max_count จากข้อมูลตัวละคร
	var max_c = unit_data.get("max_count", -1)
	var label = $CountLabel 
	
	# 2. ถ้าเป็นอินฟินิตี้ ให้โชว์เครื่องหมาย ∞
	if max_c == -1:
		label.text = "∞"
	else:
		# --- จุดสำคัญ: สูตรคำนวณให้ "ลดลง" ---
		# เอา "สิทธิ์สูงสุด" ลบด้วย "จำนวนที่วางไปแล้ว"
		var remaining = max_c - current_placed
		
		# ป้องกันเลขติดลบ (เผื่อบั๊ก)
		if remaining < 0: remaining = 0
		
		# แสดงผลเป็น [จำนวนที่เหลือ] / [จำนวนทั้งหมด]
		label.text = str(remaining) + "/" + str(max_c)
		
		# 3. ถ้าเหลือ 0 ให้ปิดปุ่มและเปลี่ยนเป็นสีแดง
		if remaining <= 0:
			label.modulate = Color(1, 0, 0) # สีแดง
			self.disabled = true            # กดปุ่มไม่ได้
		else:
			label.modulate = Color(1, 1, 1) # สีขาวปกติ
			self.disabled = false
