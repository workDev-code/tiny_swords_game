extends CharacterBody2D

# --- CONSTANTS ---
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# --- ENUMS ---
enum Facing { RIGHT, LEFT, UP, DOWN }

# --- VARIABLES ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D
@export var attack_damage: int = 20

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var facing: Facing = Facing.RIGHT
var facing_left := false

# Tách biệt rõ ràng: locomotion và action
var is_attacking := false
var current_animation: StringName = &"idle_side"


# --- READY ---
func _ready() -> void:
	# Đăng ký Player vào bảng thông báo toàn cục để các Enemy có thể truy cập
	PlayerGlobal.current_player = self

	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)


# --- PHYSICS PROCESS ---
func _physics_process(delta: float) -> void:
	var direction = _get_input_direction()
	
	_update_facing(direction)

	_handle_attack()

	_handle_movement(direction, delta)

	_update_animation()
	
	move_and_slide()

# ====================== INPUT & FACING ======================
func _get_input_direction() -> Vector2:
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
func _handle_movement(direction: Vector2, delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY
	
	# Horizontal movement
	if is_attacking and is_on_floor():
		velocity.x = 0  # Đứng yên khi attack trên mặt đất
	else:
		if direction.x != 0:
			velocity.x = direction.x * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

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
	
	# 2. Jump
	if not is_on_floor():
		return &"jump"
	
	# 3. Locomotion
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