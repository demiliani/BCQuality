---
bc-version: [all]
domain: warehouse
keywords: [invt-pick, invt-put-away, whse-activity-post, posted-invt-pick-line, posted-invt-put-away-line, create-inventory-pick-movement, create-inventory-put-away, onbeforenewwhseactivlineinsertfromsales, onupdatesourcedocumentonbeforemodifysalesline, item-ledger-entry]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Inventory picks and put-aways post through the source document

## Description

In basic warehousing, an inventory pick or put-away is a `Warehouse Activity Line` linked to its source line through `Source Type`, `Source No.` and `Source Line No.`. Creation and posting work as follows:

- **Creation.** `"Create Inventory Pick/Movement"` builds pick lines from a `Sales Line` field by field, then raises `OnBeforeNewWhseActivLineInsertFromSales(var WarehouseActivityLine, var SalesLine, var WarehouseActivityHeader, var RemQtyToPickBase)`. `"Create Inventory Put-away"` builds put-away lines from a `Purchase Line` and raises its own `OnBeforeNewWhseActivLineInsertFromPurchase(var WarehouseActivityLine, PurchaseLine)`. The names repeat across the two codeunits, but the signatures differ. With the `Put-away Template` bin policy, `"Create Inventory Put-away"` creates lines in a second routine that raises only `OnAfterInitWarehouseActivityLine(var WarehouseActivityLine)`, without the source record.
- **Posting.** `"Whse.-Activity-Post"` sums the activity lines per source line into a temporary buffer. It writes quantity to ship or receive and the bin code back to the source line, then raises `OnUpdateSourceDocumentOnBeforeModifySalesLine` or `OnUpdateSourceDocumentOnBeforePurchLineModify` before `Modify`. It then runs `"Sales-Post"` or `"Purch.-Post"` on the source header.
- **Results.** Item ledger entries come from that source document posting, so from the sales or purchase line, not from the activity line. `Posted Invt. Pick Line` and `Posted Invt. Put-away Line` are copied from the activity line with `TransferFields`. At bin locations, `CreateWhseJnlLine` builds warehouse entries from each activity line and raises `OnAfterCreateWhseJnlLine`.

## Best Practice

Treat the source line as the carrier of any value that must reach item ledger entries. Copy it from the sales or purchase line to the item journal line as for any document posting; see [carry sales line fields to the item ledger](../sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md).

When the value must show on the inventory pick or put-away, add it to `Warehouse Activity Line` and copy it in the creation event of each source the feature needs. For put-aways at locations that use the put-away template policy, also subscribe to `OnAfterInitWarehouseActivityLine` and read the source line by its source fields. Give the field the same number on the posted inventory pick or put-away line, so `TransferFields` copies it.

When users enter the value on the activity line and it must reach the ledger, write it back in `OnUpdateSourceDocumentOnBeforeModifySalesLine` or `OnUpdateSourceDocumentOnBeforePurchLineModify`. Several activity lines for one source line are merged into a single buffer line before this event. Define one value per source line, or check that the lines agree.

See sample: [`inventory-picks-and-put-aways-post-through-the-source-document.good.al`](inventory-picks-and-put-aways-post-through-the-source-document.good.al).

## Anti Pattern

Add the field only to the activity line and expect it to reach item ledger entries, or copy it into the item journal line from a guessed activity line. The item journal line is built by sales or purchase posting, which never reads the activity line. Another mistake is to subscribe to `OnBeforeNewWhseActivLineInsertFromPurchase` on `"Create Inventory Pick/Movement"`. That event serves picks for outbound purchase lines, such as return orders, not purchase put-aways.

See sample: [`inventory-picks-and-put-aways-post-through-the-source-document.bad.al`](inventory-picks-and-put-aways-post-through-the-source-document.bad.al).

## References

- [Create Inventory Pick/Movement, CreatePickOrMoveFromSales](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/CreateInventoryPickMovement.Codeunit.al).
- [Create Inventory Put-away, CreateWarehouseActivityLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/CreateInventoryPutaway.Codeunit.al).
- [Whse.-Activity-Post, UpdateSourceDocument, PostSourceDocument and CreatePostedActivLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/WhseActivityPost.Codeunit.al).
