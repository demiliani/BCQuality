---
bc-version: [all]
domain: warehouse
keywords: [internal-movement-line, invt-movement, registered-invt-movement-line, movement-worksheet, createinvtmvntwithoutsource, oncreateinvtmvntwithoutsourceonaftertransferfields, onaftertransferfrommovwkshline, whse-activity-register, warehouse-activity-line]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry fields through warehouse movements and internal movements

## Description

Business Central has two kinds of bin-to-bin movement documents, and they are created and registered by different code:

| Source | Created by | Activity type | Registered into |
| --- | --- | --- | --- |
| Movement worksheet line | Report `"Whse.-Source - Create Document"` calls `"Create Pick"`, which builds lines with `TransferFromMovWkshLine` | `Movement` | `Registered Whse. Activity Line` |
| Internal movement line | The Internal Movement page calls `CreateInvtMvntWithoutSource` on `"Create Inventory Pick/Movement"` | `Invt. Movement` | `Registered Invt. Movement Line` |

Both builders assign fields one by one. `TransferFromMovWkshLine` ends with `OnAfterTransferFromMovWkshLine(var WarehouseActivityLine, WhseWorksheetLine)` on table `Warehouse Activity Line`. `CreateInvtMvntWithoutSource` raises `OnCreateInvtMvntWithoutSourceOnAfterTransferFields(var WarehouseActivityLine, InternalMovementLine)`. It then passes that line to `CreatePickOrMoveLine`, which inserts the take line and, at a bin location, a place line from the same record. Both lines therefore keep the value.

After creating the inventory movement, the codeunit deletes the handled internal movement lines, and the header when no lines remain. The new activity lines do not point back to the internal movement line.

`"Whse.-Activity-Register"` registers both types, but `CreateRegActivLine` branches on the activity type. An inventory movement goes to `Registered Invt. Movement Line` through `TransferFields`, with `OnBeforeRegisteredInvtMovementLineInsert`. All other types go to `Registered Whse. Activity Line`. At bin locations, both types post warehouse entries through the same `RegisterWhseJnlLine` and `OnBeforeWhseJnlRegisterLine`.

## Best Practice

Decide which movement documents the feature covers. For each one, add the field with the same number to `Warehouse Activity Line` and to the matching registered line table. Then copy it at creation time:

- Internal movements: subscribe to `OnCreateInvtMvntWithoutSourceOnAfterTransferFields` on `"Create Inventory Pick/Movement"`.
- Movement worksheets: subscribe to `OnAfterTransferFromMovWkshLine` on `Warehouse Activity Line`.

Registration then copies the value by `TransferFields`. For warehouse entries, copy it to the warehouse journal line in `OnBeforeWhseJnlRegisterLine`; see [carry fields to warehouse picks, put-aways and registered activities](carry-fields-to-warehouse-picks-put-aways-and-registered-activities.md). Use the activity type, not the location, to choose which registered table a report or page reads.

See sample: [`carry-fields-through-warehouse-movements-and-internal-movements.good.al`](carry-fields-through-warehouse-movements-and-internal-movements.good.al).

## Anti Pattern

Extend only `Registered Whse. Activity Line` and expect it to hold internal movements. Those land in `Registered Invt. Movement Line`, so the field stays empty with no error. Another mistake is to read the internal movement during registration to fetch the value. By then the line is usually deleted, and the activity line has no reference to it.

See sample: [`carry-fields-through-warehouse-movements-and-internal-movements.bad.al`](carry-fields-through-warehouse-movements-and-internal-movements.bad.al).

## References

- [Create Inventory Pick/Movement, CreateInvtMvntWithoutSource and SetLineData](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/CreateInventoryPickMovement.Codeunit.al).
- [Internal Movement page, Create Inventory Movement action](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/InternalDocument/InternalMovement.Page.al).
- [Warehouse Activity Line, TransferFromMovWkshLine and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/WarehouseActivityLine.Table.al).
- [Whse.-Activity-Register, CreateRegActivLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Activity/WhseActivityRegister.Codeunit.al).
