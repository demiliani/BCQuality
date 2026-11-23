# Feature design

> When a sales invoice is posted, send the invoice number to our external delivery platform so it can schedule the truck.

**Result:** Complete design. **Business process:** Sales posting (sales invoice and sales order invoicing via Sales-Post), with follow-up outbound integration to an external delivery platform. **Knowledge used:** 20 BCQuality articles.

**Why:** Design covers every chosen stage with cited knowledge; the delivery platform's API contract and several business rules are left as open questions for a person to answer before implementation.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is the delivery platform's endpoint, HTTP method and payload shape for scheduling a truck? Is only the invoice number sent, or also ship-to address, shipment date, weight, etc.? _(affects: delivery-http-client, delivery-outbox, delivery-platform-setup)_
2. Which authentication does the platform support (OAuth2 client credentials, API key, other)? _(affects: delivery-http-client, delivery-platform-setup-card)_
3. Does the platform deduplicate repeated requests, either on an idempotency key we send or on the invoice number as a business key? If not, retries can schedule duplicate trucks. _(affects: delivery-outbox-worker, worker-success-deletes-row)_
4. Should invoices produced by posting a sales order (Ship and Invoice / Invoice) also be sent, or only standalone sales invoices? Should every invoice be sent, or only some (e.g. by shipment method, location or customer)? _(affects: delivery-posting-subscriber, posting-invoice-queues-outbox-row)_
5. When a posted invoice is corrected or cancelled (credit memo), must the platform be told to cancel the truck? _(affects: delivery-posting-subscriber, delivery-outbox)_
6. How quickly must the platform be notified after posting? This determines the recurring job queue entry's interval and retry settings. _(affects: delivery-outbox-worker)_
7. Who must see failed deliveries to the platform, and is the job queue log enough or is a status page needed? _(affects: delivery-outbox-worker, delivery-outbox)_
8. Is this a per-tenant extension or an AppSource app? AppSource permission-set requirements apply only to the latter. _(affects: delivery-permissions)_
9. What is the target BC version and country set? The SecretText guidance applies from BC 23/24 onward. _(affects: delivery-http-client, delivery-platform-setup-card)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Delivery Platform Setup | Singleton per-company setup for the integration: enabled flag and service base URL. Credentials are not stored here. | Primary Key (Code[10]): Sole key, left blank (singleton).; Enabled (Boolean): Whether posted invoices are queued for the delivery platform.; Service URL (Text[250]): Validated against a hard-coded expected host or pattern before every HTTP call. | [15] [12] [9] |
| 2 | create | page | Delivery Platform Setup | Card page for the setup: InsertAllowed = false, DeleteAllowed = false, inserts the blank row on open; actions to enter the credential (written to IsolatedStorage) and to confirm the privacy notice. |  | [15] [9] [14] |
| 3 | create | table | Delivery Notification Outbox | Work item inserted in the same transaction context as the posting follow-up; committed rows are processed by the background worker and deleted only after the external call and local updates succeed. | Entry No. (Integer): AutoIncrement primary key.; Sales Invoice No. (Code[20]): Posted invoice number from SalesInvHdrNo; the value sent to the platform.; SystemId (Guid): Platform field; sent as the stable idempotency key on every attempt. | [3] [4] |
| 4 | create | codeunit | Delivery Notification Posting Subscriber | Subscribes to Sales-Post OnAfterPostSalesDoc; inserts an outbox row for the posted invoice number. Performs no HTTP call, no Commit, no Error on integration problems. |  | [1] [3] |
| 5 | create | codeunit | Delivery Notification Worker | Job queue entry point (TableNo = Job Queue Entry), non-interactive: checks setup and privacy approval state, validates the URL, sends each outbox row with its idempotency key, checks transport failure and HTTP status, deletes the row on success, propagates failures to the job queue. |  | [3] [4] [5] [6] [7] [8] [14] [12] [16] |
| 6 | create | interface | IDelivery Platform Client | Seam for the outbound call so the worker can be tested with a deterministic test double instead of the real HTTP client. |  | [19] |
| 7 | create | codeunit | Delivery Platform Http Client | Production implementation of the interface: builds the request with SecretText credentials (secret-aware header/URI APIs), sends it, and returns the outcome. |  | [11] [10] [9] [13] [8] [7] |
| 8 | create | permissionset | Delivery Platform | Grants tabledata and execute permissions on the new setup table, outbox table, setup page and codeunits for users who post invoices, administer setup and run the job queue. |  | [2] [20] |

