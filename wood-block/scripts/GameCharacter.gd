extends Node3D

@export var slot_scene: PackedScene
@export var snap_step: float = 0.25
@export var min_unit_distance: float = 0.9

@onready var combat_menu = $HUD/CombatMenu
@onready var hp_display = $HUD/HPLabel
@onready var energy_bar = $HUD/EnergyBar
@onready var unit_list_container = $HUD/VBoxContainer/ScrollContainer/UnitList
@onready var action_menu = $HUD/ActionMenu
@onready var error_sound_player = $ErrorSoundPlayer

var army_list = [
	{"name": "forces", "category": "character", "cost": 1.0, "hp_gain": 10, "scene": preload("res://forces.tscn"), "icon": preload("res://assets/foto/ForceforUI.png"), "max_count": -1},
	{"name": "soren", "category": "character", "cost": 0.0, "hp_gain": 10, "scene": preload("res://soren.tscn"), "icon": preload("res://assets/foto/SammyforUI.png"), "max_count": 1},
	{"name": "block", "category": "block", "cost": 0.5, "scene": preload("res://construction_block.tscn"), "icon": preload("res://assets/foto/wb023forUI.png"), "max_count": -1}, 
	{"name": "gun", "category": "gun", "cost": 2.0, "scene": preload("res://gun.tscn"), "icon": preload("res://assets/foto/gun01forUI.png"), "max_count": -1}
]

var total_hp: int = 0
var current_energy: float = 10.0
var occupied_tiles = {}
var dragging_unit: Node3D = null
var selected_unit: Node3D = null
var unit_data: Dictionary

var press_timer: float = 0.0
var is_pressing: bool = false
const LONG_PRESS_TIME: float = 0.15
var is_moving_existing_unit: bool = false

var build_boundary_limit = 50.0
var dragging_gun: Node3D = null
var gun_offset: Vector3 = Vector3.ZERO
var is_game_started: bool = false

# --- ระบบต่อสู้ ---
var is_combat_aiming: bool = false
var active_combat_unit: Node3D = null
var initial_aim_rotation: float = 0.0
var current_aim_offset: float = 0.0
var MAX_AIM_ANGLE: float = deg_to_rad(60.0)

func _ready():
	draw_grid(50.0, snap_step, build_boundary_limit)
	action_menu.hide()
	if combat_menu:
		combat_menu.hide()
	update_unit_menu("character")
	update_ui()
	
	var btn_shoot = combat_menu.get_node_or_null("BtnCombatShoot")
	if btn_shoot:
		btn_shoot.pressed.connect(_on_btn_combat_shoot_pressed)

func setup(data: Dictionary):
	unit_data = data
	$CostLabel.text = "EN: " + str(data["cost"])
	if data.has("icon"):
		$Icon.texture = data["icon"]

func update_unit_menu(filter_category: String):
	for child in unit_list_container.get_children():
		child.queue_free()
	for data in army_list:
		if data.get("category") == filter_category or filter_category == "all":
			var slot = slot_scene.instantiate()
			unit_list_container.add_child(slot)
			slot.setup(data)
			slot.button_down.connect(_on_unit_slot_down.bind(slot))
	update_ui()

func _on_unit_slot_down(slot):
	if current_energy >= slot.unit_data["cost"]:
		action_menu.hide()
		selected_unit = null
		unit_data = slot.unit_data 
		dragging_unit = slot.unit_data["scene"].instantiate()
		add_child(dragging_unit)
		toggle_collision(dragging_unit, true)
	else:
		if error_sound_player:
			error_sound_player.play()
		print("Energy ไม่พอซื้อยูนิตนี้!")

func get_unit_count_on_field(target_name: String) -> int:
	var count = 0
	for unit in get_children():
		if is_instance_valid(unit) and unit != dragging_unit:
			var u_name = ""
			if unit.get("unit_name") != null:
				u_name = unit.get("unit_name")
			elif "unit_data" in unit and unit.unit_data.has("name"):
				u_name = unit.unit_data["name"]
			if u_name == target_name:
				count += 1
	return count

