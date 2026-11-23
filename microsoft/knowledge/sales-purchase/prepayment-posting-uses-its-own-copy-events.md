---
bc-version: [all]
domain: sales-purchase
keywords: [sales-post-prepayments, prepayment-inv-line-buffer, onaftercopygenjnllinefromsalesheaderprepmtpost, onaftercopygenjnllinefromprepmtinvbuffer, onaftercopyfromsalesline, onbeforesalesinvlineinsert, compress-prepayment, gen-journal-line, cust-ledger-entry, prepayment]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Prepayment posting uses its own copy events

## Description

Prepayment invoices and credit memos are posted by `Sales-Post Prepayments` and `Purchase-Post Prepayments`, not by `Sales-Post` or `Purch.-Post`. The posted header is still created with `TransferFields` from the order header, so a mirrored header field reaches `Sales Invoice Header` or `Purch. Inv. Header`.

Everything else is built differently. The posted prepayment lines are not copied from the order lines. Each order line is first summarized into a `Prepayment Inv. Line Buffer` record, and the posted line is filled field by field from that buffer. The journal lines use other copy methods: `CopyFromSalesHeaderPrepmtPost` for the customer entry, and `CopyFromSalesHeaderPrepmt` with `CopyFromPrepmtInvoiceBuffer` for the G/L lines. `CopyFromSalesHeader` is never called, so a subscriber to `OnAfterCopyGenJnlLineFromSalesHeader` does not run for prepayments.

`Compress Prepayment` is on by default on `Sales Header`. When it is on, the buffer gets no line number, so order lines that share the buffer key, such as the prepayment account and dimensions, become one posted line. Before the G/L lines are posted, the buffer is compressed in every case: `CompressBuffer` sets the line number to zero and merges the records. A per-line value therefore never has a single owner on the prepayment G/L entries.

## Best Practice

For a header field on the customer entry, add a subscriber to `OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost` on `Gen. Journal Line`, next to the one for normal invoices. The existing `OnAfterCopyCustLedgerEntryFromGenJnlLine` subscriber then carries it on; see [carry sales fields to the customer ledger](carry-sales-fields-to-customer-ledger-through-the-journal-line.md). Purchases use `OnAfterCopyGenJnlLineFromPurchHeaderPrepmtPost`. If the header value must also reach the prepayment G/L entries, subscribe to `OnAfterCopyGenJnlLineFromSalesHeaderPrepmt` or `OnAfterCopyGenJnlLineFromPurchHeaderPrepmt` as well.

For a line field on the posted prepayment line, add it to `Prepayment Inv. Line Buffer` and copy it in `OnAfterCopyFromSalesLine` or `OnAfterCopyFromPurchLine` on that table. Carry it to the posted line in `OnBeforeSalesInvLineInsert` or `OnBeforeSalesCrMemoLineInsert` on `Sales-Post Prepayments`. This only works with `Compress Prepayment` off; state that in the design or define the value for merged lines. A value that must reach the prepayment G/L entries per line belongs in a dimension, because the dimension set is part of the buffer key.

Include a prepayment order in the tests whenever the feature touches posted invoices or ledger entries.

See sample: [`prepayment-posting-uses-its-own-copy-events.good.al`](prepayment-posting-uses-its-own-copy-events.good.al).

## Anti Pattern

Reuse the normal invoice subscribers and assume they cover prepayments. The prepayment customer entry and G/L entries stay blank, and no error shows it. Or read the order line in `OnBeforeSalesInvLineInsert` by the buffer's line number: with compressed prepayments that number is zero. Or copy a line field to the G/L lines in `OnAfterCopyGenJnlLineFromPrepmtInvBuffer` and expect one value per order line: the buffer was merged before that point.

See sample: [`prepayment-posting-uses-its-own-copy-events.bad.al`](prepayment-posting-uses-its-own-copy-events.bad.al).

## References

- [Sales-Post Prepayments, buffer, posted lines and journal lines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPostPrepayments.Codeunit.al).
- [Purchase-Post Prepayments](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Posting/PurchasePostPrepayments.Codeunit.al).
- [Prepayment Inv. Line Buffer, CopyFromSalesLine and its key](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/ReceivablesPayables/PrepaymentInvLineBuffer.Table.al).
- [Gen. Journal Line, prepayment copy methods and events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al).
