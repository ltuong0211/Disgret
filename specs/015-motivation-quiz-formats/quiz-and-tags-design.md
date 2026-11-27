# Design: Motivation Quiz, Reel Tags and Matching

**Status**: Proposal for the team (2026-11-27). No code changed yet. **Related**: spec 015
(this folder), spec 002 (bounded dose), ADR-0003 (reel recommender), ADR-0007 (bundled videos).

## 1. Problem

The onboarding quiz has 4 questions and measures only one thing: the user's reason to study (top 2
of 5 `MotivationType`). A reel is tagged only with those 5 reasons and a context. Two reels with
the same reasons look identical to the recommender, even if one is a loud music edit and the other
a calm study-with-me video. The app cannot tell which one this user would actually watch and then
start studying after.

This design adds what the app needs to know (§2), the full label set the team uses to tag videos
(§3), the quiz that fills the profile (§4), and the rules that turn a profile plus labels into a
playlist (§5). It keeps the project rules: fixed rules (no AI), on-device only, explainable in the
course report, ≤3 reels before a session and 1 after a distraction (spec 002).

## 2. What the app needs to know about the user

| # | Dimension | Question it answers | Video label (§3) | Why it matters |
|---|---|---|---|---|
| 1 | Reason | Why do I study? | `motivation` | Core of hypothesis H1: a reel that speaks to my reason makes me start. |
| 2 | Format | What kind of video moves me? | `format` | Same message, different format → very different reaction. |
| 3 | Tone | What kind of push works on me? | `tone` | Some users need hype, others are put off by it. |
| 4 | Messenger | Whose voice do I trust? | `messenger`, `origin` | A peer's story lands differently from a celebrity's. |
| 5 | Blocker | What stops me from starting? | `theme` | Pick the message that answers my actual problem (S1/S2/S3). |
| 6 | Goal | What am I studying for right now? | `goal` | A "from 4.0 to 8.0 IELTS" journey fits a language learner. |
| 7 | Dislikes | What do I never want to see? | `flags`, `language` | Hard filter, so a bad match never plays. |

Reel length is already asked in onboarding and is not repeated here.

Privacy: none of these identify the user. The quiz asks nothing about grades as numbers, money at
home, health or location. Answers stay in the Hive profile on the device and are cleared by
"Xoá toàn bộ dữ liệu". Users may be under 18.

## 3. Label set for videos

Each reel in `assets/reels/reels.json` gets the fields below. Keys are English (stored in data),
labels are the Vietnamese names the team sees when tagging. Every namespace has a fixed list: a
labeller never invents a new value. Unknown values in the file map to the default when loaded.

### 3.1 `motivation`: why to study (1–2, required)

Tag only the reasons the video's message clearly speaks to.

| Key | Nhãn | Tag it when the video says… |
|---|---|---|
| `money` | Tiền bạc, tự chủ tài chính | studying leads to income, not depending on others for money |
| `family` | Gia đình | making parents proud, repaying sacrifice, taking care of family |
| `career` | Sự nghiệp, nghề mơ ước | getting the job or field you want, professional success |
| `proveYourself` | Chứng minh bản thân | proving doubters wrong, beating your old self |
| `freedom` | Tự do, tự quyết | choosing your own life, options, not living by others' rules |
| `growth` *(new)* | Hiểu biết, giỏi lên mỗi ngày | joy of understanding, curiosity, mastery for its own sake |
| `contribution` *(new)* | Giúp ích người khác | using knowledge to help people, community, society |

The two new reasons cover students who are not moved by external rewards. They are new enum
values with no migration needed: old profiles simply never have them.

### 3.2 `format`: kind of video (exactly 1, required)

Pick the dominant format. If a video mixes two, choose the one that fills most of the time.

