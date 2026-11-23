# Feature design

> Our AppSource app has a Priority option field (Low, Normal, High) on its Service Contract table, used in an integration event, an API page and a Power Automate business event. Replace it with a Priority Level code that points to a new setup table, and keep existing contracts' priorities.

**Result:** Complete design. **Business process:** Change to a feature the AppSource app already ships: the app's own Service Contract priority moves from a shipped Option field to a code on a new Priority Level table, while its integration event, API page and external business event keep their published contracts and existing contract data is migrated by upgrade code; no standard Business Central posting process is involved. **Knowledge used:** 56 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. In which release should the Priority field move from Pending to Removed, and when should the obsoleted integration event, business event version 1.0 and the v1.0 API page be retired? Are dependent apps or flows bound to them known? _(affects: service-contract-table, integration-event-publisher, business-events-codeunit, service-contract-api-v2-page)_
2. During the deprecation window, what should the v1.0 API page, the old integration event parameter and business event version 1.0 report for a contract whose Priority Level is not one of the three migrated levels? Should the obsolete Priority field be kept in sync from the new code (and through which mapping), or left frozen at its migrated value? _(affects: service-contract-table, integration-event-publisher, business-events-codeunit, service-contract-api-v2-page)_
3. Is the shipped integration event publisher local, internal or public, and does it pass the Priority option as its own parameter or the whole Service Contract record? This decides between adding a parameter and publishing a new event. _(affects: integration-event-publisher, integration-event-carries-code)_
4. Which codes and descriptions should the three migrated Priority Level records get (for example LOW, NORMAL, HIGH), and should fresh installs and new companies also receive these default levels? _(affects: priority-upgrade-codeunit, install-codeunit, upgrade-maps-option-to-code)_
5. Must every contract have a Priority Level, and should new contracts get a default level (the old option defaulted to its first value)? If so, where is the default kept? _(affects: service-contract-table, priority-level-table)_
6. May a Priority Level that contracts still use be deleted or renamed, or should it be blocked? _(affects: priority-level-table)_
7. Does the app have published procedures, keys, reports or telemetry custom dimensions that use the Priority option? Each needs its own non-breaking replacement. _(affects: service-contract-table)_
8. Should the obsolete Priority control stay on the Service Contract pages during the deprecation window because dependent apps may anchor page extensions on it, or be removed now? _(affects: service-contract-pages)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Priority Level | Supplemental code table that replaces the fixed Low/Normal/High choice. Primary key Code[10] named Code, one plural list page set as LookupPageID and DrillDownPageID. A table-level DataClassification covers its Normal fields; no field is left ToBeClassified. Tooltips are defined on the table fields where the target runtime supports inheritance (BC24 and later). The request calls it a setup table, but it holds many rows, so it follows Supplemental conventions rather than the singleton Setup type. | Code (Code[10]): Primary key; the referencing field on Service Contract must have exactly this type and length.; Description (Text[100]): Shown in the dropdown and on the list page. | [41] [43] [44] [47] |
| 2 | create | page | Priority Levels | List page for maintaining priority levels, named after its source table, used as the table's LookupPageID. It holds no business logic; tooltips are inherited from the table fields or set on the page for runtimes before 13.0. |  | [41] [45] [46] [47] |
| 3 | modify | table | Service Contract | Add the replacement field under a new, unused field ID and keep the shipped Priority option field with its original ID, name and type, marked ObsoleteState = Pending with an ObsoleteReason naming Priority Level Code and an ObsoleteTag recording the obsoletion version. The option field is not converted to Code in place, not renamed (a rename also changes its translation IDs) and not part of any key change. It moves to Removed only in a later release. | Priority Level Code (Code[10]): New field ID. TableRelation = "Priority Level".Code with exactly the related field's type and length. DataClassification inherited from the table if it has a valid table-level value, otherwise set explicitly. Needs new caption and tooltip translations.; Priority (Option (Low,Normal,High)): Existing shipped field: keep ID, name and type; ObsoleteState = Pending, ObsoleteReason = 'Replaced by Priority Level Code.', ObsoleteTag = the release that introduces the replacement. | [4] [5] [6] [7] [8] [9] [42] [43] [48] |
| 4 | modify | page | Service Contract card and list pages | Show Priority Level Code instead of the obsolete Priority field, with its tooltip inherited from the table field where supported. Validation of the code stays in the table relation, not in page triggers. Whether the old Priority control can be removed from pages that dependent apps may extend is not covered by an opened article and is left to judgment. |  | [46] [47] |
| 5 | modify | codeunit | Codeunit that publishes the Service Contract integration event | Keep the shipped integration event's name, every existing parameter's name, type and var mode, and its attribute flags exactly as shipped, and keep raising it. If the publisher is local or internal, add a Priority Level Code parameter to it (position does not matter, subscribers bind by name). If the publisher is public, leave it unchanged and publish a new local event beside it that carries the code as a concrete Code[10] value, raised at the same point; then mark the old event [Obsolete('reason', 'tag')] naming the new one. No IsHandled is added to the existing event. |  | [14] [15] [16] [17] [18] [19] [20] [8] |
| 6 | create | page | Service Contract API page v2.0 | New API page object, copied from the published one, with APIVersion = 'v2.0' and the same APIPublisher, APIGroup, EntityName and EntitySetName, exposing priorityLevelCode instead of the option field. The published v1.0 page object stays unchanged; v2.0 is not added to its APIVersion list. |  | [21] [22] [23] |
| 7 | modify | codeunit | Codeunit that declares the Service Contract external business event | Add a new procedure with the same ExternalBusinessEvent name and a higher version (for example '2.0') whose payload carries the Priority Level Code as a Code value, raise both versions from the same point, and mark the old one [Obsolete] with '[OBSOLETE]' at the start of its display name. The shipped event's name, version and parameters are not edited; it is removed in a later release. |  | [24] [8] |
| 8 | create | codeunit | Priority Level Upgrade | Codeunit with Subtype = Upgrade. OnUpgradePerCompany calls, in this order, two separately tagged steps: (1) create the Priority Level records that correspond to Low, Normal and High; (2) copy each contract's option value to Priority Level Code. Both steps live in this one codeunit so their order is guaranteed. Step 2 uses DataTransfer on Service Contract with AddSourceFilter on Priority and AddConstantValue for the matching code, once per option value. The new field has no validation or trigger logic that the transfer would skip, so the bypass is safe; if validation is later added to the field, a Validate loop replaces the transfer. |  | [25] [26] [27] [28] [30] [31] [32] |
| 9 | modify | codeunit | App install codeunit | In OnInstallAppPerCompany, detect a first install with DataVersion() = Version.Create('0.0.0.0') and explicitly SetUpgradeTag for both Priority Level upgrade tags, so the option-to-code migration never runs later against a company that starts on the new schema. Create the codeunit with Subtype = Install if the app has none. |  | [38] [39] [40] |
| 10 | modify | permissionset | App permission sets | Add tabledata "Priority Level" (R for users, RIMD for the admin/setup building block), table and page "Priority Levels" execute, and page = X for the new v2.0 API page to the app's focused non-assignable building blocks, so the assignable role sets inherit them through IncludedPermissionSets. No wildcard entries. Users must be able to set up priority levels and assign them to contracts without SUPER. |  | [49] [50] [51] [52] |

