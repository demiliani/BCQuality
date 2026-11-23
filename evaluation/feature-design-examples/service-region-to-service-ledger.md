# Feature design

> Service orders and service contracts need a Region Code. Contract invoices must take it from the contract. The code must appear on posted service invoices and on all service ledger entries, including those from credit memos, and after a service invoice is posted our field-planning system must be notified.

**Result:** Complete design. **Business process:** Service management: service orders, service contract invoicing and service posting (Service-Post, Serv-Documents Mgt., ServLedgEntries-Post), plus outbound integration after posting. **Knowledge used:** 29 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Which table does Region Code relate to (an existing table such as a territory or country/region table, or a new Region table)? Its key type and length fix the field type on every table. _(affects: service-contract-header-ext, service-header-ext, service-invoice-header-ext, service-ledger-entry-ext)_
2. Where does Region Code come from on service orders, standalone service invoices and service credit memos: manual entry only, or a default from the customer, ship-to address or service item? _(affects: service-header-ext, service-order-page-ext)_
3. Must Region Code also appear on posted service shipments and posted service credit memos (Service Shipment Header, Service Cr.Memo Header) and on posted lines? _(affects: service-invoice-header-ext)_
4. Does warranty analysis need Region Code on Warranty Ledger Entry as well? _(affects: service-ledger-entry-ext, service-region-posting)_
5. Are there service ledger entries that must carry Region Code but are created outside ServLedgEntries-Post posting (for example during contract invoice creation)? The opened knowledge covers only the four ServLedgEntries-Post insert paths. _(affects: service-region-posting, credit-memo-ledger-entries-carry-region)_
6. Is Region Code needed as a native column on service ledger lists and read on most accesses, or could it live in a related table keyed by Entry No.? _(affects: service-ledger-entry-ext, service-ledger-entries-page-ext)_
7. How is the field-planning system notified: HTTP push from Business Central (endpoint, payload, authentication, OAuth support) or does it pull through an API? Does it deduplicate on an idempotency key? _(affects: field-planning-notif-sender, field-planning-setup, field-planning-outbox)_
8. How soon after posting must the notification arrive (job queue recurrence), and does it apply to every posted service invoice, including contract invoices, or only some? _(affects: field-planning-notif-posting, field-planning-notif-sender)_
9. Which data does the notification send (invoice number only, or customer and address data)? This sets the privacy notice text and data classification. _(affects: field-planning-privacy-notice, field-planning-outbox)_
10. Must existing service contracts and open service documents get a Region Code on upgrade, or stay blank? _(affects: service-contract-header-ext, service-header-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Service Contract Header | Holds the Region Code on service contracts so contract invoices can take it from the contract. | Region Code (Code[n], n equal to the key length of the table Region Code relates to (see open question region-code-source-table)): TableRelation to the region table; same type and exact length as the related key. Explicit DataClassification on the field. | [1] [6] [22] [23] |
| 2 | extend | tableextension | Service Header | Holds the Region Code on service orders, service invoices (including contract invoices) and service credit memos; it is the source for posted invoices and every service ledger entry. | Region Code (Code[n], n equal to the key length of the table Region Code relates to (see open question region-code-source-table)): Same field number, name, type and length as on Service Invoice Header. TableRelation sized to the related key. Explicit DataClassification. | [2] [3] [5] [6] [22] [23] |
| 3 | extend | tableextension | Service Invoice Header | Shows the Region Code on posted service invoices; filled by the standard TransferFields from Service Header, so no subscriber is needed. | Region Code (Code[n], n equal to the key length of the table Region Code relates to (see open question region-code-source-table)): Same field number, name, type and length as on Service Header. Editable = false. Explicit DataClassification. | [2] [3] [5] [22] |
| 4 | extend | tableextension | Service Ledger Entry | Stores the Region Code on every service ledger entry. A stored field is chosen over a related table keyed by Entry No. because the request requires the code on all entries; the related-table alternative applies to optional or sparse attributes on hot ledgers (BC23 and later) and is kept as an open question. | Region Code (Code[n], n equal to the key length of the table Region Code relates to (see open question region-code-source-table)): Filled before insert on all four ServLedgEntries-Post insert paths. Explicit DataClassification. | [1] [7] [22] |
| 5 | create | codeunit | Service Region Posting | Event subscribers that copy the Region Code from the service contract to the contract invoice header and from the service header to each service ledger entry insert path. |  | [1] |
| 6 | create | table | Field Planning Notif. Outbox | Outbox row per posted service invoice, inserted in the posting follow-up and deleted by the job queue worker only after the notification succeeded. Its SystemId is the idempotency key sent to the field-planning system. | Entry No. (Integer): AutoIncrement primary key.; Service Invoice No. (Code[20]): Posted service invoice number passed by OnAfterPostServiceDoc. | [11] [10] [8] [22] [23] |
| 7 | create | table | Field Planning Setup | Singleton setup holding the field-planning endpoint URL and options; credentials are not stored in it. | Primary Key (Code[10]): Sole key, blank value.; Endpoint URL (Text): Validated against a fixed expected host or pattern before every call. | [27] [8] [21] [18] [22] |
| 8 | create | page | Field Planning Setup | Card page for the singleton setup: InsertAllowed = false, DeleteAllowed = false, inserts the blank row on open; credential entry writes to IsolatedStorage, not to a field. |  | [27] [18] [26] |
| 9 | create | codeunit | Field Planning Notif. Posting | Subscriber to Service-Post OnAfterPostServiceDoc that inserts an outbox row when a service invoice was posted. No HTTP call, no Commit, no PreviewMode parameter. |  | [2] [4] [10] |
| 10 | create | codeunit | Field Planning Notif. Sender | Job queue handler (TableNo = Job Queue Entry) that sends each committed outbox row to the field-planning system with the row SystemId as idempotency key, checks transport failure and HTTP status, and deletes the row only after success. Non-interactive; failures propagate to the job queue. |  | [10] [11] [12] [13] [14] [15] [16] [21] [18] [19] [20] [9] |
| 11 | create | codeunit | Field Planning Privacy Notice | Registers a dedicated privacy notice ID for the field-planning integration through OnRegisterPrivacyNotices; the sender checks that same ID. |  | [17] [16] |
| 12 | extend | pageextension | Service Order | Lets users enter the Region Code on service orders. |  | [26] |
| 13 | extend | pageextension | Service Contract | Lets users enter the Region Code on service contracts. |  | [26] |
| 14 | extend | pageextension | Posted Service Invoice | Shows the Region Code on posted service invoices (read-only). |  | [26] |
| 15 | extend | pageextension | Service Ledger Entries | Shows the Region Code as a column on service ledger entries. |  | [26] [7] |
| 16 | create | permissionset | Service Region + Field Planning | Non-assignable building block listing each new table, page and codeunit explicitly (no wildcards), included by an assignable role-shaped set. |  | [24] [25] [8] |

## 3. How the data flows

- **User** → **Service Contract Header.Region Code**: entered by the user. Entered on the Service Contract page. [1]
- **User** → **Service Header.Region Code (service order, invoice, credit memo)**: entered by the user. Entered on the service document page; any default source is an open question. [2]
- **Service Contract Header.Region Code** → **Service Header.Region Code (contract invoice)**: copied in an event subscriber. ServContractManagement OnBeforeServHeaderModify in CreateServHeader. [1]
- **Service Header.Region Code** → **Service Invoice Header.Region Code**: standard TransferFields copy. Serv-Documents Mgt. TransferFields into a temporary record, copied to the real table in Finalize; requires the same field number, type and length. [2] [3] [5]
- **Service Header.Region Code** → **Service Ledger Entry.Region Code (usage)**: copied in an event subscriber. OnBeforeServLedgerEntryInsert. [1]
- **Service Header.Region Code** → **Service Ledger Entry.Region Code (sale)**: copied in an event subscriber. OnBeforeServLedgerEntrySaleInsert; covers contract invoices. [1]
- **Service Header.Region Code** → **Service Ledger Entry.Region Code (credit memo)**: copied in an event subscriber. OnInsertServLedgEntryCrMemoOnBeforeServLedgEntryInsert. [1]
- **Service Header.Region Code** → **Service Ledger Entry.Region Code (credit memo usage)**: copied in an event subscriber. OnInsertServLedgerEntryCrMUsageOnBeforeServLedgEntryInsert. [1]
- **OnAfterPostServiceDoc ServInvoiceNo** → **Field Planning Notif. Outbox**: copied in an event subscriber. Row inserted only when ServInvoiceNo is not blank. [2] [4] [10]
- **Field Planning Notif. Outbox** → **Field-planning system**: other. Recurring job queue entry sends committed rows over HTTP with SystemId as idempotency key, then deletes the row. [10] [11] [9]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit ServContractManagement | `OnBeforeServHeaderModify(var ServiceHeader; ServiceContractHeader)` | Copy Region Code from the contract to the contract invoice header before CreateServHeader modifies it. |  | [1] |
| Codeunit ServLedgEntries-Post | `OnBeforeServLedgerEntryInsert(var ServiceLedgerEntry; ServiceLine; ServiceItemLine; ServiceHeader)` | Set Region Code on usage service ledger entries. | Assign only; do not Modify posted entries afterwards. | [1] |
| Codeunit ServLedgEntries-Post | `OnBeforeServLedgerEntrySaleInsert(var ServiceLedgerEntry; ServiceLine; ServiceItemLine; ServiceHeader)` | Set Region Code on sale service ledger entries created on invoicing. | Assign only; do not Modify posted entries afterwards. | [1] |
| Codeunit ServLedgEntries-Post | `OnInsertServLedgEntryCrMemoOnBeforeServLedgEntryInsert(var ServiceLedgerEntry; ServiceHeader; ServiceLine)` | Set Region Code on credit memo service ledger entries. | Parameter order differs from the usage and sale events; write the signature for this event. | [1] |
| Codeunit ServLedgEntries-Post | `OnInsertServLedgerEntryCrMUsageOnBeforeServLedgEntryInsert(var ServiceLedgerEntry; ServiceHeader; ServiceLine)` | Set Region Code on credit memo usage service ledger entries. | Parameter order differs from the usage and sale events; write the signature for this event. | [1] |
| Codeunit Service-Post | `OnAfterPostServiceDoc(var ServiceHeader; ServShipmentNo; ServInvoiceNo; ServCrMemoNo; var ServDocumentsMgt; CommitIsSuppressed; PassedShip; PassedConsume; PassedInvoice; WhseShip; Invoice)` | Queue a field-planning notification for the posted service invoice. | Exit when ServInvoiceNo is blank. · No PreviewMode parameter: the event is not raised during posting preview. · Do not call Commit(); never when CommitIsSuppressed is true. · No HTTP call in the subscriber; insert an outbox row only. · Do not raise errors expecting posting to roll back. | [2] [4] [10] |
| Codeunit Privacy Notice | `OnRegisterPrivacyNotices` | Register the dedicated field-planning privacy notice ID. |  | [17] |

## 5. Setup, permissions and lifecycle

- **privacy**: Give every field added by the table extensions an explicit DataClassification, classify the new tables at table level where it fits, and leave no ToBeClassified. [22] [23]
- **privacy**: Register a dedicated privacy notice for the field-planning integration and check approval for that ID before any data is sent; the job queue path checks the state without UI. [17] [16] [9]
- **setup**: Field Planning Setup singleton with card page holding the endpoint URL; validate the URL against a fixed expected host or pattern before each call. [27] [21] [8]
- **setup**: Store credentials only in IsolatedStorage and carry them as SecretText (BC23 and later per the article); use the OAuth2 codeunit when the field-planning system supports OAuth. [18] [19] [20]
- **background**: Recurring job queue entry running Field Planning Notif. Sender over committed outbox rows; non-interactive, errors propagate, row deleted only after success. [10] [11] [12] [13] [9]
- **permissions**: Non-assignable building-block permission set for the new tables, pages and codeunits with explicit entries and least letters, included by an assignable set. [24] [25] [8]

## 6. Tests

1. **service-order-region-reaches-invoice-and-ledger** [2] [1] [28] [29]
    - Given A service order with Region Code set, created with the test Library codeunits and random values.
    - When The order is posted as shipped and invoiced.
    - Then Service Invoice Header and the usage and sale Service Ledger Entries carry the same Region Code.
2. **contract-invoice-takes-region-from-contract** [1] [2] [28] [29]
    - Given A signed service contract with Region Code set.
    - When Contract invoices are created and the resulting service invoice is posted.
    - Then The created Service Header, the Service Invoice Header and the sale Service Ledger Entries carry the contract's Region Code.
3. **credit-memo-ledger-entries-carry-region** [1] [28] [29]
    - Given A service credit memo with Region Code set and lines producing credit memo and credit memo usage entries.
    - When The credit memo is posted.
    - Then Every Service Ledger Entry created by the posting carries the Region Code.
4. **invoice-posting-queues-notification** [2] [4] [28] [29]
    - Given A service order with Region Code set.
    - When The order is posted with invoice.
    - Then One Field Planning Notif. Outbox row exists with the posted invoice number.
5. **ship-only-posting-queues-nothing** [2] [29]
    - Given A service order.
    - When The order is posted as ship only.
    - Then No outbox row is created.
6. **preview-posting-queues-nothing** [2] [29]
    - Given A service order ready to invoice.
    - When Posting preview is run.
    - Then No outbox row exists afterwards.
7. **sender-deletes-row-only-after-success** [11] [15] [29]
    - Given An outbox row, approved privacy notice and a mocked endpoint returning success.
    - When The job queue handler runs.
    - Then The request carries the row SystemId as idempotency key and the row is deleted.
8. **sender-propagates-non-success-status** [13] [15] [14] [29]
    - Given An outbox row and an endpoint returning a non-success HTTP status.
    - When The job queue handler runs.
    - Then The handler ends with an error, the row remains, and the response body is not parsed as a success payload.
9. **sender-blocks-without-consent** [16] [29]
    - Given An outbox row and the field-planning privacy notice not approved.
    - When The job queue handler runs.
    - Then No request is sent and the row remains.
10. **sender-rejects-unexpected-endpoint-host** [21] [29]
    - Given Field Planning Setup with an endpoint URL whose host does not match the expected host or pattern.
    - When The job queue handler runs.
    - Then The call fails with an error before any request is sent.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area were not supplied; performance/prefer-related-table-over-extension-on-hot-ledgers and security/secrettext-for-credentials apply from BC23 and style/tooltip-required-on-page-fields inheritance from BC24 (runtime 13.0).
- The field-planning system's interface (protocol, endpoint, payload, authentication) is not covered by BCQuality knowledge; the sender design rests on the outbound guidance and must be confirmed against the answer to field-planning-interface.

## Sources

[1] `microsoft/knowledge/service/carry-service-fields-to-service-and-warranty-ledger-entries.md`: Service ledger entry insert paths and contract invoice header event.
    - Subscribe to every ServLedgEntries-Post insert event whose entry type is needed; all service ledger entries need all four subscribers.
    - Parameter order differs between the events; a subscriber written for one does not match another.
    - Copy a contract value to the invoice header in ServContractManagement OnBeforeServHeaderModify.
    - Add the field to Warranty Ledger Entry and subscribe to OnBeforeWarrantyLedgerEntryInsert only when warranty analysis needs it.
    - Do not find service ledger entries after posting and Modify them.
[2] `microsoft/knowledge/service/mirror-service-fields-and-follow-up-after-service-posting.md`: Posted service document mirroring and follow-up after service posting.
    - Same field number, name, type and length on Service Header and each posted table the plan needs; no subscriber for that hop.
    - Posted documents exist only after Finalize; do not Get the posted invoice from a subscriber that runs while lines are posted.
    - Do follow-up work in OnAfterPostServiceDoc using the posted document numbers it passes.
    - OnAfterPostServiceDoc has no PreviewMode parameter and is not raised in posting preview; do not add one.
    - An error there does not undo posting; hand external calls to an outbox; do not Commit when CommitIsSuppressed is true.
[3] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Field-number mirroring rule the service article refers to.
    - TransferFields matches by field number; a different number is skipped without error.
    - Keep mirrored fields non-editable on posted tables.
    - Do not patch posted documents with an OnAfter insert subscriber and Modify.
[4] `microsoft/knowledge/sales-purchase/onafterpostsalesdoc-runs-after-the-posting-commit.md`: Outbox rule for after-posting follow-up referenced by the service article.
    - Treat the after-posting event as follow-up processing, not as part of posting.
    - Do not call Commit() in the subscriber; when CommitIsSuppressed is true the caller owns the transaction.
    - Insert an outbox row and let a recurring job queue entry send it; make the call idempotent.
[5] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Type and length of the mirrored Region Code.
    - A field mirrored across a TransferFields cascade has the exact same number, data type and length on every table in the cascade.
[6] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing Region Code against the table it relates to.
    - Read the related field's declared type and length; do not assume Code[10] or Code[20].
    - An unconditional TableRelation field has the same type and exact length as the related field.
[7] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Stored field versus related table on Service Ledger Entry (applies from BC23).
    - Put optional, sparse or integration attributes on hot ledgers in a related table keyed by Entry No.
    - Use a stored tableextension field only when the value must appear as a native list column and is read on almost every access.
[8] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Decisions for the new outbox and setup tables: setup, privacy, permissions.
    - Plan setup, data classification and permissions for every new table instead of only the table and page.
    - A decision the request does not settle is a question for the requester, not a default.
[9] `microsoft/knowledge/feature-design/plan-api-exposure-and-background-sync.md`: Planning order for the outbound field-planning notification.
    - Outbound calls never run inside a write transaction; record an outbox row and send it from a recurring job queue entry.
    - Use a stable idempotency key per outbox row; the external service must deduplicate.
    - Who calls whom, how often and what the external service does with a repeated request are questions for the requester.
[10] `microsoft/knowledge/performance/httpclient-inside-write-transaction-holds-locks.md`: Deferring the HTTP call out of posting.
    - Insert the outbox work item in the same transaction as the change and process committed rows with a recurring job queue entry.
    - The worker performs HTTP before deleting the item; do not use Commit() as a general remedy.
[11] `microsoft/knowledge/performance/job-queue-external-effects-must-be-idempotent.md`: Retry safety of the notification.
    - Send a stable request ID that exists before processing, such as the outbox row SystemId, on every attempt.
    - Delete the outbox row only after the external call and all local updates succeed; a Processed flag does not solve the failure window.
[12] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Job queue handler behaviour.
    - No Confirm, Page.RunModal, Report.RunModal, upload, download or Message-only outcome in the job queue entry point.
[13] `microsoft/knowledge/performance/job-queue-handlers-must-propagate-failures.md`: Job queue failure reporting.
    - Let an error that invalidates the run propagate out of the entry point; do not swallow a failed TryFunction or Boolean result.
[14] `microsoft/knowledge/web-services/handle-httpclient-platform-failure-before-response-access.md`: Transport failure handling in the sender.
    - When the Boolean return is captured and false, do not read status, headers or content.
[15] `microsoft/knowledge/web-services/check-http-status-before-consuming-response-body.md`: HTTP status handling in the sender.
    - Check IsSuccessStatusCode or the expected status before treating the body as a success payload.
[16] `microsoft/knowledge/privacy/privacy-notice-consent-for-external-data-transfer.md`: Consent before sending data to the field-planning system.
    - Check the integration's own notice ID before sending; use GetPrivacyNoticeApprovalState when the flow must not show UI.
    - No path issues the request without approval; do not borrow a built-in notice ID.
[17] `microsoft/knowledge/privacy/register-integration-in-privacy-notice-registrations.md`: Registering the field-planning privacy notice.
    - Use a stable extension-owned ID registered through Privacy Notice OnRegisterPrivacyNotices or CreatePrivacyNotice; use the same ID for consent checks.
[18] `microsoft/knowledge/security/secrets-isolated-storage.md`: Where field-planning credentials are stored.
    - Credentials live in IsolatedStorage, never in a table field, including a setup table.
[19] `microsoft/knowledge/security/secrettext-for-credentials.md`: Carrying credentials (applies from BC23).
    - Declare credential parameters and variables as SecretText end to end; never round-trip through Text.
[20] `microsoft/knowledge/security/prefer-oauth2-over-api-keys-for-external-http-calls.md`: Authentication choice for the field-planning call.
    - When the partner supports OAuth, use the OAuth2 codeunit; keep tokens and secrets as SecretText in IsolatedStorage.
[21] `microsoft/knowledge/security/validate-user-configurable-urls.md`: Endpoint URL stored in setup.
    - Before any HttpClient call whose URL comes from a table field, validate it with Uri.AreURIsHaveSameHost or Uri.IsValidURIPattern and error when it fails.
[22] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification of added fields and new tables.
    - Every Normal field a tableextension adds needs an explicit DataClassification; a table-level value covers fields of the table itself.
[23] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of classification.
    - No field ships with DataClassification = ToBeClassified.
[24] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Permission set structure.
    - Ship a non-assignable building block and an assignable role-shaped set that includes it.
[25] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Permission set entries.
    - Enumerate each table and tabledata entry explicitly with only the letters needed; no wildcards.
[26] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Page fields showing Region Code.
    - From runtime 13.0 (BC24) define the tooltip on the table field and let bound page fields inherit it; earlier targets need page-level tooltips.
    - Tooltip text explains what the value is used for, without invented effects.
[27] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Field Planning Setup table and page.
    - Primary Key Code[10] is the sole key; card page with InsertAllowed = false, DeleteAllowed = false and an open-time insert of the blank row.
[28] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build prerequisite data with the test Library codeunits, parents first, and Validate foreign keys; no hand-rolled Init/Insert.
[29] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Test structure.
    - Tag the codeunit with [FEATURE] and each test with [SCENARIO], [GIVEN], [WHEN], [THEN].

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
