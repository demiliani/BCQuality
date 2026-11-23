---
bc-version: [all]
domain: sales-purchase
keywords: [transferfields, tableextension, sales-header, sales-invoice-header, sales-shipment-header, sales-cr-memo-header, return-receipt-header, sales-header-archive, initfromsalesline, field-number]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Mirror custom sales fields on every TransferFields target

## Description

Sales posting creates posted headers with `TransferFields(SalesHeader, true, true)` into `Sales Shipment Header`, `Sales Invoice Header`, `Sales Cr.Memo Header` and `Return Receipt Header`. Archiving does the same into `Sales Header Archive`. Posted lines are created by `InitFromSalesLine`, which calls `TransferFields(SalesLine)` on `Sales Shipment Line`, `Sales Invoice Line`, `Sales Cr.Memo Line` and `Return Receipt Line`. Archiving copies lines into `Sales Line Archive` the same way.

`TransferFields` matches fields by number. A table extension field reaches a target only if the target has a field with the same number and a compatible type. A different number is skipped without any error.

## Best Practice

Give the custom field the same field number, name, type and length on the source table and on every target table the plan needs. For a header field that means all four posted header tables and the archive, unless the plan states that a document type never needs it. For a line field, do the same on the line tables. Type and length must match, as [TransferFields mirrored fields must match type and length](../data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md) explains.

No subscriber is needed for these stages; the standard `TransferFields` call does the copy. Keep the mirrored fields non-editable on the posted tables.

See sample: [`mirror-sales-fields-on-every-transferfields-target.good.al`](mirror-sales-fields-on-every-transferfields-target.good.al).

## Anti Pattern

Add the field only to `Sales Header` and `Sales Invoice Header`, or use a different field number on the posted table. Then write an `OnAfter...Insert` subscriber that copies the value and calls `Modify`. The subscriber adds a write per posted document, misses the other posted and archive tables, and hides the real cause: the field numbers do not match.

See sample: [`mirror-sales-fields-on-every-transferfields-target.bad.al`](mirror-sales-fields-on-every-transferfields-target.bad.al).

## References

- [Sales-Post, posted headers created with TransferFields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al).
- [Sales Invoice Line, InitFromSalesLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/History/SalesInvoiceLine.Table.al).
- [ArchiveManagement, header and line archive with TransferFields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Utilities/ArchiveManagement.Codeunit.al).
- [Record.TransferFields method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-table-boolean-boolean-method).
