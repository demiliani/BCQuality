# Feature design

> We service equipment for our customers and need to manage maintenance contracts. Each contract gets a number from a number series and has a customer, a start date, an end date and a status. Users must be able to find contracts in a list and open them on a card. Only the service team may create or change contracts; everyone else can only view them.

**Result:** Complete design. **Business process:** Service management master data: a new custom Maintenance Contract entity (no posting process involved). **Knowledge used:** 26 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Which statuses can a contract have (for example draft, active, expired, cancelled), what is the initial status, and which transitions are allowed or automatic (e.g. when the end date passes)? _(affects: status-enum, contract-table)_
2. Must the end date be on or after the start date, and are both dates mandatory or may an open-ended contract have no end date? _(affects: contract-table)_
3. Which Customer Blocked values (Ship, Invoice, All) should prevent assigning a customer to a contract, and should existing contracts be affected when a customer is later blocked? _(affects: contract-table, blocked-customer-rejected)_
4. May the service team delete contracts, or should contracts only change status? This decides whether the Edit permission set grants D. _(affects: permset-edit, permset-service-role)_
5. Who maintains the contract number series in Maintenance Contract Setup: the service team, or administrators only? _(affects: permset-edit, permset-read, setup-page)_
6. Should installation create a default contract number series and setup row, or will an administrator configure it, and is a guided (assisted) setup wanted? _(affects: setup-table)_
7. May users type a contract number manually when the series allows it? _(affects: contract-table, manual-number-rejected-when-series-not-manual)_
8. Do contracts need further data such as a description, the serviced equipment or contract lines? Lines would make this a Document-type design. _(affects: contract-table, contract-card-page)_
9. Which Business Central version, countries and application area does the app target? This decides the tooltip placement (table field from BC24/runtime 13.0) and confirms the No. Series codeunit (BC22+). _(affects: contract-card-page, contract-list-page, contract-table)_
10. Is CustomerContent the right table-level classification for contract data, or does any field hold personal data needing a different value? _(affects: contract-table, setup-table)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Maintenance Contract | Master table: one record per maintenance contract. Primary key "No." Code[20] only; number assigned in OnInsert from the setup's number series through codeunit "No. Series" when "No." is blank; "No." OnValidate guards manual entry with NoSeries.IsManual before clearing "No. Series". Table-level DataClassification so every field inherits a real classification (no ToBeClassified). | No. (Code[20]): Sole primary key; assigned from the number series in OnInsert when blank.; No. Series (Code[20]): Editable = false; TableRelation = "No. Series"; records the series that produced No.; Customer No. (Code[20]): TableRelation = Customer; type and length must equal Customer."No." exactly - confirm against the Customer table definition. OnValidate tests the customer's Blocked value (see open question customer-blocked).; Starting Date (Date); Ending Date (Date): Relation to Starting Date is an open question (end-date-rule).; Status (Enum "Maintenance Contract Status") | [1] [2] [3] [4] [9] [8] [10] [11] |
| 2 | create | enum | Maintenance Contract Status | Named contract states for the Status field, instead of an Integer or magic numbers. Values are an open question. |  | [15] |
| 3 | create | table | Maintenance Contract Setup | Singleton setup table: "Primary Key" Code[10] left blank as the only key; holds the contract number series. | Primary Key (Code[10]): Always blank; the only row.; Contract Nos. (Code[20]): TableRelation = "No. Series"; TestField before the contract table uses it. | [1] [5] [6] [3] [10] |
| 4 | create | page | Maintenance Contract Setup | Card page over the setup table with InsertAllowed = false, DeleteAllowed = false and an OnOpenPage guard that inserts the blank row if missing; searchable with UsageCategory = Administration. |  | [5] [12] [17] [14] |
| 5 | create | page | Maintenance Contract List | List page users search for and open contracts from; UsageCategory = Lists with an object-level ApplicationArea; opens the card page. Name describes its source table. No business logic on the page. |  | [2] [12] [17] [13] [14] |
| 6 | create | page | Maintenance Contract Card | Card page for one contract. Field rules (numbering, customer validation, dates, status) live on the table, not in page triggers. Every user-facing field has an explicit or inherited tooltip. |  | [2] [12] [13] [14] |
| 7 | create | permissionset | Maint. Contract - Read | Building block, Assignable = false: R on tabledata Maintenance Contract and Maintenance Contract Setup, plus X on the contract table, the setup table and the list and card pages. Explicit entries, no wildcards. |  | [19] [20] [18] |
| 8 | create | permissionset | Maint. Contract - Edit | Building block, Assignable = false, includes Maint. Contract - Read; adds the insert and modify rights on tabledata Maintenance Contract that the service team needs (delete is an open question). Explicit entries, no wildcards. |  | [19] [20] |
| 9 | create | permissionset | Maint. Contract View | Role-shaped, Assignable = true, includes Maint. Contract - Read: everyone outside the service team can view contracts only. |  | [19] [21] |
| 10 | create | permissionset | Maint. Contract Service | Role-shaped, Assignable = true, includes Maint. Contract - Edit: the service team creates and changes contracts. |  | [19] [21] |

