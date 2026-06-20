extends CharacterBody2D

@export var max_hp: int = 100
var current_hp: int = 100

# Lấy trọng lực mặc định từ cấu hình hệ thống của Project
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Biến lưu trữ tham chiếu tới Player
var player: Node2D = null

signal died()                # Cho các node khác biết Enemy đã chết
signal damaged(new_hp: int)  # Báo lượng máu còn lại sau khi bị đấm

func _ready() -> void:
	current_hp = max_hp
	
	# Tìm Player trong Scene khi Game bắt đầu.
	# Cách này giả định Player của bạn nằm trong một Group tên là "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	# Áp dụng trọng lực nếu Enemy đang ở trên không
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Luôn nhìn về phía Player mỗi khung hình
	look_at_player()

	# Gọi hàm này để Godot thực hiện di chuyển vật lý
	move_and_slide()

# Hàm xử lý logic quay mặt về phía Player
func look_at_player() -> void:
	# Nếu không tìm thấy Player hoặc Player đã bị xóa, thoát hàm để tránh lỗi
	if not is_instance_valid(player):
		return
		
	# Tính hướng từ Enemy đến Player theo trục X
	# Nếu hiệu > 0 tức là Player đang ở bên phải Enemy, ngược lại là bên trái
	var direction_to_player = player.global_position.x - global_position.x
	
	if direction_to_player > 0:
		# Player ở bên phải -> Không lật ảnh (Giả định Sprite mặc định của bạn nhìn sang PHẢI)
		$Sprite2D.flip_h = false 
	elif direction_to_player < 0:
		# Player ở bên trái -> Lật ảnh sang trái
		$Sprite2D.flip_h = true

# Chịu trách nhiệm nhận sát thương và cập nhật HP
func take_damage(damage: int) -> void:
	if damage <= 0:
		return
		
	current_hp = max(0, current_hp - damage)  
	damaged.emit(current_hp)                   
	
	if current_hp <= 0 and not is_queued_for_deletion():
		die()

# Chịu trách nhiệm logic chết và hiệu ứng
func die() -> void:
	died.emit()
	queue_free()