## 3. How the data flows

- **Priority option values Low, Normal, High** → **Priority Level table**: other. Upgrade step 1, per company, guarded by its own upgrade tag: insert one Priority Level per option value when it does not exist yet (guarded Get), without errors that block the upgrade. [26] [33] [34]
- **Service Contract.Priority** → **Service Contract.Priority Level Code**: other. Upgrade step 2, per company, guarded by its own upgrade tag and run after step 1 from the same trigger: DataTransfer in place on Service Contract, one CopyFields per option value with AddSourceFilter(Priority) and AddConstantValue(Priority Level Code). InitValue on the new field would not reach these existing rows. [30] [31] [32] [27]
- **Priority Levels page** → **Priority Level**: entered by the user. Users maintain the list of levels. [41]
- **Service Contract card** → **Service Contract.Priority Level Code**: field validation. The TableRelation to Priority Level checks the entered code and drives the lookup. [42]
- **Service Contract.Priority Level Code** → **Integration event subscribers**: other. Passed as a new parameter on the existing local/internal event, or on a new event beside a public one. [15] [14]
- **Service Contract.Priority Level Code** → **External business event version 2.0 payload**: other. Raised beside the obsoleted version; Power Automate receives it only after the transaction commits. [24]
- **Service Contract.Priority Level Code** → **Service Contract API v2.0 priorityLevelCode**: other. Read and written through the new API page object only; v1.0 keeps its shape. [21]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Upgrade Tag | `OnGetPerCompanyUpgradeTags` | Add both Priority Level upgrade tags to the per-company list so SetAllUpgradeTags marks them complete for newly created companies, which start on the new schema. | Use the same shared tag definitions as the upgrade and install codeunits. | [40] |

