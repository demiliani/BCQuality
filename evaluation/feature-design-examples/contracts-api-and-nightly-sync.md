# Feature design

> Our customer portal needs to read maintenance contracts and their lines through an API. In addition, every night Business Central must send the contracts that changed during the day to the portal's REST endpoint.

**Result:** Complete design. **Business process:** Maintenance contract data exposed to an external portal: inbound read through API pages, outbound nightly synchronization of changed contracts through an outbox and a recurring job queue entry. **Knowledge used:** 40 BCQuality articles.

**Why:** Inbound API and nightly outbound sync are designed with cited knowledge; table ownership, the portal's payload and authentication, and the definition of a change are open questions to answer before implementation.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What are the exact names, keys and owning app of the maintenance contract header and line tables? The design assumes this app owns them so their triggers can record changes; if they belong to another app, change capture needs table events that are not confirmed here. _(affects: contract-header-table, contract-line-table, contract-change-recorder)_
2. Which contract and line fields must the portal read, and are any of them derived or calculated values? _(affects: contracts-api-page, contract-lines-api-page)_
3. Which APIPublisher and APIGroup values should the endpoints use? _(affects: contracts-api-page, contract-lines-api-page)_
4. Will the portal ever write contracts or subscribe to webhooks, or only read by polling? The design is read-only. _(affects: contracts-api-page, contract-lines-api-page)_
5. How does Business Central authenticate to the portal's REST endpoint: does it support OAuth2 client credentials, or only an API key? _(affects: contract-sync-worker, portal-sync-setup-card)_
6. What payload does the portal expect (full contract with lines, or only identifiers), one request per contract or a batch, and does it deduplicate on an idempotency key? _(affects: contract-sync-worker, contract-sync-outbox-table)_
7. Which changes count as 'changed during the day': header edits only, or also line inserts, edits and deletions? Must deleted contracts be sent to the portal, and how? _(affects: contract-header-table, contract-line-table, contract-change-recorder, contract-sync-outbox-table)_
8. If a contract changes several times in a day, should it be sent once (latest state) or once per change? _(affects: contract-change-recorder, contract-sync-outbox-table)_
9. At what time and in which time zone should the nightly run start, and how many retries are acceptable before an administrator must intervene? _(affects: contract-sync-worker)_
10. Does the sync run for one company or for several companies, each with its own endpoint? _(affects: portal-sync-setup-table, contract-sync-worker)_
11. What is the fixed portal host or URL pattern the endpoint must match? _(affects: contract-sync-worker, portal-sync-setup-table)_
12. Which Business Central version does the app target? SecretText overloads assume BC24 or later. _(affects: contract-sync-worker, portal-sync-setup-card)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | table | Maintenance Contract header table (existing; exact name to confirm) | Source of the contracts API page and of nightly change capture. Its OnInsert, OnModify, OnRename and OnDelete triggers call the contract change recorder so that every change, including a rename of the contract number, leaves an outbox row in the same transaction. Renaming fires OnRename and not OnModify, so OnRename must record the change too. No new fields; the API addresses contracts by the built-in SystemId. |  | [11] [37] [6] |
| 2 | extend | table | Maintenance Contract line table (existing; exact name to confirm) | Source of the contract-lines API part. Gains a Guid foreign key to the header's SystemId so the API part links on the stable identity, and records a change of its contract in the outbox from its own insert, modify, rename and delete triggers if line changes count as contract changes (open question). | Contract Id (Guid): TableRelation to the contract header table's SystemId; set whenever the line's contract number is set, and backfilled for existing lines by the upgrade codeunit. Needs an explicit field-level DataClassification if the line table is extended through a tableextension. | [7] [31] [32] |
| 3 | create | page | Maintenance Contracts API (PageType = API) | Read-only endpoint for the portal. APIPublisher, APIGroup, EntityName = 'maintenanceContract', EntitySetName = 'maintenanceContracts', explicit APIVersion = 'v1.0', SourceTable = contract header, ODataKeyFields = SystemId with field(id; Rec.SystemId) Editable = false, contract number exposed as an ordinary field. Editable = false, InsertAllowed = false, ModifyAllowed = false, DeleteAllowed = false, DataAccessIntent = ReadOnly. Contains a lines part linked with SubPageLink = "Contract Id" = Field(SystemId) as a collection. An API page is chosen over an API query because the portal reads a contract with its nested lines and may later need webhooks; any future change of shape goes into a new page object for v2.0. |  | [2] [3] [5] [6] [7] [8] [9] [4] |
| 4 | create | page | Maintenance Contract Lines API (PageType = API) | Read-only API part for the contract lines: EntityName = 'maintenanceContractLine', EntitySetName = 'maintenanceContractLines', APIVersion = 'v1.0', ODataKeyFields = SystemId, exposes id (SystemId) and contractId, with the same read-only guards and DataAccessIntent = ReadOnly. |  | [3] [5] [6] [7] [8] [9] |
| 5 | create | table | Portal Sync Setup | Singleton per-company setup for the nightly sync. Holds no credentials; secrets live in IsolatedStorage. Table-level DataClassification with no ToBeClassified left. | Primary Key (Code[10]): Sole key, left blank.; Enabled (Boolean): Whether contract changes are recorded and sent.; Portal Endpoint URL (Text[250]): Validated against a hard-coded expected host or URL pattern before every HTTP call; TestField before use. | [29] [22] [19] [30] [31] [32] |
| 6 | create | page | Portal Sync Setup (Card) | Card over the setup with InsertAllowed = false and DeleteAllowed = false, inserting the blank row on open. Actions to enter the portal credential (written straight to IsolatedStorage as SecretText) and to approve the portal privacy notice; no business logic in the page beyond invoking codeunits. |  | [29] [19] [21] [23] |
| 7 | create | table | Contract Sync Outbox | Work item written in the same transaction as the contract change, so it commits or rolls back with it. The worker deletes a row only after the portal call and all local updates succeed; there is no Processed flag. The row's SystemId is the idempotency key sent to the portal. | Entry No. (Integer): AutoIncrement primary key.; Contract Id (Guid): SystemId of the changed contract; stable across renames.; Contract No. (Code[20]): Business key at the time of the change, for diagnostics; length must match the contract header's No. field. | [11] [12] [31] [32] |
| 8 | create | codeunit | Contract Change Recorder | Called from the contract (and, if confirmed, line) table triggers. When Portal Sync Setup is Enabled, inserts a Contract Sync Outbox row for the contract. Performs no HTTP call, so no lock is held on external I/O inside the user's write transaction. |  | [11] |
| 9 | create | codeunit | Contract Sync Worker (TableNo = "Job Queue Entry") | Entry point of the nightly recurring job queue entry. Non-interactive (no Confirm, Page.Run, Message as status). Steps: Get setup and TestField the endpoint; check the custom privacy notice with GetPrivacyNoticeApprovalState (no UI) and error when not approved; validate the endpoint URL with the Uri codeunit; read the credential from IsolatedStorage as SecretText and set it through the SecretText HttpHeaders/HttpRequestMessage APIs (OAuth2 codeunit token if the portal supports OAuth); for each committed outbox row build JSON with the row SystemId as idempotencyKey and typed values (JsonObject.Add with Date/Decimal, or Format(Value, 0, 9)); send; on a false Boolean stop without reading the response; check IsSuccessStatusCode before reading the body; delete the row only after success. Failures propagate so the job queue entry shows the error and retries apply. Logs FeatureTelemetry usage only after a successful run, with non-personal custom dimensions only. |  | [11] [12] [13] [14] [16] [17] [18] [19] [20] [21] [22] [23] [25] [30] [27] [28] [26] |
| 10 | create | codeunit | Portal Sync Privacy Notice | Owns a stable, app-specific privacy notice ID for the portal integration and registers it by subscribing to Codeunit "Privacy Notice" OnRegisterPrivacyNotices; exposes the approval check used by the setup card and the worker. Never reuses a built-in notice ID. |  | [24] [23] |
| 11 | create | permissionset | Contracts API - Read (Assignable = false) | Building block granting X on both API pages and R on the contract header and line table data, enumerated explicitly with no wildcards. |  | [10] [33] [34] |
| 12 | create | permissionset | Portal Sync - Admin (Assignable = false) and role-shaped assignable sets | Building block for the setup table and page, outbox, worker and recorder (RIMD only where owned), plus an outbox insert grant so that every user who edits contracts can record changes. Assignable role sets (portal integration user, portal sync admin) compose the building blocks through IncludedPermissionSets. |  | [33] [34] |
| 13 | create | codeunit | Portal Sync Install (Subtype = Install) | First-install and reinstall initialization only: create the empty setup row. Version migration is not placed here because install code does not run on upgrade. |  | [35] [29] |
| 14 | create | codeunit | Portal Sync Upgrade (Subtype = Upgrade) | For tenants that already have contracts: backfill Contract Id on existing contract lines and create the setup row, each step guarded by its own upgrade tag (HasUpgradeTag at entry, SetUpgradeTag at the end) instead of version checks. No HTTP calls during upgrade. |  | [35] [36] |

