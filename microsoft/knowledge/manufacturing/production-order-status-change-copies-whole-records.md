---
bc-version: [all]
domain: manufacturing
keywords: [production-order, prod-order-line, prod-order-component, prod-order-routing-line, prod-order-status-management, change-status, finished-production-order, tableextension]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Production order status changes copy whole records

## Description

A production order moves from Planned or Firm Planned to Released and then to Finished through `"Prod. Order Status Management"`. Each step creates new rows in the same tables with the new `Status`, which is part of the primary key, and deletes the old rows. `TransProdOrder` starts with `ToProdOrder := FromProdOrder`, and the line, routing line and component transfers start with the same record assignment (`ToProdOrderLine := FromProdOrderLine` and so on) before the new key values are set.

A record assignment copies every field of the record, including table extension fields. A custom field on `Production Order`, `Prod. Order Line`, `Prod. Order Routing Line` or `Prod. Order Component` therefore survives a status change with no extra code.

## Best Practice

Add the field once, on the production order table that owns it, and rely on the status change to carry it. No mirror table is needed, because a finished order lives in the same tables as a released one.

Use the copy events only to change a value on the way, for example to clear or recalculate it for the new status: `OnCopyFromProdOrder`, `OnCopyFromProdOrderLine`, `OnCopyFromProdOrderRoutingLine` and `OnCopyFromProdOrderComp` on `"Prod. Order Status Management"` run after the copy and before the new row is modified. A new header can get a new number from its number series in this step; read the new number from `ToProdOrder`, not from the old order.

See sample: [`production-order-status-change-copies-whole-records.good.al`](production-order-status-change-copies-whole-records.good.al).

## Anti Pattern

Copy the field again in a subscriber to `OnAfterTransProdOrder` by reading the new order and calling `Modify`. The value is already there, the extra write costs a database call per order, and a subscriber that reads the old order by its old number after the change finds nothing, because the old rows are deleted.

See sample: [`production-order-status-change-copies-whole-records.bad.al`](production-order-status-change-copies-whole-records.bad.al).

## References

- [Prod. Order Status Management, TransProdOrder and the line, routing and component transfers](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Document/ProdOrderStatusManagement.Codeunit.al).