func get_unit_global_aabb(pos: Vector3, basis: Basis, unit: Node3D) -> AABB:
	var extents = Vector3(0.5, 1.5, 0.25)
	for child in unit.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			extents = child.shape.size / 2.0
			break
	var e = extents - Vector3(0.05, 0.05, 0.05)
	var gx = abs(basis.x.x * e.x) + abs(basis.y.x * e.y) + abs(basis.z.x * e.z)
	var gy = abs(basis.x.y * e.x) + abs(basis.y.y * e.y) + abs(basis.z.y * e.z)
	var gz = abs(basis.x.z * e.x) + abs(basis.y.z * e.y) + abs(basis.z.z * e.z)
	var global_extents = Vector3(gx, gy, gz)
	return AABB(pos - global_extents, global_extents * 2.0)

func is_position_safe(target_pos: Vector3, current_unit: Node3D) -> bool:
	var my_aabb = get_unit_global_aabb(target_pos, current_unit.global_transform.basis, current_unit)
	for unit in get_children():
		if not is_instance_valid(unit) or unit.is_queued_for_deletion() or unit == current_unit or unit == dragging_unit or unit == dragging_gun: 
			continue
		if "unit_name" in unit or "unit_data" in unit:
			var other_aabb = get_unit_global_aabb(unit.global_position, unit.global_transform.basis, unit)
			if my_aabb.intersects(other_aabb):
				return false 
	return true

func _process(delta: float) -> void:
	if dragging_unit:
		var pos = get_ground_position()
		if pos != Vector3.ZERO:
			var snap_x = snapped(pos.x, snap_step)
			var snap_z = snapped(pos.z, snap_step)
			var current_aabb = get_unit_global_aabb(dragging_unit.global_position, dragging_unit.global_transform.basis, dragging_unit)
			var target_y = current_aabb.size.y / 2.0
			
			dragging_unit.global_position = Vector3(snap_x, target_y, snap_z)

			var max_stack_levels = 40
			var step_count = 0
			while not is_position_safe(dragging_unit.global_position, dragging_unit) and step_count < max_stack_levels:
				target_y += 0.25
				dragging_unit.global_position.y = target_y
				step_count += 1
			
			var current_pos = dragging_unit.global_position
			var is_safe = is_position_safe(current_pos, dragging_unit)
			var is_in_bounds = is_within_boundary(current_pos)
			
			var is_hero_limit_reached = false
			if not is_moving_existing_unit:
				var max_c = unit_data.get("max_count", -1)
				if max_c != -1:
					var current_count = get_unit_count_on_field(unit_data["name"])
					if current_count >= max_c:
						is_hero_limit_reached = true
			
			var is_within_gun_radius = true
			if unit_data.get("category") == "gun":
				is_within_gun_radius = false 
				var max_radius = 2.0 
				var nearest_char = null
				var min_dist = max_radius
				
				for tile_unit in occupied_tiles.values():
					if is_instance_valid(tile_unit):
						var t_name = tile_unit.get("unit_name")
						if t_name == "soren" or t_name == "forces":
							if tile_unit.has_meta("linked_gun") and is_instance_valid(tile_unit.get_meta("linked_gun")):
								if tile_unit.get_meta("linked_gun") != dragging_unit:
									continue
							var dist = current_pos.distance_to(tile_unit.global_position)
							if dist <= min_dist:
								min_dist = dist
								nearest_char = tile_unit
								
				if nearest_char:
					is_within_gun_radius = true
					dragging_unit.global_rotation.y = nearest_char.global_rotation.y + deg_to_rad(90)

			var gun_safe = true
			if dragging_gun and is_instance_valid(dragging_gun):
				dragging_gun.global_position = dragging_unit.global_position + gun_offset
				gun_safe = is_position_safe(dragging_gun.global_position, dragging_gun)
			
			var can_place = is_safe and is_in_bounds and not is_hero_limit_reached and is_within_gun_radius and gun_safe

			if can_place:
				set_unit_preview_color(dragging_unit, Color(0.0, 1.0, 1.0, 0.502)) 
				if dragging_gun: set_unit_preview_color(dragging_gun, Color(0.0, 1.0, 1.0, 0.502))
			else:
				set_unit_preview_color(dragging_unit, Color(1, 0, 0, 0.5))
				if dragging_gun: set_unit_preview_color(dragging_gun, Color(1, 0, 0, 0.5))
	
	if is_pressing and selected_unit and not dragging_unit:
		press_timer += delta
		if press_timer >= LONG_PRESS_TIME:
			start_re_drag()

	if is_game_started and selected_unit and is_instance_valid(selected_unit) and combat_menu.visible:
		var cam = get_viewport().get_camera_3d()
		combat_menu.global_position = cam.unproject_position(selected_unit.global_position) + Vector2(60, -60)
	elif not is_game_started and selected_unit and is_instance_valid(selected_unit) and action_menu.visible:
		var cam = get_viewport().get_camera_3d()
		action_menu.global_position = cam.unproject_position(selected_unit.global_position) + Vector2(60, -60)
		var btn_horizontal = action_menu.get_node_or_null("BtnRotateHorizontal") 
		var btn_duplicate = action_menu.get_node_or_null("BtnDuplicate")
		if btn_horizontal:
			var current_name = ""
			if dragging_unit: current_name = unit_data.get("name")
			elif selected_unit: current_name = selected_unit.get("unit_name")
			if current_name == "block":
				btn_horizontal.show()
				if btn_duplicate: btn_duplicate.show()
			else:
				btn_horizontal.hide()
				if btn_duplicate: btn_duplicate.hide()
				
	if is_game_started and is_combat_aiming and is_instance_valid(active_combat_unit):
		var rotate_dir = int(Input.is_physical_key_pressed(KEY_A)) - int(Input.is_physical_key_pressed(KEY_D))
		if rotate_dir != 0:
			current_aim_offset += rotate_dir * 2.5 * delta 
			current_aim_offset = clamp(current_aim_offset, -MAX_AIM_ANGLE, MAX_AIM_ANGLE)
			active_combat_unit.rotation.y = initial_aim_rotation + current_aim_offset
		if active_combat_unit.has_meta("linked_gun"):
			var attached_gun = active_combat_unit.get_meta("linked_gun")
			if is_instance_valid(attached_gun):
				attached_gun.global_rotation.y = active_combat_unit.global_rotation.y + deg_to_rad(90)