## 3. How the data flows

- **Maintenance Contract header table** → **Maintenance Contracts API (maintenanceContracts)**: other. API page read over the source table, addressed by SystemId. [3] [6] [8]
- **Maintenance Contract line table** → **Maintenance Contract Lines API part (maintenanceContractLines)**: other. API part linked on Contract Id = header SystemId, collection multiplicity. [7]
- **Contract line Contract No. (existing link)** → **Contract line Contract Id**: field validation. Set whenever the line's contract number is set; existing rows backfilled by the upgrade codeunit. [7] [36]
- **Contract header (and line) insert, modify, rename, delete** → **Contract Sync Outbox**: other. Table trigger calls Contract Change Recorder, which inserts the outbox row inside the same write transaction; OnRename recorded explicitly. [11] [37]
- **Contract Sync Outbox (committed rows)** → **Portal REST endpoint**: other. Nightly recurring job queue entry runs Contract Sync Worker; HTTP POST outside any write transaction with idempotencyKey = outbox SystemId; row deleted after success. [11] [12] [16] [17] [25]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Privacy Notice" | `OnRegisterPrivacyNotices` | Register the portal integration's own privacy notice ID, name and link so an administrator can approve it before data leaves Business Central. | Use a stable, app-owned notice ID; never a built-in one such as the Exchange ID. · Insert into the temporary Privacy Notice record without failing if the ID is already present. | [24] |

