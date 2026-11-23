---
kind: action-skill
id: al-inventory-review
version: 1
title: AL inventory review
description: Reviews AL extensions of item tracking, item charge and inventory journal processes against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL inventory review

Reviews AL source changes against the `inventory` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain inventory`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: code that creates `Reservation Entry` rows or extends `Tracking Specification`, `Reservation Entry`, `Lot No. Information`, item charge assignment tables, `Item Journal Line`, `Item Ledger Entry` or `Phys. Inventory Ledger Entry`, or event subscribers to `Create Reserv. Entry`, the `Item Tracking Lines` page, `Item Charge Assgnt. (Purch.)`, `Item Charge Assgnt. (Sales)` or `Item Jnl.-Post Line`; item journal lines with entry type Transfer (reclassification), or code reading variant requirements from `Item`, `Item Variant` or `Inventory Setup`. Also review inputs that extend `Requisition Line`, `Inventory Profile`, `Item`, `Nonstock Item` or `Item Reference`, or subscribe to `Req. Wksh.-Make Order`, `Inventory Profile Offsetting`, `Sales Line Invt. Profile`, `Mfg. Carry Out Action`, `Carry Out Action`, `Catalog Item Management`, `Item Subst.` or `Item Reference Management`.

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `inventory` articles:

- Code inserts `Reservation Entry` rows directly (`Init` and `Insert` with hand-filled source fields or a computed `Entry No.`) to assign lot or serial numbers, instead of `"Create Reserv. Entry".CreateReservEntryFor` and `CreateEntry` — `assign-lot-and-serial-tracking-from-code-through-create-reserv-entry`.
- A field added to `Tracking Specification` has no field with the same number on `Reservation Entry`, or it is expected on `Item Ledger Entry` with no subscriber to `OnAfterCopyTrackingFromSpec` and `OnAfterCopyTrackingFromItemJnlLine`, or it is patched on posted item ledger entries by lot — `carry-item-tracking-line-fields-to-item-ledger-entries`.
- A subscriber to `OnBeforeSuggestAssgnt` sets `IsHandled` to replace the item charge suggestion, or an `OnAssignItemCharges` subscriber acts without comparing `SelectionTxt` with its own caption or never sets `ItemChargesAssigned` — `add-a-custom-item-charge-distribution-method`.
- A field is mirrored by number on `Phys. Inventory Ledger Entry` with no subscriber to `OnBeforeInsertPhysInvtLedgEntry`, or that subscriber reads `LastSplitItemJournalLine` — `carry-item-journal-fields-to-item-and-phys-inventory-ledger`.
- An `OnAfterInitItemLedgEntry` subscriber branches on `Quantity > 0`, `Positive` or `Location Code` to choose a new value for transfer entries, or a value set only on the negative entry is expected on the positive one — `item-reclassification-posts-two-entries-from-one-journal-line`.
- Code reads `Variant Mandatory if Exists` from the setup or the item alone instead of `Item.IsVariantMandatory()`, assigns `Variant Code` with `:=` on a line that is posted, or validates `Bin Code` before `Variant Code` — `check-variant-requirements-through-item-is-variant-mandatory`.
- A planned value is read from `Sales Line` only through `Requisition Line."Demand Order No."`, a subscriber to `OnAfterPurchOrderLineInsert` or `OnInsertProdOrderLineOnAfterProdOrderLineInsert` sets a custom field and calls `Modify`, an `OnMaintainPlanningLineOnBeforeReqLineInsert` subscriber copies from `DemandInvtProfile` without a `"Source Type"` check, or a requisition field reaches `Purchase Line` but not `Prod. Order Line` when manufactured items are in scope — `carry-demand-fields-through-planning-lines-to-supply-orders`.
- An item default lives in an `Item` table-extension `OnInsert` trigger or an insert subscriber that exits when `not RunTrigger`, a `Sales Line` `OnAfterAssignItemValues` or `No.` validate subscriber exits on `IsTemporary()`, or a line default is set in a page-extension `OnAfterValidate` of `No.` — `catalog-items-substitutions-and-item-references-set-sales-lines-differently`.

Resolve layer conflicts per READ. When no inventory knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"Inventory"`.
