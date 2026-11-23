# Feature design

> We must send our posted sales invoices to the Contoso e-invoicing network in Contoso's own XML format, and pull supplier invoices from the same network into Business Central. The network confirms delivery a few minutes after upload.

**Result:** Complete design. **Business process:** Sales invoice posting with E-Document export and sending (outgoing), and E-Document import into purchase invoices (incoming), through E-Document Core with a custom Contoso XML format and a Contoso network connector. **Knowledge used:** 29 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is the Contoso XML schema (elements, namespaces, required values) for outgoing sales invoices and incoming supplier invoices, and which encoding does Contoso require? _(affects: format-codeunit, reader-codeunit, posting-creates-contoso-e-document, receive-creates-purchase-invoice)_
2. Are only posted sales invoices sent, or also sales credit memos (and service invoices)? This decides the supported types rows and the branches in Create. _(affects: format-codeunit, create-error-sets-export-error)_
3. Which data must be present on the sales invoice for Contoso to accept it, and should a missing value block release and posting (Check) or only fail the export (Create)? _(affects: format-codeunit, check-blocks-posting)_
4. How does the Contoso network authenticate: OAuth2 client credentials, API key or another scheme? What are the token endpoint and scopes? _(affects: network-client-codeunit, credential-codeunit, setup-table)_
5. What is the fixed Contoso host (or host pattern) the configured endpoint must match, and are there separate test and production endpoints? _(affects: network-client-codeunit, setup-table, untrusted-endpoint-rejected)_
6. Does the Contoso network deduplicate a repeated upload of the same invoice, and on which key (for example a client-supplied request ID such as the E-Document SystemId)? _(affects: connector-codeunit, send-http-failure-sets-sending-error)_
7. How does Contoso report delivery (status endpoint per upload ID, list of confirmations) and what states can it report besides delivered, such as rejected? What should a rejection do to the E-Document? _(affects: connector-codeunit, delivery-confirmation-completes)_
8. Must received supplier invoices be acknowledged or marked fetched on the network so they are not downloaded again? _(affects: connector-codeunit)_
9. Which identifiers in the Contoso supplier invoice identify the vendor and the lines (vendor VAT number, GLN, item references, G/L accounts), and should the draft be processed to a purchase invoice automatically or reviewed first? _(affects: reader-codeunit, receive-creates-purchase-invoice)_
10. Which Business Central version and countries does the app target? Secret request URI APIs apply from BC23, SecretText IsolatedStorage overloads from BC24, and the V2 integration interfaces replace the interface obsolete since 26.0. _(affects: connector-codeunit, credential-codeunit, network-client-codeunit)_
11. Should the app create the E-Document Service, its supported types and the workflow on setup, or will the administrator configure them by hand? _(affects: setup-page)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | enumextension | "E-Document Format" (enum 6101, E-Document Core) | Add the "Contoso XML" format value whose Implementation binds interface "E-Document" to the Contoso format codeunit. IEDocResponseProvider has a default implementation and is left out. No event subscription is needed. The app.json declares a dependency on E-Document Core (id e1d97edc-c239-46b4-8d84-6368bdf67c8b). |  | [1] |
| 2 | create | codeunit | Contoso E-Doc. Format (implements "E-Document") | Check: rules that must stop release or posting of a sales invoice that will be sent to Contoso, branched on the processing phase. Create: build the Contoso XML for one posted sales invoice from the mapped SourceDocumentHeader and SourceDocumentLines record refs (never Get the posted invoice again), write it to the Temp Blob through a UTF-8 OutStream, format decimals, dates and booleans with Format(Value, 0, 9), branch on EDocument."Document Type" and log unsupported types with "E-Document Error Helper".LogSimpleErrorMessage; no Commit and no blocking errors expected to stop posting. CreateBatch: implemented, logs an error if batch is unsupported. GetBasicInfoFromReceivedDocument and GetCompleteInfoFromReceivedDocument: V1 import only, left empty because the import runs on V2. |  | [1] [3] [4] [16] [17] |
| 3 | extend | enumextension | "Service Integration" (enum 6151, E-Document Core) | Add the "Contoso Network" value, selected by the "Service Integration V2" field on "E-Document Service". Binds both IDocumentSender and IDocumentReceiver to the connector codeunit, because the enum has no default implementation for either. The obsolete "E-Document Integration" interface and enum 6143 are not used. |  | [2] |
| 4 | create | codeunit | Contoso E-Doc. Connector (implements IDocumentSender, IDocumentReceiver, IDocumentResponseHandler) | Send: read the file with SendContext.GetTempBlob(), POST it to the Contoso network with local request and response variables, store both with SendContext.Http().SetHttpRequestMessage/SetHttpResponseMessage, raise an error when HttpClient.Send returns false (without touching the response) or when the status is not a success. No own log, status update, Commit or retry job. Because Contoso confirms delivery a few minutes after upload, the same codeunit implements IDocumentResponseHandler so the framework sets Pending Response and polls GetResponse from a job queue entry until it returns true. ReceiveDocuments: add one metadata Temp Blob per available supplier invoice. DownloadDocument: fill ReceiveContext.GetTempBlob() and set the name and file format. Authorization uses SecretText headers or SetSecretRequestUri. |  | [2] [15] [14] [10] [18] [19] |
| 5 | extend | enumextension | "E-Doc. Read into Draft" (E-Document Core) | Add a "Contoso XML" value whose Implementation binds IStructuredFormatReader to the Contoso reader codeunit, so the V2 import process can read received Contoso XML into the purchase staging tables. |  | [4] |
| 6 | create | codeunit | Contoso E-Doc. Reader (implements IStructuredFormatReader) | ReadIntoDraft: insert the "E-Document Purchase Header" for the E-Document, parse the received Contoso XML (read through a UTF-8 InStream, numbers and dates parsed with Evaluate(..., 9)) into the standard staging header and "E-Document Purchase Line" fields, and return "E-Doc. Process Draft"::"Purchase Invoice". Core finish step "E-Doc. Create Purchase Invoice" then creates the purchase invoice from the named staging fields. View: show the received document. |  | [4] [16] [17] |
| 7 | create | interface | Contoso Network Client | Seam for the HTTP exchange (upload, delivery status, list and download). The connector depends on this interface variable; production assigns the real HTTP codeunit and tests assign a deterministic double so send, confirmation and receive can be tested without calling the network. |  | [26] |
| 8 | create | codeunit | Contoso Network Http Client (implements Contoso Network Client) | Performs the HTTP calls: validates the configured endpoint host against the expected Contoso base URL with Uri.AreURIsHaveSameHost before any call, authenticates with OAuth2 through the platform OAuth2 codeunit when Contoso supports it, carries the secret as SecretText into HttpHeaders.Add or SetSecretRequestUri, handles a false Send result before touching the response, and checks the status before parsing a body. |  | [13] [11] [10] [15] [14] [5] |
| 9 | create | codeunit | Contoso Credential Mgt. | Stores and reads the Contoso client secret, API key or token in IsolatedStorage with SetEncrypted and the SecretText overloads. Every procedure that touches IsolatedStorage is local or internal; callers get intent-specific procedures, not the secret. |  | [8] [9] [12] |
| 10 | create | table | Contoso E-Doc. Connection Setup | Singleton setup (Primary Key Code[10], blank row) for non-secret connection options. Holds no secret field; secrets live in IsolatedStorage. Table-level DataClassification with field-level overrides where a field stores different data; no ToBeClassified at release. | Primary Key (Code[10]); Endpoint URL (Text[250]): Validated against the expected Contoso host before every call.; Client ID (Text[250]): Only if Contoso uses OAuth2 client credentials; the client secret is not stored here. | [21] [8] [13] [22] [23] [6] |
| 11 | create | page | Contoso E-Doc. Connection Setup (Card) | Card over the singleton setup with InsertAllowed = false, DeleteAllowed = false and an OnOpenPage guard that inserts the blank row. Captures the secret through the credential codeunit at the point of entry. |  | [21] [8] |
| 12 | create | codeunit | Contoso Privacy Notice | Registers a Contoso-owned, stable privacy notice ID through OnRegisterPrivacyNotices. The connector checks GetPrivacyNoticeApprovalState for that ID before sending or receiving, because Send and GetResponse run from job queue entries without UI. |  | [20] [19] |
| 13 | create | permissionset | Contoso E-Doc. building blocks and role set | Non-assignable building blocks (setup tabledata and page; connector, format, reader and client codeunits) composed with IncludedPermissionSets into an assignable role set that lets a non-SUPER user complete setup and run send and receive. No wildcard grants. |  | [24] [25] [6] |

