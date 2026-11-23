---
bc-version: [all]
domain: warehouse
keywords: [warehouse-request, get-source-documents, warehouse-source-filter, whse-sales-release, whse-purch-release, whse-transfer-release, onbeforecreatewhserequest, onsetfiltersonsourcetables, onaftersetsaleslinefilters, release]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Warehouse requests decide which source documents reach warehouse documents

## Description

Warehouse shipments, receipts and inventory picks and put-aways never search sales, purchase or transfer lines directly. They read `Warehouse Request` (table 5765). Report `Get Source Documents` (5753) iterates `Warehouse Request` records with `Document Status` Released and `Completely Handled` false, and only then reads the source lines of each one. `Create Warehouse Shipment` on a sales order goes through `Get Source Doc. Outbound` (5752), and `Create Warehouse Receipt` on a purchase order through `Get Source Doc. Inbound` (5751). Both filter `Warehouse Request` and run the same report. Report `Create Invt Put-away/Pick/Mvmt` also starts from `Warehouse Request`.

A request exists only after release. `Whse.-Sales Release` (5771), `Whse.-Purch. Release` (5772) and `Whse.-Transfer Release` (5773) create one request per document, location and direction, and only when the location requires shipment or pick, or receipt or put-away. They assign header fields one by one, raise `OnBeforeCreateWhseRequest`, then insert, or modify if it exists. Reopening sets the request back to Open, and releasing again rewrites it.

A filter or field the warehouse should use must therefore be on `Warehouse Request`. A field on `Sales Header` is invisible to `Get Source Documents`.

## Best Practice

For a header-level value, such as a delivery route, add the field to `Warehouse Request` and copy it in each release codeunit the feature needs:

- `OnBeforeCreateWhseRequest` on `Whse.-Sales Release`, with the `Sales Header` and the first `Sales Line` of that location.
- `OnBeforeCreateWhseRequest` on `Whse.-Purch. Release`, with the `Purchase Header`.
- `OnBeforeCreateWhseRequest` on `Whse.-Transfer Release`, raised for both the inbound and the outbound request.

To filter by it, add the field to `Warehouse Source Filter` and to page `Source Document Filter Card`. Then apply it in `OnSetFiltersOnSourceTables` on `Warehouse Source Filter`, which passes the `Warehouse Request` filter record by `var` before it reaches the report. Picking a single document for a shipment goes through `GetSingleOutboundDoc` and the `Source Documents` list instead; filter that list in `OnGetSingleOutboundDocOnAfterSetFilters` on `Get Source Doc. Outbound`.

For a line-level condition, such as excluding lines with a hold flag, do not use `Warehouse Request`. It has one record per document and location. Use `OnAfterSetSalesLineFilters` or `OnAfterSetPurchLineFilters` on `Get Source Documents`.

The value is captured at release. If users can change it on a released document, plan a reopen and release, or update the request yourself. A custom document type needs its own `Warehouse Request Source Document` value, its own release logic and a report extension with a dataitem, like BaseApp's service module. Field copying to the warehouse lines is a separate step; see [carry source line fields to warehouse receipt and shipment lines](carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.md).

See sample: [`warehouse-requests-decide-which-source-documents-reach-warehouse-documents.good.al`](warehouse-requests-decide-which-source-documents-reach-warehouse-documents.good.al).

## Anti Pattern

Add a route field to `Sales Header` only, and drop documents in `OnAfterSalesHeaderOnAfterGetRecord` on `Get Source Documents` by setting `SkipRecord`. The filter card cannot offer the option, the `Source Documents` list still shows every released document, and `Create Invt Put-away/Pick/Mvmt` ignores the rule. Writing `Warehouse Request` from a sales header `OnModify` subscriber fails the other way: it can create requests for open documents or for locations that do not use warehouse documents.

See sample: [`warehouse-requests-decide-which-source-documents-reach-warehouse-documents.bad.al`](warehouse-requests-decide-which-source-documents-reach-warehouse-documents.bad.al).

## References

- [Warehouse Request table](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Request/WarehouseRequest.Table.al).
- [Whse.-Sales Release, CreateWarehouseRequest](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/WhseSalesRelease.Codeunit.al).
- [Whse.-Purch. Release](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/WhsePurchRelease.Codeunit.al).
- [Whse.-Transfer Release](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Transfer/WhseTransferRelease.Codeunit.al).
- [Get Source Documents report](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Request/GetSourceDocuments.Report.al).
- [Warehouse Source Filter, SetFilters](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Request/WarehouseSourceFilter.Table.al).
- [Get Source Doc. Outbound](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Warehouse/Request/GetSourceDocOutbound.Codeunit.al).
