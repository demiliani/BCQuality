---
bc-version: [all]
domain: service
keywords: [service-header, service-line, service-invoice-header, service-shipment-header, service-cr-memo-header, serv-documents-mgt, transferfields, onafterpostservicedoc, service-post, previewmode]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Mirror service fields on posted service documents and follow up after service posting

## Description

`Serv-Documents Mgt.` builds the posted service documents with `TransferFields`: `Service Header` into `Service Shipment Header`, `Service Invoice Header` and `Service Cr.Memo Header`, and `Service Line` into `Service Shipment Line`, `Service Invoice Line` and `Service Cr.Memo Line`. It first writes them to temporary records. Only at the end, in `Finalize`, does it copy each temporary record with `Copy()` into the real table and insert it. Extension fields survive both steps, but until `Finalize` runs the posted documents do not exist in the database.

`Service-Post` then commits, unless commit is suppressed, and raises `OnAfterPostServiceDoc(var ServiceHeader; ServShipmentNo; ServInvoiceNo; ServCrMemoNo; var ServDocumentsMgt; CommitIsSuppressed; PassedShip; PassedConsume; PassedInvoice; WhseShip; Invoice)`. The event has no `PreviewMode` parameter, and needs none: in posting preview `Service-Post` stops with the preview error before `Finalize`, so the event is never raised during preview. That differs from sales, where the after-posting event also runs in preview, and from purchases, where it runs without telling the subscriber.

## Best Practice

Give a custom service field the same field number, name, type and length on `Service Header` or `Service Line` and on each posted table the plan needs, as for sales; see [mirror sales fields on every TransferFields target](../sales-purchase/mirror-sales-fields-on-every-transferfields-target.md). No subscriber is needed for that hop.

Do follow-up work, such as notifying another system, in `OnAfterPostServiceDoc`, using the posted document numbers it passes. Because the commit has already happened in normal posting, an error there does not undo the posting; hand external calls to an outbox, as [OnAfterPostSalesDoc runs after the posting commit](../sales-purchase/onafterpostsalesdoc-runs-after-the-posting-commit.md) describes. Do not call `Commit()` when `CommitIsSuppressed` is true.

See sample: [`mirror-service-fields-and-follow-up-after-service-posting.good.al`](mirror-service-fields-and-follow-up-after-service-posting.good.al).

## Anti Pattern

Copy a sales or purchase after-posting subscriber to service and add a `PreviewMode` parameter, which the service event does not have. Or read the posted service invoice with `Get` from a subscriber that runs while lines are being posted: the row is still only in a temporary table, so the lookup fails.

See sample: [`mirror-service-fields-and-follow-up-after-service-posting.bad.al`](mirror-service-fields-and-follow-up-after-service-posting.bad.al).

## References

- [Serv-Documents Mgt., TransferFields into temporary posted documents and Finalize](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Posting/ServDocumentsMgt.Codeunit.al).
- [Service-Post, preview error, commit and OnAfterPostServiceDoc](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Posting/ServicePost.Codeunit.al).
