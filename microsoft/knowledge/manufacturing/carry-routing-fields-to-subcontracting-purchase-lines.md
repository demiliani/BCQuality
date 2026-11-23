---
bc-version: [all]
domain: manufacturing
keywords: [subcontracting, prod-order-routing-line, requisition-line, req-wksh-make-order, oninsertpurchorderlineonaftertransferfromreqlinetopurchline, subc-calculate-subcontracts, calculate-subcontracts, carry-out-action, purchase-line]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry routing fields to subcontracting purchase lines at the make-order step

## Description

A subcontracting purchase line is made in two steps. First a `Requisition Line` is built from a released `Prod. Order Routing Line` whose work center has a subcontractor. Then codeunit `Req. Wksh.-Make Order` turns the requisition line into a `Purchase Line`. Neither step copies records: each one assigns named fields.

The first step has more than one implementation:

- Base report 99001015 `Calculate Subcontracts` is marked obsolete (pending, tag 28.0). It will be replaced by report 20505 `Subc. Calculate Subcontracts` in the Microsoft Subcontracting app. Both reports raise `OnAfterTransferProdOrderRoutingLine` and `OnBeforeReqWkshLineInsert`. The base report's events are marked obsolete for 29.0.
- The Subcontracting app can also create the order straight from a routing line (`Subc. Purchase Order Creator`.`CreateSubcontractingPurchaseOrderFromRoutingLine`). It builds the requisition line in a local procedure that raises no event, then runs report `Carry Out Action Msg. - Req.`.

All paths end in `Req. Wksh.-Make Order`.`InsertPurchOrderLine`. `InitPurchOrderLine` sets the general fields. Then the base `Mfg. Requisition Line` codeunit handles `OnTransferFromReqLineToPurchLine` and calls `"Mfg. Purchase Line".TransferFromReqLineToPurchLine`. That sets `Routing No.`, `Routing Reference No.`, `Operation No.` and `Work Center No.`. Next comes `OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine(PurchOrderLine, RequisitionLine)`, and the line is inserted after `OnBeforePurchOrderLineInsert`.

## Best Practice

Copy routing or production order values at the make-order step, where every path meets. Subscribe to `OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine` on `Req. Wksh.-Make Order`. Exit unless `RequisitionLine."Prod. Order No."` and `"Operation No."` are filled, because the same code creates ordinary purchase lines.

Then read the routing line with `Get(Status::Released, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.")` from the requisition line, as `TransferFromReqLineToPurchLine` does. Set the purchase line field before the insert. The Subcontracting app uses the same event for its own price logic.

Add the field to `Requisition Line` too only if planners must see it in the worksheet. Fill it from `OnAfterTransferProdOrderRoutingLine` on the report your version uses, and remember the direct path does not fill it. Routing lines get their own fields from the master routing; see [copy routing line fields on the refresh and planning paths](copy-routing-line-fields-on-refresh-and-planning-paths.md).

See sample: [`carry-routing-fields-to-subcontracting-purchase-lines.good.al`](carry-routing-fields-to-subcontracting-purchase-lines.good.al).

## Anti Pattern

Put the value on the requisition line in `OnAfterTransferProdOrderRoutingLine` of base report `Calculate Subcontracts`, and copy it from there to the purchase line. The subscriber uses an event that is obsolete and goes away with the report. Orders created directly from a routing line in the Subcontracting app never pass through that report, so their purchase lines stay empty.

Patching purchase lines after `Carry Out Action` by searching on `Prod. Order No.` adds a write per line and misses orders made by other callers.

See sample: [`carry-routing-fields-to-subcontracting-purchase-lines.bad.al`](carry-routing-fields-to-subcontracting-purchase-lines.bad.al).

## References

- [Req. Wksh.-Make Order: InitPurchOrderLine, InsertPurchOrderLine and their events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Requisition/ReqWkshMakeOrder.Codeunit.al).
- [Mfg. Purchase Line: TransferFromReqLineToPurchLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Purchases/Document/MfgPurchaseLine.TableExt.al).
- [Calculate Subcontracts report (obsolete pending)](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Planning/CalculateSubcontracts.Report.al).
- [Subcontracting app: Subc. Calculate Subcontracts](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subcontracting/App/src/Purchase/SubcCalculateSubcontracts.Report.al).
- [Subcontracting app: Subc. Purchase Order Creator](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subcontracting/App/src/Purchase/SubcPurchaseOrderCreator.Codeunit.al).
