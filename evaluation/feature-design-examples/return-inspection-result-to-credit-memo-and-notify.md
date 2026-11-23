# Feature design

> When a sales return is received, the warehouse records an Inspection Result code on each return line. The credit memo lines created later with Get Return Receipt Lines must show the result recorded at receipt. After a bank reconciliation is posted, notify the treasury system that the statement was closed.

**Result:** Complete design. **Business process:** Carries a warehouse-recorded Inspection Result from sales return order lines through return receipt posting to credit memo lines created by Get Return Receipt Lines (sales returns), and notifies an external treasury system through an outbox and job queue after Bank Acc. Reconciliation Post posts a statement (bank reconciliation). **Knowledge used:** 27 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Is the Inspection Result code chosen from a maintained list (a new code table with a TableRelation, and who maintains it), or free text? What length should it have? _(affects: sales-line-ext, return-receipt-line-ext, sales-cr-memo-line-ext, sales-shipment-line-ext, sales-invoice-line-ext, sales-line-archive-ext)_
2. Do the return locations use warehouse receipts? If so, does the warehouse record the result on the Warehouse Receipt Line instead of the return order line? That path (return order line to warehouse receipt line to return receipt line) is not covered by BCQuality knowledge and its events must be confirmed in the target version's symbols. _(affects: return-order-subform-ext, sales-line-ext, return-receipt-line-ext)_
3. Besides the return receipt line and the credit memo, should the field reach the other Sales Line mirror targets (posted credit memo lines, sales shipment and invoice lines, Sales Line Archive)? The mirroring guidance designs all of them unless you state a document type never needs it. _(affects: sales-cr-memo-line-ext, sales-shipment-line-ext, sales-invoice-line-ext, sales-line-archive-ext, mirror-targets-carry-result, posted-cr-memo-carries-result)_
4. Must the result also appear on credit memo lines created by Copy Document from a posted return receipt or by Get Posted Document Lines to Reverse? Those paths recalculate lines and drop the field unless OnAfterRecalculateSalesLine copies it. _(affects: inspection-result-returns, cr-memo-subform-ext)_
5. Is the feature limited to sales returns, or should purchase return shipments carry an Inspection Result to purchase credit memos too (Get Return Shipment Lines)? _(affects: inspection-result-returns, sales-line-ext)_
6. May users change the Inspection Result on a credit memo line after Get Return Receipt Lines, or must it stay as recorded at receipt? _(affects: cr-memo-subform-ext, sales-line-ext)_
7. Which postings count as 'the statement was closed': only bank account reconciliations, or also payment reconciliation journals posted through the same codeunit? _(affects: bank-rec-subscriber)_
8. What must the treasury message contain (bank account, statement no., statement date, ending balance, others) and in which format? _(affects: treasury-outbox, treasury-worker)_
9. What is the treasury system's endpoint and host, does it support OAuth2 client credentials, and does it deduplicate requests by an idempotency key? Is the setup per company or per tenant? _(affects: treasury-setup, treasury-worker, treasury-setup-card)_
10. How soon after posting must the treasury system be notified? This sets the job queue recurrence. _(affects: treasury-worker)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Sales Line | Holds the Inspection Result code the warehouse records on each sales return order line, and the value copied onto credit memo lines created by Get Return Receipt Lines. Source of every TransferFields cascade below. | Inspection Result (Code[10]): Field number to be taken from the app's ID range and reused unchanged on every mirror table; DataClassification = CustomerContent. TableRelation depends on open question inspection-result-code-list. | [3] [5] [10] [11] |
| 2 | extend | tableextension | Return Receipt Line | Keeps the result recorded at receipt. Return order posting fills it by TransferFields (InitFromSalesLine); Get Return Receipt Lines reads it from here, not from the order line. | Inspection Result (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. | [3] [5] [10] [11] |
| 3 | extend | tableextension | Sales Cr.Memo Line | Mirror target for the posted credit memo line, so the value shown on the credit memo survives posting by TransferFields. Chosen by the mirroring article; see open question mirror-targets. | Inspection Result (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. | [5] [7] [10] [11] |
| 4 | extend | tableextension | Sales Shipment Line | Mirror target required by the mirroring article for a Sales Line field unless the plan states the document type never needs it; see open question mirror-targets. | Inspection Result (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. | [5] [10] [11] |
| 5 | extend | tableextension | Sales Invoice Line | Mirror target required by the mirroring article for a Sales Line field unless the plan states the document type never needs it; see open question mirror-targets. | Inspection Result (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. | [5] [10] [11] |
| 6 | extend | tableextension | Sales Line Archive | Mirror target for archived return orders and credit memos, filled by TransferFields during archiving; see open question mirror-targets. | Inspection Result (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. | [5] [7] [10] [11] |
| 7 | create | codeunit | Inspection Result Returns | Event subscriber that copies the Inspection Result from the posted Return Receipt Line to the new credit memo Sales Line in Get Return Receipt Lines, so the credit memo shows the value recorded at receipt rather than the return order line's current value. |  | [3] |
| 8 | extend | pageextension | Sales Return Order Subform | Lets the warehouse enter the Inspection Result on each return order line. |  | agent judgment |
| 9 | extend | pageextension | Posted Return Receipt Subform | Shows the result recorded at receipt (read-only). |  | agent judgment |
| 10 | extend | pageextension | Sales Cr. Memo Subform | Shows the Inspection Result on credit memo lines created with Get Return Receipt Lines, as the request requires. |  | agent judgment |
| 11 | extend | pageextension | Posted Sales Cr. Memo Subform | Shows the Inspection Result on the posted credit memo lines (read-only). |  | agent judgment |
| 12 | create | table | Treasury Integration Setup | Singleton setup (Primary Key Code[10], one blank-keyed row) holding whether the notification is enabled and the treasury endpoint URL. Credentials are not stored here; they go to IsolatedStorage. | Primary Key (Code[10]); Enabled (Boolean); Endpoint URL (Text[250]): User-configurable; validated against a fixed expected host or pattern before every call. | [25] [19] [21] |
| 13 | create | page | Treasury Integration Setup | Card page over the singleton setup: InsertAllowed = false, DeleteAllowed = false, inserts the blank row on open; captures the credential straight into IsolatedStorage as SecretText and offers the privacy notice approval. |  | [25] [19] [20] [22] |
| 14 | create | table | Treasury Notification Outbox | Outbox work item inserted in the same transaction as the bank reconciliation posting; it commits or rolls back with the posting. Its SystemId is the idempotency key sent to the treasury system. A row is deleted only after the call and all local updates succeed. | Entry No. (Integer): AutoIncrement primary key.; Bank Account No. (Code[20]): Copied from the posted Bank Acc. Reconciliation record.; Statement No. (Code[20]): Copied from the posted Bank Acc. Reconciliation record.; Statement Date (Date): Sent as a typed JSON value or Format(..., 0, 9).; Statement Ending Balance (Decimal): Sent as a typed JSON value or Format(..., 0, 9). Payload content is open question treasury-payload. | [12] [13] [24] |
| 15 | create | codeunit | Treasury Bank Rec. Notification | Subscribes to OnAfterFinalizePost and inserts one Treasury Notification Outbox row from the reconciliation record it receives. It runs inside the posting transaction, so it does no HTTP, no Commit and no slow work. |  | [4] [6] [12] |
| 16 | create | codeunit | Treasury Notification Worker | Job queue handler (TableNo = Job Queue Entry) run by a recurring job queue entry. For each committed outbox row: checks the custom privacy notice approval without UI, validates the endpoint URL, POSTs the statement-closed message with the outbox SystemId as idempotency key, handles platform failure then HTTP status, and deletes the row only on success. No UI; failures propagate to the job queue. |  | [12] [13] [14] [15] [16] [17] [18] [19] [20] [21] [22] [24] |
| 17 | create | codeunit | Treasury Privacy Notice | Registers the integration's own stable privacy notice ID through OnRegisterPrivacyNotices; the same ID is used for the consent check in the worker. |  | [23] [22] |
| 18 | create | permissionset | Return Inspection and Treasury | Grants the new tables, pages and codeunits (setup, outbox, subscribers, worker) to the users who post returns and bank reconciliations and to the job queue user. |  | agent judgment |

## 3. How the data flows

- **User (warehouse)** → **Sales Line (Return Order).Inspection Result**: entered by the user. Entered on Sales Return Order Subform before the return is received. Warehouse-receipt entry point is open question warehouse-receipt-entry. agent judgment
- **Sales Line (Return Order).Inspection Result** → **Return Receipt Line.Inspection Result**: standard TransferFields copy. Return order posting (receive) creates the posted line with InitFromSalesLine / TransferFields; same field number required, no subscriber. [5] [3] [10]
- **Return Receipt Line.Inspection Result** → **Sales Line (Credit Memo).Inspection Result**: copied in an event subscriber. Get Return Receipt Lines (InsertInvLineFromRetRcptLine) copies from the open return order line by default; the subscriber overrides that with the posted receipt line's value in OnAfterCopyFieldsFromReturnReceiptLine, before insert, without Modify. [3]
- **Sales Line (Credit Memo).Inspection Result** → **Sales Cr.Memo Line.Inspection Result**: standard TransferFields copy. Credit memo posting creates posted lines with InitFromSalesLine / TransferFields. [5] [7] [10]
- **Sales Line.Inspection Result** → **Sales Shipment Line / Sales Invoice Line.Inspection Result**: standard TransferFields copy. Mirror targets chosen by the mirroring article; see open question mirror-targets. [5] [10]
- **Sales Line.Inspection Result** → **Sales Line Archive.Inspection Result**: standard TransferFields copy. Archiving copies lines with TransferFields; see open question mirror-targets. [5] [7] [10]
- **Bank Acc. Reconciliation (posted)** → **Treasury Notification Outbox**: other. Inserted in the OnAfterFinalizePost subscriber inside the posting transaction, from the record the event passes (the reconciliation lines are already deleted). [4] [6] [12]
- **Treasury Notification Outbox** → **Treasury system**: other. Recurring job queue entry POSTs each committed outbox row with its SystemId as idempotency key, then deletes the row. [12] [13] [14] [15] [16] [17]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Return Receipt Line | `OnAfterCopyFieldsFromReturnReceiptLine` | Assign SalesLine."Inspection Result" := ReturnReceiptLine."Inspection Result" so the credit memo line carries the value recorded at receipt, not the return order line's current value. | Assign only; no Modify (the line is inserted after the event) · Do not patch the credit memo line in OnAfterInsertEvent | [3] |
| Bank Acc. Reconciliation Post | `OnAfterFinalizePost` | Insert one Treasury Notification Outbox row for the posted statement, from the reconciliation record the event passes. | Runs before the codeunit's Commit: no HttpClient call, no Commit, no slow work (they hold the posting's locks) · An error here rolls back the whole reconciliation posting; raise one only to deliberately stop posting · Do not read the reconciliation lines from the database; they are already deleted · No preview guard: FinalizePost exits before this event in preview · Exit when Treasury Integration Setup is missing or not Enabled · Restrict to the statement types the requester confirms (open question statement-types) | [4] [6] [12] |
| Privacy Notice | `OnRegisterPrivacyNotices` | Add the treasury integration's own stable notice ID, name and link to the temporary Privacy Notice record. | Never reuse a built-in notice ID such as Exchange | [23] [22] |

## 5. Setup, permissions and lifecycle

- **privacy**: Classify Inspection Result as CustomerContent on Sales Line and on every mirror table (table extensions cannot inherit a table-level value); classify the outbox and setup tables explicitly. [11]
- **privacy**: Register the custom treasury privacy notice through OnRegisterPrivacyNotices; the worker checks GetPrivacyNoticeApprovalState with that ID (no UI) before sending, and the setup page lets the admin approve it with ConfirmPrivacyNoticeApproval outside a write transaction. [23] [22]
- **setup**: Treasury Integration Setup singleton card: Enabled flag and endpoint URL; credential captured into IsolatedStorage (SetEncrypted where it fits) and carried as SecretText; prefer OAuth2 client credentials via the OAuth2 codeunit when the treasury system supports it. [25] [19] [20] [18]
- **background**: Create a recurring job queue entry for Treasury Notification Worker when the integration is enabled. Handler must be non-interactive and let failures propagate so the entry shows the error and retries apply. [12] [14] [15]
- **permissions**: Ship a permission set covering the new tables, pages and codeunits, and assign it to posting users and the job queue user. agent judgment

## 6. Tests

1. **receive-return-carries-result** [5] [26] [27]
    - Given A customer, an item and a sales return order line with an Inspection Result, built with the Library codeunits (LibrarySales, LibraryInventory).
    - When The return order is posted with Receive only.
    - Then The Return Receipt Line has the same Inspection Result.
2. **get-return-receipt-lines-uses-received-value** [3] [26]
    - Given A return order line received in two parts: first with Inspection Result A, then the field is changed to B on the return order line and the rest is received.
    - When A sales credit memo for the customer runs Get Return Receipt Lines for both receipt lines.
    - Then Each credit memo line shows the result of its own receipt (A and B), not the return order line's current value.
3. **posted-cr-memo-carries-result** [5] [7] [26]
    - Given A credit memo created with Get Return Receipt Lines whose lines carry Inspection Results.
    - When The credit memo is posted.
    - Then Each Sales Cr.Memo Line carries the Inspection Result of its source line.
4. **mirror-targets-carry-result** [5] [10] [26]
    - Given A sales line with an Inspection Result on a document type that reaches shipment, invoice and archive (only if open question mirror-targets keeps them).
    - When The document is archived and posted.
    - Then Sales Line Archive, Sales Shipment Line and Sales Invoice Line carry the value; the posted fields are not editable.
5. **bank-rec-post-creates-outbox-row** [4] [6] [12] [26] [27]
    - Given Treasury Integration Setup enabled and a bank account reconciliation ready to post, built with Library codeunits.
    - When The bank reconciliation is posted.
    - Then Exactly one Treasury Notification Outbox row exists with the bank account no., statement no., statement date and ending balance; no HTTP call was made during posting. Test uses AutoCommit (posting commits).
6. **bank-rec-disabled-no-outbox** [4] [26]
    - Given Treasury Integration Setup missing or Enabled = false.
    - When A bank reconciliation is posted.
    - Then No outbox row is created and posting succeeds.
7. **worker-sends-and-deletes** [13] [24] [12]
    - Given A committed outbox row, approved privacy notice and valid endpoint (HTTP stubbed).
    - When Treasury Notification Worker runs.
    - Then One POST is sent whose body contains the outbox row's SystemId as idempotency key and culture-independent date/amount values; the row is deleted afterwards.
8. **worker-failure-propagates** [15] [16] [17] [13]
    - Given A committed outbox row and a treasury response that is a platform failure or a non-success HTTP status.
    - When Treasury Notification Worker runs.
    - Then The run ends with an error (the job queue entry shows it), the body is not parsed as success, and the outbox row still exists for the retry.
9. **worker-blocks-without-consent-or-valid-url** [22] [21] [14]
    - Given A committed outbox row with the privacy notice not approved, or an endpoint URL whose host does not match the expected host/pattern.
    - When Treasury Notification Worker runs.
    - Then No request is sent, the run errors without UI, and the row remains.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Page extensions (return-order-subform-ext, posted-return-receipt-subform-ext, cr-memo-subform-ext, posted-cr-memo-subform-ext) rest on judgment: not covered by BCQuality knowledge.
- The permission set (feature-permissions) and its assignment rest on judgment: not covered by BCQuality knowledge.
- The user-entry hop onto the return order line rests on judgment: not covered by BCQuality knowledge.
- Warehouse receipt entry point for sales return orders: no BCQuality article confirms the events that carry a field from a sales return line to a warehouse receipt line or back to the return receipt line; left as open question warehouse-receipt-entry.
- Stubbing the treasury HTTP endpoint in tests is not covered by BCQuality knowledge.
- bc-version, countries and application-area could not be determined (no repository); applicability assumed for all.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Process map for the return field: Returns row (Get Return Receipt Lines) and cross-cutting rows (mirrored definitions, privacy, tests).
    - Plan one row group per process the field touches and open every linked article for the chosen stages
    - Whether the field reaches stages the request does not name is a question for the requester, one question per group of stages
    - Do not fill other records with subscribers that find and modify them after posting
[2] `microsoft/knowledge/feature-design/plan-api-exposure-and-background-sync.md`: Outbound map for the treasury notification: where the call runs, retries, job queue handler, responses, credentials, consent, exchanged values.
    - Never call the external service inside a write transaction; record an outbox row and send it from a recurring job queue entry
    - Give each outbox row a stable idempotency key; the external service must deduplicate
    - Who calls whom, how often and what the external service does with a repeated request are questions for the requester
[3] `microsoft/knowledge/sales-purchase/get-return-receipt-lines-copies-custom-fields-from-the-return-order-line.md`: Hop from Return Receipt Line to the credit memo line and its subscriber; partial-receipt test.
    - InsertInvLineFromRetRcptLine copies the open return order line, not the posted receipt line
    - When the credit memo must carry the received value, mirror the field on Return Receipt Line and assign it in OnAfterCopyFieldsFromReturnReceiptLine without Modify
    - Test a return order received in two parts and invoiced through Get Return Receipt Lines, changing the field between receipts
    - Get Posted Document Lines to Reverse and Copy Document take another path
[4] `microsoft/knowledge/sales-purchase/choose-the-after-posting-hook-per-posting-routine.md`: Choice and guards of the bank reconciliation after-posting hook.
    - OnAfterFinalizePost runs before the commit; an error there rolls back the whole posting
    - Keep slow work and external calls out because they hold the posting's locks
    - The reconciliation lines are already deleted; use the record the event passes
    - Not raised in preview, so no preview guard
    - Do not copy guards from sales or purchase after-posting subscribers by analogy
[5] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring the Sales Line field on Return Receipt Line, Sales Cr.Memo Line, Sales Shipment Line, Sales Invoice Line and Sales Line Archive.
    - Same field number, name, type and length on the source and on every target table the plan needs, unless the plan states a document type never needs it
    - No subscriber is needed for TransferFields stages
    - Keep mirrored fields non-editable on posted tables
[6] `microsoft/knowledge/finance-extensions/carry-bank-reconciliation-line-fields-to-payment-postings.md`: Confirms Bank Acc. Reconciliation Post's commit order and that FinalizePost exits in preview.
    - OnAfterFinalizePost runs before the codeunit's Commit(), so an error rolls back the reconciliation posting
    - Neither OnBeforeFinalizePost nor OnAfterFinalizePost runs in preview
    - Do not modify posted bank, customer or vendor ledger entries in OnAfterFinalizePost
[7] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Posted credit memo line and archive stages of a Sales Line field; Copy Document flow-back decision.
    - Plan one step per stage the field must reach
    - Posted lines and Sales Line Archive are filled by TransferFields from Sales Line
    - Decide whether a field mirrored on posted tables should flow back through Copy Document
[8] `microsoft/knowledge/warehouse/carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.md`: Basis for leaving the warehouse-receipt entry point open.
    - Warehouse lines are built field by field; sales return orders build their warehouse lines in their own codeunits with their own events, to be confirmed per source type in the target version's symbols
[9] `microsoft/knowledge/sales-purchase/copy-document-recalculate-lines-drops-custom-line-fields.md`: Basis for the open question on credit memos created by Copy Document or Get Posted Document Lines to Reverse.
    - With Recalculate Lines (always for posted return receipts) custom line fields are not copied
    - To keep the field, copy it in OnAfterRecalculateSalesLine without Modify
[10] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Mirrored field definitions.
    - Exact same field number, data type and length on every table in the TransferFields cascade
[11] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Classification of the new fields.
    - Every Normal field in a table extension sets its own DataClassification matching the data it stores; never leave ToBeClassified
[12] `microsoft/knowledge/performance/httpclient-inside-write-transaction-holds-locks.md`: Outbox pattern for the notification.
    - Insert the outbox work item in the same transaction as the business change
    - Process committed outbox rows from a recurring job queue entry; perform HTTP before deleting the row
    - Do not use Commit() as a remedy
[13] `microsoft/knowledge/performance/job-queue-external-effects-must-be-idempotent.md`: Idempotency key for the treasury call.
    - Use a stable request ID such as the outbox SystemId in every attempt; the external service must enforce uniqueness
    - Delete the outbox row only after the external call and local updates succeed; a Processed flag does not close the failure window
[14] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Non-interactive worker.
    - No Confirm, Page.Run(Modal), Report.Run(Modal), Hyperlink, upload or download in the job queue handler
    - Message cannot report the result
[15] `microsoft/knowledge/performance/job-queue-handlers-must-propagate-failures.md`: Failure propagation from the worker.
    - Let errors that invalidate the run propagate so the dispatcher records them and retries apply
[16] `microsoft/knowledge/web-services/handle-httpclient-platform-failure-before-response-access.md`: Platform failure handling.
    - When the Boolean result of Post is false, stop without reading status, headers or content
[17] `microsoft/knowledge/web-services/check-http-status-before-consuming-response-body.md`: HTTP status handling.
    - Check IsSuccessStatusCode before treating the response body as success
[18] `microsoft/knowledge/security/prefer-oauth2-over-api-keys-for-external-http-calls.md`: Authentication choice.
    - Use the OAuth2 codeunit when the partner supports OAuth; tokens and secrets as SecretText, persisted only in IsolatedStorage
[19] `microsoft/knowledge/security/secrets-isolated-storage.md`: Credential storage.
    - Credentials in IsolatedStorage, never in a table field; prefer SetEncrypted when the value fits
[20] `microsoft/knowledge/security/secrettext-for-credentials.md`: Credential type.
    - Carry credentials as SecretText end to end; never round-trip through Text
[21] `microsoft/knowledge/security/validate-user-configurable-urls.md`: Endpoint validation.
    - Before HttpClient uses a URL from a table field, validate it with Uri.AreURIsHaveSameHost or Uri.IsValidURIPattern and error when it fails
[22] `microsoft/knowledge/privacy/privacy-notice-consent-for-external-data-transfer.md`: Consent before data leaves Business Central.
    - Use the integration's own notice ID
    - Check GetPrivacyNoticeApprovalState in flows without UI; ConfirmPrivacyNoticeApproval only outside a write transaction
    - No path sends the request without approval
[23] `microsoft/knowledge/privacy/register-integration-in-privacy-notice-registrations.md`: Registering the privacy notice.
    - Register a stable, extension-owned ID through OnRegisterPrivacyNotices or CreatePrivacyNotice; do not reuse built-in IDs
[24] `microsoft/knowledge/web-services/format-exchanged-values-with-standard-format-9.md`: Exchanged values in the treasury payload.
    - Use typed JsonObject values or Format(Value, 0, 9) for dates and decimals sent externally
[25] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Treasury Integration Setup table and card.
    - Primary Key Code[10] as sole key, one blank row
    - Card page with InsertAllowed = false, DeleteAllowed = false and an open-time guard that inserts the row
[26] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build customers, items, documents and bank accounts with the Library codeunits, parents first, validating foreign keys
[27] `microsoft/knowledge/testing/transactionmodel-attribute-governs-test-transactions.md`: Transaction model of posting tests.
    - Code under test that commits (posting, job queue handlers) needs AutoCommit, not explicit AutoRollback; pair suite-wide AutoCommit with a TestIsolation runner

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

