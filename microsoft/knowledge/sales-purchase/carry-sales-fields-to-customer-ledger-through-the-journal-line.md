---
bc-version: [all]
domain: sales-purchase
keywords: [cust-ledger-entry, gen-journal-line, copyfromsalesheader, onaftercopygenjnllinefromsalesheader, onaftercopycustledgerentryfromgenjnlline, onaftercopyglentryfromgenjnlline, sales-post-invoice, g-l-entry]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry sales fields to the customer ledger through the journal line

## Description

Sales posting does not create `Cust. Ledger Entry` from `Sales Header` directly. `Sales Post Invoice` builds a `Gen. Journal Line` with `CopyFromSalesHeader`, and `Gen. Jnl.-Post Line` creates the customer entry from that journal line with `CopyFromGenJnlLine`. Both copy methods assign named fields one by one, so a custom field is not carried unless an extension copies it.

Each copy method ends with an integration event: `OnAfterCopyGenJnlLineFromSalesHeader` on `Gen. Journal Line` and `OnAfterCopyCustLedgerEntryFromGenJnlLine` on `Cust. Ledger Entry`. These are the supported places to carry the value.

## Best Practice

Add the field to `Gen. Journal Line` and `Cust. Ledger Entry`, then subscribe to both events. The first copies the value from the sales header to the journal line. The second copies it from the journal line to the customer entry while it is being initialized, before it is inserted. The value is then part of the posting itself, with no extra write. Store the field on the ledger entry only when users must see or filter it as a native list column, or it is read on almost every access. For optional or integration-only attributes, prefer a related table keyed by the entry number; see [prefer a related table over stored fields on hot ledgers](../performance/prefer-related-table-over-extension-on-hot-ledgers.md).

The journal-line field also lets the value reach other entries built from the same line. For example, `OnAfterCopyGLEntryFromGenJnlLine` on `G/L Entry` can copy it to the G/L entries, if the plan needs it there. Purchase posting follows the same shape with `CopyFromPurchHeader` and `Vendor Ledger Entry`.

See sample: [`carry-sales-fields-to-customer-ledger-through-the-journal-line.good.al`](carry-sales-fields-to-customer-ledger-through-the-journal-line.good.al).

## Anti Pattern

Subscribe to `OnAfterPostSalesDoc`, find the customer entry by document number and `Modify` it. That subscriber runs after the posting commit, so a failure leaves posted entries without the value. It also edits a posted ledger entry outside the posting engine; see [do not modify or delete posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md).

See sample: [`carry-sales-fields-to-customer-ledger-through-the-journal-line.bad.al`](carry-sales-fields-to-customer-ledger-through-the-journal-line.bad.al).

## References

- [Gen. Journal Line, CopyFromSalesHeader and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al).
- [Cust. Ledger Entry, CopyFromGenJnlLine and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Receivables/CustLedgerEntry.Table.al).
- [Gen. Jnl.-Post Line, InitCustLedgEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al).