func _input(event: InputEvent) -> void:
	if is_game_started:
		if is_combat_aiming:
			var is_right_click = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed)
			var is_esc_key = (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed)
			if is_right_click or is_esc_key:
				cancel_combat_aim()
				return
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				print("ปัง! (เตรียมพร้อมลากง้างยิง)")
				return
			return 
			
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_mouse_over_ui():
				combat_check_selection()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not is_mouse_over_ui():
				is_pressing = true
				press_timer = 0.0
				check_for_unit_selection()
		else:
			is_pressing = false
			press_timer = 0.0
			if dragging_unit:
				finalize_placement()

func is_mouse_over_ui() -> bool:
	if action_menu and action_menu.visible:
		var rect = Rect2(action_menu.global_position, action_menu.get_rect().size * 2) 
		if rect.has_point(get_viewport().get_mouse_position()): return true
	if combat_menu and combat_menu.visible:
		var rect = Rect2(combat_menu.global_position, combat_menu.get_rect().size * 2) 
		if rect.has_point(get_viewport().get_mouse_position()): return true
	return false

func check_for_unit_selection():
	var result = get_raycast_result()
	if result and (result.collider is CharacterBody3D or result.collider is RigidBody3D):
		selected_unit = result.collider
		action_menu.show()
	elif not dragging_unit:
		selected_unit = null
		action_menu.hide()

func combat_check_selection():
	var result = get_raycast_result()
	if result and (result.collider is CharacterBody3D or result.collider is RigidBody3D):
		var u_name = result.collider.get("unit_name")
		if u_name in ["soren", "forces"]:
			selected_unit = result.collider
			combat_menu.show()
		else:
			selected_unit = null
			combat_menu.hide()
	else:
		selected_unit = null
		combat_menu.hide()