## 3. How the data flows

- **Maintenance Contract Setup."Contract Nos."** → **Maintenance Contract."No." and "No. Series"**: other. OnInsert: if No. is blank, Get setup, TestField("Contract Nos."), store it in No. Series, assign No. with NoSeries.GetNextNo. Callers that create contracts in code use Insert(true). [3] [4] [6] [7]
- **User (Maintenance Contract Setup page)** → **Maintenance Contract Setup."Contract Nos."**: entered by the user. [5]
- **User (Maintenance Contract Card)** → **Maintenance Contract."Customer No."**: field validation. TableRelation to Customer validates the value; OnValidate gets the customer and tests its Blocked value at this point of use. [9] [8]
- **User (Maintenance Contract Card)** → **Maintenance Contract."Starting Date", "Ending Date", Status**: entered by the user. Any date or status rule belongs on the table fields, not on the page. [13] [15]
- **Maintenance Contract** → **Maintenance Contract List and Card (search and open)**: other. Users find contracts through Tell Me on the list page (UsageCategory = Lists) and open them on the card. [17] [2]

## 4. Event subscriptions

None.

## 5. Setup, permissions and lifecycle

- **setup**: Setup card creates the singleton row on first open; an administrator assigns the contract number series before contracts are created. Contract insertion fails with a TestField error while the series is blank. [5] [6]
- **permissions**: Ship two non-assignable building blocks (Read, Edit including Read) and two assignable roles (View, Service) composed with IncludedPermissionSets; enumerate every object explicitly with no wildcards; verify the grants fall within the entitlement the target users hold. [19] [20] [18] [21]
- **privacy**: Set a table-level DataClassification on both new tables and override only fields that store a different kind of data; no field may ship as ToBeClassified. [10] [11]
- **install**: No install code is required for the design as requested. If the setup row or a default number series must exist after installation (open question default-number-series), put it in a Subtype = Install codeunit; install code does not run on version upgrade. [22]
- **upgrade**: First version needs no upgrade code. Any later data change to contracts or setup goes in a Subtype = Upgrade codeunit guarded by HasUpgradeTag/SetUpgradeTag with a per-feature tag, not DataVersion checks. [22] [23]
- **other**: Place all contract objects (tables, enum, pages, permission sets, tests) in one feature folder, consistent with the repository's existing layout convention. [16]

## 6. Tests

1. **insert-assigns-number-from-series** [3] [4] [7] [24] [26]
    - Given Setup has a contract number series created through test library codeunits
    - When A contract is inserted with Insert(true) and a blank No.
    - Then No. is the next number from that series and No. Series equals the setup's Contract Nos.
2. **insert-fails-without-setup-series** [6] [26]
    - Given Setup exists with Contract Nos. blank
    - When A contract is inserted with a blank No.
    - Then A TestField error on Contract Nos. is raised and no contract is created
