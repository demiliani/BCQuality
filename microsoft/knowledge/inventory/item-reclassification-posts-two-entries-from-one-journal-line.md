---
bc-version: [all]
domain: inventory
keywords: [item-reclassification-journal, item-journal-line, entry-type-transfer, new-location-code, inserttransferentry, onafterinititemledgentry, onbeforeinserttransferentry, item-ledger-entry, item-jnl-post-line]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Item reclassification posts two entries from one journal line

## Description

A line in the item reclassification journal is an `Item Journal Line` with `Entry Type` set to `Transfer`. `Item Jnl.-Post Line` turns it into two kinds of item ledger entries. The negative entry is built by `InitItemLedgEntry` at `Location Code`. After that entry is applied, `InsertTransferEntry` creates the positive entry. Unless the item uses average cost, it creates one positive entry for each entry the negative entry applies to, so one journal line can produce several positive entries.

`InsertTransferEntry` also calls `InitItemLedgEntry`, so `OnAfterInitItemLedgEntry(var NewItemLedgEntry, var ItemJournalLine, var ItemLedgEntryNo)` runs for the negative entry and for every positive entry, with the same journal line. Only after that event does `InsertTransferEntry` set the positive entry's values:

- `Quantity` becomes the applied quantity. `InitItemLedgEntry` gave every transfer entry the negated journal quantity, so for a normal positive journal line it is negative.
- `Location Code` comes from `New Location Code`.
- Lot and serial numbers come from `New Lot No.` and `New Serial No.`, and the expiration date from `New Item Expiration Date`.

It then raises `OnBeforeInsertTransferEntry(var NewItemLedgerEntry, var OldItemLedgerEntry, var ItemJournalLine)`. When the entry is inserted, it takes its dimensions from `New Dimension Set ID`.

## Best Practice

For a value that is the same on both sides, add the field to `Item Journal Line` and `Item Ledger Entry`. Copy it in `OnAfterInitItemLedgEntry`, the same subscriber that other item postings use; see [carry item journal fields to item and physical inventory ledger](carry-item-journal-fields-to-item-and-phys-inventory-ledger.md). It reaches the negative entry and all positive entries without extra code.

For a value that the reclassification changes, follow the standard `New ...` pattern. Add a second journal field, for example `New Storage Zone`. Copy the old value in `OnAfterInitItemLedgEntry`, then overwrite it with the new value in `OnBeforeInsertTransferEntry`, which runs only for the positive entries.

Transfer orders post through other codeunits but reach the same events; see [carry transfer line fields to the item ledger](../warehouse/carry-transfer-line-fields-to-item-ledger.md).

See sample: [`item-reclassification-posts-two-entries-from-one-journal-line.good.al`](item-reclassification-posts-two-entries-from-one-journal-line.good.al).

## Anti Pattern

Tell the two sides apart inside `OnAfterInitItemLedgEntry` with `Quantity > 0` or `Location Code`. At that point every transfer entry of a normal line is still negative and still at the old location, so the new value is never used. Another mistake is to set the value on the negative entry and expect the positive entry to inherit it. The positive entry is built again from the journal line, not copied from the negative entry.

See sample: [`item-reclassification-posts-two-entries-from-one-journal-line.bad.al`](item-reclassification-posts-two-entries-from-one-journal-line.bad.al).

## References

- [Item Jnl.-Post Line, InitItemLedgEntry, ApplyItemLedgEntry and InsertTransferEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Posting/ItemJnlPostLine.Codeunit.al).
- [Item Ledger Entry, CopyTrackingFromNewItemJnlLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Ledger/ItemLedgerEntry.Table.al).
- [Item Journal Line, IsReclass](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Journal/ItemJournalLine.Table.al).
