# AGENTS.md - Hướng Dẫn Tự Động Hoá Cho Codex

> **File này chỉ chứa QUY TẮC và WORKFLOW.** Mọi thông tin về kiến trúc, quyết định thiết kế, gameplay hiện tại, và known issues nằm ở `docs/` — đây là NGUỒN SỰ THẬT DUY NHẤT (single source of truth) cho nội dung đó. AGENTS.md không lặp lại nội dung của `docs/` để tránh 2 nơi lệch nhau. Nếu bạn (AI) thấy thông tin về game ở đâu đó ngoài `docs/` mâu thuẫn với `docs/`, **`docs/` luôn thắng**.

## 0. BẮT BUỘC: Đọc docs/ trước khi làm bất kỳ việc gì

Trước khi đọc code, sửa code, hay trả lời bất kỳ yêu cầu nào liên quan đến gameplay, bạn PHẢI đọc theo thứ tự sau:

1. **`docs/decisions.md`** — các quyết định thiết kế đã khóa. Đây là luật, không phải gợi ý.
2. **`docs/architecture.md`** — cấu trúc code hiện tại (scene, script, luồng dữ liệu).
3. **`docs/gameplay.md`** — cơ chế gameplay hiện tại + mục tiêu cảm giác chơi (phần "Design Intent").
4. **`docs/known_issues.md`** — bug/TODO đã biết, để không báo cáo lại thứ đã ghi nhận hoặc vô tình "sửa" một quyết định thiết kế tưởng là bug.
5. **`docs/roadmap.md`** — ưu tiên hiện tại, để biết task có nằm trong phạm vi "Now" hay đang bị hoãn ở "Later"/"Explicitly not now".

Nếu 1 trong 5 file trên chưa tồn tại hoặc trống, nói rõ điều đó trong câu trả lời thay vì tự suy luận nội dung thay cho nó.

Nếu yêu cầu của người dùng có vẻ mâu thuẫn với `docs/decisions.md` (ví dụ: người dùng bảo thêm jump trong khi decisions.md khóa top-down không-jump), DỪNG LẠI và hỏi rõ trước khi code — không tự ý chọn bên nào.

## 1. Mục tiêu công việc
Bạn là một AI lập trình toàn diện (hoặc trợ lý tự động). Bạn cần tự động đọc hiểu yêu cầu, đọc `docs/` theo mục 0, nghiên cứu cấu trúc thư mục hiện tại, thực hiện chỉnh sửa, tạo file, và chạy test từ A đến Z mà không cần hỏi lại người dùng từng bước nhỏ — **NGOẠI TRỪ những trường hợp thuộc mục 2.3**.

## 2. Quy tắc hoạt động (Không hỏi - Tự làm, trừ core feel & core decisions)

- Không hỏi các câu như: "Tôi có nên làm thế này không?", "File này để làm gì?", hoặc "Bạn có muốn tôi sửa tiếp không?" đối với thay đổi kỹ thuật thông thường (refactor, viết thêm hàm, sửa bug có nguyên nhân rõ ràng, viết UI, code lặp lại).
- Tự động suy luận, tự động refactor, hoặc viết tiếp code cần thiết cho các phần không thuộc core feel/core decision.
- **2.3 — Chỉ dừng lại và hỏi khi:**
  1. Gặp lỗi hệ thống hoặc xung đột logic cực kỳ nghiêm trọng.
  2. Cần mật khẩu, API key mới, hoặc thông tin bảo mật.
  3. Thay đổi động chạm đến core movement system, combat timing, hoặc bất kỳ con số nào ảnh hưởng trực tiếp đến cảm giác chơi (speed, damage, cooldown, knockback, hitbox timing). Có thể đề xuất giá trị nhưng KHÔNG tự áp dụng khi chưa được duyệt.
  4. Thay đổi kiến trúc di chuyển nền tảng hoặc bất kỳ điều gì đã LOCKED trong `docs/decisions.md`.
  5. Yêu cầu của người dùng mâu thuẫn với một entry trong `docs/decisions.md`.
- **2.4 — Không bao giờ tự ý ghi vào `docs/decisions.md` hoặc `docs/roadmap.md`.** Xem bảng phân quyền ở mục 4.

