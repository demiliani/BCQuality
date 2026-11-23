---
bc-version: [all]
domain: warehouse
keywords: [whse-post-shipment, whse-post-receipt, onafterpostwhseshipment, onafterpostsalesdoc, shipment-posting-policy, receipt-posting-policy, commit, posting-preview, whseship, source-document]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Warehouse shipment and receipt posting commits per source document

## Description

One warehouse shipment or receipt can hold lines from several source documents, for example several sales orders. `"Whse.-Post Shipment"` and `"Whse.-Post Receipt"` loop over the source documents and, for each one, prepare it and then run its own posting codeunit. The run is not one transaction:

- The routine commits after it assigns the shipping or receiving number.
- For each source document it updates the source header and lines (quantities to handle, posting date and the other copied values), then commits again before posting.
- `Sales-Post`, `Purch.-Post` and the other posting codeunits then post that document and commit as usual. `OnAfterPostSalesDoc` and `OnAfterPostPurchaseDoc` are raised once per source document, inside the warehouse run. `OnAfterPostSalesDoc` receives `WhseShip` or `WhseReceiv` set to true; `OnAfterPostPurchaseDoc` has no such flag.
- `OnAfterPostWhseShipment` on `"Whse.-Post Shipment"` runs once, after every source document is posted and committed. `"Whse.-Post Receipt"` raises `OnAfterCode` at the same point, after it creates put-aways.

None of these commits happens when commit is suppressed or in preview. Both routines support posting preview: `Preview` on `"Whse.-Post Shipment (Yes/No)"` and `"Whse.-Post Receipt (Yes/No)"` runs them in preview mode. `Sales-Post` and `Purch.-Post` then run with preview set, so `OnAfterPostSalesDoc` is raised with `PreviewMode` true. The routine then calls `ThrowError` before `OnAfterPostWhseShipment` and `OnAfterCode`, so neither is raised in preview.

What happens when one source document fails depends on `Shipment Posting Policy` and `Receipt Posting Policy` in `Warehouse Setup`. The default, "Stop and show the first posting error", calls `RunWithCheck` and stops the run. "Posting errors are not processed" calls the posting codeunit with `Codeunit.Run`, counts the documents that posted and continues. The failed document's posting is rolled back, but the quantities and values already written to its lines stay committed.

## Best Practice

Put everything that must become part of the posted documents on the source document before it is posted; see [carry warehouse shipment and receipt values to the source document before posting](carry-warehouse-shipment-and-receipt-values-to-the-source-document-before-posting.md).

Treat per-document follow-up as sales or purchase follow-up. Subscribe to `OnAfterPostSalesDoc` and use `WhseShip` or `WhseReceiv` when the work applies only to warehouse-driven posting. That event runs once per source document, after that document is committed. Guard it with `PreviewMode` and `CommitIsSuppressed`, as described in [OnAfterPostSalesDoc runs after the posting commit](../sales-purchase/onafterpostsalesdoc-runs-after-the-posting-commit.md) and [choose the after-posting hook per posting routine](../sales-purchase/choose-the-after-posting-hook-per-posting-routine.md).

Use `OnAfterPostWhseShipment` only for work about the warehouse shipment as a whole, such as a notification. Expect that some source documents may not have posted under "Posting errors are not processed". Design for partial shipments: a later shipment for the same order runs the same subscribers again with new quantities. Values written to the source lines persist into that next run unless the subscriber overwrites them.

In tests, cover a shipment with two source documents, a preview, and a run where one document fails under each posting policy.

See sample: [`warehouse-shipment-and-receipt-posting-commits-per-source-document.good.al`](warehouse-shipment-and-receipt-posting-commits-per-source-document.good.al).

## Anti Pattern

Subscribe to `OnAfterPostWhseShipment` to write a value onto the sales header, the posted sales shipment or item ledger entries. By then every source document is already posted and committed, so the value misses the posted documents. Fully shipped and invoiced orders may already be deleted. The subscriber also never runs in preview, and it cannot tell which source documents failed. A second mistake is to assume the whole warehouse shipment rolls back on an error: earlier source documents are already committed.

See sample: [`warehouse-shipment-and-receipt-posting-commits-per-source-document.bad.al`](warehouse-shipment-and-receipt-posting-commits-per-source-document.bad.al).

## References

- [Whse.-Post Shipment, Code, commits and OnAfterPostWhseShipment](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Document/WhsePostShipment.Codeunit.al).
- [Sales Whse. Post Shipment, OnPostSourceDocument and the posting policy](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/SalesWhsePostShipment.Codeunit.al).
- [Whse.-Post Receipt, Code and PostSourceDocument](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Document/WhsePostReceipt.Codeunit.al).
- [Whse.-Post Shipment (Yes/No), Preview](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Document/WhsePostShipmentYesNo.Codeunit.al).
- [Warehouse Setup, Shipment Posting Policy and Receipt Posting Policy](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Setup/WarehouseSetup.Table.al).