| Key | Nhãn | Definition | Example |
|---|---|---|---|
| `interview` | Phỏng vấn | A well-known or successful person answering questions or talking on a show/podcast | A singer on a talk show about years of rejection |
| `speech` | Bài phát biểu | One person speaking to an audience (TED, graduation, seminar) | A graduation speech excerpt |
| `edit` | Video edit truyền động lực | Fast cuts, music, big text or voice-over quotes | Music + "Không ai học thay bạn" |
| `quote` | Câu nói + nhạc nền | Static or slow text/quote with music or narration, little footage | A quote on a calm background |
| `journey` | Hành trình chạm đến thành công | Before → after, from zero to a result, told as a path | "Từ 4.0 lên 8.0 IELTS trong 1 năm" |
| `studyWithMe` | Học cùng mình | Real study footage, desk, timelapse, timer | 60 s timelapse of a study session |
| `dayInLife` | Một ngày của người học giỏi | Vlog of a student's or professional's routine | "1 ngày ôn thi của thủ khoa" |
| `story` | Câu chuyện, phim ngắn, hoạt hình | A plot with characters (acted, animated, narrated parable) | Animated snail that is slow but steady |
| `tips` | Mẹo học, phương pháp | Concrete how-to: Pomodoro, active recall, planning | "3 cách bắt đầu học khi đang lười" |
| `other` | Khác | Anything else (default) | |

Spec 015 had 4 formats (`interview`, `edit`, `studyWithMe`, `story`). This list splits them more
finely, because the user's own example ("video phỏng vấn người nổi tiếng", "video hành trình chạm
đến thành công") names formats that the old list merged.

### 3.3 `tone`: emotional push (exactly 1, required)

Judge by the first 5 seconds plus the overall feel.

| Key | Nhãn | Definition |
|---|---|---|
| `hype` | Bùng nổ, hô hào | Strong music, raised voice, high energy |
| `toughLove` | Nói thẳng, hơi "phũ" | Direct, confronting ("không ai cứu bạn đâu") |
| `calm` | Nhẹ nhàng, ấm áp | Slow, soft voice or music, no pressure |
| `emotional` | Chạm cảm xúc | Moving story, may be sad or tearful |
| `funny` | Hài hước | Light, makes you smile |
| `practical` | Thực tế, chỉ việc | Neutral voice, tells you what to do |

### 3.4 `messenger` and `origin`: who speaks (1 each, required)

| Key | Nhãn | | Key | Nhãn |
|---|---|---|---|---|
| `celebrity` | Người nổi tiếng, thần tượng | | `vietnamese` | Người Việt |
| `achiever` | Doanh nhân, người giỏi trong nghề | | `international` | Người nước ngoài |
| `athlete` | Vận động viên | | | |
| `expert` | Thầy cô, chuyên gia, nhà khoa học | | | |
| `peer` | Học sinh, sinh viên cùng trang lứa | | | |
| `ordinary` | Người bình thường, chuyện đời thật | | | |
| `character` | Nhân vật phim, hoạt hình | | | |
| `none` | Không có người nói (chỉ chữ, nhạc) | | | |

### 3.5 `theme`: main message (1–3, required)

| Key | Nhãn | Answers the blocker (§4 Q9) |
|---|---|---|
| `startSmall` | Bắt đầu từ việc nhỏ, chỉ 5 phút | "Việc nhiều quá, không biết bắt đầu từ đâu" |
| `digitalDetox` | Bỏ điện thoại xuống | "Cứ cầm điện thoại là trôi" |
| `fearCourage` | Sợ thì vẫn làm | "Sợ làm không tốt nên né" |
| `futureSelf` | Hình dung bản thân tương lai | "Thấy học chẳng để làm gì" |
| `timeMatters` | Thời gian không chờ ai | "Thấy học chẳng để làm gì" |
| `ownPath` | Đừng so sánh, đi đường của mình | "Hay so sánh rồi nản" |
| `consistency` | Đều đặn mỗi ngày | "Làm được vài hôm rồi bỏ" |
| `discipline` | Kỷ luật hơn cảm hứng | "Làm được vài hôm rồi bỏ" |
| `comeback` | Thất bại rồi đứng dậy | "Làm được vài hôm rồi bỏ", returning after missed days |
| `selfCompassion` | Nghỉ đúng cách, không tự trách | "Mệt, hết năng lượng" |
| `examPressure` | Vượt qua áp lực thi cử | goal `exam` |
| `gratitude` | Biết ơn người đã hy sinh cho mình | reason `family` |

