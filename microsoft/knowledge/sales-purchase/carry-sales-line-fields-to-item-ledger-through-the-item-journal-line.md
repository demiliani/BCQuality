---
bc-version: [all]
domain: sales-purchase
keywords: [item-ledger-entry, item-journal-line, copyfromsalesline, onaftercopyitemjnllinefromsalesline, onafterinititemledgentry, item-jnl-post-line, sales-line]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry sales line fields to the item ledger through the item journal line

## Description

When a sales line with an item is shipped or invoiced, `Sales-Post` builds an `Item Journal Line` with `CopyFromSalesHeader` and `CopyFromSalesLine`. `Item Jnl.-Post Line` then initializes the `Item Ledger Entry` from that journal line. The copy methods assign named fields one by one, so a custom sales line field does not reach the item ledger unless an extension carries it.

Two integration events cover the path. `OnAfterCopyItemJnlLineFromSalesLine` on `Item Journal Line` runs after the line copy. `OnAfterInitItemLedgEntry` on `Item Jnl.-Post Line` runs after the item ledger entry is initialized and before it is inserted.

## Best Practice

Add the field to `Item Journal Line` and `Item Ledger Entry`, then subscribe to both events. Copy the value from the sales line to the journal line in the first, and from the journal line to the new item ledger entry in the second. The value is then written as part of the posting. Store the field on the ledger entry only when users must see or filter it as a native list column, or it is read on almost every access. For optional or integration-only attributes, prefer a related table keyed by the entry number; see [prefer a related table over stored fields on hot ledgers](../performance/prefer-related-table-over-extension-on-hot-ledgers.md).

Purchase lines reach the same item ledger subscriber through `OnAfterCopyItemJnlLineFromPurchLine`; see [carry purchase fields to the vendor ledger](carry-purchase-fields-to-vendor-ledger-through-the-journal-line.md). Item journals posted directly, and other documents that post item lines, reach the same `OnAfterInitItemLedgEntry` subscriber. Their journal lines leave the field empty, so the entry stays empty too; no filter on the source document is needed unless the plan says otherwise. Value entries, warehouse entries and other inventory records are separate stages; extend them only when the plan names them. Inventory postings must still go through item journals; see [post item ledger changes through item journals](../scm/post-item-ledger-changes-through-item-journals.md).

See sample: [`carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.good.al`](carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.good.al).

## Anti Pattern

Find the item ledger entries after posting by document number and `Modify` them, or copy the value only to the posted sales lines and expect it to appear in the item ledger. Neither puts the value on the entry when it is created, and the first edits a posted entry outside the posting engine.

See sample: [`carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.bad.al`](carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.bad.al).

## References

- [Sales-Post, item journal line built from the sales line](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al).
- [Item Journal Line, CopyFromSalesLine and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Journal/ItemJournalLine.Table.al).
- [Item Jnl.-Post Line, OnAfterInitItemLedgEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Posting/ItemJnlPostLine.Codeunit.al).
