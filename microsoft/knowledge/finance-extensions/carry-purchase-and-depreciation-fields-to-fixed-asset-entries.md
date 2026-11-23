---
bc-version: [all]
domain: finance-extensions
keywords: [fixed-asset, acquisition-cost, purchase-line, invoice-posting-buffer, copytogenjnllinefa, calculate-depreciation, onbeforefajnllineinsert, onbeforegenjnllineinsert, fa-ledger-entry]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry purchase and depreciation fields to fixed asset entries

## Description

A purchase line of type Fixed Asset never posts through an FA journal. `Purch. Post Invoice` collects it in `Invoice Posting Buffer` with buffer type Fixed Asset, builds a `Gen. Journal Line` with `CopyFromPurchHeader`, `CopyToGenJnlLine` and then `CopyToGenJnlLineFA`, and posts it. `Gen. Jnl.-Post Line` hands the line to `FA Jnl.-Post Line`, which builds the FA ledger entry in `Make FA Ledger Entry`.`CopyFromGenJnlLine`. A custom purchase field therefore crosses three hops: purchase line to buffer, buffer or header to journal line, journal line to FA ledger entry.

Depreciation follows yet another path. Report `Calculate Depreciation` writes FA journal lines when the depreciation book does not integrate depreciation with G/L, and general journal lines when it does. It raises `OnBeforeFAJnlLineInsert(var TempFAJournalLine; var FAJournalLine)` and `OnBeforeGenJnlLineInsert(var TempGenJournalLine; var GenJournalLine)` just before each insert.

## Best Practice

For a purchase line field, put it in the buffer as [carry sales and purchase line fields to G/L through the Invoice Posting Buffer](../sales-purchase/carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.md) describes, including its grouping key when values may differ per line. Copy it from buffer to journal line in `OnAfterCopyToGenJnlLine` or `OnAfterCopyToGenJnlLineFA` on `Invoice Posting Buffer`. For a header field, use `OnAfterCopyGenJnlLineFromPurchHeader`. The last hop is the `OnAfterCopyFromGenJnlLine` subscriber on `Make FA Ledger Entry`; see [carry custom fields to FA ledger entries](carry-fields-to-fa-ledger-entries-from-fa-and-gen-journal-lines.md).

For a value that depreciation lines must carry, set it in both `OnBeforeFAJnlLineInsert` and `OnBeforeGenJnlLineInsert` of `Calculate Depreciation`, so it does not depend on the book's G/L integration.

See sample: [`carry-purchase-and-depreciation-fields-to-fixed-asset-entries.good.al`](carry-purchase-and-depreciation-fields-to-fixed-asset-entries.good.al).

## Anti Pattern

Expect a purchase line field to reach the FA ledger because it has the same field number on `FA Ledger Entry`: no hop on this path uses `TransferFields` from the purchase line. Or handle only one of the two depreciation insert events, so the value depends on a setup flag.

See sample: [`carry-purchase-and-depreciation-fields-to-fixed-asset-entries.bad.al`](carry-purchase-and-depreciation-fields-to-fixed-asset-entries.bad.al).

## References

- [Purch. Post Invoice, PrepareGenJnlLine for fixed asset buffer lines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Posting/PurchPostInvoice.Codeunit.al).
- [Invoice Posting Buffer, CopyToGenJnlLineFA and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/ReceivablesPayables/InvoicePostingBuffer.Table.al).
- [Gen. Jnl.-Post Line, PostFixedAsset](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al).
- [Calculate Depreciation report](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/FixedAssets/Depreciation/CalculateDepreciation.Report.al).
