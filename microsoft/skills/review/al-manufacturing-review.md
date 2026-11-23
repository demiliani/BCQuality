---
kind: action-skill
id: al-manufacturing-review
version: 1
title: AL manufacturing review
description: Reviews AL extensions of manufacturing and assembly processes against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL manufacturing review

Reviews AL source changes against the `manufacturing` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain manufacturing`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: table extensions of production order, routing, component, `Capacity Ledger Entry`, assembly or posted assembly tables, or event subscribers to `Prod. Order Status Management`, `Production Journal Mgt`, `Output Jnl.-Expl. Route`, the `Calc. Consumption` report, `Mfg. Item Jnl.-Post Line`, `Assembly-Post` or `Assemble-to-Order Link`; code or subscribers touching `Routing Line`, `Planning Routing Line`, `Prod. Order Routing Line`, `Calculate Prod. Order`, `Mfg. Carry Out Action`, subcontracting reports and codeunits or `Req. Wksh.-Make Order`.

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `manufacturing` articles:

- A subscriber to `OnAfterTransProdOrder` reads the new production order and modifies it to copy an extension field, or the field is mirrored on another table to "move" it between statuses — `production-order-status-change-copies-whole-records`.
- A production order field is copied to `Item Journal Line` by only one generation path while the input says users use others, or matching field numbers are expected to be enough — `carry-production-order-fields-to-output-and-consumption-journal-lines`.
- Code finds `Capacity Ledger Entry` rows by order after posting and modifies them — `carry-production-journal-fields-to-capacity-and-item-ledger`.
- A subscriber to `OnAfterCreateItemJnlLineFromAssemblyLine` copies an assembly line field meant for item component consumption entries, or fields on `Posted Assembly Header` or `Posted Assembly Line` use a different number than the source table — `carry-assembly-fields-through-assembly-posting`.
- A subscriber to `OnBeforeNeedsSynchronization` sets `IsHandled := true` unconditionally, or a field copied in `OnBeforeAsmHeaderModify` must update when it changes alone but its `OnValidate` does not call `AutoAsmToOrder` — `carry-sales-line-fields-to-assemble-to-order-assembly-headers`.
- A subscriber to the obsolete `Calculate Subcontracts` report, or a subcontracting purchase line field filled only from a requisition line field set in a calculate-subcontracts event — `carry-routing-fields-to-subcontracting-purchase-lines`.
- A `Routing Line` field copied only on the refresh path with no `Planning Routing Line` field and no `OnAfterCopyFromPlanningRoutingLine` subscriber, or a `Prod. Order Routing Line` insert-event subscriber that reads `Routing Line` and calls `Modify` — `copy-routing-line-fields-on-refresh-and-planning-paths`.

Resolve layer conflicts per READ. When no manufacturing knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"Manufacturing"`.
