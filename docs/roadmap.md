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
- `jump` = Space — being removed, see decisions.md

## Player (AI-maintained, current state)
- `scripts/player.gd`, root `Player` (`CharacterBody2D`)
- `SPEED = 300.0`
- `attack_damage = 20`, `max_hp = 1000`
- Facing enum: RIGHT / LEFT / UP / DOWN, `facing_left` flips sprite

## Enemy (AI-maintained, current state)
- `scripts/enemy.gd`, root `Enemy` (`CharacterBody2D`)
- `max_hp = 100`, `speed = 120.0`, `chase_range = 200.0`,
  `stop_distance = 8.0`, `attack_range = 60.0`, `attack_cooldown = 1.0`

## Combat flow (AI-maintained, current state)
- Player attack → enables Hitbox → on Hurtbox overlap → `enemy.take_damage(attack())`
- Enemy in range + cooldown ready → `player.take_damage(10)` immediately
  (not yet synced to animation hit-frame — see known_issues.md)
- Enemy death → `died.emit()` → `queue_free()`
- Player death → currently just logs a message (no game-over flow yet)

## Animations (AI-maintained, current state)
- Player: `idle_side`, `run`, `run_up`, `run_down`, `jump`, `attack_side`,
  `attack_up`, `attack_down`
- Enemy: `idle`, `run`, `attack`