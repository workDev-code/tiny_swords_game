extends CharacterBody2D

@export var max_hp: int = 100
@onready var health_bar = $HealthBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_hp: int = 100

# Movement / chasing
@export var speed: float = 120.0
@export var chase_range: float = 200.0
@export var stop_distance: float = 8.0
var is_chasing: bool = false

# Attack animation / behavior
@export var attack_range: float = 60.0
@export var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var is_attacking: bool = false

# Lấy trọng lực mặc định từ cấu hình hệ thống của Project
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Biến lưu trữ tham chiếu tới Player
var player: Node2D = null

signal died()                # Cho các node khác biết Enemy đã chết
signal damaged(new_hp: int)  # Báo lượng máu còn lại sau khi bị đấm


func _ready() -> void:
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

	# Lấy Player từ PlayerGlobal (được đăng ký trong player.gd)
	player = PlayerGlobal.current_player

func _physics_process(delta: float) -> void:
	# Áp dụng trọng lực nếu Enemy đang ở trên không
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Luôn nhìn về phía Player mỗi khung hình
	look_at_player()

	# Thêm logic di chuyển theo Player
	_chase_player(delta)
	_try_attack_player(delta)
	_update_animation()

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
		$AnimatedSprite2D.flip_h = false 
	elif direction_to_player < 0:
		# Player ở bên trái -> Lật ảnh sang trái
		$AnimatedSprite2D.flip_h = true


func _chase_player(delta: float) -> void:
	if not is_instance_valid(player):
		return

	# Enemy đến Player.
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()


	if dist > chase_range:
		# Nếu vượt quá phạm vi, dừng chase
		is_chasing = false
		velocity.x = move_toward(velocity.x, 0, speed * delta)
		return

	if dist <= stop_distance:
		# Dừng lại khi đã rất gần Player
		velocity.x = move_toward(velocity.x, 0, speed * delta)
		is_chasing = false
		return

	# Trong phạm vi chase: di chuyển về phía Player (chỉ trên trục X để giữ gravity)
	var dir: Vector2 = to_player.normalized()
	velocity.x = dir.x * speed
	is_chasing = true

func _try_attack_player(delta: float) -> void:
	if not is_instance_valid(player):
		return

	attack_timer = max(0.0, attack_timer - delta)

	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()

	if dist <= attack_range and attack_timer <= 0.0:
		is_attacking = true
		attack_timer = attack_cooldown
		print(name, " tấn công Player!")
		# Gọi hàm làm player bị đau
		if player.has_method("take_damage"):
			player.take_damage(10)  # Gây 10 sát thương
		return

	if dist > attack_range:
		is_attacking = false
		print(name, " không thể tấn công Player vì quá xa. Khoảng cách: ", dist)

func _update_animation() -> void:
	if not is_instance_valid(animated_sprite):
		return

	var target_anim = "idle"
	if is_attacking:
		target_anim = "attack"
	elif is_chasing:
		target_anim = "run"

	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)

func _on_animated_sprite_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false


# Chịu trách nhiệm nhận sát thương và cập nhật HP
func take_damage(damage: int) -> void:
	if damage <= 0:
		return
		
	current_hp = max(0, current_hp - damage)  
	health_bar.value = current_hp
	damaged.emit(current_hp)                   
	
	# Câu lệnh log của Enemy nằm ở đây:
	print(name, " bị đánh! Mất ", damage, " máu. Máu còn lại: ", current_hp)

	if current_hp <= 0 and not is_queued_for_deletion():
		die()

# Chịu trách nhiệm logic chết và hiệu ứng
func die() -> void:
	died.emit()
	queue_free()