<!--
OWNERSHIP: AI, freely. AI mô tả code/scene hiện tại. Cập nhật mỗi khi cấu trúc đổi.
-->

# Architecture

Trạng thái code hiện tại của project, mapping từ scene tree sang script và signal flow.
Đối chiếu chéo với `docs/decisions.md` để biết entry nào đã được khoá cứng.

## Project root

- Godot 4.6 (`project.godot` → `"4.6", "Forward Plus"`)
- Main scene: `res://node_2d.tscn` (config: `[application] run/main_scene`).
- Autoload duy nhất: `PlayerGlobal` (`*res://scripts/player_global.gd`).
- Engine vật lý 3D setting `Jolt Physics` (cosmetic — project này dùng 2D).
- Không có `export_presets.cfg`, không có CI/CD.

## Scene tree (main)

```
res://node_2d.tscn  "Game" (Node2D)
├── TileMap               (TileMap, terrain ground)
├── Tree1                 (Sprite2D, region 0,0,192,192,     pos user-tuned)
├── Tree2                 (Sprite2D, region 192,0,192,192)
├── Tree3                 (Sprite2D, region 0,192,192,192)
├── Player                (instance: res://player.tscn)
├── Enemy                 (instance: res://enemy.tscn)
├── Enemy2                (instance: res://enemy.tscn)
├── FLoorBoudary          (StaticBody2D, WorldBoundary)
│   └── CollisionShape2D  (WorldBoundaryShape2D)
└── GameOver              (instance: res://game_over.tscn, CanvasLayer)
```

Decor (thêm 2026-07-08, xem "Đổi gần đây"):
- 3× Tree1/2/3 — sprite 192x192 lấy từ `Resources/Trees/Tree.png` (sheet 768x576,
  layout giả định 4 cột × 3 hàng). Mỗi cây region khác nhau cho variety.
- Vị trí do người dùng tinh chỉnh trong editor sau khi AI đặt ban đầu.
- (Đã thử 1× Water1 dùng Water.png 64x64 scale 3x = 192x192 pool nhưng bị
  xoá 2026-07-09 vì quá xấu — 1 ô vuông xanh phẳng không match phong cách
  Tiny Swords có foam viền đảo. Cần foam tiles hoặc redesign tile.)

Ghi chú:
- `FLoorBoudary` (viết sai chính tả — không phải `FloorBoundary`) vẫn tồn tại
  trong scene. Sau migration top-down không còn gravity, node này gần như
  không có tác dụng (world boundary không giữ entity khỏi rơi). Xem
  `docs/known_issues.md` mục "Bug" để biết xem xét xoá/đổi tên.
- Các scene `player.tscn`, `enemy.tscn`, `health_bar.tscn`, `game_over.tscn`
  là PackedScene được load qua `ExtResource`.

## Script ↔ Scene

| Script | Root type | Loaded bởi | Ghi chú |
|---|---|---|---|
| `scripts/player.gd` | `CharacterBody2D` | `player.tscn` (Player) | Top-down 4-dir, không gravity. |
| `scripts/enemy.gd` | `CharacterBody2D` | `enemy.tscn` (Enemy, Enemy2…) | Chase 2D, knockback Vector2 220. |
| `scripts/health_bar.gd` | `ProgressBar` | `health_bar.tscn` | Được Player + Enemy nhúng làm con. |
| `scripts/player_global.gd` | `Node` | autoload | Singleton `current_player`, `is_game_over`. |
| `scripts/game_over.gd` | `CanvasLayer` | `game_over.tscn` (GameOver) | Pause tree, hiện/ẩn theo signal `died`. |

## Input map (`project.godot` → `[input]`)

| Action | Physical key | Used bởi |
|---|---|---|
| `move_left` | A (65) | Player `_get_input_direction().x` |
| `move_right` | D (68) | Player `_get_input_direction().x` |
| `move_up` | W (87) | Player `_get_input_direction().y` |
| `move_down` | S (83) | Player `_get_input_direction().y` |
| `attack` | J (74) | Player `_handle_attack()` |
| `jump` | Space (32) | **KHÔNG còn dùng trong gameplay** (per `decisions.md` 2026-07-06). Action vẫn còn trong `project.godot` — xem `known_issues.md`. |

## Autoload

`PlayerGlobal` (`scripts/player_global.gd`):
- `current_player: Node2D` — được `Player._ready()` set = self.
  Enemy `_ready()` đọc từ đây để biết target.
- `is_game_over: bool` — Enemy `_try_attack_player()` check; GameOver UI set true
  khi player chết.

## Signal flow

