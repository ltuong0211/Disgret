# Data Contract: `assets/reels/reels.json`

Each entry in `reels`:

| Key | Required | Type | Notes |
|---|---|---|---|
| id | yes | string | unique, e.g. `r7` |
| assetPath | yes | string | `assets/reels/<id>.mp4`, file must exist and be declared in pubspec |
| title | yes | string | Vietnamese or original title |
| tags | yes | list of MotivationType names | ≥1 |
| lengthSec | yes | int | 15–60 for new reels |
| context | yes | list of `start` / `distracted` | ≥1 |
| pinFirst | no | list of contexts | unchanged |
| format | no (new) | `interview` / `edit` / `studyWithMe` / `story` | missing or unknown → `other` |
| source, creditUrl | yes for new reels | string | recorded for ADR-0007 |

Invariant checked by a unit test (SC-006): each of the four quiz formats has ≥1 reel whose
`context` contains `start`.