func finalize_placement():
	if not dragging_unit: return
	var pos = dragging_unit.global_position
	
	var is_within_gun_radius = true
	var linked_character = null 
	if unit_data.get("category") == "gun":
		is_within_gun_radius = false
		var max_radius = 2.0
		var min_dist = max_radius
		for tile_unit in occupied_tiles.values():
			if is_instance_valid(tile_unit):
				var t_name = tile_unit.get("unit_name")
				if t_name in ["soren", "forces"]:
					if tile_unit.has_meta("linked_gun") and is_instance_valid(tile_unit.get_meta("linked_gun")):
						if tile_unit.get_meta("linked_gun") != dragging_unit: continue
					var dist = pos.distance_to(tile_unit.global_position)
					if dist <= min_dist:
						min_dist = dist
						linked_character = tile_unit 
		if linked_character: is_within_gun_radius = true

	var is_hero_limit = false
	if not is_moving_existing_unit:
		var max_c = unit_data.get("max_count", -1)
		if max_c != -1 and get_unit_count_on_field(unit_data["name"]) >= max_c:
			is_hero_limit = true
			
	var char_safe = is_position_safe(pos, dragging_unit)
	var in_bounds = is_within_boundary(pos)
	var gun_safe = true
	if dragging_gun and is_instance_valid(dragging_gun):
		gun_safe = is_position_safe(dragging_gun.global_position, dragging_gun)

	var can_place = char_safe and in_bounds and not is_hero_limit and gun_safe and is_within_gun_radius

	if can_place:
		if not is_moving_existing_unit:
			var cost = dragging_unit.get("energy_cost") if dragging_unit.get("energy_cost") != null else 1.0
			var hp_gain = dragging_unit.get("hp_gain_on_place") if dragging_unit.get("hp_gain_on_place") != null else 0
			current_energy -= cost
			total_hp += hp_gain
		
		var tile_key = get_tile_key(pos)
		dragging_unit.tile_key = tile_key
		occupied_tiles[tile_key] = dragging_unit
		
		if dragging_gun and is_instance_valid(dragging_gun):
			var gun_key = get_tile_key(dragging_gun.global_position)
			dragging_gun.tile_key = gun_key
			occupied_tiles[gun_key] = dragging_gun
			toggle_collision(dragging_gun, false)
			set_unit_preview_color(dragging_gun, Color(1,1,1,1))
			dragging_gun = null
			
		if unit_data.get("category") == "gun" and linked_character:
			if dragging_unit.has_meta("linked_char"):
				var old_char = dragging_unit.get_meta("linked_char")
				if is_instance_valid(old_char): old_char.set_meta("linked_gun", null)
			linked_character.set_meta("linked_gun", dragging_unit)
			dragging_unit.set_meta("linked_char", linked_character)
			
		toggle_collision(dragging_unit, false)
		if dragging_unit.has_method("activate_unit"): dragging_unit.activate_unit(tile_key)
		set_unit_preview_color(dragging_unit, Color(1,1,1,1))
		
		selected_unit = dragging_unit
		action_menu.show()
		dragging_unit = null
		is_moving_existing_unit = false
	else:
		flash_red_effect(dragging_unit)
		if dragging_gun: flash_red_effect(dragging_gun)
		if error_sound_player: error_sound_player.play()
		
		if is_moving_existing_unit:
			var cost = dragging_unit.get("energy_cost") if dragging_unit.get("energy_cost") != null else 1.0
			var hp_gain = dragging_unit.get("hp_gain_on_place") if dragging_unit.get("hp_gain_on_place") != null else 0
			current_energy += cost
			total_hp -= hp_gain
			
			if dragging_gun and is_instance_valid(dragging_gun):
				var gun_cost = dragging_gun.get("energy_cost") if dragging_gun.get("energy_cost") != null else 2.0
				var gun_hp = dragging_gun.get("hp_gain_on_place") if dragging_gun.get("hp_gain_on_place") != null else 0
				current_energy += gun_cost
				total_hp -= gun_hp
				
		if dragging_gun and is_instance_valid(dragging_gun):
			dragging_gun.queue_free()
		dragging_gun = null 
				
		dragging_unit.queue_free()
		dragging_unit = null
		is_moving_existing_unit = false

	update_ui()

