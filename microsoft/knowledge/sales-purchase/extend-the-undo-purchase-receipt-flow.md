---
bc-version: [all]
domain: sales-purchase
keywords: [undo-receipt, posted-purchase-receipt, purch-rcpt-line, undo-purchase-receipt-line, correction-line, partial-receipt, onbeforenewpurchrcptlineinsert]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Extend the standard Undo Receipt flow

## Description

Use **Undo Receipt** to correct a posted purchase receipt before invoicing, rather than cancelling a posted purchase invoice. The action runs codeunit `Undo Purchase Receipt Line` on the selected `Purch. Rcpt. Line` records. The codeunit checks the selected lines, reverses the inventory posting for item lines, inserts a corrective receipt line, and updates the source purchase order; it also corrects the posted warehouse receipt when applicable. The undo targets the selected receipt, not every receipt for the order line.

## Best Practice

For a new action that undoes a receipt, pass the intended receipt-line selection to `Undo Purchase Receipt Line` and let the codeunit perform its checks and updates. To add behavior to the existing action, subscribe to the codeunit rather than to the page action. Choose the event according to what the feature needs:

| Requirement | Event on `Undo Purchase Receipt Line` | Timing and data |
| --- | --- | --- |
| Add a business validation before undoing a line | `OnBeforeCheckPurchRcptLine` | Inspect the original `Purch. Rcpt. Line` and raise an error if your rule fails. Leave `IsHandled` unchanged so the standard checks still run. |
| Set custom values on the corrective receipt line | `OnBeforeNewPurchRcptLineInsert` | The new line has already been copied from the original and assigned its correction values. Set extension fields on `var NewPurchRcptLine` before the standard insert. |
| React to the source order line update | `OnAfterUpdateOrderLine` | The codeunit has updated the source `Purchase Line`. This event is per line; it is not an after-commit notification. |

The record copy already carries extension fields on `Purch. Rcpt. Line`. Keep business references that should identify both the original receipt and its correction. Clear fields that describe only the original record, such as an external message ID assigned when it was exported, in `OnBeforeNewPurchRcptLineInsert`. No extra `Modify` is needed.

See [`extend-the-undo-purchase-receipt-flow.good.al`](extend-the-undo-purchase-receipt-flow.good.al).

## Anti Pattern

Reset `Quantity Received` on the order or delete the posted receipt line to emulate Undo Receipt. That does not reverse the inventory posting or record the correction, and resetting the order line can discard quantities from other valid receipts.

Treat an export message ID that identifies the original transmission as a shared business reference. An integration that uses a populated ID to skip previously exported lines will then skip the corrective line as well. See [`extend-the-undo-purchase-receipt-flow.bad.al`](extend-the-undo-purchase-receipt-flow.bad.al).

## Verification scenario

Order 10 units of an item, post two separate receipts of 3 and 2 without invoicing, and undo only the receipt for 2. With an otherwise standard setup, verify that the selected posted receipt has a corrective line for -2, the order still shows 3 received and 7 outstanding, and the item ledger reflects a net receipt of 3. If the extension clears an export message ID, verify that the corrective line has no ID and the original keeps its ID.

## References

- [Microsoft Learn: Undo a receipt or shipment posting](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-how-reverse-journal-posting#to-undo-a-quantity-posting-on-a-posted-purchase-receipt-or-sales-shipment).
- [Microsoft Learn: Undo Purchase Receipt Line events](https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/codeunit/microsoft.purchases.history.undo-purchase-receipt-line).
- [Base Application source: Undo Purchase Receipt Line](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/History/UndoPurchaseReceiptLine.Codeunit.al).
