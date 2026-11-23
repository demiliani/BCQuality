# Feature design

> Purchase orders need a Supplier Contract Reference typed by the buyer. It must be visible on posted purchase invoices and on vendor ledger entries. When a purchase invoice is posted, the reference and the invoice number must be sent to the supplier's web portal.

**Result:** Complete design. **Business process:** Purchase document posting (Purch.-Post creating posted purchase headers by TransferFields and vendor ledger entries through Gen. Journal Line), with follow-up integration after posting. **Knowledge used:** 25 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Should Supplier Contract Reference be Code or Text, and what maximum length? The same type and length will be used on every mirrored table. _(affects: purchase-header-ext, purch-inv-header-ext, purch-rcpt-header-ext, purch-cr-memo-hdr-ext, return-shipment-header-ext, purchase-header-archive-ext, gen-journal-line-ext, vendor-ledger-entry-ext, portal-outbox-table, max-length-ref-posts)_
2. Is the reference needed on receipts, return orders/credit memos, return shipments and archives? The mirroring article requires them unless you state a document type never needs it; the design currently includes all of them. _(affects: purch-rcpt-header-ext, purch-cr-memo-hdr-ext, return-shipment-header-ext, purchase-header-archive-ext)_
3. Should buyers also type the reference on purchase invoices (and credit memos) entered directly, not only on purchase orders? Only the Purchase Order page is extended now. _(affects: purchase-order-page-ext)_
4. When a user copies a posted or archived purchase document, should the reference flow back into the new document? If not, a clearing subscriber is needed; no purchase Copy Document event was confirmed in BCQuality knowledge. _(affects: purchase-header-ext)_
5. Should posting a purchase credit memo also notify the portal, or only purchase invoices? _(affects: portal-notice-scheduler-codeunit, posting-queues-outbox-row)_
6. Is the reference mandatory before posting, and should an invoice with a blank reference still be sent to the portal? _(affects: purchase-header-ext, portal-notice-scheduler-codeunit)_
7. Is there one supplier portal for all vendors or a different portal (URL, credentials) per vendor? This decides whether the setup is a singleton or per-vendor configuration. _(affects: portal-setup-table, portal-setup-page, portal-sender-codeunit)_
8. What is the portal's endpoint, payload format and authentication method (OAuth2 supported?), and does it accept an idempotency key and treat repeats as the same request? _(affects: portal-sender-codeunit, portal-setup-table)_
9. Which fixed host or URL pattern should the stored portal URL be validated against? _(affects: portal-sender-codeunit, sender-rejects-unexpected-host)_
10. How often should the sender job run, and who creates the recurring job queue entry (setup action, install code, or manual)? _(affects: portal-sender-codeunit)_
11. How should persistent send failures be surfaced to users beyond the job queue log? _(affects: portal-sender-codeunit)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Purchase Header | Hold the Supplier Contract Reference the buyer types on the purchase order; source of every posting hop. | Supplier Contract Reference (Type and length to be confirmed (see open question field-type-and-length)): Field number reused on every TransferFields target and on Gen. Journal Line and Vendor Ledger Entry. Explicit DataClassification, never ToBeClassified. Define the ToolTip on the table field when the target runtime is 13.0 or later. | [3] [7] [20] [21] |
| 2 | extend | tableextension | Purch. Inv. Header | Show the reference on posted purchase invoices; filled by the standard TransferFields from Purchase Header. | Supplier Contract Reference (Same type and length as the Purchase Header field (see open question field-type-and-length)): Same field number, name, type and length as on Purchase Header so TransferFields copies it; Editable = false; explicit DataClassification. | [3] [7] [20] |
| 3 | extend | tableextension | Purch. Rcpt. Header | Mirror required by the article for every posted purchase header unless the plan excludes the document type. | Supplier Contract Reference (Same type and length as the Purchase Header field (see open question field-type-and-length)): Same field number, name, type and length as on Purchase Header so TransferFields copies it; Editable = false; explicit DataClassification. | [3] [7] [20] |
| 4 | extend | tableextension | Purch. Cr. Memo Hdr. | Mirror required by the article for every posted purchase header unless the plan excludes the document type. | Supplier Contract Reference (Same type and length as the Purchase Header field (see open question field-type-and-length)): Same field number, name, type and length as on Purchase Header so TransferFields copies it; Editable = false; explicit DataClassification. | [3] [7] [20] |
| 5 | extend | tableextension | Return Shipment Header | Mirror required by the article for every posted purchase header unless the plan excludes the document type. | Supplier Contract Reference (Same type and length as the Purchase Header field (see open question field-type-and-length)): Same field number, name, type and length as on Purchase Header so TransferFields copies it; Editable = false; explicit DataClassification. | [3] [7] [20] |
| 6 | extend | tableextension | Purchase Header Archive | Mirror required by the article so archived orders keep the reference. | Supplier Contract Reference (Same type and length as the Purchase Header field (see open question field-type-and-length)): Same field number, name, type and length as on Purchase Header so TransferFields copies it; Editable = false; explicit DataClassification. | [3] [7] [20] |
| 7 | extend | tableextension | Gen. Journal Line | Carry the reference from Purchase Header to Vendor Ledger Entry during posting. | Supplier Contract Reference (Same type and length as the Purchase Header field (see open question field-type-and-length)): Explicit DataClassification. | [4] [7] [20] |
| 8 | extend | tableextension | Vendor Ledger Entry | Show the reference on vendor ledger entries; set while the entry is initialized, never by modifying a posted entry. | Supplier Contract Reference (Same type and length as the Purchase Header field (see open question field-type-and-length)): Editable = false; explicit DataClassification. | [4] [8] [7] [20] |
| 9 | extend | pageextension | Purchase Order | Let the buyer type the reference on the purchase order. |  | [21] |
| 10 | extend | pageextension | Posted Purchase Invoice | Show the reference on the posted purchase invoice (read-only). |  | [21] |
| 11 | extend | pageextension | Vendor Ledger Entries | Show the reference on vendor ledger entries (read-only). |  | [21] |
| 12 | create | codeunit | Supplier Ref. Posting (new) | Event subscribers that copy the reference Purchase Header -> Gen. Journal Line -> Vendor Ledger Entry. |  | [4] |
| 13 | create | table | Supplier Portal Outbox (new) | Work item inserted in the posting transaction; one row per posted purchase invoice to send. Its SystemId is the idempotency key. | Entry No. (BigInteger): AutoIncrement primary key.; Purch. Invoice No. (Code[20]): Posted invoice number passed by OnAfterPostPurchaseDoc.; Supplier Contract Reference (Same type and length as the Purchase Header field (see open question field-type-and-length)): Optional snapshot; can instead be read from Purch. Inv. Header when sending. | [5] [6] [9] [10] [20] |
| 14 | create | codeunit | Supplier Portal Notice Scheduler (new) | OnAfterPostPurchaseDoc subscriber that inserts an outbox row; no HTTP call and no Commit. |  | [5] [6] [9] |
| 15 | create | codeunit | Supplier Portal Sender (new, TableNo = Job Queue Entry) | Recurring job queue worker: reads committed outbox rows, sends reference and invoice number to the supplier portal with the outbox SystemId as idempotency key, deletes the row only after success. |  | [9] [10] [11] [12] [13] [14] [15] [16] [18] [19] |
| 16 | create | table | Supplier Portal Setup (new) | Singleton setup holding the portal URL and options; credentials are not stored here. | Primary Key (Code[10]): Blank singleton key.; Portal URL (Text (length to be decided)): Validated against a fixed expected host or pattern before every call. | [23] [18] [16] [20] |
| 17 | create | page | Supplier Portal Setup (new, Card) | Card page over the singleton setup (InsertAllowed = false, DeleteAllowed = false, inserts the blank row on open); captures credentials into IsolatedStorage. |  | [23] [16] [15] [21] |
| 18 | create | permissionset | Supplier Contract Ref. (new) | Explicit, non-wildcard grants for every new table, page and codeunit of the feature. |  | [24] [25] [1] |