3. **manual-number-rejected-when-series-not-manual** [4] [26]
    - Given The contract number series does not allow manual numbers
    - When A user validates a typed No. on a contract
    - Then An error is raised and No. Series is not cleared
4. **customer-no-validates-against-customer** [24] [9] [26]
    - Given A customer created with LibrarySales.CreateCustomer
    - When Customer No. is validated with that customer's No., and separately with a value that is not a customer
    - Then The existing customer is stored; the non-existent value is rejected by the table relation
5. **blocked-customer-rejected** [8] [24] [26]
    - Given A customer created with LibrarySales.CreateCustomer and blocked with the Blocked value(s) chosen in open question customer-blocked
    - When Customer No. on a contract is validated with that customer
    - Then An error on the customer's Blocked field is raised
6. **setup-page-creates-singleton** [5] [26]
    - Given No Maintenance Contract Setup record exists
    - When The Maintenance Contract Setup page is opened
    - Then Exactly one setup record with a blank Primary Key exists
7. **viewer-can-read-but-not-change** [25] [19] [26]
    - Given TestPermissions = Restrictive and the test user lowered to the Maint. Contract View role, with an existing contract
    - When The user reads the contract, then tries to insert and to modify a contract
    - Then Reading succeeds; insert and modify fail with a permission error
8. **service-team-can-create-and-change** [25] [19] [26]
    - Given TestPermissions = Restrictive and the test user lowered to the Maint. Contract Service role, with a contract number series in setup
    - When The user creates a contract and changes its Status
    - Then Both operations succeed and the contract carries a number from the series

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- context: bc-version, countries and application-area are unknown; no repository was supplied.
- Customer."No." length (Code[20]) is assumed from standard Business Central and was not confirmed against repository symbols.
- End-date and status-transition rules are not covered by BCQuality knowledge; any such validation rests on the agent's judgment and the answers to open questions.
- Read-only access for non-service users relies on permission sets alone; no BCQuality article covers making the pages non-editable per role.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Decision checklist for the new contract entity: table type, numbering, setup, data rules, privacy, pages, permissions, install/upgrade, tests, layout.
    - Plan every decision row before building, not only the table and page.
    - A row the request does not settle is a question for the requester, not a default to assume.
[2] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Classify Maintenance Contract as a Master table and Maintenance Contract Setup as a Setup table.
    - Master: primary key Code[20] named No.; Card + List pages.
    - Setup: exactly one record; primary key Code[10] named Primary Key, always blank; one page that creates the singleton on first open.
[3] `microsoft/knowledge/data-modeling/master-table-no-from-number-series-in-oninsert.md`: Contract numbering.
    - No. Code[20] is the sole primary key; a non-editable No. Series Code[20] records the source series.
    - OnInsert checks No. is blank, reads setup, TestFields the series, stores it in No. Series and assigns No. from the series.
    - Not an Integer AutoIncrement, GUID or SystemId business key.
[4] `microsoft/knowledge/data-modeling/use-no-series-codeunit-not-noseriesmanagement.md`: Number-series API for assignment and manual-entry guard (applies from BC22).
    - Assign with codeunit "No. Series" GetNextNo; guard manual No. entry with IsManual or TestManual.
    - Do not use obsolete NoSeriesManagement InitSeries/TestManual.
[5] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Maintenance Contract Setup table and page.
    - Primary Key Code[10] is the sole key, value blank.
    - Card page with InsertAllowed = false, DeleteAllowed = false, and an open-time guard that inserts the blank row if missing.
    - No Integer key, no List page over the setup.
[6] `microsoft/knowledge/data-modeling/testfield-required-setup-field.md`: Guard on the contract number series before use.
    - TestField the required setup field before use instead of falling back silently.
    - Write a test that blanks the setup field and asserts the error.
[7] `microsoft/knowledge/data-modeling/master-data-must-be-inserted-with-trigger.md`: How code and tests create contracts.
    - Create master records with Insert(true) so OnInsert assigns the number, unless the caller itself does the trigger's work.
