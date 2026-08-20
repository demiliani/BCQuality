---
bc-version: [all]
domain: performance
keywords: [setloadfields, partial-record, jit-load, modify, insert, transferfields, write-path]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Skip SetLoadFields on write and copy paths

> Contributions welcome — open a PR to refine or extend this article.

## Description

`SetLoadFields` is a read optimization. `Insert`, `Modify`, `Delete`, `Rename`, `TransferFields`, and copy into a temporary record all require a fully loaded row. When those operations run on a partial record, the platform issues a just-in-time load of the missing fields. That extra round-trip costs more than loading the full row on the original `FindSet` or `Get`. Agents that apply `use-setloadfields-for-partial-records.md` to every loop therefore make write loops slower, not faster.

## Best Practice

Use `SetLoadFields` only when the subsequent access is read-only. On a loop that writes the iterated record, or copies it with `TransferFields` / `Copy` onto a temporary record, omit `SetLoadFields` so the initial read already materializes every field those operations need.

See sample: `skip-setloadfields-on-write-and-transferfields.good.al`.

## Anti Pattern

Calling `SetLoadFields` immediately before a `FindSet` whose body `Modify`s, `Delete`s, `Rename`s, or `TransferFields`s the same record. The review signal is partial-record setup on a record variable that is written or copied in the same iteration, not the mere presence of `SetLoadFields` on a read-only loop.

See sample: `skip-setloadfields-on-write-and-transferfields.bad.al`.