## 3. How the data flows

- **Buyer** → **Purchase Header.Supplier Contract Reference**: entered by the user. Typed on the Purchase Order page. [21]
- **Purchase Header** → **Purch. Inv. Header**: standard TransferFields copy. Standard Purch.-Post TransferFields; no subscriber. [3] [7]
- **Purchase Header** → **Purch. Rcpt. Header**: standard TransferFields copy. [3] [7]
- **Purchase Header** → **Purch. Cr. Memo Hdr.**: standard TransferFields copy. [3] [7]
- **Purchase Header** → **Return Shipment Header**: standard TransferFields copy. [3] [7]
- **Purchase Header** → **Purchase Header Archive**: standard TransferFields copy. ArchiveManagement copies the header with TransferFields. [3] [7]
- **Purchase Header** → **Gen. Journal Line**: copied in an event subscriber. OnAfterCopyGenJnlLineFromPurchHeader. [4]
- **Gen. Journal Line** → **Vendor Ledger Entry**: copied in an event subscriber. OnAfterCopyVendLedgerEntryFromGenJnlLine, while the entry is initialized. [4] [8]
- **Purch.-Post (posted invoice number)** → **Supplier Portal Outbox**: other. OnAfterPostPurchaseDoc subscriber inserts one outbox row per posted invoice. [5] [6] [9]
- **Supplier Portal Outbox + Purch. Inv. Header** → **Supplier web portal**: other. Recurring job queue entry sends reference and invoice number over HTTP with the outbox SystemId as idempotency key. [9] [10] [13] [14]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Gen. Journal Line" | `OnAfterCopyGenJnlLineFromPurchHeader` | Copy Supplier Contract Reference from Purchase Header to the vendor journal line. |  | [4] |
| Table "Vendor Ledger Entry" | `OnAfterCopyVendLedgerEntryFromGenJnlLine` | Copy Supplier Contract Reference from the journal line to the vendor ledger entry while it is initialized. | Assign only; never find and Modify a posted vendor ledger entry | [4] [8] |
| Codeunit "Purch.-Post" | `OnAfterPostPurchaseDoc` | Queue the portal notification by inserting an outbox row for the posted invoice. | Exit when "Gen. Jnl.-Post Preview".IsActive() (the event has no PreviewMode parameter; CommitIsSupressed is not a substitute) · Exit when PurchInvHdrNo is blank · No HTTP call and no Commit() in the subscriber · Confirm the event's parameters in the target version's symbols; do not copy the sales subscriber signature | [5] [6] [9] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set an explicit DataClassification on every new field and table; resolve every ToBeClassified before release. [20] [1]
- **privacy**: Register a custom Privacy Notice for the supplier portal (CreatePrivacyNotice during setup or OnRegisterPrivacyNotices). The background sender checks GetPrivacyNoticeApprovalState and does not send without approval. [19]
- **setup**: Singleton Supplier Portal Setup with a card page; validate the stored portal URL with Uri.AreURIsHaveSameHost or Uri.IsValidURIPattern against a fixed expected value before each call. [23] [18]
- **setup**: Store portal credentials only in IsolatedStorage (SetEncrypted when it fits) and carry them as SecretText; prefer OAuth2 via the OAuth2 codeunit if the portal supports it. [16] [15] [17]
- **background**: Run Supplier Portal Sender as a recurring job queue entry: non-interactive, errors propagate to the job queue log, external call idempotent through the outbox SystemId, outbox row deleted only after the call and local updates succeed. [9] [10] [11] [12]
- **permissions**: Ship a permission set listing each new table (tabledata), page and codeunit explicitly, with no wildcard grants. [24] [25] [1]

