<!--
OWNERSHIP: MIXED.
- Sections describing what the code currently does (input map, animations,
  combat flow as implemented) → AI writes freely.
- The "Design Intent / Feel Goals" section below is HUMAN ONLY. AI must not
  invent or reword these lines — only describe current behavior elsewhere.
-->

# Gameplay

## Design Intent / Feel Goals
<!-- HUMAN ONLY — AI: do not write here -->

_(fill in by hand, e.g. "combat should create real dodge pressure, not just
trade hits" — this is your tension statement, not a technical description)_

---

## Input map (AI-maintained, current state)
- `move_left` = A
- `move_right` = D
- `move_up` = W
- `move_down` = S
- `attack` = J
- `jump` = Space — **không còn được đọc bởi gameplay sau migration top-down
  (xem `decisions.md` 2026-07-06)**. Input action vẫn còn trong `project.godot`,
  quyết định 6.5-a.

## Player (AI-maintained, current state)
- `scripts/player.gd`, root `Player` (`CharacterBody2D`).
- `SPEED = 300.0`.
- `attack_damage = 20`, `max_hp = 1000`.
- `Facing` enum: RIGHT / LEFT / UP / DOWN, `facing_left` flips sprite ngang.
- **Top-down 4-directional movement** (LOCKED trong `docs/decisions.md`):
  `_get_input_direction()` trả về `dir.normalized()` → diagonal speed = cardinal.
  `_handle_movement(direction)` set `velocity = direction * SPEED` cho cả 2 trục;
  khi `is_attacking` thì `velocity = Vector2.ZERO`.
- Không gravity, không jump, không dùng `is_on_floor()`.

## Enemy (AI-maintained, current state)
- `scripts/enemy.gd`, root `Enemy` (`CharacterBody2D`).
- `max_hp = 100`, `speed = 120.0`, `chase_range = 200.0`,
  `stop_distance = 8.0`, `attack_range = 60.0`, `attack_cooldown = 1.0`.
- **Top-down 4-dir chase**: `_chase_player()` chase cả 2 trục với
  `velocity = to_player.normalized() * speed`. Scalar `dist = to_player.length()`
  so với `chase_range` / `stop_distance` (đã là scalar 2D, không đổi số).
- Khi ngoài chase range / đã vào stop_distance → `velocity.move_toward(0, …)`
  trên cả 2 trục (decay đều).
- Knockback chết: `velocity = dir * 220.0` rồi fade + scale 0.5s, sau đó
  `queue_free()`. Quyết định 6.4-a — gravity trước đây kéo xuống làm "đáp đất"
  tự nhiên; ở top-down enemy sẽ **trôi theo vector này trong 0.5s**.

## Combat flow (AI-maintained, current state)
- Player attack (J) → bật Hitbox → animation `attack_<facing>` →
  `animation_finished` → tắt Hitbox, `is_attacking = false`.
- `Hitbox._on_hitbox_area_entered(area)` → nếu `area.name == "Hurtbox"` →
  `enemy.take_damage(attack())`.
- Enemy trong `attack_range` + cooldown ready → `player.take_damage(10)`
  ngay lập tức. **Chưa sync với hit-frame animation** — xem
  `docs/known_issues.md` ("Core-feel — cần người playtest").
- Enemy death → `died.emit()` → `queue_free()` (sau tween).
- Player death → set `is_dead=true`, `velocity = Vector2.ZERO` (6.1-b),
  flip V sprite, play `idle_side`, `died.emit()`. UI GameOver lắng nghe signal
  này và pause tree sau 0.6s.

## Animations (AI-maintained, current state)
- Player: `idle_side`, `run`, `run_up`, `run_down`, `attack_side`,
  `attack_up`, `attack_down`. Animation `jump` tồn tại trong sprite sheet
  nhưng **không còn được play** (đã bỏ nhánh `is_on_floor()` khỏi
  `_resolve_animation_name()`).
- Enemy: `idle`, `run`, `attack`.
