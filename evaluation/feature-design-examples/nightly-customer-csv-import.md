# Feature design

> Every night our web shop exports a CSV file of newly registered customers. Import them as customers in the background, report rows that fail without stopping the rest of the file, let the administrator change the column layout without a new release, and keep the import log for 90 days.

**Result:** Complete design. **Business process:** Nightly background import of new web shop customers from a CSV file into the Customer master table through a data exchange definition and a job queue entry, with per-row error logging kept under retention policies; it extends customer master data creation in the base application, not a posting process. **Knowledge used:** 27 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Where does the web shop put the nightly CSV, and how may Business Central read it from a background session (for example a storage service, a mailbox, or the web shop pushing the file through an API)? What happens to the file after import (move, archive, delete)? _(affects: import-job-handler, import-setup)_
2. What are the separator, header line, encoding, and date and decimal formats of the file, and which columns does it contain? _(affects: import-buffer, mapping-codeunit)_
3. Which Customer fields must be filled from the file? Adding a field that has no buffer field later needs a release; only the column layout of existing fields is admin-configurable. _(affects: import-buffer, row-codeunit)_
4. Should a customer template supply posting groups and other defaults for imported customers, and is one template enough for all web shop customers? _(affects: import-setup, row-codeunit, template-fills-empty-fields)_
5. Should customer numbers come from the customer number series, or does the web shop supply a number to use as "No."? _(affects: row-codeunit)_
6. How should a customer already imported (same web shop customer ID or e-mail) or a file delivered twice be treated: skip, update, or fail the row? Should the web shop customer ID be stored on the customer? _(affects: row-codeunit, import-log-entry)_
7. When some rows fail, should the job queue entry itself end in Error (so the standard job queue notifications fire) or finish with the run marked Completed with Errors? A retry or rerun of the same file would re-create customers already created. _(affects: import-job-handler)_
8. Should the log be deleted after exactly 90 days or kept at least 90 days, which standard retention period should the default policy use, and should it ship enabled? _(affects: retention-codeunit, install-codeunit)_
9. Which user or permission set does the nightly job queue entry run under, and is it allowed to create customers? _(affects: permission-sets)_
10. Should anyone be notified of failed rows (for example by e-mail), or is the import run list enough? _(affects: import-run-pages)_
11. Do you want feature telemetry for runs and failures? If yes, it carries only counts and statuses. _(affects: import-job-handler)_
12. Should the Data Exch. records of processed files be deleted after the run, and when? _(affects: import-job-handler)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Web Shop Cust. Import Setup | Singleton setup for the import: blank Code[10] "Primary Key", the data exchange definition code that describes the CSV layout, the job queue category code, and (if confirmed) the customer template to apply and the file source settings. The CSV layout itself lives in the data exchange definition so the administrator changes columns, separator, header lines and encoding without a release. | Primary Key (Code[10]): always blank; Data Exch. Def. Code (Code[20]): TableRelation to Data Exch. Def; the shipped definition is the default; Job Queue Category Code (Code[10]): shared by every entry that runs this import; Customer Templ. Code (Code[20]): only if open question customer-template is answered yes | [7] [6] [2] |
| 2 | create | page | Web Shop Cust. Import Setup | Card page over the setup singleton with InsertAllowed = false, DeleteAllowed = false and an OnOpenPage guard that inserts the blank row when missing; actions to open the data exchange definition for editing, to schedule the nightly job queue entry and to open the import runs. |  | [7] |
| 3 | create | table | Web Shop Cust. Import Buffer | TableType = Temporary mapping target for Process Data Exch. Its last primary key field is an Integer line number, as ProcessColumnMapping requires; Customer cannot be the mapping target because its key is Code "No.". Fields hold the raw column values as text so that the administrator can map any file column to them; the shipped field list is fixed by the release. It is a working table, not one of the nine business table types. | Import Run No. (Integer): key field 1, set on the template record; Line No. (Integer): key field 2, set by ProcessColumnMapping from the file line number; Data Exch. Entry No. (Integer); Web Shop Customer ID (Text[50]): DataClassification = CustomerContent; Name (Text[100]): CustomerContent; Address (Text[100]): CustomerContent; Post Code (Text[20]): CustomerContent; City (Text[30]): CustomerContent; Country/Region Code (Text[10]): CustomerContent; E-Mail (Text[80]): CustomerContent; Phone No. (Text[30]): CustomerContent | [2] [6] [20] |
| 4 | create | table | Web Shop Cust. Import Run | Log header, one row per processed file: Integer "No.", started/finished, data exchange entry, rows read, created and failed, and status (In Progress, Completed, Completed with Errors, Failed). It is the persisted aggregate outcome of the job, so a run with failed rows is observable even though the job itself finishes. Owned by the app, registered for retention policies. | No. (Integer); Status (Enum "Web Shop Cust. Import Status"); Data Exch. Entry No. (Integer); File Name (Text[250]): CustomerContent; Rows Read (Integer); Customers Created (Integer); Rows Failed (Integer) | [16] [18] [20] |
| 5 | create | table | Web Shop Cust. Import Log Entry | Log line, one row per file row: run no., line no., result (Created or Failed), created customer no., the identifying values of the row and the error text of a failed row. Rows are written after the row loop from an in-memory list, so a failed row's rollback never removes its own log line. Owned by the app, registered for retention policies. | Run No. (Integer); Line No. (Integer); Result (Enum "Web Shop Cust. Import Result"); Customer No. (Code[20]): TableRelation Customer; Web Shop Customer ID (Text[50]): CustomerContent; Name (Text[100]): CustomerContent; E-Mail (Text[80]): CustomerContent; Error Message (Text[2048]): CustomerContent: error text can contain field values from the file | [14] [12] [18] [20] |
| 6 | create | enum | Web Shop Cust. Import Status | Status values of an import run; a second enum "Web Shop Cust. Import Result" holds Created and Failed for log entries. |  | agent judgment |
| 7 | create | page | Web Shop Cust. Import Runs | Read-only list of import runs with a drill-down to their log entries (a second read-only list page "Web Shop Cust. Import Log"), so the administrator sees which rows failed and why. |  | agent judgment |
| 8 | create | codeunit | Web Shop Cust. Import Mapping | Mapping Codeunit of the Data Exch. Mapping, TableNo = "Web Shop Cust. Import Buffer": gets the Data Exch. from the template record and calls Process Data Exch. ProcessAllLinesColumnMapping(DataExch, RecRef) on the temporary template record. |  | [2] |
| 9 | create | codeunit | Web Shop Cust. Import Job | Job queue entry point, non-interactive. Reads setup, obtains the file content as a stream, inserts the run row, imports the file into Data Exch. with the configured definition, commits once, maps into the temporary buffer, then calls the row codeunit with "if Codeunit.Run" per buffer row, collecting each failure (line, identifying values, GetLastErrorText) in memory. After the loop it writes the log entries and the run totals and status. Failures that invalidate the whole run (no setup, unreadable file, missing definition) are raised as errors so the job queue entry shows them. |  | [15] [16] [11] [12] [13] [14] [3] [2] |
| 10 | create | codeunit | Web Shop Cust. Create Customer | One file row as an atomic sub-operation, TableNo = "Web Shop Cust. Import Buffer". Customer.Init, Customer.Insert(true) so OnInsert assigns "No." from the number series and the standard defaults, then Validate each mapped field from the buffer, then (if confirmed) apply the customer template, then Modify(true). Any error rolls back the whole customer of that row only. |  | [9] [11] [10] [5] |
| 11 | create | codeunit | Web Shop Cust. Import Install | Subtype = Install, OnInstallAppPerCompany: imports the shipped data exchange definition once, registers both log tables as retention-policy allowed tables, creates the default retention policy setup, and seeds the upgrade tags. |  | [18] [19] [2] [24] [23] |
| 12 | create | codeunit | Web Shop Cust. Import Upgrade | Subtype = Upgrade, OnUpgradePerCompany: calls the same retention registration routine, because install code does not run on a version upgrade; every step guarded by its own upgrade tag. |  | [18] [23] [24] |
| 13 | create | codeunit | Web Shop Cust. Import Retention | Shared registration routine for the run and log entry tables (AddAllowedTable with SystemCreatedAt and MandatoryMinRetenDays = 90), with a ForceUpdate path for OnRefreshAllowedTables, plus the one-time default Retention Policy Setup creation. Needs tabledata "Retention Policy Setup" = ri. |  | [18] [19] |
| 14 | create | permissionset | WEBSHOP CUST IMPORT | Non-assignable building blocks composed into assignable role sets: an admin set (setup RIMD, runs and log R, execute on the job and page objects) and a viewer set (runs and log read). Log and run tables are written only by the import code, so roles get indirect insert/modify on them rather than direct rights. |  | [22] [21] |