### 3.6 `goal`: fits which study goal (0–2, optional)

`exam` (Kỳ thi: THPT, đại học, chuyển cấp) · `language` (Ngoại ngữ, chứng chỉ) · `grades` (Điểm
trên lớp, GPA) · `skill` (Kỹ năng, nghề: lập trình, thiết kế…). Leave empty when the video fits
any goal.

### 3.7 `language` (exactly 1, required) and `flags` (0–n)

`language`: `vi` (tiếng Việt) · `enSub` (tiếng Anh có phụ đề Việt) · `en` (tiếng Anh không phụ đề).

`flags` mark content that some users dislike (§4 Q11). Tag every one that applies:

| Key | Nhãn |
|---|---|
| `loud` | La hét, nhạc rất to |
| `sad` | Nhạc buồn, không khí nặng |
| `wealthDisplay` | Khoe tiền, xe, nhà |
| `fastCuts` | Cắt cảnh nhanh, nhấp nháy |

### 3.8 Existing fields (unchanged)

`id`, `source`, `title`, `lengthSec`, `assetPath`, `creditUrl` (now required: author credit),
`context` (`start` / `distracted`), `pinFirst`. Proposed later: context `comeback` for opening the
app after ≥2 missed days (S3).

### 3.9 Safety checklist: reject the video, don't tag it

Users may be under 18, and ADR-0007 applies. A video is **not** added if it has any of:
swearing or violence; get-rich-quick or gambling; body shaming; praise for skipping sleep or
studying to exhaustion ("ngủ 3 tiếng/ngày"); putting other people down; politics or religion;
advertising a product; self-harm or heavy grief; a watermark or source that can't be credited.

### 3.10 Example entry

```json
{
  "id": "r7",
  "source": "asset",
  "title": "Từ 4.0 lên 8.0 IELTS trong 1 năm",
  "assetPath": "assets/reels/r7.mp4",
  "lengthSec": 42,
  "creditUrl": "https://…",
  "context": ["start"],
  "motivation": ["proveYourself", "growth"],
  "format": "journey",
  "tone": "emotional",
  "messenger": "peer",
  "origin": "vietnamese",
  "theme": ["consistency", "comeback"],
  "goal": ["language"],
  "language": "vi",
  "flags": []
}
```

The old field `tags` keeps working: when loading, `tags` is read as `motivation` if `motivation`
is missing.

## 4. Quiz

Rules: one question per screen (the current onboarding style); every question has **"Không
chắc"** and can be skipped (= no preference in that dimension); multi-select questions have a cap.
The quiz has two parts so onboarding stays short:

- **Core part** in onboarding: 7 questions, about 75 seconds.
- **Extra part** "Giúp app hiểu bạn hơn": 4 questions, about 40 seconds. Offered once on Hôm nay
  after the third finished session, and always in Cài đặt next to "Làm lại quiz động lực". It
  sharpens the profile; the app works without it.

### Core part (onboarding)

**Q1. Điều gì khiến bạn muốn cố gắng nhất?** (chọn 1) → `motivation`
Có thu nhập tốt, không phải lo chuyện tiền (`money`) · Làm người thân tự hào và yên tâm (`family`)
· Có công việc mình thật sự muốn làm (`career`) · Chứng minh rằng mình làm được (`proveYourself`)
· Được tự quyết định cuộc sống của mình (`freedom`) · Hiểu sâu và giỏi lên mỗi ngày (`growth`)
· Làm được điều có ích cho người khác (`contribution`)