func start_re_drag():
	if selected_unit:
		is_moving_existing_unit = true
		dragging_unit = selected_unit
		var u_name = dragging_unit.get("unit_name")
		for data in army_list:
			if data["name"] == u_name:
				unit_data = data
				break
		occupied_tiles.erase(dragging_unit.tile_key)
		action_menu.hide()
		toggle_collision(dragging_unit, true)
		is_pressing = false 
		
		if dragging_unit.has_meta("linked_gun"):
			var attached_gun = dragging_unit.get_meta("linked_gun")
			if is_instance_valid(attached_gun):
				dragging_gun = attached_gun
				gun_offset = attached_gun.global_position - dragging_unit.global_position
				if occupied_tiles.has(attached_gun.tile_key):
					occupied_tiles.erase(attached_gun.tile_key)
				toggle_collision(dragging_gun, true)

func get_raycast_result():
	var m_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	if not camera: return null
	var query = PhysicsRayQueryParameters3D.create(camera.project_ray_origin(m_pos), camera.project_ray_origin(m_pos) + camera.project_ray_normal(m_pos) * 1000)
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(query)

func _on_btn_rotate_pressed():
	if dragging_unit and is_instance_valid(dragging_unit):
		dragging_unit.global_rotate(Vector3.UP, deg_to_rad(90))
		dragging_unit.rotation_degrees = dragging_unit.rotation_degrees.round()
		dragging_unit.force_update_transform() 
		if is_position_safe(dragging_unit.global_position, dragging_unit):
			set_unit_preview_color(dragging_unit, Color(0.0, 1.0, 1.0, 0.502))
		else:
			set_unit_preview_color(dragging_unit, Color(1, 0, 0, 0.5))
	elif selected_unit and is_instance_valid(selected_unit):
		var old_transform = selected_unit.global_transform
		selected_unit.global_rotate(Vector3.UP, deg_to_rad(90))
		selected_unit.rotation_degrees = selected_unit.rotation_degrees.round()
		selected_unit.force_update_transform() 
		if not is_position_safe(selected_unit.global_position, selected_unit):
			selected_unit.global_transform = old_transform
			flash_red_effect(selected_unit)

func _on_btn_rotate_horizontal_pressed():
	var target_unit = null
	if dragging_unit and is_instance_valid(dragging_unit): target_unit = dragging_unit
	elif selected_unit and is_instance_valid(selected_unit): target_unit = selected_unit
	
	if target_unit and target_unit.get("unit_name") == "block":
		var old_transform = target_unit.global_transform
		target_unit.global_rotate(Vector3.RIGHT, deg_to_rad(90))
		target_unit.rotation_degrees.x = round(target_unit.rotation_degrees.x)
		target_unit.rotation_degrees.y = round(target_unit.rotation_degrees.y)
		target_unit.rotation_degrees.z = round(target_unit.rotation_degrees.z)
		target_unit.force_update_transform()
		
		var current_aabb = get_unit_global_aabb(target_unit.global_position, target_unit.global_transform.basis, target_unit)
		target_unit.global_position.y = current_aabb.size.y / 2.0
			
		var max_stack_levels = 40
		var step_count = 0
		while not is_position_safe(target_unit.global_position, target_unit) and step_count < max_stack_levels:
			target_unit.global_position.y += 0.25
			step_count += 1
		
		target_unit.force_update_transform()

		if is_position_safe(target_unit.global_position, target_unit):
			if target_unit == dragging_unit: set_unit_preview_color(target_unit, Color(0.0, 1.0, 1.0, 0.502))
		else:
			target_unit.global_transform = old_transform
			if target_unit == dragging_unit: set_unit_preview_color(target_unit, Color(1, 0, 0, 0.5))
			else: flash_red_effect(target_unit)

