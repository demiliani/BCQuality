---
bc-version: [all]
domain: sales-purchase
keywords: [vendor-ledger-entry, gen-journal-line, copyfrompurchheader, onaftercopygenjnllinefrompurchheader, onaftercopyvendledgerentryfromgenjnlline, onaftercopyitemjnllinefrompurchline, purch-post-invoice, item-journal-line]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry purchase fields to the vendor ledger through the journal line

## Description

Purchase posting does not create `Vendor Ledger Entry` from `Purchase Header` directly. `Purch. Post Invoice` builds a `Gen. Journal Line` with `CopyFromPurchHeader`, and `Gen. Jnl.-Post Line` initializes the vendor entry from that journal line with `CopyFromGenJnlLine`. Both methods assign named fields one by one and end with an integration event: `OnAfterCopyGenJnlLineFromPurchHeader` on `Gen. Journal Line` and `OnAfterCopyVendLedgerEntryFromGenJnlLine` on `Vendor Ledger Entry`.

Item lines follow the same shape. `Purch.-Post` builds an `Item Journal Line` with `CopyFromPurchLine`, which ends with `OnAfterCopyItemJnlLineFromPurchLine`, and `Item Jnl.-Post Line` raises `OnAfterInitItemLedgEntry` before inserting the item ledger entry.

## Best Practice

Add the field to `Gen. Journal Line` and `Vendor Ledger Entry`, then subscribe to both events: copy from the purchase header to the journal line, then from the journal line to the vendor entry while it is initialized. For a purchase line field that must reach the item ledger, add it to `Item Journal Line` and `Item Ledger Entry` and use `OnAfterCopyItemJnlLineFromPurchLine` and `OnAfterInitItemLedgEntry`. That second subscriber is shared with sales; see [carry sales line fields to the item ledger](carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md).

The value is then part of the posting itself, with no extra write. Store the field on the ledger entry only when users must see or filter it as a native list column, or it is read on almost every access. For optional or integration-only attributes, prefer a related table keyed by the entry number; see [prefer a related table over stored fields on hot ledgers](../performance/prefer-related-table-over-extension-on-hot-ledgers.md). Sales documents follow the same shape; see [carry sales fields to the customer ledger](carry-sales-fields-to-customer-ledger-through-the-journal-line.md).

See sample: [`carry-purchase-fields-to-vendor-ledger-through-the-journal-line.good.al`](carry-purchase-fields-to-vendor-ledger-through-the-journal-line.good.al).

## Anti Pattern

Subscribe to `OnAfterPostPurchaseDoc`, find the vendor entry by document number and `Modify` it. The subscriber runs after the posting commit, so a failure leaves the posted entry without the value, and it edits a posted ledger entry outside the posting engine; see [do not modify or delete posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md).

See sample: [`carry-purchase-fields-to-vendor-ledger-through-the-journal-line.bad.al`](carry-purchase-fields-to-vendor-ledger-through-the-journal-line.bad.al).

## References

- [Purch. Post Invoice, vendor journal line built with CopyFromPurchHeader](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Posting/PurchPostInvoice.Codeunit.al).
- [Vendor Ledger Entry, CopyFromGenJnlLine and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Payables/VendorLedgerEntry.Table.al).
- [Item Journal Line, CopyFromPurchLine and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Journal/ItemJournalLine.Table.al).