## 3. Tiêu chuẩn code & Đầu ra
- Tuân thủ tuyệt đối cấu trúc dự án.
- Code viết ra phải rõ ràng, có comment, đảm bảo tiêu chuẩn project (chi tiết coding convention nằm ở mục 6 bên dưới).
- Trước khi lưu file, tự động kiểm tra lại cú pháp (syntax check).
- Sau khi hoàn thành một luồng việc, xuất báo cáo ngắn gọn về những gì đã làm — bao gồm cả file nào trong `docs/` cần người review cập nhật (nếu có).

## 4. Phân quyền ghi vào docs/

```
docs/
├── architecture.md    → AI tự do viết/cập nhật
├── decisions.md        → CHỈ con người viết
├── gameplay.md          → mixed (xem bên dưới)
├── known_issues.md      → AI tự do viết/cập nhật
└── roadmap.md            → CHỈ con người viết (AI có thể đề xuất bằng lời trong chat)
```

| File | Ai viết | Quyền của AI |
|---|---|---|
| `decisions.md` | Người | AI chỉ đọc và tuân theo. Không được tự thêm/sửa/xóa entry, kể cả để "ghi lại" một quyết định AI tự suy luận ra. Nếu thấy cần quyết định mới → dừng lại, hỏi người, chờ họ chốt bằng lời rồi mới ghi (và vẫn nên để người xác nhận bản ghi cuối). |
| `roadmap.md` | Người | AI có thể đề xuất thứ tự/ưu tiên trong câu trả lời chat, nhưng không tự sửa file trừ khi được yêu cầu rõ ràng "cập nhật roadmap.md". |
| `architecture.md` | AI | Mô tả thuần code hiện tại. Cập nhật tự do sau mỗi thay đổi cấu trúc, không cần hỏi. |
| `known_issues.md` | AI | Tự quét code, liệt kê bug/TODO tìm thấy. Không cần duyệt trước khi cập nhật. |
| `gameplay.md` | Mixed | Phần mô tả kỹ thuật (input map, animation, combat flow hiện tại) → AI viết tự do. Phần "Design Intent / Feel Goals" (mục tiêu cảm giác chơi) → CHỈ người viết, AI không được tự bịa hay diễn giải lại. |

**Nguyên tắc vàng:** mô tả code đang làm gì → AI viết được. Mô tả ai đó đã quyết định nó nên như thế nào, hoặc tại sao → chỉ người viết, AI chỉ đọc và tuân theo.

Nếu được yêu cầu chung chung "cập nhật docs" → chỉ động vào `architecture.md`, `known_issues.md`, và phần kỹ thuật của `gameplay.md`. Phải nói rõ trong báo cáo rằng `decisions.md` và `roadmap.md` bị bỏ qua có chủ đích.

## 5. File Safety

Không bao giờ sửa các mục sau trừ khi được yêu cầu rõ ràng:
- `.godot/`, `.import/`, `Tiny Swords/`, imported assets, generated files
- `project.godot`, `.gitignore`, `.gitattributes`, `.vscode/launch.json`

## 6. Coding Conventions

- Files: lowercase snake_case (`player.gd`, `enemy.gd`).
- Functions/variables: snake_case (`current_hp`, `is_attacking`).
- Constants: UPPERCASE (`SPEED`); Enums: PascalCase (`Facing`).
- Input actions: snake_case trong `project.godot`.
- Dùng `@export` cho giá trị cần chỉnh trong Godot editor; `@onready` cho tham chiếu node con.
- Dùng signal cho sự kiện xuyên node khi cần listener.
- Comment ưu tiên tiếng Việt cho phần giải thích gameplay, trừ khi code xung quanh toàn tiếng Anh.
- Không đổi tên method/node public (`take_damage`, `attack`, `_on_hitbox_area_entered`, `AnimatedSprite2D`, `Hitbox`, `Hurtbox`, `HealthBar`, `Camera2D`) mà không cập nhật hết nơi gọi.
- Ưu tiên thứ tự: Correctness → Readability → Maintainability → Simplicity → Performance.

## 7. Ngoài phạm vi (Out of Scope)

Trừ khi được yêu cầu rõ ràng, KHÔNG tự làm: Multiplayer, Networking, ECS architecture, plugin systems, save optimization, refactor lớn, tối ưu performance vi mô.

