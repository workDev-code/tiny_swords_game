<!--
OWNERSHIP: HUMAN ONLY.
AI agents: READ this file and follow it. Do NOT add, edit, or remove entries here
yourself — not even to "record" a decision you inferred from a conversation.
If you think a new decision is needed, stop and ask the human, then wait for
their explicit wording before touching this file.
-->

# Design Decisions

Intentional project decisions, not bugs. Newest on top.

## 2026-07-06 — Movement model: TOP-DOWN 4-DIRECTIONAL

Status: LOCKED

Decision:
- Top-down 4-directional movement (Stardew Valley style).
- `move_left/right/up/down` all move the player directly on both axes.
- No gravity, no jump. `jump` input and `JUMP_VELOCITY` are removed from gameplay.

Reason:
Matches intended genre/camera style. Supersedes an earlier incorrect
side-scrolling/platformer draft.

Do NOT reintroduce gravity or jump without a new decision logged here.

---

<!-- Add new decisions above this line, newest first. -->