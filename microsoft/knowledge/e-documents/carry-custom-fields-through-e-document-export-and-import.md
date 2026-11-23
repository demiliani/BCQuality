---
bc-version: [all]
domain: e-documents
keywords: [onaftercreatepeppolxmldocument, onafterprocessincomingedocument, e-document-purchase-header, e-document-link, read-into-draft, istructuredformatreader, import-process, e-document-create-purch-doc]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry custom fields through e-document export and import

## Description

**Export.** The format's `Create` gets the posted header and lines as temporary record refs. `"E-Doc. Mapping".MapRecord` fills them with `RecordRef.Copy`, so they also hold table extension fields. The value must already be on the posted table, for example on `Sales Invoice Header`; see [mirror sales fields on every TransferFields target](../sales-purchase/mirror-sales-fields-on-every-transferfields-target.md). The built-in `PEPPOL BIS 3.0` format is codeunit `"EDoc PEPPOL BIS 3.0"`. It builds the XML with the PEPPOL app's XMLports and then raises `OnAfterCreatePEPPOLXMLDocument`. That event passes the service, the E-Document, both record refs and the `Temp Blob`, so a subscriber can add an element to the finished XML.

**Import.** The `"Import Process"` field on `"E-Document Service"` starts as `Version 2.0`. In V2 a reader, the `"E-Doc. Read into Draft"` value, fills the staging tables `"E-Document Purchase Header"` and `"E-Document Purchase Line"`. Both are public and extensible. The finish step, `"E-Doc. Create Purchase Invoice"`, copies named staging fields one by one into a new `Purchase Header`. It raises no event, and the codeunit is internal. The built-in PEPPOL reader is also internal and raises no event. An extension field on the staging header is therefore never copied by Core. After a successful run, `"E-Doc. Import"` raises `OnAfterProcessIncomingEDocument` with the start and desired status. The created purchase header holds the E-Document's `SystemId` in `"E-Document Link"`.

The V1 events on `"E-Document Create Purch. Doc."`, such as `OnCreateNewPurchHdrOnBeforeRecRefInsert`, only run for a service set to `Version 1.0`. The same applies to the format's `GetCompleteInfoFromReceivedDocument`.

## Best Practice

For your own format, read the custom field from the `SourceDocumentHeader` record ref in `Create`. For PEPPOL, subscribe to `OnAfterCreatePEPPOLXMLDocument`. Read the field from the record ref, load the XML from the blob, add the element and write it back to the same blob.

For import, add the field to `"E-Document Purchase Header"` and to `Purchase Header`. Fill the staging field in your own `IStructuredFormatReader`, bound to a new `"E-Doc. Read into Draft"` value. Then subscribe to `OnAfterProcessIncomingEDocument`. When `DesiredEndState` is `Processed`, find the purchase header by `"E-Document Link"` and copy the value. If no header is linked, exit.

See sample: [`carry-custom-fields-through-e-document-export-and-import.good.al`](carry-custom-fields-through-e-document-export-and-import.good.al).

## Anti Pattern

Use the V1 purchase-creation events for a service that runs the V2 import process. They never fire, so the field stays empty and no error shows it. Expecting Core to copy a staging extension field to `Purchase Header` because the names match fails for the same reason. Another mistake is to re-read the posted invoice by number in the PEPPOL subscriber instead of using the record ref. That bypasses the service's mapping rules.

See sample: [`carry-custom-fields-through-e-document-export-and-import.bad.al`](carry-custom-fields-through-e-document-export-and-import.bad.al).

## References

- [EDoc PEPPOL BIS 3.0, Create and OnAfterCreatePEPPOLXMLDocument](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Format/EDocPEPPOLBIS30.Codeunit.al).
- [E-Doc. Create Purchase Invoice, CreatePurchaseInvoice](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/Import/FinishDraft/EDocCreatePurchaseInvoice.Codeunit.al).
- [E-Doc. Import, OnAfterProcessIncomingEDocument](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/EDocImport.Codeunit.al).
- [Import E-Document Process, V1 and V2 dispatch](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/Import/ImportEDocumentProcess.Codeunit.al).
- [E-Document Service, Import Process](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Service/EDocumentService.Table.al).
- [E-Document Purchase Header](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/EDocumentPurchaseHeader.Table.al).
