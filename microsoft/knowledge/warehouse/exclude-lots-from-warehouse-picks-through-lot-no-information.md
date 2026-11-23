---
bc-version: [all]
domain: warehouse
keywords: [lot-no-information, whse-item-tracking-fefo, onafterisitemtrackingblocked, oncheckwhseitemtrkglineonbeforetesttracking, onbeforevalidatelotno, warehouse-activity-line, create-pick, quarantine, blocked]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Exclude lots from warehouse picks through Lot No. Information

## Description

The warehouse already decides per lot whether stock can be picked, and it reads that decision from `Lot No. Information`, keyed by item, variant and lot. A lot with `Blocked` set is skipped by `"Whse. Item Tracking FEFO"` when it suggests lots. It is also left out of the pickable quantity, because `Bin Content` subtracts blocked lots in `CalcQtyWithBlockedItemTracking`.

A custom per-lot attribute, such as a quality status that only stops picking, can join that decision through verified events:

- `OnAfterIsItemTrackingBlocked(var ReservEntry, ItemNo, VariantCode, LotNo, var IsBlocked, ItemTrackingSetup)` on `"Whse. Item Tracking FEFO"`. Setting `IsBlocked` keeps the lot out of the FEFO suggestions that `Create Pick` uses.
- `OnBeforeValidateLotNo(var WarehouseActivityLine)` on `Warehouse Activity Line`. It runs when a lot is entered on a pick line by hand or by a scanner.
- `OnCheckWhseItemTrkgLineOnBeforeTestTracking(WarehouseActivityLine, var WhseItemTrackingSetup)` on `"Whse.-Activity-Register"`. It runs before a pick or inventory movement is registered, once per non-place line of an item with warehouse tracking.

FEFO runs only when the location has `Pick According to FEFO` or the item tracking code has `Strict Expiration Posting`, and the item has warehouse tracking. Without FEFO, lots come from the source tracking or are typed on the pick line, so the FEFO event alone is not enough.

## Best Practice

If the lot must not be used anywhere, set `Blocked` on `Lot No. Information` and write no code. If the attribute must stop warehouse picking only, add it to `Lot No. Information` with a table extension. Read it by item, variant and lot when needed. Do not copy it into warehouse or ledger entries: the status changes after the stock is posted. The same rule appears in [carry item tracking line fields to item ledger entries](../inventory/carry-item-tracking-line-fields-to-item-ledger-entries.md).

Then subscribe to all three events. The FEFO event keeps the lot out of suggestions. The validation event rejects it when typed. The registration event is a final check that also covers lines created before the status changed. This requires warehouse tracking; see [warehouse tracking settings](enable-lot-warehouse-tracking-before-relying-on-lots-in-wms-locations.md).

See sample: [`exclude-lots-from-warehouse-picks-through-lot-no-information.good.al`](exclude-lots-from-warehouse-picks-through-lot-no-information.good.al).

## Anti Pattern

Copy the quality status onto `Warehouse Entry` in `OnBeforeInsertWhseEntry` and filter on it in custom code. `Create Pick` never reads that field, and the copied value goes stale when the lot is released. Deleting pick lines with the lot after `Create Pick` is no better: it leaves the shipment partly unpicked and skips the warehouse's own availability logic.

See sample: [`exclude-lots-from-warehouse-picks-through-lot-no-information.bad.al`](exclude-lots-from-warehouse-picks-through-lot-no-information.bad.al).

## References

- [Whse. Item Tracking FEFO, IsItemTrackingBlocked and OnAfterIsItemTrackingBlocked](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Tracking/WhseItemTrackingFEFO.Codeunit.al).
- [Warehouse Activity Line, Lot No. validation and OnBeforeValidateLotNo](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/WarehouseActivityLine.Table.al).
- [Whse.-Activity-Register, CheckWhseItemTrkgLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/WhseActivityRegister.Codeunit.al).
- [Bin Content, CalcQtyWithBlockedItemTracking](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Structure/BinContent.Table.al).
- [Lot No. Information](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/LotNoInformation.Table.al).
- [Pick items for warehouse shipment, blocked lots and pickable quantity](https://learn.microsoft.com/en-us/dynamics365/business-central/warehouse-how-to-pick-items-for-warehouse-shipment).
