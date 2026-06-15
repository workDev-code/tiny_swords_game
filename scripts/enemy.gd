extends CharacterBody2D

@export var max_hp: int = 100
var current_hp: int = 100

signal died()          # Cho các node khác biết Enemy đã chết
signal damaged(amount: int)  # Tùy chọn


# chịu trách nhiệm nhận sát thương và cập nhật hp
func take_damage(damage: int) -> void:
	if damage <= 0:
		return
		
	current_hp = max(0, current_hp - damage)  # Ngăn HP âm ngay từ đầu
	
	damaged.emit(current_hp) # Báo cho UI và hiệu ứng biết
	
	if current_hp <= 0 and not is_queued_for_deletion():
		die()

# chịu logic chết và hiệu ứng
func die() -> void:
	died.emit()
	# Thêm hiệu ứng ở đây:
	# - Play animation chết
	# - Drop loot
	# - Tạo particle
	queue_free()