## 3. How the data flows

- **Web shop CSV file** → **Data Exch. (Data Exch. Field rows)**: other. The job obtains the file as an InStream (no File type), then runs ImportToDataExch with the configured Generic Import definition and its CSV reading XMLport; File Encoding is set explicitly on the definition. Where the background job fetches the file from is an open question and rests on judgment. [2] [3] [4]
- **Data Exch. Field rows** → **Web Shop Cust. Import Buffer (temporary)**: other. Mapping codeunit runs ProcessAllLinesColumnMapping into the temporary template record; column-to-field mapping, column order, optional columns and transformation rules come from Data Exch. Field Mapping, which the administrator edits. [2]
- **Web Shop Cust. Import Buffer (temporary)** → **Customer**: field validation. Per row through Codeunit.Run: Insert(true), Validate each field, Modify(true). Non-text values parsed from machine-generated text use Evaluate with format 9 unless the definition's transformation rule converts them. [9] [11] [5]
- **Customer Templ.** → **Customer**: other. Only if the requester confirms a template: applied after the file values are set, so the template fills empty fields and does not overwrite file values for customers. [10]
- **In-memory row results** → **Web Shop Cust. Import Log Entry**: other. Written in one pass after the row loop, outside any row's rollback boundary. [12] [14]
- **Row results** → **Web Shop Cust. Import Run**: other. Totals and status written after the loop; run-level failures propagate to the job queue log entry. [16]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Reten. Pol. Allowed Tables | `OnRefreshAllowedTables` | Re-register the run and log entry tables with ForceUpdate when the administrator refreshes the allowed tables on the Retention Policies page. | Pass ForceUpdate = true so the upgrade tag does not stop re-registration · Skip AddAllowedTable when IsAllowedTable is already true | [18] |

