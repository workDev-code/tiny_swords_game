extends CharacterBody2D

# Top-down 4-dir theo docs/decisions.md (2026-07-06): bỏ gravity,
# không còn is_on_floor(), chase & knockback dùng Vector2 đầy đủ.

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
# Tránh gọi die() nhiều lần khi tween fade chưa xong.
# var is_dying: bool = false

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

	add_to_group("enemies")  # Để player / debug tìm nhanh tất cả enemy còn sống.

	# Lấy Player từ PlayerGlobal (được đăng ký trong player.gd)
	player = PlayerGlobal.current_player

func _physics_process(delta: float) -> void:
	# Top-down 4-dir: bỏ hoàn toàn gravity & is_on_floor().
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
	# Quyết định 6.3-a: giữ behavior flip-H hiện tại (không thêm flip-V/up).
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
		# Nếu vượt quá phạm vi, dừng chase — top-down: tắt cả 2 trục dần dần.
		is_chasing = false
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta)
		return

	if dist <= stop_distance:
		# Dừng lại khi đã rất gần Player — top-down: tắt cả 2 trục dần dần.
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta)
		is_chasing = false
		return

	# Trong phạm vi chase: di chuyển về phía Player trên CẢ 2 trục (top-down 4-dir).
	var dir: Vector2 = to_player.normalized()
	velocity = dir * speed
	is_chasing = true

func _try_attack_player(delta: float) -> void:
	if not is_instance_valid(player):
		return

	# Game đã kết thúc (UI Game Over đang hiện) — không tấn công nữa.
	# pause tree đã khoá _physics_process, nhưng guard này đề phòng frame edge.
	if PlayerGlobal.is_game_over:
		is_attacking = false
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
	# if is_dying:
	# 	return
	# is_dying = true

	died.emit()

	# 1. Knockback: đẩy enemy ngược chiều player.
	# Quyết định 6.4-a: giữ nguyên vector 220 — gravity trước đây
	# kéo xuống làm cú knockback "đáp đất" tự nhiên; ở top-down enemy sẽ
	# trôi theo vector này cho tới khi tween fade xong (queue_free).
	if is_instance_valid(player):
		var dir := (global_position - player.global_position).normalized()
		velocity = dir * 220.0

	# 2. Tắt collision / hurtbox để không bị hit thêm lúc đang chờ fade.
	collision_layer = 0
	collision_mask = 0
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	# 3. Tween: fade + thu nhỏ trong 0.5s, sau đó queue_free.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
