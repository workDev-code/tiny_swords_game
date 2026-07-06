<!--
OWNERSHIP: AI, freely. AI scans code and lists bugs/TODOs found.
Human reviews periodically but doesn't need to approve updates here.
-->

# Known Issues & TODO

_Auto-maintained by AI._

## In progress
_(none)_

<!-- TODO cho entry In progress trước đây đã xong — xem mục "Closed / resolved"
     ở cuối file để biết lịch sử. -->

## Bugs
- `attack_down` animation có `loop = true` trong `player.tscn` — có thể khiến
  `animation_finished` không bao giờ fire, làm `is_attacking` mắc kẹt.
  **Core-feel — cần playtest xác nhận** trước khi sửa (sửa = bỏ loop hoặc
  đổi logic về time-based thay vì signal-based).
- Enemy damage applied immediately on range + cooldown, không đồng bộ với
  hit-frame trong attack animation. **Core-feel — cần human playtest
  confirmation** về thời điểm đánh trúng.
- Player death vẫn chưa có game-over/respawn flow đầy đủ ngoài UI GameOver:
  trong `game_over.gd._on_player_died()` còn comment thừa
  `"Chờ một nhịp để player kịp 'ngã xuống' đã (gravity + visual cue)"`
  — sau migration top-down, player không còn "rơi" (đông cứng velocity = 0
  theo 6.1-b), comment này lỗi thời nhưng 0.6s wait buffer vẫn ổn.
  → Không phải bug logic, chỉ là stale comment; cân nhắc cập nhật text.
- `FLoorBoudary` (sai chính tả, là `FloorBoundary`) trong `node_2d.tscn`
  gần như vô dụng ở top-down (không còn gravity để entity rơi khỏi map).
  Không rename/xoá vội — kiểm tra mọi tham chiếu nếu có ý định đổi tên.

## Stale / deprecated (giữ trong code cũ)
- `project.godot` vẫn có input action `jump` (Space) — sau migration top-down
  không còn script nào đọc `Input.is_action_just_pressed("jump")`. Action vẫn
  wire cho Space nhưng không có effect. Quyết định 6.5-a: KHÔNG xoá để tránh
  chạm `project.godot` (mục 5 AGENTS.md), nhưng có thể xoá sau khi explicit OK.

## Unknown / not found
- Build / export process (chưa có `export_presets.cfg`).
- Automated tests (không có test runner).
- Lint / format command (ngoài `.editorconfig` UTF-8).
- Package / dependency manager.
- CI / CD.
- Inventory, save / load, audio, fonts.

## Core-feel — cần người playtest

- Cú knockback enemy chết (220 px vector) ở top-down sẽ cho enemy **trôi đi
  trong 0.5s** rồi fade — trước đây gravity kéo xuống làm "đáp đất". Cảm giác
  có thể khác. Quyết định 6.4-a giữ nguyên giá trị; verify visually.
- Diagonal movement = cardinal (quyết định 6.2-a): nếu sau playtest cảm thấy
  đi chéo quá "đầm" so với đi thẳng, đề xuất đổi sang `direction * SPEED`
  (không normalize).

## Closed / resolved (lịch sử cho khỏi quên)

### 2026-07-06 — Movement migration sang top-down 4-dir

File: `scripts/player.gd`, `scripts/enemy.gd`.
Quyết định đã được người duyệt: 6.1-b, 6.2-a, 6.3-a, 6.4-a, 6.5-a, 6.6-a.

Closed vì:
- `JUMP_VELOCITY` và `var gravity` đã bỏ khỏi `player.gd` & `enemy.gd`.
- `move_up`/`move_down` đã được sử dụng trực tiếp cho trục y của
  `_get_input_direction()`; `_handle_movement()` đặt velocity theo cả 2 trục.
- `_resolve_animation_name()` không còn nhánh `is_on_floor()` → animation
  `jump` không bao giờ được play nữa.
- `_die()` đông cứng velocity = 0 (không kick-up).
- Enemy `_chase_player()` chase cả 2 trục; tắt chase dùng
  `velocity.move_toward(Vector2.ZERO, …)` thay vì chỉ tắt trục X.
- Verify: Godot 4.6.3 headless chạy `node_2d.tscn` ≥ 240 frame không có
  error/warning.