## 8. Feature Development Workflow

1. Đọc `docs/` theo mục 0.
2. Đọc code/scene liên quan trực tiếp đến task.
3. Xác định file tối thiểu cần sửa.
4. Trình bày kế hoạch ngắn trước khi sửa nếu thay đổi ảnh hưởng hành vi/kiến trúc — **luôn trình bày kế hoạch trước nếu chạm vào movement, combat timing, hoặc core-feel value.**
5. Sửa từng bước nhỏ.
6. Chạy kiểm tra khả dụng (build/syntax check); nếu không có test/build command, nói rõ là verify thủ công.
7. Kiểm tra ảnh hưởng tới gameplay hiện có: movement, attack, HP bar, enemy chase/attack, scene startup.
8. Báo cáo: file đã đổi, kết quả verify, core-feel value nào còn cần người playtest xác nhận, và file `docs/` nào nên được cập nhật (tự cập nhật nếu thuộc quyền AI theo mục 4).

## 9. Bug Fix Workflow

1. Đọc `docs/known_issues.md` xem bug đã ghi nhận chưa.
2. Đọc `docs/decisions.md` để chắc chắn hành vi "lỗi" đó không phải là quyết định thiết kế cố ý.
3. Tái hiện/mô tả bug bằng scene và input hiện tại.
4. Đọc bộ script/scene nhỏ nhất liên quan.
5. Xác định nguyên nhân gốc trước khi sửa.
6. Sửa tối thiểu, giữ nguyên method/node/animation/input public.
7. Verify bug cụ thể + một vài hành vi liên quan để tránh regression.
8. Cập nhật `docs/known_issues.md` (đóng issue hoặc ghi trạng thái mới) — thuộc quyền AI.

## 10. Verification Checklist

Sau mỗi thay đổi, xác nhận hoặc nêu rõ vì sao mục nào đó Unknown/chưa chạy được:
- Project chạy được từ `res://node_2d.tscn`.
- Không có lỗi cú pháp/compile GDScript mới.
- Test liên quan đã chạy (nếu có).
- Không sửa file không liên quan.
- Không thêm dependency/addon/plugin không cần thiết.
- Gameplay hiện có vẫn hoạt động: movement, attack, enemy chase/attack, HP bar, enemy death.
- File generated/imported không bị sửa tay.
- Không có core-feel value nào bị chốt mà chưa gắn cờ cần người xác nhận.
- Không có entry nào bị AI tự thêm/sửa trong `docs/decisions.md` hoặc `docs/roadmap.md`.

## 11. Git Guidelines

- `git status --short` trước và sau khi sửa.
- Review `git diff` trước khi báo cáo hoàn thành.
- Không commit/push/reset/clean/rebase/merge/checkout thay người dùng trừ khi được yêu cầu rõ ràng.
- Không bỏ thay đổi mà mình không tạo ra.
- Giữ diff gọn, giải thích ngay nếu có file thay đổi ngoài dự kiến.

## 12. Rules for AI Agents (tổng hợp)

- Đọc `docs/` (mục 0) + toàn bộ file liên quan trước khi sửa bất cứ gì.
- Chỉ tạo/sửa file thực sự cần cho task.
- Không sửa code/scene/asset/setting không liên quan.
- Không thay đổi kiến trúc lớn trừ khi được yêu cầu rõ ràng.
- Không xóa asset/node/signal/input/chức năng hiện có mà chưa được duyệt.
- Không thêm dependency/addon/plugin mới mà chưa giải thích và được duyệt.
- Nếu command/test/build/export nào Unknown trong `docs/`, xác minh từ repo trước hoặc hỏi trước khi dùng.
- Không được tự tinh chỉnh/chốt bất kỳ giá trị nào ảnh hưởng core game feel mà không gắn cờ "cần người playtest xác nhận".
- Không được tự ghi vào `docs/decisions.md` hay `docs/roadmap.md` (mục 2.4, mục 4).
- Không commit secrets/tokens/API keys/đường dẫn nhạy cảm.
- Không chạy lệnh phá hủy (`git reset`, `git clean`, `rm` hàng loạt...) mà chưa được duyệt rõ ràng.