[8] `microsoft/knowledge/data-modeling/check-blocked-in-referencing-code-not-in-master.md`: Customer No. validation on the contract.
    - The referencing record tests the master's Blocked at the point of use (OnValidate of the reference field).
    - An option-style block needs the specific option compared at each relevant path.
[9] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing Customer No.
    - For an unconditional TableRelation, the field has the same type and exact length as the related field, read from its table definition.
[10] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification of both new tables.
    - A table-level DataClassification is inherited by Normal fields of that table; override at field level only where the field stores different data.
[11] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of the new fields.
    - No field may ship as ToBeClassified; choose the classification from the data's content.
[12] `microsoft/knowledge/style/page-name-must-match-source-table.md`: Naming of list, card and setup pages.
    - A page name must describe the table it shows.
[13] `microsoft/knowledge/style/pages-must-not-contain-business-logic.md`: Where contract rules live.
    - Business operations and cross-entry-point invariants belong in a codeunit or the table, not only in a page trigger.
    - A setup page reading and writing its own singleton record and the OnOpenPage singleton-initialization idiom are conventional.
[14] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips on the contract and setup pages.
    - Every user-facing page field needs a non-empty explicit or inherited tooltip.
    - On runtime 13.0 (BC24) or later define the tooltip on the table field; before that, on the page field.
    - Do not invent effects, defaults or constraints in tooltip text.
[15] `microsoft/knowledge/style/fixed-choice-set-must-use-enum-not-integer.md`: Type of the Status field.
    - A fixed set of named, mutually exclusive states is an Enum, not an Integer.
[16] `microsoft/knowledge/style/source-organized-by-feature-not-object-type.md`: Folder placement of the feature's objects.
    - Group a feature's objects together consistently with the project's chosen convention; do not mix schemes.
[17] `community/knowledge/appsource/set-usagecategory-on-searchable-entry-points.md`: Making the contract list (and setup page) findable.
    - Pages users open directly set UsageCategory and an object-level ApplicationArea.
    - Supporting objects reached only through another page do not need to be searchable.
[18] `microsoft/knowledge/security/exposed-objects-must-be-in-a-permission-set.md`: Execute entries for the new pages and tables.
    - Give exposed objects an explicit execute entry in a permission set shipped by the app.
[19] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Structure of the view-only and service-team permission sets.
    - Small building blocks marked Assignable = false; role-shaped Assignable = true sets reference them through IncludedPermissionSets.
[20] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Content of the permission sets.
    - Enumerate each tabledata and table entry; no * wildcards.
    - Grant only the letters required: R for read-only consumers, RIM for editors that do not delete, RIMD only for owners of the data.
[21] `microsoft/knowledge/security/do-not-grant-rights-beyond-a-users-entitlement.md`: Validating the permission sets against user licenses.
    - Every right the set grants must be reachable within the target users' entitlement; grants beyond it are clipped silently at runtime.
[22] `microsoft/knowledge/upgrade/install-code-does-not-run-on-version-upgrade.md`: Install versus upgrade code.
    - Install codeunits run on first install and reinstall only; version migration goes in a separate Subtype = Upgrade codeunit.
[23] `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`: Future data changes.
    - Each upgrade procedure starts with HasUpgradeTag and ends with SetUpgradeTag; no DataVersion branching.
[24] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Create customers and other prerequisites with library codeunits such as LibrarySales.CreateCustomer and LibraryRandom; create parents before dependents and Validate foreign keys.
[25] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: Permission tests for viewer and service-team roles.
    - Use TestPermissions::Restrictive and lower the test user with Permissions Mock or Library - Lower Permissions before the protected operation.
    - Lowering through a role that includes the permission set under test is adequate.
[26] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Test structure.
    - [FEATURE] once per codeunit; [SCENARIO] first in each test; [GIVEN]/[WHEN]/[THEN] mark setup, action and assertions.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
