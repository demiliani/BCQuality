---
bc-version: [all]
domain: warehouse
keywords: [warehouse-entry, warehouse-journal-line, whse-jnl-register-line, onbeforeinsertwhseentry, wms-management, oncreatewhsejnlline, onaftercreatewhsejnlline, item-journal-line, bin]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry fields to warehouse entries through the warehouse journal line

## Description

Every `Warehouse Entry` is created by `"Whse. Jnl.-Register Line"` from a `Warehouse Journal Line`. The entry is initialized field by field, not with `TransferFields`, and `OnBeforeInsertWhseEntry` runs just before the insert with the entry by `var` and the journal line. A custom field reaches the entry only if it is on the warehouse journal line and a subscriber copies it.

How the value gets onto the warehouse journal line depends on the path. When a sales or purchase document is posted at a location that uses bins, the posting routine builds the warehouse journal line from the item journal line through `"WMS Management".CreateWhseJnlLine`, which ends with `OnAfterCreateWhseJnlLine` passing the journal line by `var` and the `Item Journal Line`. Splitting that line by item tracking copies the whole record, so extension fields survive. Warehouse journals and the registering of warehouse activities such as picks and put-aways build their journal lines in other code.

## Best Practice

Add the field to `Warehouse Journal Line` and `Warehouse Entry`, and copy it in `OnBeforeInsertWhseEntry` on `"Whse. Jnl.-Register Line"`. That subscriber covers every path that creates warehouse entries. For document posting, put the value on the item journal line first, as [carry sales line fields to the item ledger](../sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md) describes, then copy it to the warehouse journal line in `OnAfterCreateWhseJnlLine` on `"WMS Management"`.

For any other path the feature needs, such as registering a pick, confirm in the target version where its warehouse journal line is built before designing the subscriber; do not assume it passes through `CreateWhseJnlLine`. Warehouse and item ledgers must stay consistent; see [reconcile warehouse adjustments with the item ledger](../scm/reconcile-warehouse-adjustments-with-the-item-ledger.md).

See sample: [`carry-fields-to-warehouse-entries-through-the-warehouse-journal-line.good.al`](carry-fields-to-warehouse-entries-through-the-warehouse-journal-line.good.al).

## Anti Pattern

Find warehouse entries after posting by source document and `Modify` them, or set the field only on the warehouse receipt or shipment line and expect it to appear on the warehouse entries. The entries are built from warehouse journal lines, not from warehouse document lines, and editing posted entries afterwards bypasses the register.

See sample: [`carry-fields-to-warehouse-entries-through-the-warehouse-journal-line.bad.al`](carry-fields-to-warehouse-entries-through-the-warehouse-journal-line.bad.al).

## References

- [Whse. Jnl.-Register Line, InitWhseEntry and InsertWhseEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Journal/WhseJnlRegisterLine.Codeunit.al).
- [WMS Management, CreateWhseJnlLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Journal/WMSManagement.Codeunit.al).
- [Item Tracking Management, SplitWhseJnlLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/ItemTrackingManagement.Codeunit.al).
