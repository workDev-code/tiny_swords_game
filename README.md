# Tiny Swords

`Tiny Swords` là một dự án game 2D nhỏ được xây dựng bằng Godot Engine 4.x.

## Giới thiệu

Đây là một game hành động đơn giản, trong đó người chơi điều khiển nhân vật chính di chuyển và tấn công kẻ địch.

## Mở game

1. Cài đặt Godot Engine 4.6 (hoặc phiên bản tương thích với `project.godot`).
2. Mở thư mục dự án `tiny-swords` trong Godot.
3. Chạy project hoặc chọn `node_2d.tscn` làm scene chính nếu chưa được cấu hình tự động.

## Scene chính

- `node_2d.tscn` — scene mặc định được chạy khi mở project.
- `player.gd` — script điều khiển nhân vật người chơi.
- `enemy.gd` — script xử lý kẻ địch (HP, sát thương và chết).

## Cơ chế điều khiển

- `W` để đi lên
- `A` để đi trái
- `S` để đi xuống
- `D` để đi phải
- `J` để tấn công

## Input action trong Project Settings

Các action được định nghĩa trong `project.godot`:

- `move_left` → phím `A`
- `move_right` → phím `D`
- `move_up` → phím `W`
- `move_down` → phím `S`
- `attack` → phím `J`

## Sơ đồ logic chính

### `player.gd`

- Nhận input di chuyển và tính hướng.
- Gán trạng thái `IDLE`, `RUN`, hoặc `ATTACK`.
- Tính vận tốc nhân vật dựa trên trạng thái.
- Cập nhật hướng nhìn và animation.
- Khi animation `attack` kết thúc, nhân vật trở về trạng thái `IDLE`.

### `enemy.gd`

- Quản lý máu (`max_hp`, `current_hp`).
- Xử lý nhận sát thương với `take_damage(damage)`.
- Phát tín hiệu `damaged` và `died`.
- Gọi `queue_free()` khi chết.

## Thư mục chính

- `project.godot` — cấu hình project và input.
- `node_2d.tscn` — scene chính.
- `player.tscn` — nhân vật người chơi.
- `enemy.tscn` — kẻ địch.
- `scripts/` — chứa các script GDScript.
- `assets/` và `Tiny Swords/` — chứa tài nguyên đồ họa và sprite.

## Ghi chú

- Dự án hiện tại chưa có hệ thống combat hoàn chỉnh hay UI hiển thị HP.
- Bạn có thể mở rộng bằng cách thêm animation, hiệu ứng, và logic kẻ địch.

---

### Cách đóng góp

Nếu bạn muốn mở rộng game này, hãy bắt đầu bằng việc:

- Thêm animation `run_up`, `idle_up`, `attack_up` nếu cần.
- Thêm control logic cho trạng thái `ATTACK` và tương tác với `enemy`.
- Tạo UI hiển thị thanh máu và điểm số.
