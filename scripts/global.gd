extends Node
var next_scene_path: String = "" # เอาไว้จำว่ากำลังจะไปด่านไหน

# ==========================================
# 🌟 เพิ่มตัวแปรสำหรับระบบ Replay
# ==========================================
var is_replaying: bool = false
var saved_player_blocks: Array = [] # เอาไว้เก็บตำแหน่งบล็อก