## 3. How the data flows

- **Sales Invoice Header (posted sales invoice)** → **E-Document (outgoing, Contoso service)**: other. Created by E-Document Core on OnAfterPostSalesDoc after the posting commit, only when the bill-to customer's document sending profile uses Extended E-Document Service Flow with an enabled workflow naming the Contoso service and the service supports Sales Invoice outgoing. Deferred when CommitIsSuppressed, PreviewMode or inventory pick posting; then created when the posted document is sent through its sending profile. The extension does not subscribe to OnAfterPostSalesDoc itself. [3] [1] [7]
- **Mapped temporary Sales Invoice Header and lines (record refs)** → **Temp Blob (Contoso XML) in the E-Document log**: other. "E-Doc. Export" applies the service's "E-Doc. Mapping" rules, commits and runs the format's Create inside Codeunit.Run; errors set Export Error. [1] [3] [4]
- **E-Document log blob (SendContext)** → **Contoso e-invoicing network**: other. "E-Doc. Integration Management" loads the blob into SendContext, commits and runs Send in its own error scope, and writes the E-Document log, service status and integration log. Errors set Sending Error, from which the document can be sent again. [2] [18]
- **Contoso delivery confirmation** → **E-Document Service Status (Pending Response to final status)**: other. Because the sender implements IDocumentResponseHandler, status becomes Pending Response and a job queue entry polls GetResponse until it returns true. [2]
- **Contoso e-invoicing network (supplier invoices)** → **E-Document (incoming) with downloaded blob**: other. ReceiveDocuments returns one metadata blob per document; the framework creates each E-Document and calls DownloadDocument; MarkFetched is called only if the receiver implements IReceivedDocumentMarker. [2]
- **Received Contoso XML blob** → **"E-Document Purchase Header" and "E-Document Purchase Line" (staging)**: other. V2 import: the Contoso IStructuredFormatReader (new "E-Doc. Read into Draft" value) fills the staging tables. [4]
- **"E-Document Purchase Header" and "E-Document Purchase Line"** → **Purchase Header and Purchase Line (purchase invoice)**: other. Core finish step "E-Doc. Create Purchase Invoice" copies named staging fields; the purchase header holds the E-Document SystemId in "E-Document Link". Staging extension fields are not copied by Core; none are designed because the request names none. [4]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Privacy Notice" | `OnRegisterPrivacyNotices` | Add the Contoso-owned privacy notice ID, integration name and link to the temporary Privacy Notice record so an admin can approve the data transfer to the Contoso network. | Use a stable, extension-owned notice ID; never a built-in ID such as the Exchange notice. | [20] [19] |