func flash_red_effect(unit: Node3D):
	if has_node("ErrorSoundPlayer"):
		$ErrorSoundPlayer.play()
	var mesh_node = unit.find_child("MeshInstance3D") as MeshInstance3D
	if mesh_node:
		var mat = mesh_node.get_active_material(0)
		if mat is StandardMaterial3D:
			var tween = create_tween()
			tween.tween_property(mat, "albedo_color", Color(1, 0, 0), 0.1)
			tween.tween_property(mat, "albedo_color", Color(1, 1, 1), 0.1)
			tween.tween_property(mat, "albedo_color", Color(1, 0, 0), 0.1)
			tween.tween_property(mat, "albedo_color", Color(1, 1, 1), 0.1)

func _on_btn_delete_pressed():
	if selected_unit and is_instance_valid(selected_unit):
		if selected_unit.has_meta("linked_gun"):
			var attached_gun = selected_unit.get_meta("linked_gun")
			if is_instance_valid(attached_gun):
				current_energy += attached_gun.energy_cost
				total_hp -= attached_gun.hp_gain_on_place
				if occupied_tiles.has(attached_gun.tile_key):
					occupied_tiles.erase(attached_gun.tile_key)
				attached_gun.queue_free()
				
		if selected_unit.has_meta("linked_char"):
			var owner_char = selected_unit.get_meta("linked_char")
			if is_instance_valid(owner_char):
				owner_char.set_meta("linked_gun", null)
		
		current_energy += selected_unit.energy_cost
		total_hp -= selected_unit.hp_gain_on_place
		if occupied_tiles.has(selected_unit.tile_key):
			occupied_tiles.erase(selected_unit.tile_key)
		
		selected_unit.queue_free()
		selected_unit = null
		action_menu.hide()
		update_ui()

func _on_btn_duplicate_pressed():
	if selected_unit and is_instance_valid(selected_unit) and selected_unit.get("unit_name") == "block":
		var target_data = null
		for data in army_list:
			if data["name"] == "block":
				target_data = data
				break
		if target_data == null: return
		
		if current_energy >= target_data["cost"]:
			action_menu.hide()
			unit_data = target_data 
			dragging_unit = target_data["scene"].instantiate()
			add_child(dragging_unit)
			dragging_unit.global_transform.basis = selected_unit.global_transform.basis
			toggle_collision(dragging_unit, true)
			selected_unit = null
			is_moving_existing_unit = false
		else:
			if error_sound_player: error_sound_player.play()

func _on_btn_combat_shoot_pressed():
	if selected_unit and is_instance_valid(selected_unit):
		is_combat_aiming = true
		active_combat_unit = selected_unit
		combat_menu.hide()
		initial_aim_rotation = active_combat_unit.rotation.y
		current_aim_offset = 0.0
		
		var cam = get_viewport().get_camera_3d()
		if cam:
			var cam_rig = cam.get_parent().get_parent().get_parent() 
			if cam_rig.has_method("set_ots_mode"):
				cam_rig.set_ots_mode(active_combat_unit)

func cancel_combat_aim():
	if not is_combat_aiming: return
	is_combat_aiming = false
	if is_instance_valid(active_combat_unit):
		active_combat_unit.rotation.y = initial_aim_rotation
		active_combat_unit.force_update_transform()
		if active_combat_unit.has_meta("linked_gun"):
			var attached_gun = active_combat_unit.get_meta("linked_gun")
			if is_instance_valid(attached_gun):
				attached_gun.global_rotation.y = active_combat_unit.global_rotation.y + deg_to_rad(90)
				
	active_combat_unit = null
	current_aim_offset = 0.0
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_rig = cam.get_parent().get_parent().get_parent()
		if cam_rig.has_method("set_ots_mode"):
			cam_rig.set_ots_mode(null)

func get_ground_position():
	var camera = get_viewport().get_camera_3d()
	var m_pos = get_viewport().get_mouse_position()
	var query = PhysicsRayQueryParameters3D.create(camera.project_ray_origin(m_pos), camera.project_ray_origin(m_pos) + camera.project_ray_normal(m_pos) * 1000)
	query.collision_mask = 1
	var res = get_world_3d().direct_space_state.intersect_ray(query)
	return res.position if res else Vector3.ZERO

func get_tile_key(pos: Vector3) -> String:
	return "%.2f_%.2f_%.2f" % [snapped(pos.x, snap_step), snapped(pos.y, snap_step), snapped(pos.z, snap_step)]