## 6. Tests

1. **order-ref-reaches-posted-invoice** [3] [22]
    - Given A purchase order created with Library - Purchase with a Supplier Contract Reference
    - When The order is received and invoiced
    - Then Purch. Inv. Header has the same Supplier Contract Reference
2. **order-ref-reaches-receipt** [3] [22]
    - Given A purchase order with a Supplier Contract Reference
    - When The order is received
    - Then Purch. Rcpt. Header has the same reference
3. **return-order-ref-reaches-cr-memo-and-return-shipment** [3] [22]
    - Given A purchase return order with a Supplier Contract Reference
    - When It is shipped and invoiced
    - Then Return Shipment Header and Purch. Cr. Memo Hdr. have the same reference
4. **archived-order-keeps-ref** [3] [22]
    - Given A purchase order with a Supplier Contract Reference
    - When The order is archived
    - Then Purchase Header Archive has the same reference
5. **order-ref-reaches-vendor-ledger** [4] [8] [22]
    - Given A purchase order with a Supplier Contract Reference
    - When The order is invoiced
    - Then The Vendor Ledger Entry for the posted invoice has the same reference, written during posting
6. **max-length-ref-posts** [7]
    - Given A purchase order whose reference uses the full defined field length
    - When The order is invoiced
    - Then Posting succeeds and every target holds the full value (no length mismatch)