**Q2. Bạn hình dung mình 5 năm nữa thế nào?** (chọn 1) → `motivation`
Làm việc ở đâu, lúc nào là do mình chọn (`freedom`) · Đang ở đúng vị trí mình mơ ước (`career`) ·
Lo được cho gia đình (`family`) · Trở thành người mà trước đây ít ai tin (`proveYourself`) · Tự chủ
tài chính, có khoản tiết kiệm riêng (`money`) · Giỏi thật sự một lĩnh vực mình thích (`growth`) ·
Làm công việc giúp được nhiều người (`contribution`)

**Q5. Bạn thường thấy có động lực sau khi xem kiểu video nào?** (chọn tối đa 2) → `format`
Mỗi lựa chọn có một dòng mô tả nhỏ:
Phỏng vấn người nổi tiếng, người thành công (`interview`) · Bài phát biểu truyền cảm hứng
(`speech`) · Video edit có nhạc và câu nói mạnh (`edit`, `quote`) · Hành trình từ con số 0 đến
thành công (`journey`) · Học cùng mình, một ngày của người học giỏi (`studyWithMe`, `dayInLife`) ·
Câu chuyện ngắn, phim ngắn, hoạt hình (`story`) · Mẹo học ngắn gọn, làm được ngay (`tips`)

An option that names two formats gives both of them the point.

**Q7. Lúc lười học, kiểu "cú hích" nào hợp với bạn nhất?** (chọn 1) → `tone`
Nhạc mạnh, lời hô hào làm mình sôi máu (`hype`) · Ai đó nói thẳng, hơi "phũ" cũng được
(`toughLove`) · Nhẹ nhàng, ấm áp, không áp lực (`calm`) · Một câu chuyện chạm tới cảm xúc
(`emotional`) · Chút hài hước cho nhẹ đầu (`funny`) · Chỉ cần ai đó chỉ việc cụ thể (`practical`)

**Q9. Điều gì hay cản bạn bắt đầu học nhất?** (chọn tối đa 2) → `theme`
Cứ cầm điện thoại là trôi (`digitalDetox`) · Việc nhiều quá, không biết bắt đầu từ đâu
(`startSmall`) · Sợ làm không tốt nên né (`fearCourage`) · Thấy học chẳng để làm gì (`futureSelf`,
`timeMatters`) · Mệt, hết năng lượng (`selfCompassion`) · Hay so sánh với người khác rồi nản
(`ownPath`) · Làm được vài hôm rồi bỏ (`consistency`, `discipline`, `comeback`)

**Q10. Bạn đang học cho mục tiêu gần nhất nào?** (chọn 1) → `goal`
Một kỳ thi sắp tới (`exam`) · Ngoại ngữ, chứng chỉ (`language`) · Điểm số trên lớp (`grades`) ·
Một kỹ năng, một nghề mình thích (`skill`) · Chưa có mục tiêu rõ (none)

**Q11. Có kiểu video nào bạn KHÔNG muốn thấy?** (chọn nhiều, hoặc "Không có") → `flags`,
`language`
La hét, nhạc quá to (`loud`) · Nhạc buồn, dễ chùng xuống (`sad`) · Khoe tiền, xe, nhà
(`wealthDisplay`) · Cắt cảnh nhanh, nhấp nháy (`fastCuts`) · Tiếng Anh không có phụ đề (`en`)

### Extra part ("Giúp app hiểu bạn hơn")

**Q3. Khi sắp bỏ cuộc, điều gì kéo bạn quay lại?** (chọn 1) → `motivation`. The current question
plus "Tò mò muốn hiểu cho bằng được" (`growth`) and "Nghĩ tới những người mình muốn giúp"
(`contribution`).

**Q4. Học tốt hơn sẽ mang lại cho bạn điều gì?** (chọn 1) → `motivation`. The current question
plus "Cảm giác hiểu được điều khó" (`growth`) and "Khả năng giúp đỡ người khác" (`contribution`).

**Q6. Ai nói thì bạn dễ nghe nhất?** (chọn tối đa 2) → `messenger`
Người nổi tiếng, thần tượng của mình (`celebrity`) · Doanh nhân, người giỏi trong nghề
(`achiever`) · Vận động viên (`athlete`) · Thầy cô, chuyên gia (`expert`) · Bạn cùng tuổi đang
học như mình (`peer`) · Người bình thường với câu chuyện thật (`ordinary`) · Không quan trọng (none)