func toggle_collision(unit, is_disabled):
	for child in unit.find_children("*", "CollisionShape3D"): child.disabled = is_disabled

func set_unit_preview_color(unit: Node3D, color: Color):
	var meshes = unit.find_children("*", "MeshInstance3D")
	for mesh_node in meshes:
		if mesh_node is MeshInstance3D:
			if color.a >= 1.0:
				mesh_node.material_override = null
			else:
				var mat = mesh_node.material_override as StandardMaterial3D
				if not mat:
					mat = StandardMaterial3D.new()
					mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
					mesh_node.material_override = mat
				mat.albedo_color = color

func draw_grid(size: float, step: float, boundary_size: float):
	if step <= 0: step = 0.5
	var mesh_instance = $GridVisualizer
	var mesh = mesh_instance.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var grid_color = Color(0.0, 1.0, 1.0, 0.02) 
	var current_pos = -size
	while current_pos <= size:
		mesh.surface_set_color(grid_color); mesh.surface_add_vertex(Vector3(current_pos, 0.15, -size))
		mesh.surface_set_color(grid_color); mesh.surface_add_vertex(Vector3(current_pos, 0.15, size))
		mesh.surface_set_color(grid_color); mesh.surface_add_vertex(Vector3(-size, 0.15, current_pos))
		mesh.surface_set_color(grid_color); mesh.surface_add_vertex(Vector3(size, 0.15, current_pos))
		current_pos += step
	
	var bound_color = Color(0, 0.8, 1.0, 1.0) 
	var b = boundary_size
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(-b, 0.16, -b))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(b, 0.1, -b))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(b, 0.16, -b))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(b, 0.16, b))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(b, 0.16, b))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(-b, 0.16, b))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(-b, 0.16, b))
	mesh.surface_set_color(bound_color); mesh.surface_add_vertex(Vector3(-b, 0.16, -b))
	mesh.surface_end()

func is_within_boundary(pos: Vector3) -> bool:
	return abs(pos.x) <= build_boundary_limit and abs(pos.z) <= build_boundary_limit

func update_ui():
	if not hp_display or not unit_list_container: return 
	hp_display.text = "ARMY HP: " + str(total_hp)
	energy_bar.value = current_energy
	
	for slot in unit_list_container.get_children():
		var u_name = slot.unit_data.get("name")
		var count = 0
		for unit in occupied_tiles.values():
			if is_instance_valid(unit) and unit.get("unit_name") == u_name:
				count += 1
		if slot.has_method("update_count_display"):
			slot.update_count_display(count)

func _on_btn_tab_char_pressed() -> void: update_unit_menu("character")
func _on_btn_tab_gun_pressed() -> void: update_unit_menu("gun")
func _on_btn_tab_block_pressed() -> void: update_unit_menu("block")
func _on_btn_tab_shield_pressed() -> void: update_unit_menu("shield")

func _on_btn_start_pressed():
	if is_game_started: return 
	is_game_started = true
	
	action_menu.hide()
	if combat_menu: combat_menu.hide()
	
	if unit_list_container.get_parent() is ScrollContainer:
		unit_list_container.get_parent().hide() 
	
	var ui_panel = $HUD/VBoxContainer 
	if ui_panel: ui_panel.hide()
	$HUD/BtnStart.hide()
	if energy_bar: energy_bar.hide()
	if has_node("GridVisualizer"): $GridVisualizer.hide()

	if dragging_unit:
		dragging_unit.queue_free()
		dragging_unit = null
	selected_unit = null
	
	for unit in occupied_tiles.values():
		if is_instance_valid(unit):
			if unit is RigidBody3D:
				unit.freeze = false
			if unit.has_method("start_combat"):
				unit.start_combat()

func reduce_army_hp(amount: int):
	total_hp -= amount
	if total_hp < 0: total_hp = 0
	if hp_display: hp_display.text = "ARMY HP: " + str(total_hp)
	if total_hp == 0: print("GAME OVER! กองทัพพ่ายแพ้แล้ว")

func restore_army_hp(amount: int):
	total_hp += amount
	if hp_display: hp_display.text = "ARMY HP: " + str(total_hp)