## 5. Setup, permissions and lifecycle

- **upgrade**: Run the Priority Level migration only from OnUpgradePerCompany of a Subtype = Upgrade codeunit; guard each step with HasUpgradeTag at entry and SetUpgradeTag after success; one tag per step, not nested; no DataVersion or AppVersion branching. [25] [26] [28] [29]
- **upgrade**: Keep upgrade code safe: guard every database read with if, log a warning with a stable, registered telemetry event ID and continue instead of raising an error on unexpected data, make no external calls and never use ChangeCompany. [33] [34] [35] [36] [37]
- **install**: On first install (DataVersion 0.0.0.0) set both Priority Level upgrade tags explicitly; register them in OnGetPerCompanyUpgradeTags for new companies. [38] [39] [40]
- **other**: Obsoletion staging: this release marks the Priority field Pending (with reason and tag), the old integration event (if replaced) and the old business event version [Obsolete]; a later release moves the field to Removed and deletes the obsolete event procedures. New logic is built only on Priority Level Code, never on the obsolete members. [7] [8] [10] [11]
- **other**: Any published (non-local) procedure that takes or returns the Priority option keeps its signature; add a new procedure or overload that uses the Priority Level code, let the old one delegate, and mark the old one [Obsolete] naming the replacement. New helpers start local or internal. [12] [10] [13]
- **privacy**: Classify the Priority Level table at table level and the new Service Contract field through the table default or explicitly; no ToBeClassified at release. [43] [44]
- **permissions**: Extend the app's building-block permission sets with Priority Level tabledata, the Priority Levels page and the v2.0 API page; validate setup and contract maintenance as a user with only the app roles. [49] [51] [52]
- **other**: Translations: add XLIFF entries for the new table, page, field captions and tooltips; the old field keeps its name so its translation IDs stay valid. [48]
- **other**: Release: raise the app version deliberately (new functionality, no breaking change, so a minor bump by convention) before the AppSource submission. [53]

## 6. Tests

1. **upgrade-maps-option-to-code** agent judgment
    - Given A company with Service Contracts whose obsolete Priority is Low, Normal and High, no Priority Level records and no Priority Level upgrade tags
    - When The Priority Level upgrade procedures run
    - Then Priority Level records exist for the three former values and every contract's Priority Level Code matches its former Priority
2. **upgrade-runs-once** [26]
    - Given The Priority Level upgrade tags are already set and a contract's Priority Level Code was changed by a user
    - When The upgrade procedures run again
    - Then No Priority Level is inserted and the user's Priority Level Code is unchanged
3. **upgrade-tolerates-existing-levels** [33] [34]
    - Given A Priority Level with the code for Normal already exists
    - When Upgrade step 1 runs
    - Then The upgrade completes without error and the existing record is kept
4. **new-company-and-install-tags** [40] [39]
    - Given A first install (DataVersion 0.0.0.0) or a newly created company
    - When Install code runs or SetAllUpgradeTags initializes the company
    - Then Both Priority Level upgrade tags are set, so the migration does not run later
5. **contract-validates-priority-level** [42] [54]
    - Given A Priority Level with a 10-character code and a Service Contract built through the app's fixture helpers
    - When Priority Level Code is validated with that code, and then with a code that does not exist
    - Then The existing code is accepted without a length error and the unknown code is rejected by the table relation
6. **integration-event-carries-code** [16] [14]
    - Given A test subscriber bound to the integration event by name, one with and one without the new Priority Level Code parameter
    - When The contract action that raises the event runs
    - Then Both subscribers are called and the new parameter (or new event) carries the contract's Priority Level Code
7. **business-event-versions** [24]
    - Given A Service Contract with a Priority Level Code
    - When The business action that raises the external business event commits
    - Then Version 2.0 is raised with the Priority Level Code and the obsoleted version is still raised with its original payload
8. **api-versions** [21]
    - Given A Service Contract with a Priority Level Code
    - When It is read through the v1.0 and the v2.0 API pages
    - Then v2.0 returns priorityLevelCode and v1.0 returns exactly its published fields
