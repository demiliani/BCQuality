---
bc-version: [all]
domain: manufacturing
keywords: [capacity-ledger-entry, item-ledger-entry, output, consumption, item-jnl-post-line, onbeforeinsertcapledgentry, onafterinititemledgentry, manufacturing, production-order]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry production journal fields to capacity and item ledger entries

## Description

Posting an output line creates a `Capacity Ledger Entry` for the operation and, on the last operation, an `Item Ledger Entry` for the produced item. Posting a consumption line creates an `Item Ledger Entry` for the component. All of them are created in `"Item Jnl.-Post Line"` from the `Item Journal Line`, field by field.

`InsertCapLedgEntry` initializes the capacity entry, assigns its fields one by one and raises `OnBeforeInsertCapLedgEntry(var CapLedgEntry; ItemJournalLine; LastOperation)` just before `Insert(true)`. Item ledger entries for output and consumption go through the same initialization as every other item posting and raise `OnAfterInitItemLedgEntry(var NewItemLedgEntry; var ItemJournalLine; var ItemLedgEntryNo)` before insert.

## Best Practice

Once the value is on the journal line (see [carry production order fields to output and consumption lines](carry-production-order-fields-to-output-and-consumption-journal-lines.md)), add the field to the entry tables the feature needs and copy it in those two events. Both are published by `"Item Jnl.-Post Line"`. The item ledger subscriber is shared with every other item posting, including sales, purchases and transfers, so read the journal line's value and leave the entry empty when the line carries none; see [carry sales line fields to the item ledger](../sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md).

Store the field on the entry only when users filter or report on it there; a related table keyed by the entry number avoids the cost on these high-volume tables, as [prefer a related table over stored fields on hot ledgers](../performance/prefer-related-table-over-extension-on-hot-ledgers.md) explains.

See sample: [`carry-production-journal-fields-to-capacity-and-item-ledger.good.al`](carry-production-journal-fields-to-capacity-and-item-ledger.good.al).

## Anti Pattern

Find the capacity or item ledger entries after posting by order number and `Modify` them. The entries are outputs of posting; the subscriber adds a write per entry and runs after the values were already final. See [post item ledger changes through item journals](../scm/post-item-ledger-changes-through-item-journals.md).

See sample: [`carry-production-journal-fields-to-capacity-and-item-ledger.bad.al`](carry-production-journal-fields-to-capacity-and-item-ledger.bad.al).

## References

- [Item Jnl.-Post Line, InsertCapLedgEntry and OnAfterInitItemLedgEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Posting/ItemJnlPostLine.Codeunit.al).
- [Mfg. Item Jnl.-Post Line, output posting](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Inventory/Posting/MfgItemJnlPostLine.Codeunit.al).
