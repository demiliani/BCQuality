---
bc-version: [all]
domain: warehouse
keywords: [transfer-header, transfer-line, transfer-shipment-header, transfer-receipt-header, direct-trans-header, copyfromtransferheader, copyfromtransferline, onaftercopyfromtransferheader, tableextension, field-number]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Posted transfer documents copy fields one by one, not by field number

## Description

Sales and purchase posting create posted documents with `TransferFields`, so a custom field with the same number on the posted table is copied automatically. Transfer posting works differently. `TransferOrder-Post Shipment` fills `Transfer Shipment Header` with `CopyFromTransferHeader` and `Transfer Shipment Line` with `CopyFromTransferLine`; `TransferOrder-Post Receipt` does the same for `Transfer Receipt Header` and `Transfer Receipt Line`. These methods assign named fields one by one, so a custom field never reaches the posted transfer even when it has the same number.

Each method ends with an integration event raised before the record is inserted: `OnAfterCopyFromTransferHeader` on both posted header tables and `OnAfterCopyFromTransferLine` on both posted line tables. Direct transfers posted by `TransferOrder-Post Transfer` follow the same rule: `Direct Trans. Line` uses `CopyFromTransferLine` with `OnAfterCopyFromTransferLine`, and `Direct Trans. Header` is filled field by field, with `OnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert` raised before its insert.

## Best Practice

Add the field to each posted transfer table the plan needs, then copy it in a subscriber to the table's own copy event: `OnAfterCopyFromTransferHeader` on `Transfer Shipment Header` and on `Transfer Receipt Header`, and `OnAfterCopyFromTransferLine` on `Transfer Shipment Line` and `Transfer Receipt Line`. When direct transfers are in scope, also subscribe to `OnAfterCopyFromTransferLine` on `Direct Trans. Line` and to `OnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert` on `TransferOrder-Post Transfer`.

The record is not inserted yet when these events run, so assign the field without `Modify`. Do not reuse a sales or purchase design that relies on matching field numbers: on transfers it compiles and silently leaves the posted field blank. Posting itself must still go through the transfer codeunits; see [post transfers through shipment and receipt codeunits](../scm/post-transfers-through-shipment-and-receipt-codeunits.md).

See sample: [`posted-transfer-documents-copy-fields-one-by-one.good.al`](posted-transfer-documents-copy-fields-one-by-one.good.al).

## Anti Pattern

Give the posted transfer tables a field with the same number as on `Transfer Header` and expect it to be filled, as it would be on sales documents. Or patch the posted header after posting with `Modify` from `OnAfterTransferOrderPostShipment`. The first leaves the field empty with no error; the second adds a write after the posting has been committed.

See sample: [`posted-transfer-documents-copy-fields-one-by-one.bad.al`](posted-transfer-documents-copy-fields-one-by-one.bad.al).

## References

- [TransferOrder-Post Shipment, posted header and lines built with CopyFrom methods](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Transfer/TransferOrderPostShipment.Codeunit.al).
- [Transfer Shipment Header, CopyFromTransferHeader and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Transfer/TransferShipmentHeader.Table.al).
- [TransferOrder-Post Receipt, posted header and lines built with CopyFrom methods](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Transfer/TransferOrderPostReceipt.Codeunit.al).
- [TransferOrder-Post Transfer, direct transfer header and lines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Transfer/TransferOrderPostTransfer.Codeunit.al).
