---
bc-version: [all]
domain: warehouse
keywords: [posted-whse-shipment-header, posted-whse-receipt-header, posted-whse-shipment-line, posted-whse-receipt-line, whse-post-shipment, whse-post-receipt, onbeforepostedwhseshptheaderinsert, transferfields, create-posted-header]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry warehouse document fields to posted warehouse documents

## Description

Posting a warehouse receipt or shipment creates posted warehouse documents, but not all of them the same way:

| Target | How `Whse.-Post Receipt` / `Whse.-Post Shipment` fills it |
| --- | --- |
| `Posted Whse. Receipt Header` | `TransferFields` from `Warehouse Receipt Header` |
| `Posted Whse. Receipt Line` | `TransferFields` from `Warehouse Receipt Line` |
| `Posted Whse. Shipment Line` | `TransferFields` from `Warehouse Shipment Line` |
| `Posted Whse. Shipment Header` | Field by field from `Warehouse Shipment Header`; no `TransferFields` |

A field mirrored with the same number on the shipment header therefore stays blank on the posted shipment header, while the same design works for receipts and for shipment lines. In both codeunits the posted header is created only when the warehouse header's `Create Posted Header` is set; otherwise posting reuses the existing posted header and no insert event runs.

## Best Practice

For the three `TransferFields` targets, give the field the same number, name, type and length as on the warehouse document; no subscriber is needed. For `Posted Whse. Shipment Header`, add the field and copy it in `OnBeforePostedWhseShptHeaderInsert` on `"Whse.-Post Shipment"`, which passes the posted header by `var` and the warehouse shipment header. Because a reused posted header is not inserted again, plan the header value as the value at the first posting of that header, or ask the requester whether a later change must reach it.

The warehouse lines get the value from the source document line; see [carry source line fields to warehouse receipt and shipment lines](carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.md).

See sample: [`carry-warehouse-document-fields-to-posted-warehouse-documents.good.al`](carry-warehouse-document-fields-to-posted-warehouse-documents.good.al).

For values that must reach the posted sales shipment, purchase receipt or item ledger entries, see [carry warehouse shipment and receipt values to the source document before posting](carry-warehouse-shipment-and-receipt-values-to-the-source-document-before-posting.md) and [warehouse shipment and receipt posting commits per source document](warehouse-shipment-and-receipt-posting-commits-per-source-document.md).

## Anti Pattern

Mirror the shipment header field by number on `Posted Whse. Shipment Header` and expect it to be copied, because it works for receipts and for sales posted headers. The posted shipment header stays blank. Patching it after posting with `Modify` adds a write and misses the reuse case.

See sample: [`carry-warehouse-document-fields-to-posted-warehouse-documents.bad.al`](carry-warehouse-document-fields-to-posted-warehouse-documents.bad.al).

## References

- [Whse.-Post Shipment, CreatePostedShptHeader and CreatePostedShptLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Document/WhsePostShipment.Codeunit.al).
- [Whse.-Post Receipt, CreatePostedRcptHeader and CreatePostedRcptLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Document/WhsePostReceipt.Codeunit.al).