## 5. Setup, permissions and lifecycle

- **setup**: Create (or let the admin create) an "E-Document Service" with "Document Format" = Contoso XML, "Service Integration V2" = Contoso Network and "Import Process" = Version 2.0, and add "E-Doc. Service Supported Type" rows for the outgoing document types (Sales Invoice); Core adds none for a new format value. [1] [2] [4]
- **setup**: Configure the customer document sending profile with "Electronic Document" = Extended E-Document Service Flow and an "Electronic Service Flow" that names an existing, enabled workflow using the Contoso service; without it no E-Document is created and no error is raised. [3]
- **setup**: Open the singleton Contoso connection setup card; enter the endpoint and store credentials in IsolatedStorage (SetEncrypted, SecretText) through the internal credential codeunit; prefer OAuth2 client credentials if Contoso supports it. [21] [8] [9] [11] [12]
- **privacy**: Register the Contoso privacy notice and require admin approval; check GetPrivacyNoticeApprovalState before any send, poll or receive, since these run without UI. [20] [19]
- **privacy**: Classify the setup table at table level, override per field where needed, and resolve every ToBeClassified before release. [22] [23]
- **permissions**: Ship non-assignable building-block permission sets composed into an assignable role set covering setup and send/receive usage without SUPER, with no wildcards. [24] [25]
- **background**: Rely on the framework's job queue work: sending is started from a job queue entry after export, and a job queue entry polls GetResponse for the delivery confirmation. Do not schedule an own retry or polling job. Include a stable request ID (for example the E-Document SystemId) in each upload so a resend after Sending Error can be deduplicated by the network. [3] [2] [18] [5]

## 6. Tests

1. **posting-creates-contoso-e-document** [3] [1] [27] [28] [16] [17]
    - Given A customer whose document sending profile uses Extended E-Document Service Flow with an enabled workflow for the Contoso service, the service with Contoso XML format and Sales Invoice outgoing supported type, full posting-group chain from library codeunits, and a sales invoice
    - When The sales invoice is posted (normal commit)
    - Then An E-Document exists for the posted invoice and its exported blob is Contoso XML whose values come from the posted invoice (amounts and dates in format 9, UTF-8 encoded)
