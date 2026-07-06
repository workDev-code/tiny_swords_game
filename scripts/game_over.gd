extends CanvasLayer

# Khi get_tree().paused = true, mọi _process / _input bị khoá theo mặc định.
# process_mode = ALWAYS trên CanvasLayer cho phép Button và signal handler
# chạy ngay cả khi game đang pause. (Đã được set trong game_over.tscn)
@onready var restart_button: Button = $Center/Panel/VBox/RestartButton


func _ready() -> void:
	# Ẩn ban đầu — chỉ hiện khi nhận signal died từ Player.
	visible = false

	restart_button.pressed.connect(_on_restart_button_pressed)

	# GameOver là sibling cuối trong node_2d.tscn, nên Player._ready() đã chạy
	# và PlayerGlobal.current_player đã có giá trị trước khi ta kết nối signal.
	var player = PlayerGlobal.current_player
	if player:
		player.died.connect(_on_player_died)
	else:
		push_warning("GameOver: PlayerGlobal.current_player rỗng khi _ready()")


func _on_player_died() -> void:
	PlayerGlobal.is_game_over = true

	# Chờ một nhịp để player kịp "ngã xuống" đã (gravity + visual cue),
	# rồi mới phủ UI và pause tree — tránh Game Over hiện tức thì.
	await get_tree().create_timer(0.6).timeout

	visible = true
	get_tree().paused = true
	print("Game Over! Nhấn Restart để chơi lại.")


func _on_restart_button_pressed() -> void:
	# Reset autoload state — PlayerGlobal sống xuyên suốt các lần reload scene,
	# nên phải tự tay đặt lại is_game_over, nếu không sẽ "game over" ngay khi vào.
	PlayerGlobal.is_game_over = false
	get_tree().paused = false
	get_tree().reload_current_scene()
