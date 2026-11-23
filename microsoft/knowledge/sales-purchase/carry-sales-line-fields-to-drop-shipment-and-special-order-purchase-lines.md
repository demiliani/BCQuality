---
bc-version: [all]
domain: sales-purchase
keywords: [drop-shipment, special-order, purch-get-drop-shpt, dist-integration, transfldsfromsalestopurchline, onaftertransfldsfromsalestopurchline, requisition-line, req-wksh-make-order, onafterinsertreqwkshline, onafterinitpurchorderline]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry sales line fields to drop shipment and special order purchase lines

## Description

A purchase line linked to a sales line for a drop shipment or a special order is never created with `TransferFields`. There are two routes, and they copy different things.

From the purchase order, `Get Sales Order` runs `Purch.-Get Drop Shpt.` and `Get Special Order` runs `GetSpecialOrders` in `Dist. Integration`. Both call `TransfldsFromSalesToPurchLine` on `Copy Document Mgt.`. Despite its name, that method validates a short list of fields one by one: type, number, variant, location, unit of measure, quantity, descriptions and dimensions. It ends with `OnAfterTransfldsFromSalesToPurchLine`, raised before the purchase line is inserted.

From the requisition worksheet, the `Get Sales Orders` report creates `Requisition Line` records from the sales lines, and `Req. Wksh.-Make Order` later creates the purchase lines from those requisition lines. This route never calls `TransfldsFromSalesToPurchLine`, and the purchase line sees only the requisition line, not the sales line. The `Create Purchase Order` action on a sales order (`Purch. Doc. From Sales Doc.`) also builds requisition lines, but not with `Get Sales Orders`; if users rely on it, test that path separately.

## Best Practice

For the purchase order route, subscribe to `OnAfterTransfldsFromSalesToPurchLine` and copy the value from `FromSalesLine` to `ToPurchaseLine`. One subscriber covers both drop shipments and special orders.

For the requisition route, add the field to `Requisition Line`. Copy it from the sales line in `OnBeforeInsertReqWkshLine` on the `Get Sales Orders` report, then from the requisition line to the purchase line in `OnAfterInitPurchOrderLine` on `Req. Wksh.-Make Order`. Both events run before the insert, so assign without `Modify`.

Test both routes, for a drop shipment and for a special order.

See sample: [`carry-sales-line-fields-to-drop-shipment-and-special-order-purchase-lines.good.al`](carry-sales-line-fields-to-drop-shipment-and-special-order-purchase-lines.good.al).

## Anti Pattern

Give `Purchase Line` a field with the same number as on `Sales Line` and expect it to be copied. Or subscribe only to `OnAfterPurchaseLineInsert` on `Purch.-Get Drop Shpt.` and `Modify` the line. The first copies nothing. The second covers only one of the routes and adds a write per line.

See sample: [`carry-sales-line-fields-to-drop-shipment-and-special-order-purchase-lines.bad.al`](carry-sales-line-fields-to-drop-shipment-and-special-order-purchase-lines.bad.al).

## References

- [Copy Document Mgt., TransfldsFromSalesToPurchLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Utilities/CopyDocumentMgt.Codeunit.al).
- [Purch.-Get Drop Shpt.](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/PurchGetDropShpt.Codeunit.al).
- [Dist. Integration, GetSpecialOrders](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/DistIntegration.Codeunit.al).
- [Get Sales Orders report, InsertReqWkshLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/GetSalesOrders.Report.al).
- [Req. Wksh.-Make Order, InitPurchOrderLine and InsertPurchOrderLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Requisition/ReqWkshMakeOrder.Codeunit.al).
- [Purch. Doc. From Sales Doc., CreatePurchaseOrder](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/PurchDocFromSalesDoc.Codeunit.al).