7. **posting-queues-outbox-row** [5] [6]
    - Given A purchase order with a Supplier Contract Reference
    - When The order is invoiced
    - Then One Supplier Portal Outbox row exists for the posted invoice number
8. **preview-queues-nothing** [5]
    - Given A purchase order with a Supplier Contract Reference
    - When Posting preview runs
    - Then No outbox row exists and no portal call is made
9. **receive-only-queues-nothing** [5]
    - Given A purchase order
    - When It is received but not invoiced
    - Then No outbox row is created (PurchInvHdrNo is blank)
10. **sender-sends-and-deletes-on-success** [10] [13]
    - Given A committed outbox row and a portal stub returning success
    - When The sender job runs
    - Then The request carries the invoice number, the reference and the outbox SystemId as idempotency key, and the row is deleted
11. **sender-fails-on-non-success-status** [11] [13] [14]
    - Given A committed outbox row and a portal stub returning a non-success status
    - When The sender job runs
    - Then The job errors, the row remains, and the response body is not parsed as success
12. **sender-blocks-without-privacy-approval** [19]
    - Given A committed outbox row and the custom privacy notice not approved
    - When The sender job runs
    - Then No request is sent and the row remains
13. **sender-rejects-unexpected-host** [18]
    - Given Setup Portal URL pointing to a host other than the expected one
    - When The sender job runs
    - Then The job errors before any HTTP call

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Context dimensions bc-version, countries and application-area are unknown (no repository); the tooltip guidance depends on runtime 13.0 (BC24) or later.
- The supplier portal API contract (endpoint, payload, authentication, idempotency support) is not covered by BCQuality knowledge; the sender's request shape rests on agent judgment until open question portal-api-contract is answered.
- Standard page names Purchase Order, Posted Purchase Invoice and Vendor Ledger Entries are not confirmed by an opened article; confirm them in the target version's symbols.
- How the recurring job queue entry is created is not covered by an opened article; see open question job-queue-schedule.
- OnAfterPostPurchaseDoc parameter list must be confirmed in the target version's symbols, as the article requires.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Checklist of cross-cutting decisions (privacy, permissions, setup) for new objects
    - Plan classification, permissions and setup rows; a row the request does not settle is a question, not a default.
[2] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Path map for a header field through document posting; purchases follow the same map
    - Plan one step per stage the field must reach.
    - Copy Document copies posted and archived headers back with TransferFields; decide whether the value should flow back.
    - Do not copy a sales subscriber to purchases without checking the purchase event's parameters.
[3] `microsoft/knowledge/sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md`: Mirroring the field on posted purchase headers and the archive
    - Same field number, name, type and length on Purchase Header and every target: all four posted headers and Purchase Header Archive unless the plan states a document type never needs it.
    - No subscriber for TransferFields stages.
    - Mirrored fields non-editable on posted tables.
[4] `microsoft/knowledge/sales-purchase/carry-purchase-fields-to-vendor-ledger-through-the-journal-line.md`: Carrying the field to Vendor Ledger Entry
    - Add the field to Gen. Journal Line and Vendor Ledger Entry and subscribe to OnAfterCopyGenJnlLineFromPurchHeader and OnAfterCopyVendLedgerEntryFromGenJnlLine.
    - Do not find and Modify the vendor entry from OnAfterPostPurchaseDoc.
[5] `microsoft/knowledge/sales-purchase/onafterpostpurchasedoc-has-no-previewmode-parameter.md`: Preview guard and outbox insertion in the purchase after-posting subscriber
    - OnAfterPostPurchaseDoc has no PreviewMode parameter; detect preview with "Gen. Jnl.-Post Preview".IsActive() and exit before any external side effect.
    - CommitIsSupressed is not a preview substitute.
    - Do not call Commit(), do not rely on rollback, hand external calls to an outbox processed by a recurring job queue entry.
    - Confirm the event's parameters in the target version's symbols.
