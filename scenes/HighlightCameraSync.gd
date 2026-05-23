extends Camera3D
# ==========================================
# HighlightCameraSync.gd — sync กล้องหลักทุกเฟรม
# แก้บั๊ก: ใช้ get_tree().root เพื่อหา main viewport camera
# (get_viewport() ภายใน SubViewport จะคืน SubViewport ตัวเอง ไม่ใช่ main viewport)
# ==========================================

func _process(_delta: float) -> void:
	# ดึงกล้องหลักจาก ROOT viewport (ไม่ใช่จาก SubViewport ที่เราอยู่)
	var main_cam := get_tree().root.get_camera_3d()

	if is_instance_valid(main_cam) and main_cam != self:
		# ซิงค์ทุกอย่างให้ตรงกับกล้องหลัก
		global_transform = main_cam.global_transform
		fov              = main_cam.fov
		near             = main_cam.near
		far              = main_cam.far
		keep_aspect      = main_cam.keep_aspect
		projection       = main_cam.projection
		
		# ป้องกันไม่ให้กล้องหลักเห็น Layer 20 (ที่เป็น silhouette สีทึบ)
		main_cam.cull_mask = main_cam.cull_mask & ~(1 << 19)
