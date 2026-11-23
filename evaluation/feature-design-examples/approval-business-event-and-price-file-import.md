# Feature design

> When a Service Request in our app is approved, a Power Automate flow must start so the warehouse is told. Integrators already use version 1 of that trigger, and we now need to add the warehouse code to it. Separately, a supplier sends a weekly CSV of item prices whose column layout changes now and then; the rows must land in our Price Import Line staging table. Customers also load their initial Site Contract records with configuration packages.

**Result:** Complete design. **Business process:** Changes a shipped integration contract and adds data import: the app's Service Request approval raises a new version of its external business event for Power Automate with the warehouse code, a supplier price CSV is imported through the Data Exchange framework into the app's Price Import Line staging table, and the app's Site Contract table is made safe for loading through RapidStart configuration packages. **Knowledge used:** 17 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Where does the warehouse code come from: an existing Service Request field (which one, and is it a Location code), or a new field that must be added and back-filled for existing requests? _(affects: service-request-business-events)_
2. In which release may ServiceRequestApproved 1.0 be removed, and are the integrators' flows known so they can be told to move to 2.0? _(affects: service-request-business-events)_
3. Should version 2.0 carry anything besides the 1.0 parameters and the warehouse code (for example a status or a web client URL)? Each later change needs another version. _(affects: service-request-business-events)_
4. What is the current primary key of Price Import Line, and does it already end in an Integer or BigInteger field? Does the table already hold data in customer tenants? _(affects: price-import-line)_
5. What separator, encoding, header lines, date and decimal formats does the supplier CSV use, and which columns are mandatory? _(affects: price-csv-definition-setup, import-price-file)_
6. How does the weekly file arrive and who runs the import: a user uploading it, or a scheduled job queue entry reading it from a storage location? _(affects: import-price-file)_
7. What should happen to rows that fail validation: stop the whole file, or collect the errors and import the valid rows? And what happens if the same file is imported twice? _(affects: import-price-file)_
8. Do staged Price Import Line rows stay after they are processed, and for how long? If they accumulate, should the table be registered for retention policies (designed), and is a default retention policy wanted? _(affects: price-import-line, price-csv-definition-setup, price-import-upgrade)_
9. What processes the staged rows after import (for example into price lists)? This design stops at the staging table as requested. _(affects: price-import-line)_
10. Should the data exchange definition be created by install and upgrade code (designed), or supplied as a file that administrators import themselves? _(affects: price-csv-definition-setup, price-import-upgrade)_
11. Which Site Contract fields default other fields, check non-key fields in OnInsert, or open dialogs in OnValidate? If a defaulting field has a higher number than the fields it fills, how should that be resolved without renumbering shipped fields? _(affects: site-contract, site-contract-config-package)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | modify | enumextension | EventCategory | The app's existing EventCategory enum extension that version 1.0 of the Service Request approved event already uses. Keep it unchanged so version 2.0 is listed in the same category; create it only if version 1.0 does not already use an app-owned category. |  | [3] |
| 2 | modify | codeunit | Service Request Business Events | The app codeunit that declares the shipped 1.0 external business event for an approved Service Request. Leave the 1.0 procedure's name, version and parameters exactly as shipped; mark it [Obsolete] with a reason that names version 2.0 and a tag, and prefix its display name with [OBSOLETE]. Add a new procedure with the same event name and version '2.0' whose parameters are the 1.0 parameters plus the warehouse code (simple types only: SystemId as Guid, request number as Code, warehouse code as Code). Raise both 1.0 and 2.0 from the same place that raises 1.0 today, inside the approval transaction, with no Commit and no HttpClient call; the platform sends the notification only after commit. Use the target name of the existing codeunit if it differs. |  | [3] [1] [8] |
| 3 | modify | table | Price Import Line | The app's existing persistent staging table, the target of the data exchange mapping. Process Data Exch. requires the last primary key field to be Integer or BigInteger (filled with line number x 10000) and takes the other key fields from the template record; keep or adjust the key only if it does not fit and the table holds no data that blocks the change. Add a field that carries the Data Exch. entry number so the mapping codeunit can find the imported file. A staging table used only inside this import does not have to follow one of the nine business table types. Mapped fields that depend on another field validate after it, so give them a lower Priority in the field mapping. | Data Exch. Entry No. (Integer): Links the template record to the Data Exch. row of the imported file; DataClassification SystemMetadata.; Line No. (Integer): Only if the current key does not already end in an Integer or BigInteger field; Process Data Exch. sets it per file line. | [4] [7] [12] |
| 4 | create | codeunit | Map Price Import | Mapping Codeunit of the definition's Data Exch. Mapping, with TableNo = Price Import Line. Gets the Data Exch. from the template record's entry number and calls Process Data Exch.ProcessAllLinesColumnMapping into the temporary template record. |  | [4] |
| 5 | create | codeunit | Import Price File | Entry point for the weekly file: gets the shipped data exchange definition, runs Data Exch.ImportToDataExch, prepares the temporary Price Import Line template (key fields and Data Exch. entry number), runs the mapping codeunit named on the Data Exch. Mapping, then inserts the real Price Import Line rows in its own code with Insert(true) and any checks, because Process Data Exch. inserts without OnInsert. |  | [4] [2] |
| 6 | create | codeunit | Price Import Install | Install codeunit (Subtype = Install, OnInstallAppPerCompany) that ships the supplier price data exchange definition: type Generic Import, reading XMLport 1220 Data Exch. Import - CSV, explicit File Encoding, header lines, column definitions and field mappings to Price Import Line, mapping codeunit Map Price Import. For example imported from an XML definition file with XMLport 1225 Imp / Exp Data Exch Def & Map. Users then adapt column definitions when the supplier changes the layout, without a release. Shares one routine with the upgrade codeunit. |  | [4] [5] [9] |
| 7 | create | codeunit | Price Import Upgrade | Upgrade codeunit (Subtype = Upgrade, OnUpgradePerCompany) that runs the same definition setup routine for tenants that already have the app, guarded by HasUpgradeTag and closed with SetUpgradeTag under a tag of its own, because install code does not run on a version upgrade. |  | [9] [10] |
| 8 | modify | table | Site Contract | The app's existing table loaded by configuration packages. Keep OnInsert to key-only work such as number series and defaults; move any check or copy of non-key fields (for example TestField on a customer number) into those fields' OnValidate. A field that defaults others must have a lower field number than the fields it fills, so package values for the dependent fields are applied after the default. Do not renumber fields of the shipped table to achieve this; raise it as a question instead. |  | [6] [2] |
| 9 | create | codeunit | Site Contract Config. Package | Holds the OnBeforeValidateException subscriber for Site Contract fields whose OnValidate cannot run during a package import, such as one that opens a confirm dialog or needs a field validated later. Needed only when such fields exist. |  | [6] |
| 10 | modify | permissionset | App permission sets | Extend the app's focused, non-assignable building-block sets with execute on Import Price File, Map Price Import and Site Contract Config. Package, and the tabledata the import touches (Price Import Line and the Data Exch. tables it writes), and include them in the assignable role sets through IncludedPermissionSets, so the import and package load work for a user without SUPER. No wildcards. |  | [13] [14] |