9. **permissions-without-super** [55] [52] [56]
    - Given A test user lowered to the app's assignable role sets only (TestPermissions = Restrictive)
    - When The user creates a Priority Level, assigns it to a contract and reads it through the v2.0 API page
    - Then Each operation succeeds without SUPER

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Testing the upgrade path on data shaped like the previous app version is not covered by BCQuality knowledge; the upgrade-maps-option-to-code test rests on judgment.
- Whether removing a shipped control from a page breaks dependent page extensions is not covered by an opened article; service-contract-pages rests on judgment for that part.
- Seeding default Priority Level records in newly created companies is not covered by an opened article; only the upgrade-tag registration is.
- Applicability dimensions bc-version, countries and application-area are unknown; version-conditional guidance (Isolated from BC20, table-field tooltip inheritance from BC24) is applied conditionally.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-change-to-a-shipped-feature.md`: Planning map for changing the shipped Priority option: one decision per row for fields, obsoletion, procedures, upgrade, events, APIs, business events, translations, release and tests.
    - Establish whether the symbol was released before applying breaking-change and upgrade rules.
    - Do not change the option field to a code field in place, rename the event parameter or rely on InitValue.
    - Which release removes an obsolete element, and whether dependent apps or flows are known, are questions for the requester.
[2] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Planning map for the new Priority Level table: table type, pages, privacy, permissions, install and tests.
    - Plan table type, pages, privacy, permissions and install behavior, not only the table and its page.
    - A row the request does not settle is a question for the requester, not a default.
[3] `microsoft/knowledge/feature-design/plan-api-exposure-and-background-sync.md`: Inbound API decisions for the changed Service Contract API page: version by adding, routing properties, permissions.
    - A changed shape is a new version.
    - Every API page needs an execute entry in a permission set.
[4] `microsoft/knowledge/breaking-changes/unreleased-symbol-change-is-not-a-breaking-change.md`: Establishes that breaking-change rules apply: the request states the Priority field ships in an AppSource app.
    - Treat a change as breaking only when the symbol was present in a released baseline.
[5] `microsoft/knowledge/breaking-changes/obsolete-table-fields-instead-of-deleting-them.md`: Keep the Priority field and add Priority Level Code under a new ID.
    - Keep the old field's ID, name and type unchanged.
    - Add the replacement under an unused ID and mark the old field Pending with a reason naming the replacement and a tag.
    - Keep the old field readable so upgrade code can copy its data; move to Removed only in a later release.
[6] `microsoft/knowledge/upgrade/breaking-changes-only-on-tables-without-data.md`: Rules out changing the Priority field type in place on a table with customer data.
    - Field-type changes are restricted to tables introduced in the same change; tables with data need an explicit migration design.
[7] `microsoft/knowledge/upgrade/obsolete-pending-to-removed-staging.md`: Staging the Priority field and obsolete events across releases.
    - Mark Pending first with reason and tag; move to Removed in a later release.
    - Do not jump straight to Removed and do not leave an element Pending indefinitely.
[8] `microsoft/knowledge/upgrade/obsoletion-requires-reason-and-tag.md`: Obsoletion metadata for the Priority field and the [Obsolete] events.
    - Fields use ObsoleteState, ObsoleteReason and ObsoleteTag together.
    - Events and methods use [Obsolete('reason', 'tag')] with both arguments.
    - Keep the original tag stable through the lifecycle.
[9] `microsoft/knowledge/upgrade/obsoletereason-need-not-restate-removal-version.md`: Wording of the Priority field's ObsoleteReason.
    - The reason explains the deprecation and names the replacement; the version lives in ObsoleteTag.
[10] `microsoft/knowledge/breaking-changes/deprecate-public-members-with-the-obsolete-lifecycle.md`: Retiring published procedures and events that use the Priority option.
    - Keep a superseded procedure, mark it [Obsolete] naming the replacement, and let it forward to the new one.
    - Delete it only after the deprecation window; methods have no ObsoleteState.
[11] `microsoft/knowledge/breaking-changes/do-not-modify-code-already-marked-obsolete.md`: New behavior is built on Priority Level Code, not on the obsolete field or events.
    - Leave obsolete members as they are and implement against the supported replacement.
[12] `microsoft/knowledge/breaking-changes/do-not-change-published-procedure-signatures.md`: Published procedures that take or return the Priority option.
    - Do not add, remove, reorder or retype parameters of a non-local procedure that shipped; add a new procedure or overload and let the old one delegate.
[13] `microsoft/knowledge/breaking-changes/choose-access-modifiers-deliberately.md`: Access of the new procedures introduced for the Priority Level code.
    - Start new members local or internal; make public only a deliberately supported entry point.
[14] `microsoft/knowledge/events/treat-local-and-internal-events-as-subscriber-contracts.md`: Keeping the shipped integration event's identity and parameters.
    - Preserve the event name and every existing parameter's name, type/subtype and var mode, whatever the publisher's access modifier.
[15] `microsoft/knowledge/events/add-new-event-parameters-at-the-end.md`: Choosing between adding a parameter and publishing a new event.
    - Add a parameter directly only when the shipped publisher is local or internal.
    - For a public event, keep the original unchanged and introduce a new event.
[16] `microsoft/knowledge/events/adding-a-parameter-to-an-event-is-not-a-breaking-change.md`: Confirms that existing subscribers keep binding after the Priority Level Code parameter is added.
    - Adding a parameter to a local or internal publisher does not break subscribers at any position.
[17] `microsoft/knowledge/events/do-not-change-shipped-event-attribute-flags.md`: Attribute flags of the shipped integration event.
    - Keep IncludeSender, GlobalVarAccess and (BC20 and later) Isolated exactly as shipped; publish a new event for different flags.
[18] `microsoft/knowledge/events/do-not-add-ishandled-to-an-existing-event.md`: The existing integration event stays a notification.
    - Do not add var IsHandled to the existing event; use a separate OnBefore event if an override seam is needed.
[19] `microsoft/knowledge/events/declare-event-publishers-local-or-internal.md`: Access of any new integration event publisher.
    - Declare new publishers local (or internal when another object in the app raises them).
[20] `microsoft/knowledge/events/avoid-loosely-typed-event-parameters.md`: Typing of the new Priority Level Code parameter.
    - Pass a concrete typed value, not a RecordRef or xRec.
[21] `microsoft/knowledge/web-services/version-apis-by-adding-not-mutating-published-versions.md`: New v2.0 API page object beside the unchanged v1.0 page.
    - Keep the existing page object and its v1.0 contract unchanged.
    - Create a separate page object with APIVersion = 'v2.0' for the changed shape; do not add v2.0 to the old page.
[22] `microsoft/knowledge/web-services/set-required-api-page-properties.md`: Routing properties of the v2.0 API page.
    - Declare APIPublisher, APIGroup, EntityName, EntitySetName and SourceTable, and an explicit stable APIVersion.
[23] `microsoft/knowledge/style/api-page-version-format.md`: Format of the new API version.
    - APIVersion follows vX.Y, such as 'v2.0'; bump the major for a breaking shape change.
[24] `microsoft/knowledge/web-services/raise-external-business-events-for-power-automate.md`: Versioning the Power Automate business event to carry the Priority Level code.
    - Do not rename, re-version or change the parameters of the shipped event.
    - Add a procedure with the same name and a higher version, raise both, and mark the old one [Obsolete] with [OBSOLETE] at the start of its display name; remove it in a later release.
    - Payload uses simple types such as Code, not records.
[25] `microsoft/knowledge/upgrade/upgrade-codeunit-subtype.md`: Home of the migration code.
    - Upgrade logic lives in a codeunit with Subtype = Upgrade entered from OnUpgradePerCompany or OnUpgradePerDatabase; helpers it calls inherit upgrade rules.
[26] `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`: Making each migration step run once per company.
    - Start each upgrade procedure with HasUpgradeTag and end with SetUpgradeTag; no DataVersion branching.
[27] `microsoft/knowledge/upgrade/install-and-upgrade-codeunits-have-no-order.md`: Ordering the create-levels step before the copy step.
    - Coordinate dependent steps from one owning trigger in the required order; do not rely on codeunit order.
[28] `microsoft/knowledge/upgrade/upgrade-tag-logic-must-not-nest-deeply.md`: Tag structure of the two migration steps.
    - One tag, one migration; do not nest one tag check inside another.
[29] `microsoft/knowledge/upgrade/appversion-meaning-depends-on-execution-context.md`: Rules out AppVersion-based routing in the migration.
    - AppVersion() in upgrade code is the target version; prefer upgrade tags to control steps.
[30] `microsoft/knowledge/upgrade/datatransfer-for-bulk-init.md`: Set-based copy of the option value to the new code field.
    - Prefer DataTransfer over an equivalent FindSet/Modify loop regardless of record count, using SetTables, AddSourceFilter, AddConstantValue and CopyFields.
    - Clear the variable before reusing it for a different transfer.
[31] `microsoft/knowledge/upgrade/datatransfer-skips-triggers-and-subscribers.md`: Checking that skipping the new field's validation is safe.
    - DataTransfer runs no OnValidate, OnModify or subscribers; establish which logic is bypassed before using it.
    - Use a Validate loop when field validation must run.
[32] `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`: Why existing contracts need upgrade code rather than an InitValue.
    - InitValue reaches new rows only; existing rows need an upgrade routine guarded by an upgrade tag.
[33] `microsoft/knowledge/upgrade/guard-database-reads.md`: Reads in the migration steps.
    - Wrap every Get, FindSet and FindLast in upgrade code in an if.
[34] `microsoft/knowledge/upgrade/do-not-block-upgrade-on-data-errors.md`: Handling unexpected data during migration.
    - Log a warning with a stable event ID and exit the procedure instead of raising an error.
[35] `microsoft/knowledge/upgrade/no-external-calls-in-upgrade.md`: Upgrade code must not notify flows or external systems.
    - No HttpClient or other external I/O in upgrade code or anything it calls.
[36] `microsoft/knowledge/upgrade/no-changecompany-in-upgrade.md`: Per-company scope of the migration.
    - Migrate in OnUpgradePerCompany for the current company only; never ChangeCompany.
[37] `microsoft/knowledge/telemetry/telemetry-event-id-stable-unique.md`: Event ID of the upgrade warning.
    - Use a real, registered, unique event ID; never a placeholder.
[38] `microsoft/knowledge/upgrade/install-code-does-not-run-on-version-upgrade.md`: Separating first-install tag seeding from the version migration.
    - Install code runs on install and reinstall only; version migration goes in an upgrade codeunit.
[39] `microsoft/knowledge/upgrade/first-install-dataversion-zero-check.md`: Detecting a first install before seeding the upgrade tags.
    - Run first-install logic only when DataVersion() = Version.Create('0.0.0.0').
[40] `microsoft/knowledge/upgrade/register-upgrade-tags-with-subscribers.md`: Upgrade tags for new companies and fresh installs.
    - Add the tags in OnGetPerCompanyUpgradeTags for new companies.
    - Seed the tags explicitly with SetUpgradeTag from OnInstallAppPerCompany; registration does not set them on install.
    - Share one tag definition across all paths.
[41] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Table type of Priority Level.
    - A Supplemental table has primary key Code[10] named Code and one plural list page set as LookupPageID.
    - A table that holds more than one record does not follow singleton Setup rules.
[42] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Type and length of Priority Level Code.
    - An unconditionally related field has the same type and exact length as the related field.
[43] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification of the new table and field.
    - A table-level classification covers the table's own Normal fields; a tableextension field must classify itself.
[44] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of the new table and field.
    - No ToBeClassified in a shipped extension.
[45] `microsoft/knowledge/style/page-name-must-match-source-table.md`: Name of the new list page.
    - The page name must describe its source table.
[46] `microsoft/knowledge/style/pages-must-not-contain-business-logic.md`: Keeping priority validation out of pages.
    - A rule that must hold for every entry point belongs in the table or a codeunit, not in a page trigger.
[47] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips for the new field and table (applies from BC24 for table-field inheritance).
    - On runtime 13.0 or later define tooltips on the table field and let pages inherit them; earlier runtimes need page-level tooltips.
[48] `microsoft/knowledge/style/renaming-objects-or-members-changes-translation-ids.md`: Not renaming the old field, and translating the new captions.
    - A rename changes translation IDs; existing translations must be moved in the same change.
[49] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Where the new grants go.
    - Add objects to focused non-assignable building blocks included by role-shaped assignable sets.
[50] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Shape of the new grants.
    - Enumerate each tabledata and object entry with only the letters needed; no wildcards.
[51] `microsoft/knowledge/security/exposed-objects-must-be-in-a-permission-set.md`: Execute permission for the v2.0 API page.
    - Every API page has a page = X entry in a shipped permission set.
[52] `microsoft/knowledge/appsource/permission-sets-cover-setup-and-usage-without-super.md`: AppSource permission completeness for priority setup and use.
    - App role sets must let users complete setup and normal usage without SUPER, validated as such a user.
[53] `microsoft/knowledge/appsource/release-must-update-app-version.md`: Version of the release that ships the change.
    - Update the app version deliberately at every release; major for breaking changes, minor for new functionality by convention.
[54] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Building test fixtures.
    - Use library codeunits for standard prerequisite data, create parents first and Validate foreign-key fields so the TableRelation runs.
[55] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: Permission test for priority setup and use.
    - Use TestPermissions::Restrictive and lower the user with the test libraries before the protected operation.
[56] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunits.
    - Tag codeunits with [FEATURE] and tests with [SCENARIO], [GIVEN], [WHEN], [THEN].

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

