---
bc-version: [all]
domain: performance
keywords: [tableextension, companion-table, gl-entry, related-table, flowfield, hot-table]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Prefer a related table over stored fields on hot ledgers

> Contributions welcome — open a PR to refine or extend this article.

## Description

Stored fields on a table extension live in companion storage that is joined when the base row is read. On hot tables — G/L Entry, Item Ledger Entry, Cust. Ledger Entry — that join is paid on posting, lists, and APIs even when the extra columns are unused. A related table keyed by the ledger `Entry No.`, optionally surfaced with a FlowField or FactBox, leaves the base read path alone. Agents extend G/L Entry because it is "where the posting already is".

## Best Practice

Put optional, sparse, or integration attributes in a related table with the ledger entry number as primary key. Show them from a FactBox or a FlowField. Use a tableextension stored field only when the value must appear as a native list column and is read on almost every access.

See sample: `prefer-related-table-over-extension-on-hot-ledgers.good.al`.

## Anti Pattern

`tableextension` on `"G/L Entry"` (or another posting table) that adds several stored `Text`/`Blob` fields used only by one integration. Every base-table read now joins those columns.

See sample: `prefer-related-table-over-extension-on-hot-ledgers.bad.al`.
