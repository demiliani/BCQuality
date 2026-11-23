---
bc-version: [all]
domain: warehouse
keywords: [warehouse-activity-line, registered-whse-activity-line, create-pick, create-put-away, onaftertransferfromshptline, onbeforewhseactivlineinsert, whse-activity-register, onbeforewhsejnlregisterline, posted-whse-receipt-line, warehouse-entry]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry fields to warehouse picks, put-aways and registered activities

## Description

A custom field on a warehouse shipment or receipt line does not reach a pick or put-away by itself. Each hop uses its own mechanism:

| Hop | Mechanism |
| --- | --- |
| `Warehouse Shipment Line` to `Warehouse Activity Line` (pick) | `"Create Pick"` builds each take and place line through `TransferFromShptLine`, field by field, which raises `OnAfterTransferFromShptLine(var WarehouseActivityLine, WarehouseShipmentLine)` on `Warehouse Activity Line` |
| `Posted Whse. Receipt Line` to `Warehouse Activity Line` (put-away) | `"Create Put-away"` fills each line field by field in `CreateNewWhseActivity` and raises `OnBeforeWhseActivLineInsert(var WarehouseActivityLine, PostedWhseRcptLine)` before the insert |
| `Warehouse Activity Line` to `Registered Whse. Activity Line` | `"Whse.-Activity-Register"` uses `TransferFields` in `CreateRegActivLine` |
| `Warehouse Activity Line` to `Warehouse Journal Line` | `RegisterWhseJnlLine` assigns fields one by one and raises `OnBeforeWhseJnlRegisterLine(var WarehouseJournalLine, WarehouseActivityLine)` before it runs `"Whse. Jnl.-Register Line"` |

Put-aways are created from the posted receipt line, not from the open `Warehouse Receipt Line`. Receipt posting copies the receipt line to the posted line with `TransferFields`, so the value must be on the posted line with the same field number.

Registration writes warehouse entries only at locations with `Bin Mandatory`, one per take or place line. Picks from a pick worksheet or an internal pick use other builders: `TransferFromPickWkshLine` and `TransferFromIntPickLine`, each with its own `OnAfterTransferFrom...` event.

## Best Practice

Give the field the same number and type on `Warehouse Activity Line` and `Registered Whse. Activity Line`, so registration copies it with no subscriber. Then add one creation subscriber per source the feature needs:

- Picks from shipments: `OnAfterTransferFromShptLine` on table `Warehouse Activity Line`. It runs for every temporary take, place and breakbulk line, so all of them get the value.
- Put-aways from receipts: `OnBeforeWhseActivLineInsert` on `"Create Put-away"`, reading the posted receipt line.

When the value must reach warehouse entries, add it to `Warehouse Journal Line` and `Warehouse Entry`. Copy it in `OnBeforeWhseJnlRegisterLine` on `"Whse.-Activity-Register"`, then to the entry in `OnBeforeInsertWhseEntry`, as described in [carry fields to warehouse entries through the warehouse journal line](carry-fields-to-warehouse-entries-through-the-warehouse-journal-line.md). The earlier hops are in [carry source line fields to warehouse receipt and shipment lines](carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.md) and [carry warehouse document fields to posted warehouse documents](carry-warehouse-document-fields-to-posted-warehouse-documents.md).

See sample: [`carry-fields-to-warehouse-picks-put-aways-and-registered-activities.good.al`](carry-fields-to-warehouse-picks-put-aways-and-registered-activities.good.al).

## Anti Pattern

Copy the value to the pick in `OnBeforeWhseActivLineInsert` on `"Create Pick"`. That event passes the activity line and header, not the shipment line, and breakbulk and place lines are inserted by other calls. Another mistake is to read the open `Warehouse Receipt Line` when creating a put-away: it can already be deleted after posting. Finding registered lines afterwards and calling `Modify` adds a write outside registration.

See sample: [`carry-fields-to-warehouse-picks-put-aways-and-registered-activities.bad.al`](carry-fields-to-warehouse-picks-put-aways-and-registered-activities.bad.al).

## References

- [Create Pick, CreateTempActivityLine and CreateWhseDocLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/CreatePick.Codeunit.al).
- [Warehouse Activity Line, TransferFromShptLine and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/WarehouseActivityLine.Table.al).
- [Create Put-away, CreateNewWhseActivity](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/CreatePutaway.Codeunit.al).
- [Whse.-Activity-Register, CreateRegActivLine and RegisterWhseJnlLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/WhseActivityRegister.Codeunit.al).