## 3. How the data flows

- **Service Request (approved)** → **ServiceRequestApproved external business event 2.0**: other. Raised from the existing approval point inside the approval transaction, beside the obsoleted 1.0 event, passing SystemId, request number and warehouse code; delivered to Power Automate only after commit. [3]
- **Service Request (approved)** → **ServiceRequestApproved external business event 1.0**: other. Still raised with its shipped payload so existing flows keep working during the deprecation window. [3] [1]
- **Supplier price CSV file** → **Data Exch. Field**: other. Data Exch.ImportToDataExch runs the definition's reading XMLport 1220 Data Exch. Import - CSV with the definition's explicit File Encoding; column definitions absorb layout changes. [4] [5]
- **Data Exch. Field** → **Price Import Line (temporary template)**: field validation. Process Data Exch.ProcessAllLinesColumnMapping assigns and validates each mapped value, by Priority (highest first) when set, else by column; missing non-Optional values raise an error naming line and column. [4]
- **Price Import Line (temporary template)** → **Price Import Line**: other. Import Price File copies each temporary row and inserts it with Insert(true) so OnInsert and the app's checks run. [4]
- **Configuration package** → **Site Contract**: field validation. Config. Package Management pass one inserts key fields with Insert(true); pass two validates the other fields in Processing Order (field number order by default) and calls Modify(true). [6]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Config. Package Management | `OnBeforeValidateException` | Return true for Site Contract fields whose OnValidate cannot run during a package import, so they are imported without validation by default. Only needed when such fields exist. | Act only when TableID is Site Contract and FieldID is one of the listed fields · Set IsHandled only for those fields | [6] |

## 5. Setup, permissions and lifecycle