```
Player._ready()
  └── set PlayerGlobal.current_player = self

Player._handle_attack() (J just_pressed)
  └── enable Hitbox / CollisionShape2D
  └── animated_sprite.play(&"attack_<facing>")
Player._on_animation_finished()
  └── is_attacking = false; tắt Hitbox

Hitbox._on_hitbox_area_entered(area)  (Player script)
  └── nếu area.name == "Hurtbox": enemy.take_damage(attack())

Enemy._physics_process(delta)
  └── look_at_player()          (flip_H theo trục X)
  └── _chase_player(delta)      (Vector2 velocity)
  └── _try_attack_player(delta) (nếu trong range + cooldown ready)
        └── player.take_damage(10)
  └── _update_animation()       (idle / run / attack)
Enemy._on_animated_sprite_animation_finished()
  └── nếu anim == "attack": is_attacking = false
Enemy.take_damage(damage)
  └── current_hp -= damage; damaged.emit(...)
  └── nếu current_hp <= 0: die()
Enemy.die()
  ├── died.emit()
  ├── velocity = dir * 220.0          (knockback)
  ├── collision_layer/mask = 0; Hurtbox off
  └── tween fade + scale 0.5s → queue_free

Player.take_damage(damage)
  └── current_hp -= damage
  └── nếu current_hp <= 0: _die()
Player._die()
  ├── is_dead = true; velocity = Vector2.ZERO   (6.1-b)
  ├── animated_sprite.flip_v = true; play idle_side
  └── died.emit()
        ↓
GameOver._on_player_died()
  ├── PlayerGlobal.is_game_over = true
  ├── await timer 0.6s (chờ cue visual)
  ├── visible = true; get_tree().paused = true
  └── (button "Restart") → reload_current_scene()
```

## Player → Movement model

> Quyết định khoá: `docs/decisions.md` 2026-07-06 — **TOP-DOWN 4-DIRECTIONAL**.

- `scripts/player.gd` không còn `JUMP_VELOCITY`/`gravity`/`is_on_floor()`.
- `_get_input_direction()` trả về `dir.normalized()` → diagonal speed = cardinal speed (cùng `SPEED = 300.0`).
- `_handle_movement(direction)` set `velocity = direction * SPEED` cho cả 2 trục.
  Khi `is_attacking` thì `velocity = Vector2.ZERO` (đứng yên khi đánh).
- `_resolve_animation_name()` không còn nhánh `is_on_floor()` → không còn animation `jump`.
- `_die()` đông cứng velocity = 0 (không còn "rơi xuống đất" vì không có gravity).

## Collision layer scheme

Cấu hình hoàn toàn từ `_ready()` trong script (không sửa `.tscn` theo mục 5
AGENTS.md):

| Body | layer (bits) | mask (bits) | Mục đích |
|---|---|---|---|
| Player (CharacterBody2D) | bit 0 (= 1, world) | bit 0 (= 1, world) | Bị cây chặn, không bị enemy chặn |
| Enemy  (CharacterBody2D) | bit 1 (= 2, enemy) | 0 (không chặn ai) | Không chặn player, không chặn cây |
| Tree   (StaticBody2D)    | 1 (default từ `tree.tscn`) | 1 (default) | Vật cản world |
| FLoorBoudary (StaticBody2D) | 1 (default) | 1 (default) | World boundary (top-down không gravity, gần như vô dụng) |

Quy ước:
- **Bit 0 = world layer** (cây, floor, mọi StaticBody2D trang trí cản đường).
- **Bit 1 = enemy layer** (chỉ các CharacterBody2D enemy).
- Hitbox / Hurtbox là `Area2D`, layer/mask riêng — không liên quan đến body
  collision này (xem "Signal flow" ở trên).
- Khi thêm enemy type mới hoặc world decor khác: tuân theo quy ước trên,
  set layer/mask từ script để không chạm `.tscn`.

Lịch sử: xem `docs/known_issues.md` mục "Closed 2026-07-15 — Player chạy
xuyên qua cây".

## Enemy → Movement model

- `scripts/enemy.gd` không còn `var gravity`/`is_on_floor()`.
- `_chase_player()` so scalar `dist` với `chase_range`/`stop_distance` (đã là 2D,
  không đổi giá trị), set `velocity = to_player.normalized() * speed` để chase
  cả 2 trục.
- Khi `dist > chase_range` hoặc `dist <= stop_distance`: dùng
  `velocity.move_toward(Vector2.ZERO, speed * delta)` (tắt dần cả 2 trục).
- `die()` giữ `velocity = dir * 220.0` (knockback Vector2 — không đổi cảm giác).

## Public API (giữ nguyên để các scene/script khác còn dùng)

| Tên | Vai trò |
|---|---|
| `signal died()` (Player & Enemy) | Death hook |
| `take_damage(damage: int)` | Damage entry, hỗ trợ cả Player + Enemy |
| `attack(base_damage: int = 0) -> int` | Tính damage cho Player |
| `_on_hitbox_area_entered(area)` | Player ↔ Enemy Hitbox overlap |
| `_on_animation_finished()` | Animation signal trên cả Player & Enemy |
| `PlayerGlobal.current_player` | Singleton lookup cho Enemy |
| `PlayerGlobal.is_game_over` | Pause state cho Enemy + GameOver |

## Đổi gần đây

- 2026-07-09: Phase 1 redesign TileMap — bỏ pattern checker đều,
  thay bằng 1 đảo cỏ chính (186 cells) + 1 vệ tinh 2-cell. Player/Enemy/Tree
  đều nằm trên grass. Vẫn dùng Tilemap_Flat tiles (chưa chuyển sang
  Tilemap_Elevation — chờ visual-verify trước khi đổi atlas).
- 2026-07-08: Thêm decor 3 cây + 1 vũng nước vào `node_2d.tscn`
  (xem "Scene tree (main)" ở trên). Không động vào code/scripts.
- 2026-07-06: Migration top-down 4-dir hoàn tất (`scripts/player.gd`,
  `scripts/enemy.gd`). Mapping chi tiết ở `docs/decisions.md` và
  `docs/known_issues.md` (task "In progress" đã đóng).
