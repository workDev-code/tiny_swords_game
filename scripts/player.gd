extends CharacterBody2D

const SPEED = 300.0

enum State { IDLE, RUN, ATTACK }
enum Facing { RIGHT, LEFT, UP, DOWN }

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var state: State = State.IDLE
var facing: Facing = Facing.RIGHT
var facing_left := false
var current_animation: StringName = resolve_idle_animation_name()

func _ready() -> void:
	# Khi animation chạy XONG ĐẾN FRAME CUỐI CÙNG, nó sẽ gọi hàm thoát trạng thái attack
	animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

func _physics_process(_delta: float) -> void:
	## người chơi bấm hướng nào?
	var direction := get_input_direction()
	
	# Nhân vật đang ở trạng thái (State) hành động nào?
	resolve_locomotion_state(direction)

	## VẤN ĐỀ : Trạng thái chiến đấu có cần được ưu tiên hơn trạng thái di chuyển không?
    # Giải quyết: Kiểm tra nút bấm tấn công. Nếu có, "đè" (override) trạng thái di chuyển ở trên thành trạng thái Attack.
	check_and_trigger_attack(direction)
	
	#tính vận tốc
	calculate_velocity(direction)

	## Nhân vật đang nhìn về hướng nào
	apply_facing_direction(direction)
	
	## VẤN ĐỀ : Làm sao để người chơi "nhìn thấy" hành động của nhân vật khớp với logic ngầm bên trong?
	sync_sprite_animation(direction)
	
	move_and_slide()

func get_input_direction() -> Vector2:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	return direction.normalized() if direction != Vector2.ZERO else Vector2.ZERO

func resolve_locomotion_state(direction: Vector2) -> void:
	if state == State.ATTACK:
		return
	state = State.IDLE if direction == Vector2.ZERO else State.RUN

func check_and_trigger_attack(direction: Vector2) -> void:
	if not Input.is_action_just_pressed("attack") or state == State.ATTACK:
		return

	if direction != Vector2.ZERO:
		apply_facing_direction(direction)

	state = State.ATTACK


func calculate_velocity(direction: Vector2) -> void:
	if state == State.ATTACK or direction == Vector2.ZERO:
		velocity = Vector2.ZERO
	else:
		velocity = direction * SPEED

func apply_facing_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	if direction.x < 0.0:
		facing_left = true
	elif direction.x > 0.0:
		facing_left = false

	if abs(direction.x) > abs(direction.y):
		facing = Facing.RIGHT if direction.x > 0.0 else Facing.LEFT
	else:
		facing = Facing.DOWN if direction.y > 0.0 else Facing.UP

func sync_sprite_animation(direction: Vector2) -> void:
	animated_sprite.flip_h = facing_left # Đơn giản hóa việc lật hình
	animated_sprite.flip_v = false
	
	var animation_name := resolve_animation_name()
	if animation_name != current_animation:
		current_animation = animation_name
		animated_sprite.play(animation_name)

func resolve_animation_name() -> StringName:
	match state:
		State.IDLE: return resolve_idle_animation_name()
		State.RUN: return resolve_run_animation_name()
		State.ATTACK: return resolve_attack_animation_name()
		_: return &"idle_side"

func resolve_idle_animation_name() -> StringName:
	return &"idle_side" # Thêm logic idle_down / idle_up nếu game của bạn có hỗ trợ

func resolve_run_animation_name() -> StringName:
	match facing:
		Facing.DOWN: return &"run_down"
		Facing.UP: return &"run_up" # Thêm trường hợp chạy lên trên
		_: return &"run"

func resolve_attack_animation_name() -> StringName:
	match facing:
		Facing.UP: return &"attack_up"
		Facing.DOWN: return &"attack_down"
		_: return &"attack_side"

func _on_animated_sprite_animation_finished() -> void:
	if state == State.ATTACK:
		exit_attack_state()

func exit_attack_state() -> void:
	state = State.IDLE # Trả về mặc định, frame sau _physics_process tự cập nhật lại nếu đang giữ nút di chuyển
