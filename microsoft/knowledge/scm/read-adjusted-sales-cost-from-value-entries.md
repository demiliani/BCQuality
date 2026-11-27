---
bc-version: [all]
domain: scm
keywords: [cost-adjustment, adjust-cost-item-entries, inventory-cost, cost-amount-actual, value-entry, sales-margin, item-application, post-inventory-cost-to-gl, onbeforeinsertvalueentry]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Read adjusted sales cost from value entries

## Description

When a purchase invoice changes the cost of a receipt after the item has been sold, Business Central can forward the cost difference to the outbound item ledger entry through the inventory costing process. Cost adjustment adds `Value Entry` records linked to the existing `Item Ledger Entry`; it does not post another shipment or change the sold quantity. A margin calculated only from the original sales posting can therefore become stale even though nothing changed on the posted sales invoice.

## Best Practice

Keep the standard steps separate:

- **Adjust Cost - Item Entries** forwards cost changes to affected outbound entries. Adjustment can run automatically according to **Automatic Cost Adjustment** in **Inventory Setup**, or through the standard batch job.
- **Post Inventory Cost to G/L** posts inventory costs from value entries to the general ledger when they have not already been posted. The current inventory cost and the amount already posted to G/L are different measures.
- Use the [revaluation journal](post-revaluation-through-the-item-journal-batch.md) for an explicit revaluation, not to make a late purchase invoice cost reach sales that standard cost adjustment already handles.

For current actual cost on a known outbound item ledger entry, calculate its `Cost Amount (Actual)` FlowField. This sums all linked value entries, including later adjustments. If the feature needs the **individual adjustment** instead, use `OnBeforeInsertValueEntry` on `Item Jnl.-Post Line` to populate extension fields on the new `Value Entry`. For the inventory adjustment path, check `CalledFromAdjustment` and `ValueEntry.Adjustment`; use `ValueEntry."Item Ledger Entry No."` to identify the affected movement. The event runs inside posting, not after commit: do not dispatch an external notification from it.

See [`read-adjusted-sales-cost-from-value-entries.good.al`](read-adjusted-sales-cost-from-value-entries.good.al).

## Anti Pattern

Report current sales cost by summing only value entries with `Adjustment = false`. That can omit the later cost differences and leave the margin showing the original cost after adjustment has completed.

See [`read-adjusted-sales-cost-from-value-entries.bad.al`](read-adjusted-sales-cost-from-value-entries.bad.al).

## Verification scenario

With FIFO and automatic cost adjustment and automatic cost posting disabled, receive one unit at an expected cost of 10, then ship and invoice its sale. Invoice the original purchase receipt at 12 and run **Adjust Cost - Item Entries**. Verify that the sale still has one outbound item ledger entry and that its signed actual cost is now -12, including the adjustment value entries. Run **Post Inventory Cost to G/L** separately and verify that the cost is then reflected in G/L.

## References

- [Microsoft Learn: Design details - Cost adjustment](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-cost-adjustment).
- [Microsoft Learn: Reconcile inventory costs with the general ledger](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-how-to-post-inventory-costs-to-the-general-ledger).
- [Base Application: Item Ledger Entry, `Cost Amount (Actual)`](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Ledger/ItemLedgerEntry.Table.al#L426).
- [Base Application: Item Jnl.-Post Line, `OnBeforeInsertValueEntry`](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Posting/ItemJnlPostLine.Codeunit.al#L2930).
