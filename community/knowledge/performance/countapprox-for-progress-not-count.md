---
bc-version: [all]
domain: performance
keywords: [countapprox, count, dialog, progress-bar, approximate-count]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Use CountApprox for progress UI, not Count

> Contributions welcome — open a PR to refine or extend this article.

## Description

`Count()` asks SQL for an exact row count of the current filter. On a large table that is a `SELECT COUNT(*)` before any useful work starts — the usual cost of `Dialog.Open` with a percentage bar. `CountApprox()` exists for that UI case: it returns a cheap estimate (partition stats / metadata), accurate enough for a progress denominator. Agents default to `Count()` because the name matches "how many rows".

## Best Practice

Feed progress dialogs and informational messages with `CountApprox()`. Use `Count()` only when the exact integer is a business result (a posted control, a reconciliation, a test assertion).

See sample: `countapprox-for-progress-not-count.good.al`.

## Anti Pattern

`Total := Rec.Count(); Window.Open(...);` immediately before a `FindSet` over the same filter. The exact count is discarded after the bar finishes; the user paid a full scan to draw it.

See sample: `countapprox-for-progress-not-count.bad.al`.
