---
bc-version: [all]
domain: e-documents
keywords: [service-integration, idocumentsender, idocumentreceiver, idocumentresponsehandler, sendcontext, receivecontext, e-document-integration-log, sending-error, e-document-connector]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Connect an e-document service through the V2 integration interfaces

## Description

A connector that sends and receives e-documents extends enum 6151 `"Service Integration"`. The `"Service Integration V2"` field on `"E-Document Service"` selects the value. The enum has no default implementation for `IDocumentSender` and `IDocumentReceiver`, so each new value must bind both. The Microsoft connectors, such as B2Brouter, bind one codeunit to both.

The older `"E-Document Integration"` interface and enum 6143 are obsolete since version 26.0. They exist only behind `#if not CLEAN26`, and the old `"Service Integration"` field is removed under that symbol. New code must not use them.

`"E-Doc. Integration Management"` does the framework work around each call:

- Before `Send`, it checks the service status, loads the exported blob from the log into `SendContext` and sets the default status to `Sent`.
- It commits and runs the sender inside `Codeunit.Run`. A runtime error, or an error logged with `"E-Document Error Helper"`, sets `Sending Error`. A document in `Sending Error` can be sent again.
- It writes the E-Document log, the service status and the integration log. The log takes the HTTP request and response that the connector stored in `SendContext.Http()`.
- If the sender codeunit also implements `IDocumentResponseHandler`, the status becomes `Pending Response` and a job queue entry polls `GetResponse` until it returns `true`.
- On receive, `ReceiveDocuments` returns one metadata blob per document. The framework creates each E-Document, calls `DownloadDocument`, and calls `MarkFetched` only when the receiver implements `IReceivedDocumentMarker`.

The status only depends on errors. A connector that gets a failed HTTP response and simply returns leaves the document as `Sent`.

## Best Practice

Bind `IDocumentSender` and `IDocumentReceiver` in the enum extension. Implement `IDocumentResponseHandler` on the sender codeunit only when the service confirms asynchronously.

In `Send`, read the file with `SendContext.GetTempBlob()`. Send with local request and response variables. Store both with `SendContext.Http().SetHttpRequestMessage` and `SetHttpResponseMessage`. If `HttpClient.Send` returns false or the status code is not a success, raise an error or log one with `"E-Document Error Helper"`. Use `SendContext.Status().SetStatus` only to choose a different success status. See [check HTTP status before consuming the response body](../web-services/check-http-status-before-consuming-response-body.md).

In `DownloadDocument`, fill `ReceiveContext.GetTempBlob()` and set the name and file format.

See sample: [`connect-an-e-document-service-through-the-v2-integration-interfaces.good.al`](connect-an-e-document-service-through-the-v2-integration-interfaces.good.al).

## Anti Pattern

Extend the obsolete `"E-Document Integration"` enum. Or write a `Send` that catches the failure, inserts its own log row, updates `"E-Document Service Status"` by hand, calls `Commit()`, and schedules its own retry job. That duplicates the framework's log, status, error scope and polling. It also hides the failure, because no error is raised and the framework reports `Sent`.

See sample: [`connect-an-e-document-service-through-the-v2-integration-interfaces.bad.al`](connect-an-e-document-service-through-the-v2-integration-interfaces.bad.al).

## References

- [Service Integration enum](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Integration/ServiceIntegration.Enum.al).
- [IDocumentSender](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Integration/Interfaces/IDocumentSender.Interface.al) and [IDocumentResponseHandler](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Integration/Interfaces/IDocumentResponseHandler.Interface.al).
- [E-Doc. Integration Management, Send, RunSend and DetermineServiceStatus](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Integration/EDocIntegrationManagement.Codeunit.al).
- [Obsolete E-Document Integration interface](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Integration/EDocumentIntegration.Interface.al).
- [B2Brouter connector, Send](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocumentConnectors/B2Brouter/app/src/B2BrouterApiManagement.Codeunit.al).
