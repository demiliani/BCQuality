---
bc-version: [all]
domain: sales-purchase
keywords: [invoice-posting-buffer, g-l-entry, buildprimarykey, onafterbuildprimarykey, onpreparelineonafterfillinvoicepostingbuffer, onaftercopytogenjnlline, sales-post-invoice-events, purch-post-invoice-events, group-id]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry sales and purchase line fields to G/L entries through the Invoice Posting Buffer

## Description

Sales and purchase lines do not become G/L entries one by one. `Sales Post Invoice` and `Purch. Post Invoice` fill a temporary `Invoice Posting Buffer` per line and merge lines that share the same `Group ID`, built by `BuildPrimaryKey` from accounts, posting groups, dimensions and similar fields. When a line joins an existing group, the buffer adds up the amounts and keeps the other fields of the first line in the group. Each group then becomes one `Gen. Journal Line` through `CopyToGenJnlLine`, which ends with `OnAfterCopyToGenJnlLine`, and then a G/L entry.

A custom line field therefore reaches G/L only if it is copied into the buffer and, when lines with different values must stay separate, made part of the `Group ID`. The fill event is published by `Sales Post Invoice Events` (codeunit 825) and `Purch. Post Invoice Events` (codeunit 826), both as `OnPrepareLineOnAfterFillInvoicePostingBuffer`. The purchase event adds `TempInvoicePostingBuffer`, the line counters and `var IsHandled`; setting `IsHandled` skips the standard buffer update for that line.

## Best Practice

Add the field to `Invoice Posting Buffer`, `Gen. Journal Line` and `G/L Entry`. Then subscribe to:

1. `OnPrepareLineOnAfterFillInvoicePostingBuffer` on the events codeunit of each side, to copy the line value into the buffer. Leave `IsHandled` untouched on the purchase event.
2. `OnAfterBuildPrimaryKey` on `Invoice Posting Buffer`, to add the field to `Group ID` when lines with different values must post separately. `Group ID` is `Text[1000]`; pad the value with `PadField` as the standard key does.
3. `OnAfterCopyToGenJnlLine` on `Invoice Posting Buffer`, to copy the value to the journal line, and `OnAfterCopyGLEntryFromGenJnlLine` on `G/L Entry`, to copy it to the entry.

Extending `G/L Entry` has a cost; see [prefer a related table over stored fields on hot ledgers](../performance/prefer-related-table-over-extension-on-hot-ledgers.md).

See sample: [`carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.good.al`](carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.good.al).

## Anti Pattern

Copy the field into the buffer but leave it out of `Group ID`. Two lines with the same account and posting groups but different values merge into one G/L entry that carries only the first line's value. Subscribing to `OnPrepareLineOnAfterFillInvoicePostingBuffer` on codeunit `"Sales Post Invoice"`, as older examples on Microsoft Learn show, also fails: the event is published by `"Sales Post Invoice Events"`.

See sample: [`carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.bad.al`](carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.bad.al).

## References

- [Invoice Posting Buffer, BuildPrimaryKey, Update and CopyToGenJnlLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/ReceivablesPayables/InvoicePostingBuffer.Table.al).
- [Sales Post Invoice Events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPostInvoiceEvents.Codeunit.al).
- [Purch. Post Invoice Events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Posting/PurchPostInvoiceEvents.Codeunit.al).
- [Extending G/L entry aggregations when posting invoices](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-invoice-posting-example). Its publisher codeunit and setup step predate the current source.
