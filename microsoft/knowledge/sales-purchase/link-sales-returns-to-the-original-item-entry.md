---
bc-version: [all]
domain: sales-purchase
keywords: [sales-return-order, exact-cost-reversing, appl-from-item-entry, item-application, posted-sales-shipment, get-posted-document-lines-to-reverse, copy-document-mgt]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Link a sales return to the original item entry for exact cost reversal

## Description

When a customer returns an item, exact cost reversal values the returned inventory at the cost of the original sale. The link is a fixed application to the **outbound Item Ledger Entry**: for an untracked item on a sales return line, this is `Sales Line."Appl.-from Item Entry"`. A reference to the posted invoice, a customer ledger application, or a copied unit cost does not establish that inventory link.

## Best Practice

- **Extend the standard return flow.** Start from **Get Posted Document Lines to Reverse** on the sales return order. For a posted shipment, `Copy Document Mgt.` resolves the item ledger entries behind the selected shipment line and can split the copy by entry and carry item tracking. If you need to carry your own metadata, use `OnAfterCopySalesLineFromSalesShptLineBuffer` on that codeunit. It runs after a destination line has been copied and, when applicable, after standard item tracking has been copied. Treat it as a per-destination-line hook, not once per shipment line, and preserve the standard application and tracking.
- **Create a return line from an integration.** For an untracked item returned against one known outbound entry, validate the item, variant and quantity on the return line first, then validate `Appl.-from Item Entry` with the original entry number. Field validation checks the entry and the return quantity and derives `Unit Cost (LCY)`. When the source spans entries or uses lot or serial tracking, reuse the standard return-copy and tracking flow rather than choosing a single entry by item number.

Enable **Exact Cost Reversing Mandatory** in **Sales & Receivables Setup** when policy requires the link; keep the standard posting check enabled.

See [`link-sales-returns-to-the-original-item-entry.good.al`](link-sales-returns-to-the-original-item-entry.good.al).

## Anti Pattern

Copy only `Unit Cost (LCY)` from the original sale and expect posting to reverse its inventory cost. The line still has no fixed application: posting can reject it when exact cost reversal is mandatory, or use normal costing when it is not.

See [`link-sales-returns-to-the-original-item-entry.bad.al`](link-sales-returns-to-the-original-item-entry.bad.al).

## Verification scenario

With FIFO and no item tracking, receive two units of the same item at different costs and ship and invoice them on two separate orders. Return one unit from the second sale. Verify that the new inbound item ledger entry is applied to the second sale's outbound entry, not the first, and compare their costs after cost adjustment. With exact cost reversal mandatory, verify that the same return without the application link is rejected rather than accepted because the line shows a copied cost.

## References

- [Microsoft Learn: Process sales return orders](https://learn.microsoft.com/en-us/dynamics365/business-central/sales-how-process-sales-returns-cancellations).
- [Base Application: Copy Document Mgt., `CopySalesShptLinesToDoc`](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Utilities/CopyDocumentMgt.Codeunit.al#L2960).
- [Base Application: `Appl.-from Item Entry` field validation on Sales Line](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesLine.Table.al#L3951).