- **upgrade**: Mark ServiceRequestApproved 1.0 [Obsolete('<reason naming version 2.0>', '<tag>')] and keep the tag stable; remove it only in a later release after integrators have moved to 2.0. [8] [3]
- **install**: Ship the supplier price data exchange definition from install code on first install and reinstall. [4] [9]
- **upgrade**: Create the same definition for existing tenants from an upgrade codeunit guarded by an upgrade tag of its own. [9] [10]
- **privacy**: Register Price Import Line as a retention-policy allowed table (AddAllowedTable with SystemCreatedAt, guarded by IsAllowedTable) from both install and upgrade code, if staged rows accumulate week after week. [11]
- **privacy**: Set DataClassification on every new field (Data Exch. Entry No. and any new key field are SystemMetadata); keep the classification of existing fields. [12]
- **permissions**: Cover running the price import and loading Site Contract packages through the app's role permission sets, composed from building blocks, without SUPER. [13] [14]
- **other**: Raise the app version in app.json for this release, since it adds functionality and a new event version. [17] [1]

## 6. Tests

1. **approval-raises-both-event-versions** agent judgment
    - Given A Service Request with a warehouse code, ready for approval
    - When The request is approved through the app's approval path
    - Then Both ServiceRequestApproved 1.0 (shipped payload) and 2.0 (payload including the warehouse code) are raised; how the raise is observed in a test rests on judgment
2. **failed-approval-raises-no-event** [3]
    - Given A Service Request whose approval fails with an error after the event is raised
    - When The approval transaction rolls back
    - Then No notification is delivered, because business event notifications are sent only after commit; no HttpClient call is made from the approval
3. **import-price-csv-into-staging** [4] [5] [16]
    - Given The shipped price data exchange definition and a CSV file with accented text, encoded as the definition states
    - When Import Price File runs on that file
    - Then One Price Import Line per data row exists with item, price and date values read back correctly, the integer key field is set per line, and OnInsert effects of the staging table are present
4. **import-price-csv-after-layout-change** [4]
    - Given The definition's column definitions changed to a new column order, with no code change
    - When A CSV in the new layout is imported
    - Then The same Price Import Line values are produced as for the original layout
5. **import-price-csv-missing-mandatory-value** [4]
    - Given A CSV row missing a value for a mapping that is not Optional
    - When The file is imported
    - Then An error names the line and column, and no Price Import Line rows from that file are left half-inserted
6. **definition-created-on-upgrade** [9] [10]
    - Given A company that had the previous app version installed, without the price definition
    - When The app is upgraded, and then upgraded again
    - Then The definition exists after the first upgrade and the upgrade tag prevents a second creation
7. **site-contract-loads-by-package** [6] [15] [16]
    - Given A configuration package with Site Contract rows, including values for fields that another field defaults, created with Library codeunits for the related records such as customers
    - When The package is applied (not entered through the page)
    - Then Every Site Contract is inserted, OnInsert succeeds with only the key set, and package values for dependent fields are kept rather than overwritten by defaults
8. **site-contract-validation-exception** [6]
    - Given A package that sets a Site Contract field whose OnValidate is listed in the OnBeforeValidateException subscriber
    - When The package is applied
    - Then The field is imported without running its interactive validation and no dialog is raised
