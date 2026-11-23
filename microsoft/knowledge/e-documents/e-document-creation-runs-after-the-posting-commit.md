---
bc-version: [all]
domain: e-documents
keywords: [e-document-subscribers, onafterpostsalesdoc, onaftercheckandupdate, document-sending-profile, extended-e-document-service-flow, commitissuppressed, export-error, e-document-processing-phase]
technologies: [al]
countries: [w1]
application-area: [all]
---

# E-document creation runs after the posting commit

## Description

E-Document Core hooks into sales posting in two places, through its internal codeunit `"E-Document Subscribers"`.

- **Check.** On `OnAfterCheckAndUpdate` of `Sales-Post`, it runs the format's `Check` with phase `Post`, inside the posting transaction. On `OnBeforeReleaseSalesDoc` of `Release Sales Document`, it runs `Check` with phase `Release`. It does this only for an electronic document that has no E-Document yet. An error in `Check` stops posting or release.
- **Create.** On `OnAfterPostSalesDoc`, after the posting commit, it creates the E-Document for the posted invoice, credit memo or shipment. `"E-Doc. Export"` then commits and runs the format's `Create` in its own error scope. An error there leaves the posted invoice in place and sets the service status to `Export Error`. Sending is then started from a job queue entry.

Creation needs setup. The bill-to customer's document sending profile must have `"Electronic Document"` set to `Extended E-Document Service Flow`. Its `"Electronic Service Flow"` must name an existing, enabled workflow that uses the service. The service must support the document type for the outgoing direction.

Creation is skipped when `OnAfterPostSalesDoc` reports `CommitIsSuppressed`, `PreviewMode` or inventory pick and put-away posting. Core only logs the telemetry message "E-Document creation deferred". Core creates the E-Document later when the posted document is sent through its document sending profile. For inventory picks, Core creates it when the warehouse activity is completed. Purchase, service, reminder and finance charge memo posting follow the same pattern. See [OnAfterPostSalesDoc runs after the posting commit](../sales-purchase/onafterpostsalesdoc-runs-after-the-posting-commit.md).

## Best Practice

Put every rule that must stop posting in the format's `Check`, and use the processing phase to decide when it applies. Keep `Create` for building the file. Log problems there with `"E-Document Error Helper"` so that they show on the E-Document.

When a feature posts sales documents from code with commit suppressed, do not expect an E-Document right after posting. Plan for the user to send the posted document, or let the normal posting commit run. Tests must also enable the document sending profile, the workflow and the supported types. Without them, no E-Document is created and no error is raised.

See sample: [`e-document-creation-runs-after-the-posting-commit.good.al`](e-document-creation-runs-after-the-posting-commit.good.al).

## Anti Pattern

Raise a blocking validation error in `Create` and expect posting to stop. The invoice is already committed. The user gets a posted invoice and an E-Document in `Export Error`. Another mistake is to subscribe to `OnAfterPostSalesDoc` in the extension, look for the E-Document and fail when none is found. That subscriber may run before Core's, and Core does not create one at all when commit is suppressed.

See sample: [`e-document-creation-runs-after-the-posting-commit.bad.al`](e-document-creation-runs-after-the-posting-commit.bad.al).

## References

- [E-Document Subscribers, posting check and after-posting regions, AllowCreateEDocument](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/EDocumentSubscribers.Codeunit.al).
- [E-Doc. Export, CheckEDocument, CreateEDocument and CreateAndExportEDocument](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/EDocExport.Codeunit.al).
- [E-Document Processing, RunEDocumentCheck](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/EDocumentProcessing.Codeunit.al).
- [E-Document Background Jobs, StartEDocumentCreatedFlow](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/EDocumentBackgroundJobs.Codeunit.al).