2. **check-blocks-posting** [3] [1]
    - Given The Contoso setup as above and a sales invoice that violates a rule placed in Check
    - When The user releases or posts the invoice
    - Then Release or posting fails with the Check error and no posted invoice exists
3. **create-error-sets-export-error** [1] [3]
    - Given The Contoso setup and a posted document type the format does not support (for example a credit memo, if out of scope)
    - When The E-Document is exported
    - Then The document stays posted, the E-Document shows the logged error and the service status is Export Error
4. **send-success-pending-response** [2] [26]
    - Given An exported Contoso E-Document and a network client double returning a success status on upload
    - When The document is sent
    - Then The service status is Pending Response and the integration log holds the request and response
5. **send-http-failure-sets-sending-error** [2] [14] [15] [26]
    - Given An exported Contoso E-Document and a network client double returning a non-success status, and separately one whose Send returns false
    - When The document is sent
    - Then The service status is Sending Error (never Sent), and the document can be sent again
6. **delivery-confirmation-completes** [2] [26]
    - Given A Contoso E-Document in Pending Response and a network client double that first reports not delivered and then delivered
    - When GetResponse is polled twice
    - Then The first poll leaves Pending Response; the second returns true and the status moves to the confirmed status
7. **receive-creates-purchase-invoice** [2] [4] [26] [28] [17]
    - Given A Contoso service on Import Process Version 2.0 with the Contoso reader, an existing vendor, and a network client double offering one Contoso XML supplier invoice
    - When Documents are received and the import is processed to Processed
    - Then An incoming E-Document exists with the downloaded blob, the staging header and lines hold the parsed values, and a purchase invoice exists whose "E-Document Link" equals the E-Document SystemId with the expected vendor, amounts and dates
8. **no-consent-no-transfer** [19] [26]
    - Given The Contoso privacy notice not approved
    - When A send or receive runs
    - Then No HTTP call reaches the network client double and the run reports an error
9. **untrusted-endpoint-rejected** [13]
    - Given The setup endpoint changed to a host other than the expected Contoso host
    - When A send runs
    - Then The call fails with an error before any HTTP request is issued
10. **non-super-user-can-setup-and-send** [29] [24]
    - Given A test user lowered to the Contoso role permission set with TestPermissions Restrictive
    - When The user opens the setup card and sends an exported E-Document
    - Then Both succeed without SUPER

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined from the request; articles with bc-version [all] apply, and microsoft/knowledge/security/secrettext-with-httpclient.md applies from BC23 only.
- The exact signatures of IDocumentResponseHandler.GetResponse, IStructuredFormatReader members beyond ReadIntoDraft and View, and IReceivedDocumentMarker.MarkFetched are not given in the opened articles; confirm them against the E-Document Core symbols before implementing.
- How a received Contoso E-Document is routed to the new "E-Doc. Read into Draft" value (service or E-Document field) is not described in the opened articles; confirm in the E-Document Core symbols.

## Sources

[1] `microsoft/knowledge/e-documents/add-an-e-document-format-through-the-format-enum.md`: Contoso XML export format: enum value, format codeunit, supported types, Check vs Create.
    - Extend enum "E-Document Format" with a value whose Implementation binds "E-Document"; no event subscription; declare a dependency on E-Document Core.
    - In Create read the mapped SourceDocumentHeader/SourceDocumentLines record refs; do not Get the posted invoice again; do not Commit.
    - Branch on EDocument."Document Type" and log unsupported types with "E-Document Error Helper".LogSimpleErrorMessage; implement CreateBatch even if it only logs an error.
    - Put rules that must stop posting in Check, not Create.
    - Setup or install code must add outgoing document types to "E-Doc. Service Supported Type"; Core adds defaults only for PEPPOL BIS 3.0.
    - Do not build the XML in an own OnAfterPostSalesDoc subscriber and store it in a custom table.