## 5. Setup, permissions and lifecycle

- **setup**: Portal Sync Setup singleton with card page; endpoint URL required (TestField) before the worker uses it; Enabled flag gates recording and sending. [29] [30]
- **setup**: Credential capture on the setup card: OAuth2 (client credentials) if the portal supports it, otherwise the portal's key; either way stored only in IsolatedStorage and carried as SecretText to the HTTP header or request URI. [18] [19] [21] [20]
- **privacy**: Register the portal privacy notice and require its approval before any send; the worker checks approval state without UI and fails the run when not approved. [24] [23]
- **privacy**: Classify the new tables at table level and the new tableextension field (if any) explicitly; resolve every ToBeClassified before release. [31] [32]
- **permissions**: Explicit X grants for both API pages in a permission set; building-block sets with Assignable = false composed into role sets through IncludedPermissionSets; no wildcard grants. [10] [33] [34]
- **background**: One recurring job queue entry per company that runs Contract Sync Worker nightly, with a non-empty Job Queue Category Code shared by any other job that must not overlap with this sync. [15] [13] [14]
- **install**: Install codeunit creates the setup row on first install or reinstall only. [35]
- **upgrade**: Upgrade codeunit backfills Contract Id on existing lines and creates the setup row on existing tenants, each step under its own upgrade tag; no external calls. [35] [36]
- **telemetry**: FeatureTelemetry LogUsage only after a successful nightly run, LogError on failure; integration failures sent with TelemetryScope::All so the tenant operator can act; no contract, customer or user data in custom dimensions (counts and status only). [27] [26] [28]

## 6. Tests

1. **api-returns-contract-with-lines** [6] [7] [38] [40]
    - Given A contract with two lines created through the app's contract test helpers, with Contract Id set on the lines
    - When The maintenanceContracts API page is read for that contract's SystemId with its lines part expanded
    - Then The contract is returned under id = SystemId with exactly its two lines, each carrying contractId = the contract's SystemId
2. **api-rejects-writes** [8] [40]
    - Given An existing contract
    - When An insert, modify or delete is attempted through the contracts API page (and through the lines page)
    - Then Each write is rejected and the contract is unchanged
3. **api-key-survives-rename** [6] [40]
    - Given A contract read through the API and its SystemId stored
    - When The contract number is renamed
    - Then Reading the API by the stored SystemId still returns the contract with the new number
4. **change-records-outbox-row** [11] [40]
    - Given Portal sync enabled and a contract with no outbox rows
    - When The contract is modified
    - Then One Contract Sync Outbox row exists for that contract's SystemId
5. **rename-records-outbox-row** [37] [40]
    - Given Portal sync enabled and a contract with no outbox rows
    - When The contract number is renamed
    - Then An outbox row exists for the contract, proving OnRename records the change
