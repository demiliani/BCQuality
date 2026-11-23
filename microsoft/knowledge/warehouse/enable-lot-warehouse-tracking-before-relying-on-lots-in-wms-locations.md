---
bc-version: [all]
domain: warehouse
keywords: [item-tracking-code, lot-warehouse-tracking, sn-warehouse-tracking, strict-expiration-posting, getwhseitemtrkgsetup, item-tracking-setup, itemtrkgismanagedbywhse, warehouse-entry, put-away, fefo]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Enable lot warehouse tracking before relying on lots in WMS locations

## Description

An item can be lot-tracked on documents and in the item ledger but not in the warehouse. The warehouse code reads only the warehouse flags on `Item Tracking Code`. `"Item Tracking Management".GetWhseItemTrkgSetup` fills `Item Tracking Setup` through `CopyTrackingFromItemTrackingCodeWarehouseTracking`. That method sets `Lot No. Required` from `Lot Warehouse Tracking` and `Serial No. Required` from `SN Warehouse Tracking`.

When these flags are off:

- Validating `Lot No.` on a `Warehouse Activity Line` or `Warehouse Journal Line` raises an error through `CheckWhseItemTrkgSetup`.
- `SplitPostedWhseRcptLine` does not split the posted receipt by lot. Put-away lines have no lot, so the warehouse entries and bin contents do not know which lot is in which bin.
- Warehouse shipments do not copy the source tracking into `Whse. Item Tracking Line`. Registration does not write picked lots back to the source line.
- `Create Pick` applies neither `Pick According to FEFO` nor `Strict Expiration Posting`, because both require warehouse tracking.

`Lot Warehouse Tracking` requires `Lot Specific Tracking`, and `SN Warehouse Tracking` requires `SN Specific Tracking`. Turning on the specific flag also turns on the warehouse flag, but the warehouse flag can be turned off again on its own. A code that tracks lots only on selected transaction types, such as purchase inbound, has `Lot Specific Tracking` off, so it can never use warehouse tracking. You cannot change either warehouse flag once warehouse entries exist for any item that uses the code (`TestNoWhseEntriesExist`).

When the flags are on, at a location that requires picking, the source line's tracking is managed by the warehouse once a shipment or pick exists (`ItemTrkgIsManagedByWhse`). The Item Tracking Lines page then locks the quantity fields and blocks deletes. Lots come from the pick.

`Strict Expiration Posting` changes warehouse behavior too. It turns on `Use Expiration Dates`, makes `Create Pick` use FEFO even without the location setting, and leaves out expired lots.

## Best Practice

When a feature needs lot or serial information in bins, picks or put-aways, include warehouse tracking on the item tracking code in the plan. Check it in setup validation. In code, branch on `GetWhseItemTrkgSetup` and the `Lot No. Required` and `Serial No. Required` fields it returns. Do not branch on `Item."Item Tracking Code" <> ''` or `Lot Specific Tracking`.

Decide the setting before the first warehouse posting, because it cannot change afterwards. For document-level assignment, see [assign lots on warehouse documents](assign-lots-on-warehouse-documents-through-the-table-each-document-reads.md). For picks, see [lot and serial on picks](lot-and-serial-on-warehouse-picks-come-from-whse-tracking-and-reach-warehouse-entries.md).

See sample: [`enable-lot-warehouse-tracking-before-relying-on-lots-in-wms-locations.good.al`](enable-lot-warehouse-tracking-before-relying-on-lots-in-wms-locations.good.al).

## Anti Pattern

Treat an item as lot-tracked in the warehouse because it has an item tracking code with lot tracking on sales and purchases. The feature then sets `Lot No.` on pick lines, or reads it from warehouse entries. The first fails at validation. The second finds blank lots, because the put-away never split the receipt by lot.

See sample: [`enable-lot-warehouse-tracking-before-relying-on-lots-in-wms-locations.bad.al`](enable-lot-warehouse-tracking-before-relying-on-lots-in-wms-locations.bad.al).

## References

- [Item Tracking Code, warehouse tracking fields and TestNoWhseEntriesExist](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/ItemTrackingCode.Table.al).
- [Item Tracking Setup, CopyTrackingFromItemTrackingCodeWarehouseTracking](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/ItemTrackingSetup.Table.al).
- [Item Tracking Management, GetWhseItemTrkgSetup, ItemTrkgIsManagedByWhse and SplitPostedWhseRcptLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/ItemTrackingManagement.Codeunit.al).
- [Create Pick, PickAccordingToFEFO and PickStrictExpirationPosting](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/CreatePick.Codeunit.al).
- [Whse.-Post Receipt, put-away creation with warehouse tracking](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Document/WhsePostReceipt.Codeunit.al).
- [Enable picking items by FEFO](https://learn.microsoft.com/en-us/dynamics365/business-central/warehouse-picking-by-fefo).
