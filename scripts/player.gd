extends CharacterBody2D

# Top-down 4-dir movement (LOCKED trong docs/decisions.md, 2026-07-06).
# Không gravity, không jump, không is_on_floor().

# --- CONSTANTS ---
const SPEED = 300.0

# --- ENUMS ---
enum Facing { RIGHT, LEFT, UP, DOWN }

# --- SIGNALS ---
# Phát ra khi Player hết máu. UI Game Over (game_over.tscn) lắng nghe signal này.
signal died()

# --- VARIABLES ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var camera: Camera2D = $Camera2D

@export var attack_damage: int = 20
@export var max_hp: int = 1000

var facing: Facing = Facing.RIGHT
var facing_left := false
var current_hp: int = max_hp

# Tách biệt rõ ràng: locomotion và action
var is_attacking := false
# Đặt true sau khi _die() chạy. Chặn input/vật lý/animation cho tới khi scene reload.
var is_dead := false
var current_animation: StringName = &"idle_side"


# --- READY ---
func _ready() -> void:
	# Đăng ký Player vào bảng thông báo toàn cục để các Enemy có thể truy cập
	PlayerGlobal.current_player = self

	camera.enabled = true
	camera.make_current();  # Kích hoạt camera cho Player

	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)


# --- PHYSICS PROCESS ---
func _physics_process(delta: float) -> void:
	# Sau khi chết: đông cứng hoàn toàn velocity (quyết định 6.1-b), không xử lý input/attack/animation.
	# Không còn gravity nên không cần giữ nhánh "rơi xuống đất".
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction = _get_input_direction()

	_update_facing(direction)

	_handle_attack()

	# _handle_movement không cần delta nữa ở top-down; velocity = direction * SPEED.
	_handle_movement(direction)

	_update_animation()

	move_and_slide()

# ====================== DEBUG (test focus) ======================
# Phím K: tiêu diệt enemy gần nhất ngay lập tức để quan sát chuyển động chết
# mà không cần spam attack. Chỉ hoạt động khi player còn sống.
func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			_debug_kill_nearest_enemy()

func _debug_kill_nearest_enemy() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_d_sq := INF
	for e in enemies:
		if not is_instance_valid(e) or not is_instance_valid(e.get_parent()):
			continue
		if e.is_queued_for_deletion():
			continue
		var d_sq := global_position.distance_squared_to(e.global_position)
		if d_sq < min_d_sq:
			min_d_sq = d_sq
			nearest = e
	if nearest and nearest.has_method("die"):
		print("Debug [K]: killing nearest enemy ", nearest.name)
		nearest.die()
	else:
		print("Debug [K]: không còn enemy nào trong nhóm 'enemies'.")

# ====================== INPUT & FACING ======================
func _get_input_direction() -> Vector2:
	# 6.2-a: normalized -> diagonal == cardinal speed (đi đâu cũng tốc độ SPEED).
	var dir = Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")
	return dir.normalized()

func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	# Flip sprite
	if direction.x < 0:
		facing_left = true
	elif direction.x > 0:
		facing_left = false

	# Xác định Facing (ưu tiên trục có biên độ lớn hơn)
	if abs(direction.x) > abs(direction.y):
		facing = Facing.RIGHT if direction.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if direction.y > 0 else Facing.UP

# ====================== ATTACK ======================
func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		# Attack animation sẽ được resolve ở _update_animation()
		# 1. Bật chốt an toàn (Mở Hitbox để sẵn sàng gây sát thương)
		if hitbox_collision:
			hitbox_collision.disabled = false

		# 2. Tính toán lượng sát thương bằng hàm attack() có sẵn của bạn
		var total_damage = attack()

		# 3. Log (in) lượng sát thương ra màn hình Output
		print("Player tấn công! Sát thương gây ra: ", total_damage)

func _on_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		# Tắt chốt an toàn (Đóng Hitbox sau khi tấn công xong)
		if hitbox_collision:
			hitbox_collision.disabled = true

# ====================== MOVEMENT ======================
func _handle_movement(direction: Vector2) -> void:
	# Top-down 4-dir: set cả 2 trục từ direction đã normalize.
	# Khi attack -> đứng yên hoàn toàn (giữ intent cũ).
	if is_attacking:
		velocity = Vector2.ZERO
	else:
		velocity = direction * SPEED

# ====================== ANIMATION ======================
func _update_animation() -> void:
	animated_sprite.flip_h = facing_left
	animated_sprite.flip_v = false

	var new_anim = _resolve_animation_name()

	if new_anim != current_animation:
		current_animation = new_anim
		animated_sprite.play(new_anim)

func _resolve_animation_name() -> StringName:
	# 1. Attack có độ ưu tiên cao nhất
	if is_attacking:
		match facing:
			Facing.UP:    return &"attack_up"
			Facing.DOWN:  return &"attack_down"
			_:            return &"attack_side"

	# 2. Locomotion (bỏ nhánh jump - top-down không có "trên không")
	var direction = _get_input_direction()  # dùng lại hàm cũ để kiểm tra đang di chuyển không

	if direction == Vector2.ZERO:
		return _get_idle_animation()
	else:
		return _get_run_animation()

func _get_idle_animation() -> StringName:
	# match facing:
	#     Facing.UP:    return &"idle_up"
	#     Facing.DOWN:  return &"idle_down"
	#     _:            return &"idle_side"
	return &"idle_side"  # tạm thời, bạn có thể mở rộng sau

func _get_run_animation() -> StringName:
	match facing:
		Facing.UP:    return &"run_up"
		Facing.DOWN:  return &"run_down"
		_:            return &"run"

func attack(base_damage: int = 0) -> int:
	if base_damage <= 0:
		return attack_damage
	return base_damage + attack_damage

func _on_hitbox_area_entered(area: Area2D) -> void:
	print(area.name)
	if area.name == "Hurtbox":
		var enemy = area.get_parent()

		if enemy.has_method("take_damage"):
			enemy.take_damage(attack())

func take_damage(damage: int) -> void:
	# Sau khi chết, mọi đòn đánh thêm đều bị bỏ qua — tránh emit died nhiều lần.
	if damage <= 0 or is_dead:
		return

	current_hp = max(0, current_hp - damage)
	health_bar.value = current_hp
	print("Player bị đánh! Mất ", damage, " máu. Máu còn lại: ", current_hp)

	if current_hp <= 0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	# Quyết định 6.1-b: đông cứng hoàn toàn velocity (không kick-up).
	velocity = Vector2.ZERO
	# Cue trực quan khi chết: lật ngang sprite + đứng yên pose.
	animated_sprite.flip_v = true
	animated_sprite.play(&"idle_side")
	died.emit()
