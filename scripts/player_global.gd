extends Node

var current_player: Node2D = null # Nơi lưu trữ Player toàn cục

# Trạng thái game: true khi Player đã chết và UI Game Over đang hiện.
# Enemy sẽ dùng cờ này để dừng đánh khi game đã kết thúc.
var is_game_over: bool = false