6. **rolled-back-change-leaves-no-outbox-row** [11] [40]
    - Given Portal sync enabled and a contract
    - When A contract modification is followed by an error in the same transaction (asserterror)
    - Then Neither the change nor an outbox row persists
7. **worker-sends-and-deletes** [12] [25] [40]
    - Given Setup with a valid endpoint, approved privacy notice, a stored credential and one outbox row; the portal call answered with a success status by a test double
    - When Contract Sync Worker runs
    - Then The request body carries idempotencyKey = the outbox row SystemId and the contract data in culture-independent formats, and the outbox row is deleted
8. **worker-non-success-keeps-row** [17] [14] [12] [40]
    - Given One outbox row and a portal double that returns a 4xx or 5xx status
    - When Contract Sync Worker runs
    - Then The run ends in an error naming the status, the response body is not parsed as success, and the outbox row still exists for the next run
9. **worker-retry-reuses-key** [12] [40]
    - Given An outbox row whose first send failed after the portal accepted it
    - When The worker runs again
    - Then The same idempotencyKey is sent again
10. **worker-blocks-without-consent** [23] [40]
    - Given Setup complete but the portal privacy notice not approved, and one outbox row
    - When Contract Sync Worker runs
    - Then No request is sent, the run errors, and the outbox row remains
11. **worker-blocks-unexpected-host** [22] [40]
    - Given Portal Endpoint URL changed to a host that does not match the expected host or pattern
    - When Contract Sync Worker runs
    - Then The run errors before any HTTP call
12. **worker-requires-endpoint** [30] [40]
    - Given Portal sync enabled with a blank Portal Endpoint URL and one outbox row
    - When Contract Sync Worker runs
    - Then The TestField error for Portal Endpoint URL is raised
13. **worker-runs-without-ui** [13] [40]
    - Given One outbox row and a successful portal double
    - When The worker runs through a job queue entry in a background session
    - Then It completes without requiring any UI handler
14. **api-role-can-read-contracts** [39] [10] [40]
    - Given Test runner with TestPermissions = Restrictive and the current user lowered to the assignable role that includes Contracts API - Read
    - When The contracts API page is read
    - Then The contract and lines are returned, while opening Portal Sync Setup is denied
15. **upgrade-backfills-contract-id** [36] [40]
    - Given Existing contract lines without Contract Id and the upgrade tag not set
    - When The upgrade codeunit runs, then runs again
    - Then Every line has Contract Id = its header's SystemId after the first run, and the second run does nothing because the tag is set

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown: no app.json was available and the request does not state them.
- No repository was supplied: existing contract tables, ID ranges, permission sets and install/upgrade codeunits could not be reused or confirmed.
- Creating the recurring nightly job queue entry (from install, upgrade or a setup action) rests on agent judgment; no BCQuality article covers how to create it.
- Replacing the portal with a test double for HTTP calls in the worker tests rests on agent judgment; no BCQuality article covers HTTP test doubles.
- No test Library codeunit exists for maintenance contracts; the app needs its own fixture helpers (agent judgment).
- If the contract tables are not owned by this app, recording changes needs table events that are not confirmed in an opened article or repository symbols.

## Sources

[1] `microsoft/knowledge/feature-design/plan-api-exposure-and-background-sync.md`: Planning order of the inbound API and outbound nightly sync decisions.
    - Plan inbound first, then outbound, then shared concerns.
    - Do not call the external service from the action that changes the data; use an outbox and a recurring job queue entry.
    - Facts the request leaves open (who calls whom, how often, how the service treats repeats) are questions for the requester.
[2] `microsoft/knowledge/web-services/api-query-is-read-only-and-has-no-webhooks.md`: Choosing API pages rather than an API query for contracts with nested lines.
    - An API query is read-only and supports no webhooks; an API page supports writes and webhooks.
    - Decide from the consumer's operations; API objects cannot be extended.
[3] `microsoft/knowledge/web-services/set-required-api-page-properties.md`: Routing properties of both API pages.
    - Declare APIPublisher, APIGroup, EntityName, EntitySetName and SourceTable.
    - Set APIVersion explicitly (for example 'v1.0'); omitted, it publishes as beta.
[4] `microsoft/knowledge/web-services/version-apis-by-adding-not-mutating-published-versions.md`: Future evolution of the contracts API.
    - Never change a published v1.0 page's shape; create a new page object for v2.0.
    - A multi-value APIVersion list is only valid when the shape is identical.
