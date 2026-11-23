---
bc-version: [all]
domain: warehouse
keywords: [transfer-line, item-journal-line, item-ledger-entry, onaftercreateitemjnlline, onbeforepostitemjournalline, onafterinititemledgentry, in-transit, transferorder-post-shipment, transferorder-post-receipt]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry transfer line fields to the item ledger through the posting codeunits

## Description

Sales and purchase lines reach the item journal through `CopyFromSalesLine` and `CopyFromPurchLine`, which end with integration events on `Item Journal Line`. Transfer lines do not: `Item Journal Line` has no copy method or event for a `Transfer Line`. Each transfer posting codeunit builds the item journal line itself and exposes its own event instead.

`TransferOrder-Post Shipment` raises `OnAfterCreateItemJnlLine(var ItemJournalLine, TransferLine, TransferShipmentHeader, TransferShipmentLine)` after building the shipment's journal line. `TransferOrder-Post Receipt` raises `OnBeforePostItemJournalLine(var ItemJournalLine, TransferLine, TransferReceiptHeader, TransferReceiptLine, CommitIsSuppressed, PreviewMode, TransLine, PostedWhseRcptHeader)` just before posting the receipt's journal line. `TransferOrder-Post Transfer` raises `OnAfterCreateItemJnlLine(var ItemJnlLine, TransLine, DirectTransHeader, DirectTransLine)` for direct transfers.

Each transfer journal line posts two item ledger entries: the negative entry at the source location and the positive entry at the new location, created by `InsertTransferEntry`. `Item Jnl.-Post Line` initializes both through `InitItemLedgEntry`, so `OnAfterInitItemLedgEntry` runs for each of them.

## Best Practice

Add the field to `Item Journal Line` and `Item Ledger Entry`. Copy it from the transfer line to the journal line in the codeunit event of every leg the plan needs: shipment, receipt and, if used, direct transfer. Then copy it from the journal line to the entry in `OnAfterInitItemLedgEntry`, the same subscriber that sales and purchase designs use; see [carry sales line fields to the item ledger](../sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md). The value then reaches the from-location, in-transit and to-location entries without extra writes.

If only some legs should carry the value, decide it in the journal-line subscribers, not in `OnAfterInitItemLedgEntry`, which cannot tell the legs apart by source document. Item tracking on transfers has its own rules; see [transfer item tracking through source reservation codeunits](../scm/transfer-item-tracking-through-source-reservation-codeunits.md).

See sample: [`carry-transfer-line-fields-to-item-ledger.good.al`](carry-transfer-line-fields-to-item-ledger.good.al).

## Anti Pattern

Look for an `OnAfterCopyItemJnlLineFromTransferLine` event on `Item Journal Line` because sales and purchases have one, then fall back to patching item ledger entries after posting. No such event exists, and the patch edits posted entries outside the posting engine.

See sample: [`carry-transfer-line-fields-to-item-ledger.bad.al`](carry-transfer-line-fields-to-item-ledger.bad.al).

## References

- [TransferOrder-Post Shipment, CreateItemJnlLine and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Transfer/TransferOrderPostShipment.Codeunit.al).
- [TransferOrder-Post Receipt, OnBeforePostItemJournalLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Transfer/TransferOrderPostReceipt.Codeunit.al).
- [Item Jnl.-Post Line, InitItemLedgEntry and InsertTransferEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Posting/ItemJnlPostLine.Codeunit.al).