9. **import-without-super** [13]
    - Given A user assigned only the app's role permission sets
    - When The user runs the price import and applies a Site Contract package
    - Then Both complete without a permission error

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- No repository was supplied: the place where the app raises ServiceRequestApproved 1.0 today is not confirmed; version 2.0 is designed to be raised at the same point.
- Test approval-raises-both-event-versions: how to observe that an external business event was raised in a test is not covered by BCQuality knowledge and rests on judgment.
- bc-version, countries and application-area could not be determined from the request; all cited articles apply to all versions.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-change-to-a-shipped-feature.md`: Planning the change to the shipped 1.0 business event and the release around it.
    - Decide first whether the symbol was ever released; version 1 is used by integrators, so it is released.
    - External business events: raise a new version beside the old one, then obsolete the old one.
    - Raise the app version at release.
    - Which release removes an obsolete element, and whether dependent flows are known, are questions for the requester.
[2] `microsoft/knowledge/feature-design/plan-a-data-import-or-migration-feature.md`: Choosing the mechanism per data source and planning staging, setup, retention, permissions and tests for the imports.
    - A file whose layout users adapt uses a data exchange definition.
    - Setup and master data loaded by customers uses configuration packages.
    - Map into a temporary record and insert the real records in own code.
    - Test with a real file or package, not only through the page.
    - File format and owner, frequency, handling of failed rows and how long staged data is kept are questions for the requester.
[3] `microsoft/knowledge/web-services/raise-external-business-events-for-power-automate.md`: Adding version 2.0 of the Service Request approved business event with the warehouse code.
    - Payload parameters are simple types such as Guid, Text, Code, Enum, Decimal, Date and RecordId, not records; pass identifiers and small values.
    - Do not rename the event, add or change its version, or change its parameters in place.
    - Add a new procedure with the same name and a higher version, raise both, and mark the old one [Obsolete] with [OBSOLETE] at the start of its display name; remove it in a later release.
    - Raise the event inside the business transaction; it needs no Commit, and the notification is sent only after commit.
    - Do not call a Power Automate HTTP trigger URL with HttpClient from inside the transaction.
[4] `microsoft/knowledge/web-services/import-files-through-data-exchange-definitions.md`: Importing the supplier price CSV with a changing column layout into Price Import Line.
    - Ship a data exchange definition of type Generic Import for the format, for example imported with XMLport 1225 in a setup step.
    - The target table's last primary key field must be Integer or BigInteger; the other key fields come from the template RecRef.
    - Mapped values are validated in Priority order (highest first) when any priority is set, else column order; give dependent fields a lower Priority.
    - A mapping that is not Optional raises an error naming line and column when the value is missing.
    - Process Data Exch. inserts without OnInsert: map into a temporary template record and insert real records in own code with Insert(true).
    - Set File Encoding on the definition explicitly.
    - Do not write a bespoke parser that splits lines and evaluates columns by position.
[5] `microsoft/knowledge/xmlport/xmlport-text-encoding-defaults-to-msdos.md`: Setting the definition's file encoding for the CSV read through XMLport 1220.
    - Text XMLports default to MS-DOS encoding; set the encoding explicitly to what the counterpart uses.
    - A file with only ASCII looks correct in testing; test with accented characters.
[6] `microsoft/knowledge/data-modeling/config-packages-insert-key-fields-first-then-validate-by-field-order.md`: Making Site Contract load correctly through configuration packages.
    - Pass one inserts with only key fields set and runs OnInsert; pass two validates other fields in Processing Order (field number order by default) and calls Modify(true).
    - Keep OnInsert to work that needs only the key; derive values in the source fields' OnValidate.
    - A field that defaults others needs a lower field number than the fields it fills.
    - For a field whose OnValidate cannot run during import, subscribe to OnBeforeValidateException and return true.
    - Test the table by applying a package, not only through the page.
[7] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Keeping Price Import Line as a staging table whose key is shaped by the data exchange framework.
    - A staging or working table used only inside one process is not required to fit any of the nine business table types.
[8] `microsoft/knowledge/upgrade/obsoletion-requires-reason-and-tag.md`: Obsoleting the 1.0 business event procedure.
    - Events and methods use [Obsolete('reason', 'tag')] with both arguments; the reason names the replacement.
    - Keep the original tag stable through the lifecycle.
[9] `microsoft/knowledge/upgrade/install-code-does-not-run-on-version-upgrade.md`: Shipping the data exchange definition to both new and existing installations.
    - Install code runs on first install and reinstall only, not on version upgrade.
    - Put version migration in a Subtype = Upgrade codeunit entered from OnUpgradePerCompany or OnUpgradePerDatabase.
[10] `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`: Guarding the upgrade step that creates the definition.
    - Start each upgrade procedure with HasUpgradeTag and end with SetUpgradeTag; give the feature its own tag.
    - Do not branch on DataVersion to decide which upgrade step runs.
[11] `microsoft/knowledge/privacy/register-owned-log-tables-for-retention-policies.md`: Letting administrators trim staged price rows, if they accumulate.
    - Register owned tables that accumulate rows with Reten. Pol. Allowed Tables.AddAllowedTable, passing the date field that ages rows.
    - Call registration from both install and upgrade code, guarded with IsAllowedTable, keeping a force path for OnRefreshAllowedTables.
    - Do not clean the table with hand-rolled DeleteAll jobs instead of retention policies.
[12] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Classifying the new staging fields.
    - Set DataClassification to match the stored data at field definition time; do not leave ToBeClassified.
[13] `microsoft/knowledge/appsource/permission-sets-cover-setup-and-usage-without-super.md`: Permissions for running the import and loading packages.
    - Cover every page, codeunit and tabledata operation the app's setup and usage need through assignable role sets, without SUPER.
    - Validate representative workflows as a user assigned only the app roles; no wildcards.
[14] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Structuring the permission changes.
    - Add new objects to focused Assignable = false building blocks and include them in role sets through IncludedPermissionSets.
[15] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Creating customers and other prerequisites for the package tests.
    - Create prerequisite records with the Library codeunits, parents before dependents, and validate foreign keys.
[16] `microsoft/knowledge/testing/transactionmodel-attribute-governs-test-transactions.md`: Choosing the transaction model for import and package tests.
    - Do not declare AutoRollback for a test whose code under test calls Commit; use AutoCommit with a TestIsolation runner in that case.
[17] `microsoft/knowledge/appsource/release-must-update-app-version.md`: Releasing the new event version and import feature.
    - Update the app version consciously at every release; minor for new functionality by team convention.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

