---
bc-version: [all]
domain: inventory
keywords: [requisition-line, inventory-profile, calculate-plan, order-planning, req-wksh-make-order, carry-out-action, onmaintainplanninglineonbeforereqlineinsert, onaftertransferfromunplanneddemand, onafterinitpurchorderline, oninsertprodorderlinewithreqline]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry demand fields through planning lines to supply orders

## Description

A purchase or production order created by carry-out sees only the `Requisition Line`. It never reads the sales line that caused the demand. Each hop copies named fields, so a custom sales line field reaches the supply order only if an extension copies it at every hop.

How the requisition line is filled depends on the route:

- Calculate Plan (planning worksheet or requisition worksheet). The planning engine `Inventory Profile Offsetting` reads demand into `Inventory Profile` records. For sales lines this is `Sales Line Invt. Profile.TransferInventoryProfileFromSalesLine`, which ends with `OnAfterTransferInventoryProfileFromSalesLine`. `MaintainPlanningLine` then creates the requisition line from the supply profile and raises `OnMaintainPlanningLineOnBeforeReqLineInsert`, passing `DemandInvtProfile`. The engine does not fill `Demand Order No.` on these lines.
- Order Planning. `Order Planning Mgt.` builds `Unplanned Demand` records and calls `Requisition Line.TransferFromUnplannedDemand`. This sets `Demand Type`, `Demand Subtype`, `Demand Order No.` and `Demand Line No.`, then raises `OnAfterTransferFromUnplannedDemand`.
- Get Sales Orders for drop shipments and special orders. See [carry sales line fields to drop shipment and special order purchase lines](../sales-purchase/carry-sales-line-fields-to-drop-shipment-and-special-order-purchase-lines.md).

Carry-out then builds the supply order from the requisition line:

- Purchase. `Req. Wksh.-Make Order` (codeunit 333) runs `InitPurchOrderLine`, which ends with `OnAfterInitPurchOrderLine(PurchaseLine, RequisitionLine)` before the insert. Report `Carry Out Action Msg. - Plan.` also uses this codeunit, so the planning worksheet and Order Planning share this hop.
- Production. `Carry Out Action` (codeunit 99000813) hands production lines to `Mfg. Carry Out Action`. `InsertProductionOrder` raises `OnInsertProdOrderWithReqLine` for a new header, and `InsertProdOrderLine` raises `OnInsertProdOrderLineWithReqLine` before the `Prod. Order Line` insert.

## Best Practice

Add the field to `Sales Line`, `Inventory Profile`, `Requisition Line` and each target table. Then subscribe once per hop:

- `OnAfterTransferInventoryProfileFromSalesLine` on `Sales Line Invt. Profile`: copy the sales value to the profile.
- `OnMaintainPlanningLineOnBeforeReqLineInsert` on `Inventory Profile Offsetting`: copy from `DemandInvtProfile` to the requisition line. First check that `DemandInvtProfile."Source Type"` is `Database::"Sales Line"`. Some call sites pass a supply profile in that parameter.
- `OnAfterTransferFromUnplannedDemand` on `Requisition Line`: when `UnplannedDemand."Demand Type"` is `Sales`, get the sales line from the demand keys and copy the value.
- `OnAfterInitPurchOrderLine` on `Req. Wksh.-Make Order` and `OnInsertProdOrderLineWithReqLine` on `Mfg. Carry Out Action`: copy from the requisition line. Both run before the insert, so assign without `Modify`.

A planning line maps to one demand only when the item's reordering policy is Order. With Lot-for-Lot, Fixed Reorder Qty. or Maximum Qty., one line can cover several demands. The event sees only the demand that created the line, and later demands merge into it without raising it. Say in the design which demand wins, or limit the feature to Order items.

A header field needs more care. `Req. Wksh.-Make Order` groups lines into one purchase header by vendor, currency, ship-to and similar fields. If the value must split orders, set `CheckInsert` in `OnBeforeCheckInsertFinalizePurchaseOrderHeader`. Carry-out must still run through the standard workflow; see [carry out requisition actions through the standard workflow](../scm/carry-out-requisition-actions-through-the-standard-workflow.md). Routing fields have their own planning path; see [copy routing line fields on both the refresh and the planning path](../manufacturing/copy-routing-line-fields-on-refresh-and-planning-paths.md).

See sample: [`carry-demand-fields-through-planning-lines-to-supply-orders.good.al`](carry-demand-fields-through-planning-lines-to-supply-orders.good.al).

## Anti Pattern

Look up the sales line from `Demand Order No.` when the purchase line is created, and test only with Order Planning. Lines from Calculate Plan have no demand reference, so the field stays blank on most planned orders. `Copy to Req. Wksh` in the carry-out options also clears the demand fields on the copied line. Patching the purchase line in `OnAfterPurchOrderLineInsert` with `Modify` adds a write per line and still has no source.

See sample: [`carry-demand-fields-through-planning-lines-to-supply-orders.bad.al`](carry-demand-fields-through-planning-lines-to-supply-orders.bad.al).

## References

- [Sales Line Invt. Profile, TransferInventoryProfileFromSalesLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesLineInvtProfile.Codeunit.al).
- [Inventory Profile Offsetting, MaintainPlanningLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/InventoryProfileOffsetting.Codeunit.al).
- [Requisition Line, TransferFromUnplannedDemand](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Requisition/RequisitionLine.Table.al).
- [Req. Wksh.-Make Order, InitPurchOrderLine and header grouping](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Requisition/ReqWkshMakeOrder.Codeunit.al).
- [Carry Out Action, CarryOutToReqWksh](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Requisition/CarryOutAction.Codeunit.al).
- [Mfg. Carry Out Action, InsertProductionOrder and InsertProdOrderLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Inventory/Requisition/MfgCarryOutAction.Codeunit.al).