## 3. How the data flows

- **Sales-Post OnAfterPostSalesDoc (SalesInvHdrNo)** → **Delivery Notification Outbox.Sales Invoice No.**: copied in an event subscriber. Runs after the posting commit (or inside the caller's transaction when CommitIsSuppressed). Skipped when PreviewMode is true or SalesInvHdrNo is blank. [1] [3]
- **Delivery Notification Outbox (committed row)** → **External delivery platform request (invoice number + idempotency key)**: other. Recurring job queue entry reads committed outbox rows and POSTs outside any open write transaction; row deleted only after success. [3] [4] [7] [8]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Sales-Post" | `OnAfterPostSalesDoc` | Record the posted invoice number as outbox work for the delivery platform. | Exit when PreviewMode is true, before any side effect. · Exit when SalesInvHdrNo is blank (shipment-only, return or credit memo postings). · Exit when the integration is not enabled in setup. · Do not call Commit(); when CommitIsSuppressed is true the caller owns the transaction. · Do not call HttpClient or raise errors expecting posting to roll back; the posting is already committed. | [1] [3] |

## 5. Setup, permissions and lifecycle

- **setup**: Provide the singleton setup card; the worker TestFields Service URL (and the credential presence) once Enabled is true instead of silently skipping. [15] [16]
- **setup**: Store the platform credential only in IsolatedStorage, carried as SecretText; prefer OAuth2 client credentials via the OAuth2 codeunit if the platform supports it. [9] [10] [11] [13]
- **privacy**: Register a custom privacy notice with its own stable ID (CreatePrivacyNotice or OnRegisterPrivacyNotices); confirm approval from the setup page with ConfirmPrivacyNoticeApproval; the background worker checks GetPrivacyNoticeApprovalState and must not send without approval. [14]
- **background**: Create a recurring job queue entry running the worker codeunit; the handler is non-interactive and lets failures propagate so the job queue log and retries reflect them. [3] [5] [6] [4]
- **permissions**: Ship the permission set covering setup and usage (posting users need insert on the outbox table; the job queue user needs read/delete on outbox and read on setup and posted invoices). [2] [20]

## 6. Tests

1. **posting-invoice-queues-outbox-row** [1] [17] [18]
    - Given Integration enabled and a released sales invoice created with LibrarySales for a customer and item created by the libraries
    - When The invoice is posted
    - Then Exactly one outbox row exists whose Sales Invoice No. equals the posted Sales Invoice Header No.
2. **preview-does-not-queue** [1] [17]
    - Given Integration enabled and a sales invoice created with LibrarySales
    - When Posting preview is run
    - Then No outbox row exists for the document
3. **shipment-only-does-not-queue** [1] [17]
    - Given Integration enabled and a sales order created with LibrarySales
    - When The order is posted with Ship only
    - Then No outbox row is created because SalesInvHdrNo is blank
4. **worker-success-deletes-row** [19] [4] [18]
    - Given A committed outbox row and the worker injected with a test-double client returning success
    - When The worker runs
    - Then The double received the invoice number and the outbox row SystemId as idempotency key, and the row is deleted
5. **worker-non-success-status-fails** [7] [6] [19]
    - Given A committed outbox row and a test-double client returning a non-success HTTP status
    - When The worker runs
    - Then An error propagates out of the worker and the outbox row still exists
6. **worker-transport-failure-fails** [8] [6] [19]
    - Given A committed outbox row and a test-double client reporting a transport failure
    - When The worker runs
    - Then An error propagates, the response is not read, and the outbox row still exists
7. **worker-blank-service-url-errors** [16]
    - Given Integration enabled and Service URL blank
    - When The worker runs
    - Then A TestField error on Service URL is raised and nothing is sent
8. **worker-invalid-host-errors** [12]
    - Given Service URL set to a host other than the expected platform host
    - When The worker runs
    - Then An error is raised before any request is sent
9. **worker-privacy-not-approved-errors** [14] [5]
    - Given A committed outbox row and the custom privacy notice not approved
    - When The worker runs
    - Then No request is sent and the worker fails without showing UI

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Context dimensions bc-version, countries and application-area were not supplied and no repository was available; all selected articles declare [all]/[w1] except secrettext-for-credentials and secrettext-with-httpclient ([23..]), which are conditionally applicable pending the target version.
- Not covered by BCQuality knowledge: reconciling posted invoices that have no outbox row because the subscriber itself failed after the posting commit; the design relies on the agent's judgment that the subscriber does only a minimal insert.
- Not covered by BCQuality knowledge: the delivery platform's request format and whether it enforces idempotency; the idempotency article requires the external service to enforce uniqueness, which cannot be confirmed from the request.

## Sources

[1] `microsoft/knowledge/sales-purchase/onafterpostsalesdoc-runs-after-the-posting-commit.md`: Choice of event, subscriber guards and moving the external call to background processing.
    - OnAfterPostSalesDoc runs after the posting commit; a subscriber error does not undo the posting.
    - Exit on PreviewMode before any external side effect.
    - Do not call Commit() in the subscriber; when CommitIsSuppressed is true the caller owns the transaction.
    - Move calls to external services to a background job queue entry that records its own result and can be retried.
    - Use the posted document numbers passed by the event, such as SalesInvHdrNo.
[2] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Stage map for sales posting (follow-up integration stage) and the requirement to plan permission set entries and posting tests.
    - Follow-up work after posting goes through OnAfterPostSalesDoc: guard preview and do not rely on rollback.
    - Name permission set entries for any new objects and a test that posts a document and reads the value back, using test libraries.
[3] `microsoft/knowledge/performance/httpclient-inside-write-transaction-holds-locks.md`: Outbox pattern: no HTTP inside a write transaction; committed work processed by a recurring job queue entry.
    - Do not call HttpClient after a write on the same execution path, especially in posting or subscribers.
    - Insert an outbox work item in the same transaction as the change and process committed rows with a recurring job queue entry.
    - Perform HTTP before deleting the outbox item so no write lock is held during the call.
    - Do not use Commit() as a general remedy.
[4] `microsoft/knowledge/performance/job-queue-external-effects-must-be-idempotent.md`: Idempotency key and delete-after-success rule for the worker.
    - Send a stable request ID that exists before processing (e.g. outbox SystemId as idempotencyKey) on every attempt; the external service must enforce uniqueness on it.
    - Delete the outbox row only after the external call and all required local updates succeed.
    - A Processed flag set after the external call does not close the failure window.
[5] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Worker must be non-interactive.
    - No Confirm, Page.RunModal, Report.RunModal, Hyperlink, upload or download in the job queue handler.
    - Do not use Message as the only result notification; persist status or let failures propagate.
[6] `microsoft/knowledge/performance/job-queue-handlers-must-propagate-failures.md`: Worker error handling.
    - Let an error that invalidates the run propagate out of the job queue entry point.
    - Do not swallow a failed TryFunction/Boolean result and return normally.
    - Add diagnostic context only when it does not expose sensitive data.
[7] `microsoft/knowledge/web-services/check-http-status-before-consuming-response-body.md`: Response handling in the HTTP client.
    - After handling transport failure, check IsSuccessStatusCode() or the expected status before interpreting the body as success.
    - An error body must not enter the success parsing path.
[8] `microsoft/knowledge/web-services/handle-httpclient-platform-failure-before-response-access.md`: Transport-failure handling in the HTTP client.
    - When the Boolean return is captured and false, stop and do not read status, headers or content.
    - Omitting the Boolean for fail-fast runtime propagation is also valid.
[9] `microsoft/knowledge/security/secrets-isolated-storage.md`: Credential storage location.
    - Persist credentials in IsolatedStorage, never in a table Text field, including hidden setup tables.
    - Prefer SetEncrypted when the value fits its length limit; choose a DataScope matching the credential's lifetime.
[10] `microsoft/knowledge/security/secrettext-for-credentials.md`: Credential variable types.
    - Carry credentials as SecretText from retrieval to consumption; never round-trip through Text.
    - On BC 24 and later use the SecretText overload of IsolatedStorage.Get.
[11] `microsoft/knowledge/security/secrettext-with-httpclient.md`: Sending credentials over HTTP.
    - Use HttpRequestMessage.SetSecretRequestUri for secret URIs and send with HttpClient.Send.
    - Add authorization headers as SecretText; do not interpolate secrets with StrSubstNo or concatenation.
[12] `microsoft/knowledge/security/validate-user-configurable-urls.md`: Guarding the configurable Service URL.
    - Before any HttpClient call whose URL came from a table field, validate it with Uri.AreURIsHaveSameHost against a hard-coded expected base or Uri.IsValidURIPattern against a fixed pattern.
    - Fail the call with Error when validation returns false.
[13] `microsoft/knowledge/security/prefer-oauth2-over-api-keys-for-external-http-calls.md`: Authentication scheme choice.
    - When the partner supports OAuth, use the platform OAuth2 codeunit rather than hand-rolled token acquisition.
    - Carry tokens and secrets as SecretText, persist only in IsolatedStorage, refresh proactively before expiry.
[14] `microsoft/knowledge/privacy/privacy-notice-consent-for-external-data-transfer.md`: Consent gate before sending data externally.
    - Use a custom privacy notice with its own stable ID; do not borrow a built-in service's notice.
    - Call ConfirmPrivacyNoticeApproval outside a write transaction, or GetPrivacyNoticeApprovalState when no UI may be shown.
    - No path may issue the request without approval.
[15] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Setup table and card design.
    - Primary Key Code[10] is the sole key with a blank value.
    - Card page with InsertAllowed = false, DeleteAllowed = false and an open-time guard that inserts the blank row if missing.
[16] `microsoft/knowledge/data-modeling/testfield-required-setup-field.md`: Guarding required setup values in the worker.
    - Once a setup field is required for correct behavior, TestField it before use instead of falling back to a default.
    - Write a test that blanks the field and asserts the error.
[17] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Posting test fixtures.
    - Create customers, items and sales documents with LibrarySales/LibraryInventory and LibraryRandom, not hand-rolled Init/Insert.
    - Create parents before dependent records and Validate foreign keys.
[18] `microsoft/knowledge/testing/transactionmodel-attribute-governs-test-transactions.md`: Transaction model for posting and job queue tests.
    - Do not declare AutoRollback on tests whose code under test calls Commit (posting routines, job queue handlers, integration flows); use AutoCommit and exercise the commit path.
    - Pair suite-wide AutoCommit reliance with a TestIsolation-enabled test runner.
[19] `microsoft/knowledge/interfaces/assign-codeunit-to-interface-for-testability.md`: Test seam for the outbound HTTP call.
    - Declare the dependency as an Interface variable and inject the implementation; tests inject a deterministic test double.
    - Do not hardwire a concrete codeunit that performs external calls.
[20] `microsoft/knowledge/appsource/permission-sets-cover-setup-and-usage-without-super.md`: Permission set completeness (binding only if the app is distributed through AppSource).
    - Cover setup and normal usage through permission sets without requiring SUPER.
    - Grant the minimum required operations; no wildcards for completeness.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