## 5. Setup, permissions and lifecycle

- **setup**: Ship a data exchange definition (type Generic Import, CSV reading XMLport 1220, explicit File Encoding, header lines, column definitions and field mappings to the buffer table with the mapping codeunit) and import it per company with XMLport 1225 "Imp / Exp Data Exch Def & Map" once, guarded by an upgrade tag so administrator changes are not overwritten on upgrade. [2] [23]
- **setup**: Setup card creates its singleton row on first open; the administrator selects the definition code, job queue category and (if confirmed) the customer template. [7]
- **background**: Schedule one recurring nightly job queue entry for the import job codeunit with the setup's non-empty Job Queue Category Code, so a manual rerun and the nightly run never overlap. The handler has no Confirm, Message, page, report, upload or download. [15] [17]
- **background**: Transactions: one Commit after the run row and the Data Exch. import, before the first per-row Codeunit.Run; no Commit inside the row loop; log entries and totals written after the loop. [12] [13] [11]
- **background**: Failure reporting: per-row failures are recorded deliberately as Failed log entries and a Completed with Errors run status; errors that invalidate the whole run propagate out of the handler so the job queue entry shows Error. [16]
- **install**: Install codeunit registers Web Shop Cust. Import Run and Web Shop Cust. Import Log Entry with AddAllowedTable (SystemCreatedAt, MandatoryMinRetenDays 90), creates the default Retention Policy Setup once, and seeds the upgrade tags with SetUpgradeTag; tags also returned from OnGetPerCompanyUpgradeTags for new companies. [18] [19] [24]
- **upgrade**: Upgrade codeunit calls the same registration routine in OnUpgradePerCompany, each step guarded by HasUpgradeTag and closed with SetUpgradeTag. [18] [23]
- **privacy**: Classify every buffer, run and log field that holds file values or error text as CustomerContent; counters and statuses as SystemMetadata. Keep file values and error text out of any telemetry dimension. [20] [27]
- **permissions**: Ship non-assignable building-block permission sets (setup, log read, import execution) and assignable admin and viewer sets that include them; log and run tables get indirect insert/modify so only the import code writes them. [22] [21]

