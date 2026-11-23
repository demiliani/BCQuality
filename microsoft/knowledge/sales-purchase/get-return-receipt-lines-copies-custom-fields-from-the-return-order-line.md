---
bc-version: [all]
domain: sales-purchase
keywords: [return-receipt-line, return-shipment-line, insertinvlinefromretrcptline, insertinvlinefromretshptline, onaftercopyfieldsfromreturnreceiptline, onaftercopyfieldsfromreturnshipmentline, get-return-receipt-lines, sales-cr-memo, purchase-cr-memo]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Get Return Receipt Lines copies custom fields from the return order line

## Description

Posting a return order with receive only creates a `Return Receipt Line`; for purchases, ship only creates a `Return Shipment Line`. Those posted lines get custom fields by `TransferFields`, as [mirror sales fields on every TransferFields target](mirror-sales-fields-on-every-transferfields-target.md) explains. The credit memo is created later with `Get Return Receipt Lines` (`Sales-Get Return Receipts`) or `Get Return Shipment Lines` (`Purch.-Get Return Shipments`).

That second step does not copy from the posted line. `InsertInvLineFromRetRcptLine` on `Return Receipt Line` reads the open return order line with `Get` and assigns it to the new credit memo line. It then sets a fixed list of fields from the posted line, such as `Variant Code`, `Location Code` and `Return Reason Code`, and resets the quantities. `InsertInvLineFromRetShptLine` on `Return Shipment Line` does the same for purchases.

So a custom field on the credit memo line carries the current value of the return order line. A value written only to the posted receipt line, for example during posting, is not copied. A value changed on the return order after the receipt also reaches the credit memo. If the return order line no longer exists, the routine raises an error for a normal line.

Each routine raises an event after its fixed field list and before the quantity is validated and the line is inserted: `OnAfterCopyFieldsFromReturnReceiptLine(var ReturnReceiptLine; var SalesLine)` on `Return Receipt Line`, and `OnAfterCopyFieldsFromReturnShipmentLine(var ReturnShipmentLine; var PurchaseLine)` on `Return Shipment Line`.

## Best Practice

Decide which value the credit memo must carry. When it must be the received or shipped value, mirror the field on the posted return line and copy it in the event: assign it from the posted line to the new line, without `Modify`. When it should follow the return order line, no subscriber is needed.

Test a return order that is received in two parts and invoiced through `Get Return Receipt Lines`, and change the field on the return order between the receipts.

Lines copied with `Get Posted Document Lines to Reverse` or Copy Document take another path; see [Copy Document drops custom line fields when it recalculates lines](copy-document-recalculate-lines-drops-custom-line-fields.md).

See sample: [`get-return-receipt-lines-copies-custom-fields-from-the-return-order-line.good.al`](get-return-receipt-lines-copies-custom-fields-from-the-return-order-line.good.al).

## Anti Pattern

Mirror the field on `Return Receipt Line`, test the posted receipt, and assume the credit memo line is filled from it. Then patch the credit memo line in a subscriber to `OnAfterInsertEvent` with `Modify`, which adds a write and still misses the purchase side.

See sample: [`get-return-receipt-lines-copies-custom-fields-from-the-return-order-line.bad.al`](get-return-receipt-lines-copies-custom-fields-from-the-return-order-line.bad.al).

## References

- [Return Receipt Line, InsertInvLineFromRetRcptLine and its events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/History/ReturnReceiptLine.Table.al).
- [Return Shipment Line, InsertInvLineFromRetShptLine and its events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/History/ReturnShipmentLine.Table.al).
- [Sales-Get Return Receipts, CreateInvLines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesGetReturnReceipts.Codeunit.al).
- [Purch.-Get Return Shipments](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/PurchGetReturnShipments.Codeunit.al).
