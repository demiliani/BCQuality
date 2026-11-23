---
bc-version: [all]
domain: sales-purchase
keywords: [archivemanagement, restoresalesdocument, sales-header-archive, sales-line-archive, onaftertransferfromarchtosalesheader, onaftertransferfromarchtosalesline, transferfields, default-values, tableextension]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Restoring an archived sales document revalidates custom fields

## Description

`ArchiveManagement` stores a sales document with `TransferFields` into `Sales Header Archive` and `Sales Line Archive`. A custom field with the same number on the archive tables is archived without any subscriber.

`RestoreSalesDocument` deletes the current document, inserts a new `Sales Header` and copies the archive back with `TransferFields`. It then validates `Sell-to Customer No.` or `Sell-to Contact No.`, the bill-to party, `Salesperson Code` and `Payment Terms Code`. Each line is copied back with `TransferFields`, inserted, and then `No.`, `Location Code`, `Quantity`, `Unit Price` and other standard fields are validated again.

Those validations run the master data defaults. A custom field that a subscriber defaults from the customer or the item is overwritten with today's master value, not the archived one. Only after the validations does the code raise `OnAfterTransferFromArchToSalesHeader` and `OnAfterTransferFromArchToSalesLine`, just before `Modify(true)`.

`ArchiveManagement` has no restore procedure for purchase documents.

## Best Practice

Mirror the field on `Sales Header Archive` and `Sales Line Archive` with the same number; see [mirror sales fields on every TransferFields target](mirror-sales-fields-on-every-transferfields-target.md). If the field is also defaulted from master data, as in [default sales and purchase fields from master data](default-sales-and-purchase-fields-from-master-data.md), subscribe to `OnAfterTransferFromArchToSalesHeader` and `OnAfterTransferFromArchToSalesLine` and assign the archived value again. The record is modified right after the event, so assign without `Modify`.

Test the restore with a customer or item whose default changed after the document was archived.

See sample: [`restore-archived-sales-document-revalidates-custom-fields.good.al`](restore-archived-sales-document-revalidates-custom-fields.good.al).

## Anti Pattern

Rely on the `TransferFields` copy alone for a field that is also defaulted on validation. The restore then silently replaces the archived value. Or reassign it in `OnAfterRestoreSalesDocument` by reading the lines and calling `Modify` on each: that adds a second write per line after the restore has already modified them.

See sample: [`restore-archived-sales-document-revalidates-custom-fields.bad.al`](restore-archived-sales-document-revalidates-custom-fields.bad.al).

## References

- [ArchiveManagement, StoreSalesDocument and RestoreSalesDocument](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Utilities/ArchiveManagement.Codeunit.al).
