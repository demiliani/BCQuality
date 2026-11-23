---
bc-version: [all]
domain: warehouse
keywords: [whse-item-tracking-line, reservation-entry, warehouse-shipment-line, warehouse-journal-line, createwhseitemtrackinglines, whse-jnl-register-batch, lot-no, serial-no, item-tracking, warehouse-activity-line]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Assign lots on warehouse documents through the table each document reads

## Description

Warehouse documents do not keep lot and serial numbers in one place. Each document reads its own store:

- **Warehouse receipts and shipments.** The tracking belongs to the source line. `OpenItemTrackingLines` on `Warehouse Receipt Line` and `Warehouse Shipment Line` opens the item tracking of the purchase, sales or transfer line. The values are `Reservation Entry` rows of that source line.
- **Picks for a shipment.** When a shipment line is created, `CreateWhseItemTrackingLines` copies the source line's tracked entries into `Whse. Item Tracking Line` rows with `Source Type` = `Warehouse Shipment Line`. This only happens when the item has warehouse tracking. `Whse.-Shipment - Create Pick` passes these rows to `"Create Pick"` through `SetTempWhseItemTrkgLine`. It does not read `Reservation Entry`.
- **Warehouse journals, movement worksheets and internal picks or put-aways.** Tracking lives only in `Whse. Item Tracking Line`. For a warehouse journal line, the Whse. Item Tracking Lines page keys the rows like this: `Source ID` = journal batch name, `Source Batch Name` = journal template name, `Source Ref. No.` = line number. `Whse. Jnl.-Register Batch` reads them for a tracked item. If their `Qty. to Handle (Base)` does not add up to the line quantity, it raises an error.
- **Picks, put-aways and movements.** `Lot No.` and `Serial No.` are plain fields on `Warehouse Activity Line`, one value per line.

## Best Practice

Write tracking into the table the target document reads:

1. For a receipt or shipment, assign tracking on the source line with `Create Reserv. Entry`; see [assign lot and serial tracking from code](../inventory/assign-lot-and-serial-tracking-from-code-through-create-reserv-entry.md). Do this before the warehouse shipment is created, so `CreateWhseItemTrackingLines` copies it. If the shipment exists and no pick has been created, rebuild its rows with `DeleteWhseItemTrackingLines` and `CreateWhseItemTrackingLines` on the shipment line. The Item Tracking Lines page does the same on close.
2. For a warehouse journal line, insert `Whse. Item Tracking Line` rows the way the page does. Use `GetNextEntryNo`, then `SetSource` with the journal key above. Fill item, variant, location and `Qty. per Unit of Measure` from the line. Then validate `Lot No.` or `Serial No.` and `Quantity (Base)`. Validating the quantity also fills `Qty. to Handle (Base)`.
3. For a pick line, validate `Lot No.` or `Serial No.` on the activity line itself; see [lot and serial on picks and registration](lot-and-serial-on-warehouse-picks-come-from-whse-tracking-and-reach-warehouse-entries.md).

All of this requires warehouse tracking on the item tracking code; see [warehouse tracking settings](enable-lot-warehouse-tracking-before-relying-on-lots-in-wms-locations.md).

See sample: [`assign-lots-on-warehouse-documents-through-the-table-each-document-reads.good.al`](assign-lots-on-warehouse-documents-through-the-table-each-document-reads.good.al).

## Anti Pattern

Set `Lot No.` directly on a `Warehouse Journal Line` and register it. For a tracked item, the register batch checks the `Whse. Item Tracking Line` rows, finds none, and fails. Another trap is adding `Reservation Entry` rows to a sales line after its warehouse shipment exists and expecting the next pick to follow them. `Create Pick` reads the shipment's `Whse. Item Tracking Line` rows, which were copied when the shipment line was created.

See sample: [`assign-lots-on-warehouse-documents-through-the-table-each-document-reads.bad.al`](assign-lots-on-warehouse-documents-through-the-table-each-document-reads.bad.al).

## References

- [Whse. Item Tracking Line, SetSource and GetNextEntryNo](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Tracking/WhseItemTrackingLine.Table.al).
- [Whse. Item Tracking Lines page, SetFilters per source type](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Tracking/WhseItemTrackingLines.Page.al).
- [Warehouse Shipment Line, OpenItemTrackingLines and CreateWhseItemTrackingLines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Document/WarehouseShipmentLine.Table.al).
- [Whse. Jnl.-Register Batch, CreateTrackingSpecification](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Journal/WhseJnlRegisterBatch.Codeunit.al).
- [Item Tracking Lines page, SynchronizeWarehouseItemTracking](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/ItemTrackingLines.Page.al).
- [Design details: item tracking in the warehouse](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-item-tracking-in-the-warehouse).
