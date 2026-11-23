---
bc-version: [all]
domain: e-documents
keywords: [e-document-format, e-document-interface, enumextension, e-document-service, e-doc-service-supported-type, e-document-error-helper, temp-blob, e-document-core]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Add an e-document format through the format enum

## Description

The E-Document Core app (id `e1d97edc-c239-46b4-8d84-6368bdf67c8b`, publisher Microsoft) turns posted documents into files through the `"E-Document"` interface. Enum 6101 `"E-Document Format"` implements that interface. The `"Document Format"` field on `"E-Document Service"` selects the value. A new format is an enum extension value bound to a codeunit that implements `"E-Document"`. No event subscription is needed. The extension's app.json must declare a dependency on E-Document Core, as the Microsoft connector apps do.

The interface has five procedures:

- `Check` validates a sales, purchase or service document on release and before posting. It receives the source header as a `RecordRef` and the processing phase.
- `Create` writes the file for one posted document into the `Temp Blob`.
- `CreateBatch` does the same for a filtered set when the service uses batch processing.
- `GetBasicInfoFromReceivedDocument` and `GetCompleteInfoFromReceivedDocument` are the import side of the V1 import process only. See [carry custom fields through e-document export and import](carry-custom-fields-through-e-document-export-and-import.md).

`"E-Doc. Export"` calls `Create` itself. It first applies the service's `"E-Doc. Mapping"` rules to temporary copies of the posted header and lines. It then commits and runs the format inside `Codeunit.Run`. A runtime error, or an error logged with `"E-Document Error Helper"`, sets the service status to `Export Error`. The framework stores the blob in the E-Document log, and later steps read it from there.

A service only exports a document type that has a row in `"E-Doc. Service Supported Type"` with direction `Outgoing` or `Both`. When the format is chosen on the service, Core adds default rows only for `PEPPOL BIS 3.0`. A new format value gets none.

## Best Practice

Extend `"E-Document Format"` with a value whose `Implementation` binds `"E-Document"` to your codeunit. `IEDocResponseProvider` has a default implementation, so you can leave it out.

In `Create`, read the data from the `SourceDocumentHeader` and `SourceDocumentLines` record refs passed in. They hold the mapped values, and `RecordRef.Copy` carries extension fields too. Branch on `EDocument."Document Type"` and log unsupported types with `"E-Document Error Helper".LogSimpleErrorMessage`. Implement `CreateBatch` too, even if it only logs an error, because the interface requires it.

Put rules that must stop posting in `Check`. Errors in `Create` do not stop posting; see [e-document creation runs after the posting commit](e-document-creation-runs-after-the-posting-commit.md).

Tell the setup or the install code to add the outgoing document types to the service's supported types.

See sample: [`add-an-e-document-format-through-the-format-enum.good.al`](add-an-e-document-format-through-the-format-enum.good.al).

## Anti Pattern

Subscribe to `OnAfterPostSalesDoc`, build the XML from the posted invoice and store it in a custom table. The file skips the document sending profile, the E-Document record, its log, the mapping rules, the service status and the send step. It also runs in the posting session, after the posting commit.

Another mistake is to re-read the posted invoice with `Get` inside `Create`. That ignores the service's mapping rules. A further mistake is to call `Commit()` in `Create`. The framework owns the transaction and already runs the format in its own error scope.

See sample: [`add-an-e-document-format-through-the-format-enum.bad.al`](add-an-e-document-format-through-the-format-enum.bad.al).

## References

- [E-Document interface](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Document/Interfaces/EDocument.Interface.al).
- [E-Document Format enum](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Document/EDocumentFormat.Enum.al).
- [E-Doc. Export, ExportEDocument, MapEDocument and IsDocumentTypeSupported](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/EDocExport.Codeunit.al).
- [E-Doc. Mapping, MapRecord](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Mapping/EDocMapping.Codeunit.al).
- [E-Document Core app.json](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/app.json).
- [Extend e-documents (Microsoft Learn)](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extend-edocuments).
