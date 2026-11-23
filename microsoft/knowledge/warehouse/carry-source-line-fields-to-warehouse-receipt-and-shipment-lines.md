---
bc-version: [all]
domain: warehouse
keywords: [warehouse-receipt-line, warehouse-shipment-line, sales-warehouse-mgt, purchases-warehouse-mgt, onbeforecreateshptlinefromsalesline, onpurchline2receiptlineonafterupdatereceiptline, whse-create-source-document, warehouse]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry source line fields to warehouse receipt and shipment lines

## Description

When a user creates a warehouse shipment or receipt from a source document, the warehouse line is built field by field, not with `TransferFields`. `"Sales Warehouse Mgt."` builds a `Warehouse Shipment Line` from a `Sales Line`, and `"Purchases Warehouse Mgt."` builds a `Warehouse Receipt Line` from a `Purchase Line`. Both then call `"Whse. Create Source Document"` to insert the line. A custom field on the source line therefore does not reach the warehouse line unless an extension copies it.

Each source type raises its own events, with different naming styles. The insert events in `"Whse. Create Source Document"`, such as `OnBeforeWhseShptLineInsert`, receive only the warehouse line, not the source line.

## Best Practice

Add the field to the warehouse line with the same number and type as on the source line, and copy it in the source-specific event that runs just before the insert:

- Sales line to shipment line: `OnBeforeCreateShptLineFromSalesLine` on `"Sales Warehouse Mgt."`, which passes the shipment line by `var` and the sales line.
- Purchase line to receipt line: `OnPurchLine2ReceiptLineOnAfterUpdateReceiptLine` on `"Purchases Warehouse Mgt."`, which passes the receipt line by `var` and the purchase line.

Other sources, such as sales return orders, purchase return orders and transfers, build their warehouse lines in their own codeunits and raise their own events. Plan one subscriber per source type the feature needs, and confirm each event in the target version's symbols. Keeping the same field number lets the next hop, from warehouse line to posted warehouse line, copy the value by `TransferFields`; see [carry warehouse document fields to posted warehouse documents](carry-warehouse-document-fields-to-posted-warehouse-documents.md).

See sample: [`carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.good.al`](carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.good.al).

## Anti Pattern

Copy the value in `OnAfterCreateShptLineFromSalesLine` or `OnAfterCreateRcptLineFromPurchLine` and call `Modify`. Those events run after the line is inserted, so every warehouse line costs an extra write. Alternatively, subscribe to `OnBeforeWhseShptLineInsert` and read the source line again from the warehouse line's source fields, which adds a database read per line for data the source-specific event already passes.

See sample: [`carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.bad.al`](carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.bad.al).

## References

- [Sales Warehouse Mgt., FromSalesLine2ShptLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesWarehouseMgt.Codeunit.al).
- [Purchases Warehouse Mgt., PurchLine2ReceiptLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/PurchasesWarehouseMgt.Codeunit.al).
- [Whse. Create Source Document, line insert](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Request/WhseCreateSourceDocument.Codeunit.al).
