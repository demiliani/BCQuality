---
bc-version: [all]
domain: finance-extensions
keywords: [suggest-vendor-payments, payment-journal, vendor-payment-buffer, vendor-ledger-entry, copyfieldsfromvendorledgerentry, copyfieldstogenjournalline, summarize-per-vendor, payment]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry vendor ledger fields to suggested payment lines through the payment buffer

## Description

`Suggest Vendor Payments` does not copy vendor ledger entries straight into the payment journal. For each entry it fills a temporary `Vendor Payment Buffer` with `CopyFieldsFromVendorLedgerEntry`, then creates one `Gen. Journal Line` per buffer row and copies the buffer to it with `CopyFieldsToGenJournalLine`. Both methods assign named fields one by one and end with an integration event on `Vendor Payment Buffer`: `OnAfterCopyFieldsFromVendorLedgerEntry(VendorLedgerEntrySource; var VendorPaymentBufferTarget)` and `OnAfterCopyFieldsToGenJournalLine(VendorPaymentBufferSource; var GenJournalLineTarget)`.

With **Summarize per Vendor**, entries are merged into one buffer row per primary key: `Vendor No.`, `Currency Code`, `Vendor Ledg. Entry No.` (set to 0), `Dimension Entry No.` and `Remit-to Code`. When the row already exists, `Find()` reloads it and only the amount is added. A custom field therefore keeps the value of the first entry in the group, and an extension cannot add it to the buffer's primary key.

## Best Practice

Add the field to `Vendor Payment Buffer` and `Gen. Journal Line`, then subscribe to both copy events. If the value differs per invoice, decide what it means on a summarized payment line: carry it only when **Summarize per Vendor** is off, or use a value that is constant per vendor. From the payment journal line, the field reaches the vendor and bank ledger entries through the standard journal-line events; see [carry Gen. Journal Line fields to G/L, VAT and bank entries](carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md) and [carry purchase fields to the vendor ledger](../sales-purchase/carry-purchase-fields-to-vendor-ledger-through-the-journal-line.md).

See sample: [`carry-vendor-ledger-fields-to-suggested-payment-lines.good.al`](carry-vendor-ledger-fields-to-suggested-payment-lines.good.al).

## Anti Pattern

Fill the field after the report runs, by finding the new journal lines and looking up "their" vendor ledger entry, or expect a per-invoice value on a summarized line. Summarized lines have no single source entry, and the lookup picks an arbitrary one.

See sample: [`carry-vendor-ledger-fields-to-suggested-payment-lines.bad.al`](carry-vendor-ledger-fields-to-suggested-payment-lines.bad.al).

## References

- [Suggest Vendor Payments, buffer filling and summarizing](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Payables/SuggestVendorPayments.Report.al).
- [Vendor Payment Buffer, key and copy events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Payables/VendorPaymentBuffer.Table.al).