## 6. Tests

1. **valid-file-creates-customers** [9] [2] [25]
    - Given Shipped definition, Sales & Receivables customer number series, a UTF-8 CSV with two valid rows
    - When The import job codeunit runs
    - Then Two customers exist with "No." from the number series and the file values; two Created log entries reference them; the run is Completed with Rows Read 2, Customers Created 2
2. **failed-row-does-not-stop-file** [11] [12] [14]
    - Given A CSV with three rows where the second has an invalid Country/Region Code
    - When The import job runs
    - Then Rows 1 and 3 create customers; no customer exists for row 2; a Failed log entry for line 2 carries the validation error; the run is Completed with Errors with Rows Failed 1
3. **layout-change-without-release** [2]
    - Given The administrator swaps two columns in the CSV and updates the column numbers in the definition's field mapping
    - When The import job runs on the reordered file
    - Then Customers carry the same values as with the original layout
4. **encoding-preserves-accents** [4] [2]
    - Given A UTF-8 CSV with names such as Müller and Łódź
    - When The import job runs
    - Then Customer Name and City hold the accented characters unchanged
5. **buffer-guard-rejects-real-table** [8]
    - Given The row-processing helper called with a non-temporary buffer variable
    - When It runs
    - Then It raises an error naming the parameter before any write
6. **run-level-failure-propagates** [16] [15]
    - Given Setup with a definition code that does not exist
    - When The job queue handler runs
    - Then The handler raises an error, so the job queue entry would show Error; no customers are created
7. **no-ui-in-background** [15]
    - Given A test runner with no UI handlers registered
    - When The import job codeunit runs over a file with valid and failed rows
    - Then It completes without any Confirm, Message or page handler being requested
8. **retention-registered-on-install-and-upgrade** [18] [19] [23]
    - Given A company where the install and, separately, the upgrade routine run
    - When Retention registration runs, then OnRefreshAllowedTables is raised
    - Then Both log tables are allowed tables with a 90-day mandatory minimum, the default Retention Policy Setup exists once, and refresh re-registers without duplicating the setup
9. **template-fills-empty-fields** [10] [26]
    - Given Setup with a customer template that has posting groups and a country code, and a file row with its own country code
    - When The import job runs
    - Then The customer takes the posting groups from the template and keeps the country code from the file (only if the template is confirmed)
