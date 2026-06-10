extends Panel

@onready var title_label: RichTextLabel = $VBox/TitleLabel
@onready var desc_label: RichTextLabel = $VBox/DescLabel
@onready var cond_label: RichTextLabel = $VBox/CondLabel
@onready var status_label: RichTextLabel = $VBox/StatusLabel

func update_text(skill_name: String, skill_desc: String, skill_cond: String, progress: float, theme_color: Color):
	# แสดงผลชื่อสกิล โดยใช้สไตล์และขนาดฟอนต์ (Jersey 10) ที่ตั้งไว้ใน Inspector
	title_label.text = skill_name
	
	# ย้อมสีชื่อสกิลด้วยสีธีมตัวละคร โดยให้ตัวอักษรด้านในเข้มขึ้น และขอบเรืองแสงเป็นสีธีมหลัก (Boost ค่าสีขึ้นเพื่อกระตุ้น 2D HDR Glow)
	var glow_boost_color = Color(theme_color.r * 2.5, theme_color.g * 2.5, theme_color.b * 2.5, 1.0)
	title_label.add_theme_color_override("font_outline_color", glow_boost_color)
	var dark_fill = Color(theme_color.r * 0.15, theme_color.g * 0.15, theme_color.b * 0.15, 1.0)
	title_label.add_theme_color_override("default_color", dark_fill)
	
	desc_label.text = skill_desc
	cond_label.text = skill_cond
	
	# ย้อมสีขอบเรืองแสงของหน้าต่าง (StyleBoxFlat) โดยลอกลายสไตล์บ็อกเพื่อความปลอดภัยไม่ตีกัน
	var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style:
		style.border_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.6)
		add_theme_stylebox_override("panel", style)
	
	if progress >= 100.0:
		status_label.text = "FULLY CHARGED (Click again to USE)"
		status_label.add_theme_color_override("default_color", Color(0.642, 0.936, 0.0, 1.0)) # สีเขียวเด่น
	else:
		status_label.text = "Charge: " + str(int(progress)) + "%"
		status_label.remove_theme_color_override("default_color") # รีเซ็ตกลับสีของ Inspector