[6] `microsoft/knowledge/sales-purchase/onafterpostsalesdoc-runs-after-the-posting-commit.md`: General rules for after-posting follow-up processing
    - Subscriber errors do not undo posting.
    - No Commit() in the subscriber; outbox row plus recurring job queue entry for external calls; use the posted document number passed by the event.
[7] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Type and length agreement across the mirrored cascade
    - Define the mirrored field with the exact same number, type and length on every table in the cascade.
[8] `microsoft/knowledge/finance/do-not-modify-or-delete-posted-ledger-entries.md`: Ruling out patching posted vendor ledger entries
    - Do not persist changes to posted ledger content outside supported workflows; fill the extension field during posting instead.
[9] `microsoft/knowledge/performance/httpclient-inside-write-transaction-holds-locks.md`: Deferring the portal call out of the posting transaction
    - No HttpClient after a write in the same transaction; insert an outbox row in the same transaction and process committed rows from a recurring job queue entry; delete after HTTP completes.
    - Do not use Commit() as a remedy.
[10] `microsoft/knowledge/performance/job-queue-external-effects-must-be-idempotent.md`: Retry safety of the portal call
    - Send a stable request ID (outbox SystemId) the portal must enforce as unique.
    - Delete the outbox row only after the call and local updates succeed; a Processed flag does not close the failure window.
[11] `microsoft/knowledge/performance/job-queue-handlers-must-propagate-failures.md`: Failure reporting from the sender job
    - Let errors that invalidate the run propagate; do not swallow TryFunction or Boolean failures.
[12] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Background-safe sender
    - No Confirm, RunModal, Message-as-result or other UI in the job queue handler.
[13] `microsoft/knowledge/web-services/check-http-status-before-consuming-response-body.md`: Handling portal responses
    - Check IsSuccessStatusCode() before treating the body as success; handle non-success explicitly.
[14] `microsoft/knowledge/web-services/handle-httpclient-platform-failure-before-response-access.md`: Handling transport failures
    - When the Boolean result is captured and false, do not read the response; omitting the Boolean for fail-fast is valid.
[15] `microsoft/knowledge/security/secrettext-for-credentials.md`: Carrying portal credentials
    - Credentials as SecretText end to end; never round-trip through Text.
[16] `microsoft/knowledge/security/secrets-isolated-storage.md`: Storing portal credentials
    - Credentials in IsolatedStorage, never a table field; prefer SetEncrypted.
[17] `microsoft/knowledge/security/prefer-oauth2-over-api-keys-for-external-http-calls.md`: Authentication choice for the portal
    - When the partner supports OAuth, use the OAuth2 codeunit rather than API keys or basic auth.
[18] `microsoft/knowledge/security/validate-user-configurable-urls.md`: Validating the stored portal URL
    - Before any HttpClient call to a URL from a table field, validate it with Uri.AreURIsHaveSameHost or Uri.IsValidURIPattern against a fixed value and Error on mismatch.
[19] `microsoft/knowledge/privacy/privacy-notice-consent-for-external-data-transfer.md`: Consent before sending data to the supplier portal
    - Register a custom notice ID; no path sends without approval; use GetPrivacyNoticeApprovalState where no UI may be shown.
[20] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Data classification of new fields and tables
    - Resolve every ToBeClassified to a real classification before release.
[21] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips on the new page fields
    - Page fields need an explicit or inherited non-empty tooltip; on runtime 13.0 (BC24) or later define it on the table field; applies from BC24 for inheritance, otherwise page-level.
[22] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures
    - Build vendors, items and purchase documents with the Library codeunits, parents first.
[23] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Portal setup table
    - Singleton setup: Code[10] blank Primary Key, card page with InsertAllowed/DeleteAllowed false and open-time insert.
[24] `microsoft/knowledge/security/exposed-objects-must-be-in-a-permission-set.md`: Permission set membership for new objects
    - Every exposed object needs an explicit execute entry in a shipped permission set.
[25] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Permission set granularity
    - Enumerate each tabledata and object explicitly; no wildcard grants; grant only needed letters.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