**Q8. Bạn đang lướt mạng và thấy 5 video. Bạn bấm vào cái nào trước?** (chọn 1) → confirms
`format` and `tone`. This is a scenario question: what people pick is usually more reliable than
what they say they like.

| Tiêu đề hiện trên màn hình | format | tone |
|---|---|---|
| "Một ca sĩ nổi tiếng kể về 5 năm bị từ chối" | `interview` | `emotional` |
| "60 giây: nhạc dồn dập + 'Không ai học thay bạn'" | `edit` | `hype` |
| "Vlog: 1 ngày ôn thi của thủ khoa" | `dayInLife` | `practical` |
| "Từ mất gốc đến 8.0 IELTS trong 1 năm" | `journey` | `emotional` |
| "Hoạt hình 1 phút: con ốc sên chậm mà chắc" | `story` | `calm` |

Q1, Q2 and Q5 come early because they carry the most weight. The question numbers are kept stable
so Q3/Q4 (moved to the extra part) keep their current text and old answers stay valid.

## 5. From answers to a playlist

### 5.1 Profile

Each dimension is a small score table, so the recommender can explain itself ("vì bạn chọn …"):

| Profile field | Filled from | Rule |
|---|---|---|
| `motivationTypes` (top 2) | Q1, Q2 (+ Q3, Q4) | +1 per answer; ties go to the earlier question (current `topMotivationTypes`) |
| `formats` (top 2) | Q5, Q8 | Q5 choice +2 each; Q8 choice +1; keep the 2 highest |
| `tone` (1) | Q7, Q8 | Q7 choice; if Q7 is "Không chắc", Q8's tone |
| `messengers` (≤2) | Q6 | as chosen |
| `blockers` → themes | Q9 | the themes behind each chosen option |
| `goal` (0–1) | Q10 | as chosen |
| `avoidFlags`, `avoidLanguages` | Q11 | as chosen |

"Không chắc" or a skipped question leaves that field empty. An empty field gives no bonus and no
penalty.

### 5.2 Step 1: hard filters

From the reels for this context (`start` or `distracted`), drop any reel that
1. has a flag in `avoidFlags` or a language in `avoidLanguages`, or
2. failed the safety checklist (it never reaches the file).

If fewer reels remain than the playlist length, show fewer (spec 002 allows ≤3). The motivation
step still works with 0 reels: it goes straight to the end card with the start buttons.

### 5.3 Step 2: score (whole numbers)

| Match | Points | Why this weight |
|---|---|---|
| Each `motivation` key in the user's top 2 | +3 (max +6) | Reason stays the main signal (H1) |
| Each `theme` that answers a chosen blocker | +2 (max +4) | Answers today's actual problem |
| `format` = user's first format / second format | +2 / +1 | Strong taste signal |
| `tone` = user's tone | +2 | A wrong tone makes people skip |
| `messenger` in user's messengers | +1 | Weaker signal |
| `goal` matches user's goal | +1 | Nice to have; empty goal on reel = 0 |
| Context bonus: `distracted` and theme `digitalDetox` or `startSmall` | +2 | After a distraction, the message should bring the user back |
| Not watched in the last 24 h | +1 | Unchanged from today |
| Last watched reel | −3 | Unchanged rule, scaled to the new weights |

Pinned reels (`pinFirst`) still come first. Ties keep the order in `reels.json`, as today.

### 5.4 Step 3: variety in a 3-reel playlist

Take the best reel. For the next slot, take the best reel with a **different format**, unless
that reel scores more than 2 points below the best remaining reel of the same format. This keeps
the playlist from being three music edits in a row, without showing a poor match just for variety.

### 5.5 Step 4: learn from behaviour (later phase, optional)

The app already records whether the user started studying right after a reel (`startedFocus` in
`reel_watched`) and when they skip (`motivation_skipped`). After at least 3 views of a format:

