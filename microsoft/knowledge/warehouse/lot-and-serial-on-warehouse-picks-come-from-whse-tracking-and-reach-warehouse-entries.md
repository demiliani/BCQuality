---
bc-version: [all]
domain: warehouse
keywords: [warehouse-activity-line, create-pick, pick-according-to-fefo, whse-item-tracking-fefo, whse-activity-register, synchronizewhseitemtracking, warehouse-entry, bin-content, lot-no-filter, expiration-date]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Lot and serial on warehouse picks come from warehouse tracking and reach warehouse entries

## Description

`Create Pick` sets `Lot No.` and `Serial No.` on pick lines from three sources, in this order:

1. **Source tracking.** The source line's `Whse. Item Tracking Line` rows are loaded with `SetTempWhseItemTrkgLine`. Their quantities become pick lines with those lots first.
2. **FEFO.** This applies to the untracked rest when the location has `Pick According to FEFO`, or the item tracking code has `Strict Expiration Posting`. In both cases the item must also have warehouse tracking. `"Whse. Item Tracking FEFO"` lists the available lots in expiration date order and skips lots that are blocked on `Lot No. Information`. With `Strict Expiration Posting`, lots that expired before the work date are left out.
3. **Nothing.** The remaining quantity gets pick lines with a blank lot. Serial-tracked items get one line per unit. The warehouse worker fills in the lot or serial number.

Validating `Lot No.` on a pick line checks that the item has warehouse tracking and that the lot is not reserved for another demand. When a pick is registered, `CheckWhseItemTrkgLine` requires a lot or serial on every non-place line of a warehouse-tracked item.

At a bin location, registration builds one `Warehouse Journal Line` per take or place line. `CopyTrackingFromWhseActivityLine` copies lot, serial, expiration and warranty dates to it. `"Whse. Jnl.-Register Line"` then copies them to the `Warehouse Entry`. `Bin Content` stores no lot. Its quantity fields are FlowFields over `Warehouse Entry`, filtered by `Lot No. Filter` and `Serial No. Filter`.

For picks for shipments, production, assembly and projects, registration builds a `Tracking Specification` per line and calls `"Item Tracking Management".SynchronizeWhseItemTracking`. That call writes the picked lots back to the source line's `Reservation Entry` rows. Posting the shipment then uses the picked lots.

## Best Practice

Treat the pick line as the place where the lot is decided at a WMS location. To pre-select lots, track the source line before the pick is created; see [assign lots on warehouse documents](assign-lots-on-warehouse-documents-through-the-table-each-document-reads.md). For expiry-driven picking, turn on `Pick According to FEFO` instead of sorting lots in custom code.

When code sets a lot on an existing pick, validate `Lot No.` or `Serial No.` on the take line and on its matching place line. Each line produces its own warehouse entry, so the place line's lot is the one recorded in the destination bin. To read stock per lot and bin, use `Bin Content` with `Lot No. Filter`, or `Warehouse Entry`. `Item Ledger Entry` has no bin.

To carry a custom value with the registered lot, use two events on `"Whse.-Activity-Register"`. `OnBeforeWhseJnlRegisterLine` covers the warehouse entry; see [carry fields to picks and registered activities](carry-fields-to-warehouse-picks-put-aways-and-registered-activities.md). `OnBeforeRegWhseItemTrkgLine` gets the temporary `Tracking Specification` that is synchronized back to the source line.

See sample: [`lot-and-serial-on-warehouse-picks-come-from-whse-tracking-and-reach-warehouse-entries.good.al`](lot-and-serial-on-warehouse-picks-come-from-whse-tracking-and-reach-warehouse-entries.good.al).

## Anti Pattern

After a pick is registered, write the picked lot into the sales line's `Reservation Entry` rows yourself. Registration already did this, so the second write doubles or overrides the quantity to handle. Other traps: setting the lot only on the take line, which leaves the destination bin's entry without it, or computing lot-per-bin stock from item ledger entries.

See sample: [`lot-and-serial-on-warehouse-picks-come-from-whse-tracking-and-reach-warehouse-entries.bad.al`](lot-and-serial-on-warehouse-picks-come-from-whse-tracking-and-reach-warehouse-entries.bad.al).

## References

- [Create Pick, CreateTempLine, PickAccordingToFEFO and CreateTempItemTrkgLines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/CreatePick.Codeunit.al).
- [Whse. Item Tracking FEFO, SummarizeInventoryFEFO and InsertEntrySummaryFEFO](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Tracking/WhseItemTrackingFEFO.Codeunit.al).
- [Warehouse Activity Line, Lot No. and Serial No. validation](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/WarehouseActivityLine.Table.al).
- [Whse.-Activity-Register, RegisterWhseJnlLine, RegisterWhseItemTrkgLine and SyncItemTracking](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/WhseActivityRegister.Codeunit.al).
- [Item Tracking Management, SynchronizeWhseItemTracking](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/ItemTrackingManagement.Codeunit.al).
- [Bin Content, quantity FlowFields filtered by lot and serial](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Structure/BinContent.Table.al).
- [Enable picking items by FEFO](https://learn.microsoft.com/en-us/dynamics365/business-central/warehouse-picking-by-fefo).
