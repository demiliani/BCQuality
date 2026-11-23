---
bc-version: [all]
domain: warehouse
keywords: [whse-post-shipment, whse-post-receipt, sales-whse-post-shipment, onbeforesaleslinemodify, oninitsourcedocumentheaderonbeforesalesheadermodify, oninitsourcedocumentlinesonaftersourcepurchlinefound, sales-shipment-line, purch-rcpt-line, item-ledger-entry, source-document]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry warehouse shipment and receipt values to the source document before posting

## Description

Posting a warehouse shipment or receipt does not post the warehouse document into sales, purchase or inventory history by itself. For each source document it first writes onto the source header and lines, then runs the normal posting codeunit for that source:

- `"Whse.-Post Shipment"` (5763) delegates per source type. `"Sales Whse. Post Shipment"` (5746) validates `Qty. to Ship` (sales orders) or `Return Qty. to Receive` (sales return orders) on each `Sales Line`. With "Ship and Invoice" it also validates `Qty. to Invoice`. It then sets `Ship`, `Receive` and `Invoice` on the `Sales Header` and runs `Sales-Post`. `"Purch. Whse. Post Shipment"` (5747), `"Transfer Whse. Post Shipment"` (5748) and `"Serv. Whse Post-Shipment"` (5749) do the same for purchase return orders, transfers and service orders.
- `"Whse.-Post Receipt"` (5760) handles all sources itself. It validates `Qty. to Receive` or `Return Qty. to Ship` on `Purchase Line`, `Return Qty. to Receive` on sales return lines and `Qty. to Receive` on `Transfer Line`. Then it runs `Purch.-Post`, `Sales-Post` or `TransferOrder-Post Receipt`, always with `Invoice` set to false.

The source header gets only a few named values from the warehouse header: posting date, and for sales shipments also shipment date, external document no., shipping agent, service and shipment method. For receipts, only `Vendor Shipment No.` is copied. From the warehouse line, only the quantities and the bin code are copied.

The posting codeunit then builds history from the source document, not from the warehouse document. `Sales Shipment Header` and `Purch. Rcpt. Header` are filled with `TransferFields` from the source header. `Sales Shipment Line` and `Purch. Rcpt. Line` are filled with `TransferFields` from the source line (`InitFromSalesLine`, `InitFromPurchLine`). Item ledger entries come from the item journal line built from the source line. A custom field on a warehouse shipment or receipt line reaches none of them unless it is first copied to the source line.

## Best Practice

Copy the value onto the source document in the event that runs just before the warehouse routine modifies it. Set the `ModifyHeader` or `ModifyLine` flag to true when the value changed, because the routine calls `Modify` only when that flag is set.

- Warehouse shipment header to sales header: `OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify` on `"Sales Whse. Post Shipment"`.
- Warehouse shipment line to sales line: `OnBeforeSalesLineModify` on `"Sales Whse. Post Shipment"`. It also runs for sales lines without a shipment line, so check that the passed shipment line's `Source Line No.` equals the sales line's `Line No.` before copying.
- Warehouse receipt header to purchase header: `OnInitSourceDocumentHeaderOnBeforePurchHeaderModify` on `"Whse.-Post Receipt"`.
- Warehouse receipt line to purchase line: `OnInitSourceDocumentLinesOnAfterSourcePurchLineFound` on `"Whse.-Post Receipt"`, which runs only when a matching receipt line exists.
- Other sources have their own events, for example `OnBeforePurchLineModify` on `"Purch. Whse. Post Shipment"`, `OnBeforeTransLineModify` on `"Transfer Whse. Post Shipment"` and on `"Whse.-Post Receipt"`, and `OnBeforeServiceLineModify` on `"Serv. Whse Post-Shipment"`. Plan one subscriber per source type in scope.

The sales-specific shipment events are published by `"Sales Whse. Post Shipment"`, not by `"Whse.-Post Shipment"`. From the source document onwards, use the normal posting design. Give the posted header and line fields the same numbers as on the source header and line, so `TransferFields` carries them. Carry line values to the item ledger through `OnAfterCopyItemJnlLineFromSalesLine` or `OnAfterCopyItemJnlLineFromPurchLine` and `OnAfterInitItemLedgEntry`. See [carry sales line fields to the item ledger](../sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md).

For a header value that is needed only on item ledger entries, `OnPostItemJnlLineOnAfterCopyDocumentFields` on `Sales-Post` and on `Purch.-Post` passes the warehouse shipment and receipt headers directly. They are empty when the document is not posted from a warehouse document.

The posted warehouse documents are a separate path; see [carry warehouse document fields to posted warehouse documents](carry-warehouse-document-fields-to-posted-warehouse-documents.md). The warehouse lines get source line values on creation; see [carry source line fields to warehouse receipt and shipment lines](carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.md). Commits and errors are covered in [warehouse shipment and receipt posting commits per source document](warehouse-shipment-and-receipt-posting-commits-per-source-document.md).

See sample: [`carry-warehouse-shipment-and-receipt-values-to-the-source-document-before-posting.good.al`](carry-warehouse-shipment-and-receipt-values-to-the-source-document-before-posting.good.al).

## Anti Pattern

Add the field to `Warehouse Shipment Line` and `Sales Shipment Line` with the same number and expect posting to copy it. The posted sales shipment line is a `TransferFields` of the sales line, so the field stays blank. A related mistake is to copy the value onto the sales line in `OnHandleSalesLineOnSourceDocumentSalesOrderOnBeforeModifyLine` without setting `ModifyLine`. The routine recalculates the flag from the quantity right after that event, so the value is lost when the quantity did not change. Patching the posted shipment lines or item ledger entries after posting edits posted history outside the posting engine.

See sample: [`carry-warehouse-shipment-and-receipt-values-to-the-source-document-before-posting.bad.al`](carry-warehouse-shipment-and-receipt-values-to-the-source-document-before-posting.bad.al).

## References

- [Whse.-Post Shipment, InitSourceDocumentLines and PostSourceDocument](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Document/WhsePostShipment.Codeunit.al).
- [Sales Whse. Post Shipment, HandleSalesLine and its events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/SalesWhsePostShipment.Codeunit.al).
- [Whse.-Post Receipt, InitSourceDocumentHeader and InitSourceDocumentLines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Document/WhsePostReceipt.Codeunit.al).
- [Sales-Post, InsertShipmentLine and OnPostItemJnlLineOnAfterCopyDocumentFields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al).
- [Sales Shipment Line, InitFromSalesLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/History/SalesShipmentLine.Table.al).