[5] `microsoft/knowledge/style/api-page-entity-naming-singular-plural.md`: Entity names of the API pages.
    - EntityName singular, EntitySetName plural, both camelCase; pluralize only the trailing noun.
[6] `microsoft/knowledge/web-services/expose-systemid-as-the-api-key.md`: Key of both API pages.
    - ODataKeyFields = SystemId and field(id; Rec.SystemId) with Editable = false.
    - Keep the contract number as an ordinary field, not the OData key.
[7] `microsoft/knowledge/web-services/link-api-parts-on-systemid-and-set-multiplicity.md`: Linking the lines part to the contract.
    - Child carries a Guid foreign key with TableRelation to the parent's SystemId; SubPageLink = "<Parent Id>" = Field(SystemId).
    - Lines are a collection: omit Multiplicity or set Many; never ZeroOrOne.
    - Multiplicity guidance applies from runtime 6.3 (BC 17.3).
[8] `microsoft/knowledge/web-services/disable-write-operations-on-read-only-api-pages.md`: Locking down the read-only API pages.
    - Set InsertAllowed = false, ModifyAllowed = false, DeleteAllowed = false and Editable = false; the API page default is writable.
[9] `microsoft/knowledge/performance/dataaccessintent-readonly-on-analytical-objects.md`: Routing portal reads to a read replica.
    - Set DataAccessIntent = ReadOnly on API pages with Editable = false that never write.
    - Applies from runtime 5.0 (BC 16).
[10] `microsoft/knowledge/security/exposed-objects-must-be-in-a-permission-set.md`: Permission entries for the API pages.
    - Each API page needs an explicit page "..." = X entry in a shipped permission set; table data grants alone do not make the endpoint usable.
[11] `microsoft/knowledge/performance/httpclient-inside-write-transaction-holds-locks.md`: Change capture and where the HTTP call runs.
    - Never call HttpClient after a write in the same transaction.
    - Insert an outbox row in the same transaction as the change and process committed rows from a recurring job queue entry.
    - Delete the outbox row only after the HTTP call; do not use Commit() as a general remedy.
[12] `microsoft/knowledge/performance/job-queue-external-effects-must-be-idempotent.md`: Retry safety of the nightly send.
    - Send a stable request ID that exists before processing, such as the outbox row SystemId as idempotencyKey.
    - The portal must enforce uniqueness of that key.
    - Delete the outbox row only after the call and all local updates succeed; a Processed flag does not close the failure window.
[13] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Worker codeunit behavior.
    - No Confirm, Page.Run/RunModal, Report.RunModal, Hyperlink, upload or download in the job queue handler.
    - Message cannot report status; persist status or let errors propagate.
[14] `microsoft/knowledge/performance/job-queue-handlers-must-propagate-failures.md`: Failure handling in the worker.
    - Let run-invalidating errors propagate out of the job queue entry point.
    - Per-item failures may be collected only with an observable aggregate outcome.
[15] `microsoft/knowledge/performance/job-queue-category-code-serializes-conflicting-jobs.md`: Scheduling the nightly job queue entry.
    - Give jobs that must not overlap the same non-empty Job Queue Category Code.
    - A category does not serialize across companies or environments.
[16] `microsoft/knowledge/web-services/handle-httpclient-platform-failure-before-response-access.md`: Transport failure handling.
    - When the Boolean return is captured and false, do not read status, headers or content.
    - Omitting the Boolean to let the runtime raise the error is also valid.
[17] `microsoft/knowledge/web-services/check-http-status-before-consuming-response-body.md`: Response handling.
    - Check IsSuccessStatusCode or the expected status before treating the body as a success payload.
[18] `microsoft/knowledge/security/prefer-oauth2-over-api-keys-for-external-http-calls.md`: Portal authentication choice.
    - When the portal supports OAuth, use the OAuth2 codeunit rather than an API key or basic auth.
    - Carry tokens and secrets as SecretText, persisted only in IsolatedStorage.
[19] `microsoft/knowledge/security/secrets-isolated-storage.md`: Where the portal credential is stored.
    - Never store a credential in a table field, including the setup table.
    - Persist in IsolatedStorage, preferring SetEncrypted within its length limit; on BC24+ use the SecretText overloads.
[20] `microsoft/knowledge/security/secrettext-with-httpclient.md`: Passing the credential to the HTTP request.
    - Use SetSecretRequestUri for a secret URI and SecretText HttpHeaders.Add for authorization headers; never materialize the secret as Text.