[2] `microsoft/knowledge/e-documents/connect-an-e-document-service-through-the-v2-integration-interfaces.md`: Contoso network connector: send, receive and asynchronous delivery confirmation.
    - Extend enum 6151 "Service Integration" and bind both IDocumentSender and IDocumentReceiver; never use the obsolete "E-Document Integration" interface or enum 6143.
    - Implement IDocumentResponseHandler on the sender codeunit only when the service confirms asynchronously.
    - In Send read SendContext.GetTempBlob(), use local request/response variables, store both via SendContext.Http(), and raise or log an error when Send returns false or the status is not a success; a silent return leaves the document Sent.
    - Do not insert own logs, update "E-Document Service Status" by hand, Commit, or schedule own retry jobs.
    - In DownloadDocument fill ReceiveContext.GetTempBlob() and set the name and file format; MarkFetched runs only if IReceivedDocumentMarker is implemented.
[3] `microsoft/knowledge/e-documents/e-document-creation-runs-after-the-posting-commit.md`: Where validation goes, when the E-Document is created, required setup, and test preconditions.
    - Core creates the E-Document on OnAfterPostSalesDoc after the posting commit; errors in Create leave the invoice posted with Export Error.
    - Every rule that must stop posting goes in Check, using the processing phase.
    - Creation needs a document sending profile with Extended E-Document Service Flow, an enabled workflow using the service, and an outgoing supported type; tests must set all three.
    - Creation is deferred when CommitIsSuppressed, PreviewMode or inventory pick posting; do not expect an E-Document right after such posting.
    - Do not subscribe to OnAfterPostSalesDoc to look for the E-Document and fail when none is found.
[4] `microsoft/knowledge/e-documents/carry-custom-fields-through-e-document-export-and-import.md`: V2 import of supplier invoices through an own IStructuredFormatReader and the staging tables.
    - Import Process starts as Version 2.0; a reader bound to an "E-Doc. Read into Draft" value fills "E-Document Purchase Header" and "E-Document Purchase Line".
    - "E-Doc. Create Purchase Invoice" copies named staging fields only and raises no event; staging extension fields are never copied by Core.
    - V1 events and GetCompleteInfoFromReceivedDocument only run for Version 1.0 services; do not rely on them for a V2 service.
    - The created purchase header holds the E-Document SystemId in "E-Document Link".
[5] `microsoft/knowledge/feature-design/plan-api-exposure-and-background-sync.md`: Planning map for the outbound integration decisions (responses, retries, credentials, consent, exchanged values).
    - Check platform failure and HTTP status before reading the body.
    - Use a stable idempotency key; the external service must deduplicate.
    - OAuth2 where supported, secrets in isolated storage as SecretText, configurable URLs validated.
    - Obtain privacy notice approval before data leaves Business Central.
    - Use culture-independent formats and explicit text encoding for exchanged values.
    - Facts the request leaves open, such as what the external service does with a repeated request, are questions for the requester.
[6] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Planning the connector's own setup table, permissions and classification.
    - A setup is a singleton table with a card page.
    - Ship permission sets for new tables and pages, composed from included sets, without wildcards.
    - Classify at table level where possible and resolve every ToBeClassified.
    - A decision the request does not settle is a question for the requester.
[7] `microsoft/knowledge/sales-purchase/onafterpostsalesdoc-runs-after-the-posting-commit.md`: Confirms the extension must not add its own OnAfterPostSalesDoc external-call subscriber.
    - OnAfterPostSalesDoc runs after the posting commit; errors there do not undo posting.
    - Do not call external services directly from the subscriber.
[8] `microsoft/knowledge/security/secrets-isolated-storage.md`: Storage location of Contoso credentials.
    - Persist every credential in IsolatedStorage, never in a table Text field.
    - Prefer SetEncrypted when the value fits its length limit; use SecretText overloads on BC24 and later.
[9] `microsoft/knowledge/security/secrettext-for-credentials.md`: Type of credential-carrying variables and parameters.
    - Declare credential-carrying parameters and variables as SecretText from retrieval to the HTTP sink; never round-trip through Text.
    - On BC24 and later use the SecretText overload of IsolatedStorage.Get.
[10] `microsoft/knowledge/security/secrettext-with-httpclient.md`: Putting the Contoso credential on the HTTP request (applies from BC23).
    - Use HttpRequestMessage.SetSecretRequestUri for a secret URI and send with HttpClient.Send.
    - Add authorization headers as SecretText; do not interpolate a credential into Text.
[11] `microsoft/knowledge/security/prefer-oauth2-over-api-keys-for-external-http-calls.md`: Authentication choice for the Contoso network.
    - When the partner supports OAuth, use the platform OAuth2 codeunit rather than hand-rolled token acquisition.
    - Carry tokens and secrets as SecretText in IsolatedStorage and refresh tokens before expiry.
