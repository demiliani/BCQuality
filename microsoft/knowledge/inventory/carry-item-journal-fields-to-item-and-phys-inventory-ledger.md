---
bc-version: [all]
domain: inventory
keywords: [item-journal-line, phys-inventory-journal, phys-inventory-ledger-entry, item-ledger-entry, onbeforeinsertphysinvtledgentry, onafterinititemledgentry, insertphysinventoryentry, item-jnl-post-line, inventory]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry item journal fields to item and physical inventory ledger entries

## Description

`Item Jnl.-Post Line` posts every item journal line, including physical inventory journal lines. A tracked line is first split into one line per lot or serial; the split copies the whole `Item Journal Line` record, so table extension fields on the journal line survive it. Each split line then produces an `Item Ledger Entry` through `InitItemLedgEntry`, which assigns named fields one by one and raises `OnAfterInitItemLedgEntry` before the insert.

A physical inventory line also produces one `Phys. Inventory Ledger Entry`. `InsertPhysInventoryEntry` builds it field by field from the original, unsplit journal line and raises `OnBeforeInsertPhysInvtLedgEntry(var PhysInventoryLedgerEntry, ItemJournalLine, LastSplitItemJournalLine)` before `Insert(true)`. The `ItemJournalLine` parameter is the original line; `LastSplitItemJournalLine` is only the last split part.

## Best Practice

Add the field to `Item Journal Line` and to each ledger table the plan needs. Copy it to the item ledger entry in `OnAfterInitItemLedgEntry` on `Item Jnl.-Post Line`, the same subscriber that document posting uses; see [carry sales line fields to the item ledger](../sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md). Copy it to the physical inventory ledger entry in `OnBeforeInsertPhysInvtLedgEntry`, reading from the `ItemJournalLine` parameter.

Values entered for each counted lot belong to the item tracking lines, not to the journal line; see [carry item tracking line fields to item ledger entries](carry-item-tracking-line-fields-to-item-ledger-entries.md). Post inventory changes only through item journals; see [post item ledger changes through item journals](../scm/post-item-ledger-changes-through-item-journals.md).

See sample: [`carry-item-journal-fields-to-item-and-phys-inventory-ledger.good.al`](carry-item-journal-fields-to-item-and-phys-inventory-ledger.good.al).

## Anti Pattern

Give the field the same number on `Phys. Inventory Ledger Entry` and expect it to be copied: the entry is built field by field, so it stays empty. Reading from `LastSplitItemJournalLine` gives the values of the last lot only. Patching ledger entries after posting by document number edits posted entries outside the posting engine.

See sample: [`carry-item-journal-fields-to-item-and-phys-inventory-ledger.bad.al`](carry-item-journal-fields-to-item-and-phys-inventory-ledger.bad.al).

## References

- [Item Jnl.-Post Line, InitItemLedgEntry, split and InsertPhysInventoryEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Posting/ItemJnlPostLine.Codeunit.al).
- [Phys. Inventory Ledger Entry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Counting/Journal/PhysInventoryLedgerEntry.Table.al).
- [Count, adjust and reclassify inventory using journals](https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-count-adjust-reclassify).