- start share ≥ 50% → that format gets +1 extra;
- skipped in the first 3 seconds 3 times in a row → that format gets −2 until the next quiz.

This is a counter per format, not AI. It can be listed in the report as "hồ sơ tự điều chỉnh".

### 5.6 Worked example

The user picks: Q1 `proveYourself`, Q2 `career`, Q5 `journey` + `interview`, Q7 `emotional`,
Q9 "Làm được vài hôm rồi bỏ", Q10 `language`, Q11 `loud`. Context: `start`.

| Reel | motivation | theme | format | tone | goal | 24 h | Total |
|---|---|---|---|---|---|---|---|
| r7 "4.0 → 8.0 IELTS" (journey, emotional, peer, [proveYourself, growth], [consistency, comeback], language) | 3 | 4 | 2 | 2 | 1 | 1 | **13** |
| r1 "Bạn đủ thông minh để thay đổi" (interview, toughLove, [proveYourself, career], [fearCourage]) | 6 | 0 | 1 | 0 | 0 | 1 | **8** |
| rX (edit, hype, `loud`, [proveYourself, career]) | removed by the `loud` filter | | | | | | – |

Playlist: r7, then r1 (a different format).

## 6. How many videos the team needs

Minimum so every quiz answer has at least one good match:

| Dimension | Minimum per value | Notes |
|---|---|---|
| `format` | 3 per format (9 formats) | including at least 1 usable in `distracted` |
| `motivation` | 4 per reason (7 reasons) | |
| `tone` | 3 per tone | |
| `theme` | 2 per theme | `digitalDetox`, `startSmall`: 4 each (used after distractions) |
| `language` | most `vi`, some `enSub` | users who avoid `en` must still have enough |
| `context: distracted` | 8 reels | short ones (≤20 s) |

One video covers several rows at once, so **about 30 videos** is enough for a first catalogue.
Start with the formats users pick most in the hallway test.

**Size limit.** The 6 current videos take 13 MB (about 2 MB each). 30 videos at that rate add
about 60 MB to the APK. The team should export at 720p, H.264, about 1 Mbps (about 4 MB per
30 seconds), keep videos at 15–45 seconds, and check the APK size before adding more. Streaming
is not an option (no network, by the constitution).

## 7. How the team tags a video

1. Check the safety list (§3.9). If any item matches, drop the video.
2. Two people tag each video on their own in a shared sheet with these columns: id, title, link,
   credit, lengthSec, context, motivation, format, tone, messenger, origin, theme, goal, language,
   flags.
3. Compare. Where the two disagree, discuss and write down the reason in a note column. Sentences
   in the "Tag it when" columns above decide disputes.
4. Fill the coverage table (§6) and look for gaps before collecting more videos.
5. Copy the agreed rows into `reels.json`. A test (spec 015 T021) checks that every value is in
   the fixed lists.

## 8. What this changes in spec 015

| Spec 015 today | This design |
|---|---|
| 5 reasons | 7 reasons (`growth`, `contribution` added) |
| 4 formats + `other` | 9 formats + `other` |
| Format bonus +1, smaller than a reason match (+2) | Reason +3, format +2/+1; reason still weighs most |
| No tone, messenger, theme, goal, dislikes | Added (§3.3–3.7) |
| Quiz 6 reason + 2 format questions, about 1 minute | 7 core questions (about 75 s) + 4 optional ones |
| No variety rule | Different formats inside one playlist (§5.4) |

The spec, plan, data model and tasks of 015 must be updated (`/speckit-specify` refinement, then
`/speckit-plan` and `/speckit-tasks`) before any code. Because the profile grows, ADR-0003 should
get a note or a follow-up ADR on the new scoring.

## 9. Open questions for the team

1. Add `growth` and `contribution` now, or keep 5 reasons for this release?
2. Is about 75 seconds for the core part acceptable, or should Q10 move to the extra part?
3. Is the 5-option scenario question (Q8) clear on a small phone, or should it show 4?
4. Who collects and tags the first 30 videos, and by when (ADR-0007 credits)?
