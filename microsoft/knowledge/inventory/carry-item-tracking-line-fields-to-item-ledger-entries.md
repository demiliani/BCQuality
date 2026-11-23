---
bc-version: [all]
domain: inventory
keywords: [item-tracking, tracking-specification, reservation-entry, item-tracking-lines, oncreatereserventryextrafields, onafterentriesareidentical, onaftermovefields, onaftercopytrackingfromspec, onaftercopytrackingfromitemjnlline, lot-no-information]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry item tracking line fields to item ledger entries

## Description

A value typed per lot or serial on the Item Tracking Lines page travels through four records: the page's temporary `Tracking Specification`, the source line's `Reservation Entry` rows, the split `Item Journal Line`, and the `Item Ledger Entry`. Each hop uses a different mechanism:

- **Page to reservation entry, new line.** `RegisterChange` builds the entry with `"Create Reserv. Entry"` and raises `OnCreateReservEntryExtraFields(var InsertReservEntry, OldTrackingSpecification, NewTrackingSpecification)` before `CreateEntry`.
- **Page to reservation entry, changed line.** The page decides whether a line changed with `EntriesAreIdentical`, which compares standard fields only, and raises `OnAfterEntriesAreIdentical`. Fields shared by a lot are written back in `ModifyFieldsWithinFilter`, which raises `OnAfterMoveFields(var TrkgSpec, var ReservEntry)`.
- **Reservation entry to page, and to posting.** The page loads entries with `TransferFields(ReservEntry)`. Posting builds its tracking specifications in `"Item Tracking Management".SumUpItemTracking`, also with `TransferFields(ReservEntry)`, summed per lot and serial.
- **Specification to journal line to ledger entry.** `Item Jnl.-Post Line` splits the line and calls `CopyTrackingFromSpec`, which raises `OnAfterCopyTrackingFromSpec` on `Item Journal Line`. `InitItemLedgEntry` calls `CopyTrackingFromItemJnlLine`, which raises `OnAfterCopyTrackingFromItemJnlLine` on `Item Ledger Entry`.

## Best Practice

Give the field the same number and type on `Tracking Specification` and `Reservation Entry`, so both `TransferFields` hops carry it. Add it to `Item Journal Line` and `Item Ledger Entry`. Then subscribe to the five events above: copy on creation, report a difference in `IdenticalArray[2]` when the custom field differs, copy on modification, copy into the split journal line, and copy into the ledger entry.

Because posting sums reservation entries per lot and serial, a value that differs between entries of the same lot keeps only the first entry's value. Use this path for a value that belongs to the tracked unit. When the value describes the lot itself and never differs per document, store it on `Lot No. Information`, keyed by item, variant and lot, and read it from there instead of copying it through posting.

See sample: [`carry-item-tracking-line-fields-to-item-ledger-entries.good.al`](carry-item-tracking-line-fields-to-item-ledger-entries.good.al).

## Anti Pattern

Add the field to `Tracking Specification` and the page only, or give it a different number on `Reservation Entry`. The value is lost when the page closes or when posting rebuilds the specifications. Patching `Item Ledger Entry` after posting by lot number edits a posted entry; see [post item ledger changes through item journals](../scm/post-item-ledger-changes-through-item-journals.md).

See sample: [`carry-item-tracking-line-fields-to-item-ledger-entries.bad.al`](carry-item-tracking-line-fields-to-item-ledger-entries.bad.al).

## References

- [Item Tracking Lines page, RegisterChange, EntriesAreIdentical and ModifyFieldsWithinFilter](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/ItemTrackingLines.Page.al).
- [Item Tracking Management, SumUpItemTracking](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/ItemTrackingManagement.Codeunit.al).
- [Item Jnl.-Post Line, split and InitItemLedgEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Posting/ItemJnlPostLine.Codeunit.al).
- [Design details: item tracking and reservations](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-item-tracking-and-reservations).
