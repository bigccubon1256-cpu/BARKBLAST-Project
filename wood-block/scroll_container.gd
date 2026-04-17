extends ScrollContainer

func _input(event):
	# 1. เช็คว่าเป็นเหตุการณ์หมุนล้อเมาส์ (MouseButton)
	if event is InputEventMouseButton:
		
		# 2. [หัวใจสำคัญ] เช็คว่าตอนนี้เมาส์กำลังชี้อยู่ "ข้างใน" พื้นที่ของ ScrollContainer หรือเปล่า?
		# get_global_rect() คือการหาขอบเขตสี่เหลี่ยมของตัวร้านค้าบนหน้าจอ
		if get_global_rect().has_point(get_global_mouse_position()):
			
			# 3. ถ้าเมาส์อยู่ในกรอบ และมีการหมุนล้อเมาส์ ให้เลื่อนแนวนอนทันที
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll_horizontal -= 60 # ปรับเลข 60 เพิ่ม/ลด ความเร็วได้ตามใจชอบครับ
				accept_event() # บอก Godot ว่า "ข้าจัดการแล้ว" คนอื่นไม่ต้องยุ่ง!
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll_horizontal += 60
				accept_event()