[21] `microsoft/knowledge/security/secrettext-for-credentials.md`: Typing credential variables in the worker and setup card.
    - Declare credential parameters and variables as SecretText end to end; no round-trip through Text.
[22] `microsoft/knowledge/security/validate-user-configurable-urls.md`: Guarding the configurable portal endpoint.
    - Before any HttpClient call with a URL from a table field, validate it with Uri.AreURIsHaveSameHost against a hard-coded base or Uri.IsValidURIPattern against a fixed pattern, and error when it fails.
[23] `microsoft/knowledge/privacy/privacy-notice-consent-for-external-data-transfer.md`: Gating the nightly send on consent.
    - Use the integration's own notice ID, never a built-in one.
    - Check approval before sending: ConfirmPrivacyNoticeApproval outside a write transaction, or GetPrivacyNoticeApprovalState when no UI is allowed.
    - No path sends data without approval.
[24] `microsoft/knowledge/privacy/register-integration-in-privacy-notice-registrations.md`: Registering the portal privacy notice.
    - Choose a stable app-owned ID and register it through Codeunit "Privacy Notice" OnRegisterPrivacyNotices or CreatePrivacyNotice.
    - Do not subscribe to Privacy Notice Registrations or reuse built-in IDs.
[25] `microsoft/knowledge/web-services/format-exchanged-values-with-standard-format-9.md`: Building the JSON payload sent to the portal.
    - Use typed JsonObject.Add values or Format(Value, 0, 9) for decimals, dates, times, datetimes and booleans.
    - Format 9 gives enum ordinals; map enum names explicitly if the portal expects names.
[26] `microsoft/knowledge/telemetry/choose-telemetry-scope-by-audience.md`: Telemetry audience for sync signals.
    - Use TelemetryScope::All for signals the tenant operator can act on, such as integration failures; ExtensionPublisher for publisher-only diagnostics.
[27] `microsoft/knowledge/telemetry/feature-usage-only-after-success.md`: When to log feature usage.
    - Call LogUsage only after successful completion; use LogError on failure; never in both branches.
[28] `microsoft/knowledge/privacy/featuretelemetry-customdimensions-no-pii.md`: Telemetry payload content.
    - No customer, employee or user data and no GetLastErrorText in CustomDimensions; only counts, statuses, error codes and durations.
[29] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Portal Sync Setup table and card.
    - Primary Key Code[10] as sole key with a blank value.
    - Card with InsertAllowed = false, DeleteAllowed = false and an open-time insert of the missing row; no list page.
[30] `microsoft/knowledge/data-modeling/testfield-required-setup-field.md`: Guarding the required endpoint setting.
    - TestField a setup value the branch requires instead of silently falling back; test that a blank value raises the error.
[31] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Data classification of the new tables and field.
    - A table-level DataClassification is inherited by that table's Normal fields.
    - Fields added by a tableextension inherit nothing and need an explicit classification.
[32] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of the new fields.
    - No field may ship with DataClassification = ToBeClassified.
[33] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Structure of the permission sets.
    - Small building-block sets with Assignable = false, composed into assignable role sets through IncludedPermissionSets.
[34] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Content of the permission sets.
    - Enumerate every tabledata and object entry; no * grants; grant only the letters needed (R for readers).
[35] `microsoft/knowledge/upgrade/install-code-does-not-run-on-version-upgrade.md`: Splitting install from upgrade steps.
    - Install code runs only on first install or reinstall, not on version upgrade; migration goes in an Upgrade codeunit.
[36] `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`: Guarding the upgrade backfill.
    - Start each upgrade step with HasUpgradeTag and end with SetUpgradeTag; one tag per feature; no version checks.
[37] `microsoft/knowledge/data-modeling/set-last-date-modified-in-onmodify-and-onrename.md`: Capturing renames of contracts as changes.
    - Renaming a record fires OnRename and not OnModify; change detection that relies only on OnModify misses renamed records.
[38] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build prerequisite records with Library codeunits where they exist; create parents before dependents and Validate foreign keys.
[39] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: Permission test of the API role.
    - Use TestPermissions::Restrictive and lower the user with Permissions Mock or Library - Lower Permissions to a context containing the set under test before the protected operation.
[40] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of every test codeunit.
    - [FEATURE] on the codeunit; [SCENARIO], [GIVEN], [WHEN], [THEN] comments in each test.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
