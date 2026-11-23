---
kind: action-skill
id: al-pricing-review
version: 1
title: AL pricing review
description: Reviews AL extensions of the price list model and price calculation against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL pricing review

Reviews AL source changes against the `pricing` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain pricing`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: table extensions of or code using `Price List Header`, `Price List Line`, `Price Worksheet Line`, `Price Calculation Buffer`, `Price Calculation Setup` or `Dtld. Price Calculation Setup`; implementations of the `Line With Price`, `Price Calculation`, `Price Source` or `Price Asset` interfaces; extensions of the price source type, price asset type, price calculation handler or price status enums; subscribers to `Sales Line - Price`, `Purchase Line - Price`, `Job Planning Line - Price`, `Price Calculation - V16`, `Price Calculation Buffer Mgt.`, `Price Calculation Mgt.` or `Price List Management`; or subscribers to `OnUpdateUnitPriceOnBeforeFindPrice`, `OnUpdateDirectUnitCostOnBeforeFindPrice` or `OnAfterApplyPrice`.

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `pricing` articles:

- An `OnUpdateUnitPriceOnBeforeFindPrice` or `OnUpdateDirectUnitCostOnBeforeFindPrice` subscriber sets `IsHandled` and reads `Price List Line` with its own filters, or an `OnAfterAddSources` subscriber calls `Add` without `SetLevel` or adds a customer source without checking that the price type is Sale — `document-line-price-selection-runs-by-source-level-then-best-price`.
- A value from the applied price list line is copied in `OnAfterApplyPrice` or `OnAfterUpdateUnitPrice` or by looking up `Price List Line` again, or an `OnAfterSetPrice` subscriber copies fields without checking `AmountType` or without handling a line that is not real — `copy-applied-price-list-line-fields-in-onaftersetprice`.
- An `OnAfterSetFilters` subscriber uses `SetRange` on a custom `Price List Line` field with no blank fallback, or a custom filter attribute has no matching `OnAfterSetAssetFilters` subscriber or is not filled into the buffer in `OnAfterFillBuffer` — `custom-price-list-line-attribute-needs-buffer-filter-and-duplicate-check`.
- `Price List Header` status is assigned directly instead of validated, a `Price List Line` is inserted without `CopyFrom` from its header or `Validate("Asset Type")`, or an active line is modified with `Modify(true)` and never re-activated with `ActivateDraftLines` — `create-price-lists-from-code-through-header-defaults-and-status-validation`.
- A field added to `Price List Line` has no field with the same number and type on `Price Worksheet Line` — `price-worksheet-and-copy-lines-carry-custom-fields-by-field-number`.
- A purchase or project cost price list line gets `Unit Price` instead of the cost fields, a project price list header validates `Source Type` before `Price Type` is set, or a pricing rule subscribes only to `Sales Line - Price` events when purchase or project lines are in scope — `purchase-and-project-prices-use-their-own-price-type-sources-and-fields`.

Resolve layer conflicts per READ. When no pricing knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"Pricing"`.
