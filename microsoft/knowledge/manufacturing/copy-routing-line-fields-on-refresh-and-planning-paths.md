---
bc-version: [all]
domain: manufacturing
keywords: [routing-line, prod-order-routing-line, planning-routing-line, calculate-prod-order, refresh-production-order, onaftercopyfromroutingline, onaftertransferfromroutingline, onaftercopyfromplanningroutingline, carry-out-action, work-center]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Copy routing line fields on both the refresh and the planning path

## Description

A production order gets its `Prod. Order Routing Line` records from the master `Routing Line` in one of two ways. Every copy assigns named fields, so a custom routing field is not carried by itself.

- Refresh. Report `Refresh Production Order` runs `Calculate Prod. Order.Calculate`, and `TransferRouting` reads the `Routing Line` records of the line's routing and version. `InitProdOrderRoutingLine` calls `Prod. Order Routing Line.CopyFromRoutingLine`, which ends with `OnAfterCopyFromRoutingLine(ProdOrderRoutingLine, RoutingLine)`. Then the line is inserted. A production order created on its page and refreshed goes this way.
- Planning. `Mfg. Planning Line Management` copies `Routing Line` to `Planning Routing Line` with `TransferFromRoutingLine`, which raises `OnAfterTransferFromRoutingLine`. When the planning line is carried out, `Mfg. Carry Out Action.TransferRouting` builds the order's routing lines from the `Planning Routing Line` records with `CopyFromPlanningRoutingLine`, which raises `OnAfterCopyFromPlanningRoutingLine`. This path never reads `Routing Line` and never runs `Calculate Prod. Order.TransferRouting`.

`TransferRouting` also exits when routing lines already exist for the same order, `Routing Reference No.` and `Routing No.`. Prod. order lines that share a routing reference share one set of routing lines.

When the refresh recalculates routings, it first deletes the order's existing routing lines and then builds them again from `Routing Line`. A value typed on a production order routing line is lost. A value copied from the routing comes back.

## Best Practice

Add the field to `Routing Line`, `Planning Routing Line` and `Prod. Order Routing Line`. Subscribe to three table events:

- `OnAfterCopyFromRoutingLine` on `Prod. Order Routing Line`, for refresh.
- `OnAfterTransferFromRoutingLine` on `Planning Routing Line`, for planning.
- `OnAfterCopyFromPlanningRoutingLine` on `Prod. Order Routing Line`, for carry-out.

All three run before the insert, so no `Modify` is needed. Status changes later copy the routing line by record assignment; see [production order status change copies whole records](production-order-status-change-copies-whole-records.md).

If users must be able to change the value per order, say so in the design. A refresh that recalculates routings resets it to the routing value.

See sample: [`copy-routing-line-fields-on-refresh-and-planning-paths.good.al`](copy-routing-line-fields-on-refresh-and-planning-paths.good.al).

For demand fields that must reach planned purchase and production orders, see [carry demand fields through planning lines to supply orders](../inventory/carry-demand-fields-through-planning-lines-to-supply-orders.md).

## Anti Pattern

Subscribe only to `OnAfterTransferRoutingLine` on `Calculate Prod. Order` and test with a manually created order. Every order created by carrying out the planning worksheet then has an empty field.

Filling the field in `OnAfterInsertEvent` of `Prod. Order Routing Line`, by looking up the `Routing Line`, is also wrong. It costs a `Modify` per operation. For orders from planning it reads the master routing instead of the planning routing lines the order was actually built from.

See sample: [`copy-routing-line-fields-on-refresh-and-planning-paths.bad.al`](copy-routing-line-fields-on-refresh-and-planning-paths.bad.al).

## References

- [Calculate Prod. Order: TransferRouting and InitProdOrderRoutingLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Document/CalculateProdOrder.Codeunit.al).
- [Prod. Order Routing Line: CopyFromRoutingLine and CopyFromPlanningRoutingLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Document/ProdOrderRoutingLine.Table.al).
- [Planning Routing Line: TransferFromRoutingLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Routing/PlanningRoutingLine.Table.al).
- [Mfg. Carry Out Action: TransferRouting](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Inventory/Requisition/MfgCarryOutAction.Codeunit.al).
- [Refresh Production Order report](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Document/RefreshProductionOrder.Report.al).