10. **commit-aware-test-transactions** [25] [26]
    - Given Import tests that run code which commits
    - When The tests are declared
    - Then They use TransactionModel AutoCommit with a TestIsolation runner, not AutoRollback; fixtures (number series, templates, country codes) come from the Library codeunits

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Reading the file from a background session: how the job obtains the CSV without upload UI is not covered by BCQuality knowledge; the intake step rests on judgment until open question file-source is answered.
- Shipping the data exchange definition XML (for example as an app resource read at install) is not covered by BCQuality knowledge beyond importing it with XMLport 1225; rests on judgment.
- The order in which the row codeunit validates dependent Customer fields (for example Country/Region Code before Post Code and City) is not covered by BCQuality knowledge; rests on judgment.
- The exact Customer Templ. Mgt. procedure that applies a template to an already inserted customer is not named by an opened article; confirm it in symbols before use.
- Detecting a row or file imported twice has no article (the data import map says it rests on judgment).
- Cleanup of Data Exch. and Data Exch. Field rows (base application tables, which an extension cannot register for retention) is not covered by BCQuality knowledge.
- Status enums and the run and log list pages rest on judgment; no article covers them.
- bc-version, countries and application-area are unknown; every cited article applies to all versions, w1 and all areas.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-data-import-or-migration-feature.md`: Planning order for the import: mechanism, reading, staging, record creation, error collection, log, transactions, background run, retention, privacy, permissions, tests.
    - A file whose layout users adapt uses a data exchange definition
    - Map into a temporary record and insert real records in own code
    - Collect row errors instead of stopping at the first; the failure log must survive rollback
    - No commit per row; commit before Codeunit.Run inside a write transaction
    - Job queue handler without UI, failures propagated, conflicting imports serialized by category
    - Detecting a file or row imported twice has no article; it rests on judgment
    - Register log tables for retention policies and consider a default setup
[2] `microsoft/knowledge/web-services/import-files-through-data-exchange-definitions.md`: Mechanism for an administrator-adaptable CSV layout and the buffer-table shape.
    - Ship a Generic Import definition and import it with XMLport 1225 in a setup step
    - The mapping target's last primary key field must be Integer or BigInteger; it is set from the file line number
    - ProcessColumnMapping validates each value and inserts with RecRef.Insert() without OnInsert, so map into a temporary record and insert real records in own code with Insert(true)
    - Dependent mapped fields get a lower Priority so they validate later
    - Set File Encoding on the definition explicitly
    - Do not write a bespoke parser that splits lines on a hard-coded separator
[3] `microsoft/knowledge/appsource/file-datatype-saas.md`: Reading the file in the cloud.
    - Do not use the File type's Open/Create/Read/Write; use streams staged in TempBlob
    - No server filesystem path is available in Business Central Online
[4] `microsoft/knowledge/web-services/set-text-encoding-on-streams-exchanged-externally.md`: Encoding of the incoming CSV bytes.
    - Pass TextEncoding matching the actual encoding of the incoming bytes on the stream that reads text
    - MSDos default can corrupt accented and non-Latin characters
[5] `microsoft/knowledge/web-services/format-exchanged-values-with-standard-format-9.md`: Parsing non-text values from the machine-generated file.
    - Parse machine-generated date, decimal and Boolean text with Evaluate(Variable, Text, 9)
    - Evaluate without format 9 depends on the session region of the job queue user
[6] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Classifying the setup, buffer and log tables.
    - Setup table has a blank Code[10] Primary Key
    - Buffer, log and working tables need not fit one of the nine business-record types
[7] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Setup singleton and its card.
    - Sole key Primary Key Code[10] left blank
    - Card page with InsertAllowed = false, DeleteAllowed = false and an open-time guard that inserts the row
[8] `microsoft/knowledge/security/guard-bulk-operations-with-istemporary.md`: Helper that processes the temporary buffer.
    - A helper that bulk-writes or deletes a var record expected to be temporary checks IsTemporary at entry and raises a descriptive error
[9] `microsoft/knowledge/data-modeling/master-data-must-be-inserted-with-trigger.md`: Creating Customer records from file rows.
    - Create the customer with Insert(true), then Validate fields and Modify(true)
    - Importing from an external source is not an exception; OnInsert assigns No. and No. Series from Sales & Receivables Setup when No. is blank and sets defaults, contact and dimensions
[10] `microsoft/knowledge/sales-purchase/templates-apply-custom-master-data-fields-by-matching-field.md`: Optional template application to imported customers.
    - Customer Templ. Mgt. inserts with Insert(true) before applying the template
    - For customers the template does not overwrite values already set and assigns without Validate
    - A field still at its InitValue counts as empty and takes the template value
[11] `microsoft/knowledge/performance/codeunit-run-as-atomic-sub-operation.md`: Per-row atomic creation so a failed row leaves no partial customer and the run continues.
    - Put each row in its own codeunit run via Codeunit.Run and capture the return value
    - On failure the row's database changes roll back and the caller receives false
    - TryFunction does not roll back writes
[12] `microsoft/knowledge/performance/codeunit-run-requires-prior-commit-inside-transaction.md`: Transaction boundary before the row loop and the deferred log write.
    - Codeunit.Run cannot nest inside an open write transaction; commit before it
    - Keep the outer loop read-only; collect failures in memory and write the log after the loop
    - Do not commit before each Codeunit.Run
[13] `microsoft/knowledge/performance/avoid-commit-inside-loops.md`: No commit inside the row loop.
    - Do not Commit inside a per-row loop
[14] `microsoft/knowledge/error-handling/log-writes-must-survive-rollback.md`: Failure log that is not lost with the failed work.
    - A log whose purpose includes capturing failures must not be written in the same transaction as the operation that fails
    - Do not swallow the error to keep the log; the log must observe the failure
[15] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Non-interactive job queue handler.
    - No Confirm, Page.Run(Modal), Report.Run(Modal), Hyperlink, upload or download in the handler
    - Message cannot report a result; persist business-visible status instead
[16] `microsoft/knowledge/performance/job-queue-handlers-must-propagate-failures.md`: Outcome reporting of the nightly run.
    - Errors that invalidate the whole run propagate out of the handler
    - Per-item failures may be collected deliberately but the batch must persist an observable aggregate outcome
[17] `microsoft/knowledge/performance/job-queue-category-code-serializes-conflicting-jobs.md`: Serializing import runs.
    - Entries that must not overlap share the same non-empty Job Queue Category Code
    - A category does not serialize across companies
[18] `microsoft/knowledge/privacy/register-owned-log-tables-for-retention-policies.md`: Making the run and log tables eligible for a 90-day retention policy.
    - Register each owned log table with AddAllowedTable and its aging date field, usually SystemCreatedAt
    - Call the registration from both install (OnInstallAppPerCompany) and upgrade (OnUpgradePerCompany)
    - Guard with IsAllowedTable and an upgrade tag but keep a ForceUpdate path for OnRefreshAllowedTables
    - Pass MandatoryMinRetenDays when the data must survive a minimum period
    - Do not delete log rows with hand-rolled DeleteAll jobs
[19] `microsoft/knowledge/privacy/ship-a-default-retention-policy-setup.md`: Default 90-day retention policy.
    - Registration deletes nothing; a Retention Policy Setup with a period must exist and be enabled
    - Get the period through Retention Policy Setup FindOrCreateRetentionPeriod; Validate Table Id, Apply to all records and Retention Period before insert
    - Create once per company behind an upgrade tag; default to Enabled = false unless the rows are documented as transient
    - Do not tell the administrator data is cleaned up automatically when no enabled setup exists
[20] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Classification of buffer, run and log fields.
    - Every field that holds customer data, such as names, e-mail addresses and addresses, is CustomerContent, not SystemMetadata or ToBeClassified
[21] `microsoft/knowledge/security/indirect-permissions-for-elevated-access.md`: Log tables written only by the import code.
    - Grant lowercase indirect letters where access must go through the import code; grant only the letters needed
[22] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Permission set structure.
    - Non-assignable building blocks composed into assignable role sets with IncludedPermissionSets
[23] `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`: Run-once install and upgrade steps.
    - Guard every step with HasUpgradeTag and call SetUpgradeTag after the work
    - No DataVersion branching
[24] `microsoft/knowledge/upgrade/register-upgrade-tags-with-subscribers.md`: Seeding tags for first install and new companies.
    - Seed the tag explicitly with SetUpgradeTag from OnInstallAppPerCompany
    - Return per-company tags from OnGetPerCompanyUpgradeTags for new companies
[25] `microsoft/knowledge/testing/transactionmodel-attribute-governs-test-transactions.md`: Transaction model of the import tests.
    - Code under test that commits needs AutoCommit, not AutoRollback
    - Pair suite-wide AutoCommit with a TestIsolation runner
[26] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build prerequisite records with the Library codeunits instead of hand-rolled Init/Insert
    - Create parents before records that reference them
[27] `microsoft/knowledge/privacy/featuretelemetry-customdimensions-no-pii.md`: Keeping file values out of telemetry if telemetry is added.
    - No customer names, e-mail addresses or GetLastErrorText output in CustomDimensions

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