[12] `microsoft/knowledge/security/isolatedstorage-access-must-be-local-or-internal.md`: Visibility of the credential codeunit procedures.
    - Every procedure that touches IsolatedStorage is local or internal; expose intent-specific procedures, not the secret.
[13] `microsoft/knowledge/security/validate-user-configurable-urls.md`: Guard on the configurable Contoso endpoint.
    - Before any HttpClient call whose URL comes from a table field, validate it with Uri.AreURIsHaveSameHost against a hard-coded expected base (or IsValidURIPattern) and Error when it fails.
[14] `microsoft/knowledge/web-services/check-http-status-before-consuming-response-body.md`: Response handling for upload, status polling, list and download calls.
    - After handling platform failure, check IsSuccessStatusCode or the expected status before treating the body as a success payload.
    - A non-success body may be read for diagnostics only, never on the success parsing path.
[15] `microsoft/knowledge/web-services/handle-httpclient-platform-failure-before-response-access.md`: Transport failure handling in the HTTP client.
    - When the Boolean result of Send is false, stop without reading status, headers or content.
    - Omitting the Boolean to let the runtime raise the error is also valid.
[16] `microsoft/knowledge/web-services/set-text-encoding-on-streams-exchanged-externally.md`: Encoding of the Contoso XML written in Create and read in the reader.
    - Pass TextEncoding::UTF8 (or the encoding Contoso requires) on streams that perform encoding-sensitive text writes or reads; the default is MSDos.
[17] `microsoft/knowledge/web-services/format-exchanged-values-with-standard-format-9.md`: Formatting and parsing of amounts, dates and booleans in the Contoso XML.
    - Use Format(Value, 0, 9) for machine-readable text and Evaluate(Variable, Text, 9) to parse it.
    - Format 9 gives ordinals for Enum and Option; map names explicitly when the contract exchanges names.
[18] `microsoft/knowledge/performance/job-queue-external-effects-must-be-idempotent.md`: Resend after Sending Error must not create duplicate invoices on the network.
    - Use a stable request ID that exists before the job runs and send it with every attempt.
    - The external service must enforce uniqueness on that ID.
[19] `microsoft/knowledge/privacy/privacy-notice-consent-for-external-data-transfer.md`: Consent gate before sending invoices to or pulling invoices from Contoso.
    - Use an own stable notice ID; consent for another service does not authorize this one.
    - Call ConfirmPrivacyNoticeApproval outside a write transaction, or GetPrivacyNoticeApprovalState when the flow must not show UI; no path issues the request without approval.
[20] `microsoft/knowledge/privacy/register-integration-in-privacy-notice-registrations.md`: Registering the Contoso privacy notice.
    - Register an extension-owned stable ID through OnRegisterPrivacyNotices or CreatePrivacyNotice during setup; "Privacy Notice Registrations" is not the registration API for a custom service.
[21] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Shape of the Contoso connection setup.
    - Primary Key Code[10] as sole key with a blank row.
    - Card page with InsertAllowed = false, DeleteAllowed = false and an open-time guard inserting the row.
[22] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification of the setup table fields.
    - A table-level DataClassification is the default for Normal fields in that table; override per field only where the data differs.
[23] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of the new table.
    - No field may ship as ToBeClassified.
[24] `microsoft/knowledge/appsource/permission-sets-cover-setup-and-usage-without-super.md`: Coverage of setup and usage by the shipped permission sets.
    - Assignable role sets composed from focused non-assignable sets must cover every setup and usage path without SUPER, with minimum grants.
[25] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Structure of the permission sets.
    - Mark building blocks Assignable = false and compose assignable role sets with IncludedPermissionSets.
[26] `microsoft/knowledge/interfaces/assign-codeunit-to-interface-for-testability.md`: Test seam for the Contoso HTTP exchange.
    - Depend on an Interface variable and inject the implementation; tests inject a deterministic double instead of performing external calls.
[27] `microsoft/knowledge/testing/given-blocks-must-cover-full-precondition-chain.md`: Preconditions for the posting test.
    - Set up the full posting-group chain and every setup record the posting path reads in GIVEN.
[28] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for customers, vendors and sales documents.
    - Create fixtures with library codeunits (LibrarySales, LibraryPurchase, LibraryRandom), parents first, validating foreign keys.
[29] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: Non-SUPER permission test.
    - Use TestPermissions Restrictive and lower the test user with Permissions Mock or Library - Lower Permissions before the protected operation.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
