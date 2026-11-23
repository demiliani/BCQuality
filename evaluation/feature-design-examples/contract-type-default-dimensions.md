# Feature design

> Add Service Contract Types as a new master list whose records carry default dimensions like customers and items, and make new service contracts inherit dimensions from both their contract type and their customer.

**Result:** Partial design: some parts could not be designed. **Business process:** Service contract management: master data setup and service contract creation (dimension inheritance). **Knowledge used:** 19 BCQuality articles.

**Why:** The Service Contract Type master table, its default-dimension ownership and the type-to-contract hop on the new type field are designed. Material gap: inheriting from the contract type when the contract's customer changes needs an event in the service contract's own dimension computation, and no opened article or repository symbol confirms one (no repository was supplied).

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Are the 'service contracts' the standard Service Contract Header (to be extended) or a new custom contract document in this app? _(affects: ext-service-contract-header, pex-service-contract, cod-contract-type-dim-mgt, t-new-contract-inherits-type-and-customer)_
2. Should Service Contract Type follow the Master convention (No., Code[20], card + list) as the request's 'master list' suggests, or the Supplemental convention (Code, Code[10], one list page)? _(affects: tbl-service-contract-type, pag-service-contract-type-card, ext-service-contract-header)_
3. Are contract type numbers entered manually or assigned from a number series (which would also need a setup table)? _(affects: tbl-service-contract-type)_
4. Do contract types need a Blocked flag that prevents their use on new contracts? _(affects: tbl-service-contract-type, ext-service-contract-header)_
5. When the contract type and the customer both define a default for the same dimension, which value must the contract get? _(affects: cod-contract-type-dim-mgt, t-new-contract-inherits-type-and-customer)_
6. Is a contract type mandatory on every new service contract, and does it apply to contract quotes too? _(affects: ext-service-contract-header, pex-service-contract)_
7. Must existing contracts receive a type or recomputed dimensions on upgrade, or does the rule apply only to contracts created after installation? _(affects: ext-service-contract-header)_
8. Should the inherited dimensions continue to contract lines and to invoices or credit memos created from the contract, beyond what the standard process already copies? _(affects: cod-contract-type-dim-mgt)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Service Contract Type | Master table for contract types (the request calls it a master list). Owns its default dimensions following the Customer pattern: global dimension fields validated through ValidateShortcutDimCode (ValidateDimValueCode + SaveDefaultDim), UpdateDefaultDim in OnInsert, RenameDefaultDim in OnRename, DeleteDefaultDim in OnDelete. Primary key is a single Code field so DefaultDimObjectNoList lists the table on the Default Dimensions lookup without a subscriber. Table-level DataClassification = CustomerContent. Declares Permissions on the Default Dimension rows it deletes. Whether the key is Master-style (No., Code[20], number series) or Supplemental-style (Code, Code[10]) is an open question. | No. (Code[20]): Master convention primary key; numbering open (see q-number-series). One Code field only, so the table qualifies for DefaultDimObjectNoList.; Description (Text[100]): Include in DataCaptionFields per the Master convention.; Global Dimension 1 Code (Code[20]): CaptionClass '1,1,1'; TableRelation "Dimension Value".Code where("Global Dimension No." = const(1), Blocked = const(false)); OnValidate calls ValidateShortcutDimCode(1, ...).; Global Dimension 2 Code (Code[20]): CaptionClass '1,1,2'; TableRelation "Dimension Value".Code where("Global Dimension No." = const(2), Blocked = const(false)); OnValidate calls ValidateShortcutDimCode(2, ...). | [1] [2] [3] [4] [7] [9] [10] |
| 2 | create | page | Service Contract Types | List page for the master list, named after its source table, set as LookupPageID/DrillDownPageID. Includes a Dimensions action opening the Default Dimensions page for the selected type. No business logic: dimension handling stays in the table. |  | [4] [11] [12] [13] |
| 3 | create | page | Service Contract Type Card | Card page required by the Master table convention, showing Description and the two global dimension fields, with the Dimensions action. Tooltips defined on the table fields (inherited from runtime 13.0 / BC24) or on the page for older targets. |  | [4] [11] [12] [13] |
| 4 | create | codeunit | Service Contract Type Dim. Mgt. | Holds the OnAfterUpdateGlobalDimCode subscriber that keeps Service Contract Type global dimension fields in sync with the Default Dimensions page, and the procedure that recomputes a service contract's Dimension Set ID from AddDimSource entries for the contract type and the customer with GetDefaultDimID and InheritFromDimSetID = 0. |  | [2] [3] |
| 5 | extend | tableextension | Service Contract Header | Adds the contract type reference. Its OnValidate calls the codeunit recompute so the contract's Dimension Set ID inherits the type's and the customer's default dimensions. Applies only if service contracts are the standard Service Contract Header (see q-contract-object). | Service Contract Type Code (Code[20]): TableRelation "Service Contract Type"."No."; same type and exact length as the related key. Explicit DataClassification = CustomerContent (a tableextension inherits no table-level default). | [3] [8] [9] |
| 6 | extend | pageextension | Service Contract card page | Shows Service Contract Type Code on the contract so users can set it; presentation only. |  | [12] [13] |
| 7 | create | permissionset | Contract Type - Objects | Non-assignable building block listing the new table (tabledata RIMD), pages and codeunit explicitly, with no wildcard grants. |  | [14] [15] |
| 8 | create | permissionset | Contract Type - Edit | Assignable role-shaped set that includes the building block through IncludedPermissionSets. |  | [14] [15] |
| 9 | create | codeunit | Contract Type Dimensions Tests | Test codeunit tagged [FEATURE] with [SCENARIO]/[GIVEN]/[WHEN]/[THEN] per test; fixtures from library codeunits; permission test lowers the execution context. |  | [17] [19] [18] |

## 3. How the data flows

- **Service Contract Type.Global Dimension 1/2 Code** → **Default Dimension (Table ID = Service Contract Type, No.)**: field validation. ValidateShortcutDimCode calls ValidateDimValueCode then SaveDefaultDim with the shortcut dimension number (1 or 2), not the field ID; skipped for temporary records. [2] [3]
- **Default Dimension (edited on the Default Dimensions page)** → **Service Contract Type.Global Dimension 1/2 Code**: copied in an event subscriber. Default Dimension writes global values back only to standard tables it knows; for this table it raises OnAfterUpdateGlobalDimCode, which the subscriber handles. [2]
- **Service Contract Type record (OnInsert / OnRename / OnDelete)** → **Default Dimension rows of that type**: other. UpdateDefaultDim on insert, RenameDefaultDim on rename, DeleteDefaultDim on delete, so no orphaned Default Dimension rows remain. Callers must use Insert(true) and Delete(true). [2] [7] [5] [6]
- **User on the service contract card** → **Service Contract Header.Service Contract Type Code**: entered by the user. [8]
- **Default Dimension of Service Contract Type and of Customer** → **Service Contract Header.Dimension Set ID**: other. On validate of Service Contract Type Code: clear the shortcut fields, AddDimSource for Customer (Customer No.) and for Service Contract Type when each Get succeeds, then GetDefaultDimID with InheritFromDimSetID = 0. Recompute the same way when the type is blank or invalid; never exit early. Whether this source list must also include the other sources the standard contract already uses is unresolved. The same recompute on a customer change needs an unconfirmed event (see unresolved). [3] [2] [16]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Default Dimension" | `OnAfterUpdateGlobalDimCode` | Copy a global dimension value changed on the Default Dimensions page to the matching Service Contract Type field. | Exit when TableID <> Database::"Service Contract Type". · Exit when the Service Contract Type record (AccNo) is not found. · Set only the field matching GlobalDimCodeNo (1 or 2). | [2] |

## 5. Setup, permissions and lifecycle

- **permissions**: Ship the non-assignable building block and the assignable set composed with IncludedPermissionSets; enumerate each object explicitly, no wildcards. Declare Permissions = tabledata "Default Dimension" = rd on the Service Contract Type table so its OnDelete cleanup works for non-SUPER users. [14] [15] [7]
- **privacy**: Classify the new table at table level (CustomerContent) and the tableextension field explicitly; no ToBeClassified at release. [9] [10]
- **other**: Any code that creates or deletes Service Contract Types (imports, demo data, tests) uses Insert(true) and Delete(true) so the table triggers maintain default dimensions. [5] [6]

## 6. Tests

1. **t-type-dim-saved-as-default-dimension** [2] [17] [19]
    - Given A Service Contract Type and a global dimension 1 value created with library codeunits
    - When Global Dimension 1 Code is validated on the type
    - Then A Default Dimension row exists for Table ID Service Contract Type, the type's No. and that dimension value
2. **t-default-dimension-edit-syncs-type** [2] [19]
    - Given A Service Contract Type with no global dimension 2
    - When A Default Dimension row for global dimension 2 is inserted or modified for that type through the Default Dimension table
    - Then The type's Global Dimension 2 Code equals the new value
3. **t-subscriber-ignores-other-tables** [2]
    - Given A customer and a Service Contract Type with the same No.
    - When A global dimension default is changed for the customer
    - Then The Service Contract Type's global dimension fields are unchanged
4. **t-rename-and-delete-move-default-dimensions** [2] [7] [6]
    - Given A Service Contract Type with default dimensions
    - When The type is renamed, then deleted with Delete(true)
    - Then Default Dimension rows follow the new No. after rename and none remain after delete
5. **t-new-contract-inherits-type-and-customer** [3] [17]
    - Given A customer with a default for dimension A and a Service Contract Type with a default for dimension B
    - When A new service contract is created for the customer and Service Contract Type Code is validated
    - Then The contract's Dimension Set ID contains dimension A with the customer's value and dimension B with the type's value
6. **t-changing-type-drops-previous-type-dims** [3]
    - Given A contract inheriting dimension B from type 1, and type 2 with no default for dimension B
    - When Service Contract Type Code is changed to type 2, and then cleared
    - Then Dimension B is no longer in the contract's Dimension Set ID in either case, and the customer's dimension A remains
7. **t-permission-set-allows-type-maintenance** [18] [14] [7]
    - Given A test user lowered to the Contract Type - Edit permission set (TestPermissions Restrictive)
    - When The user creates a Service Contract Type, sets its global dimensions and deletes it
    - Then All operations succeed, including Default Dimension cleanup on delete

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Material: no confirmed event on the service contract's own dimension computation (for example when Customer No. changes) to add the Service Contract Type as a dimension source; no opened article names one and no repository symbols were available. Without it, a later customer change recomputes dimensions without the contract type.
- The full list of dimension sources the standard service contract already uses besides the customer is not covered by BCQuality knowledge; the type-field recompute must not drop them.
- Context dimensions bc-version, countries and application-area are unknown; tooltip inheritance depends on runtime 13.0 (BC24) or later.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Decision map for the new master table: table type, numbering, data rules, privacy, pages, permissions, install/upgrade and tests.
    - Plan every decision row, not only the table and its page.
    - A row the request does not settle, such as whether a number series is needed, is a question for the requester, not a default.
[2] `microsoft/knowledge/finance-extensions/give-a-new-master-table-default-dimensions.md`: Default-dimension ownership of Service Contract Type and the Default Dimensions page sync.
    - Add Global Dimension 1/2 Code with CaptionClass '1,1,1' and '1,1,2', validated through ValidateShortcutDimCode calling ValidateDimValueCode and SaveDefaultDim.
    - Call UpdateDefaultDim in OnInsert, RenameDefaultDim in OnRename and DeleteDefaultDim in OnDelete.
    - Subscribe to Default Dimension OnAfterUpdateGlobalDimCode and update the record only when its table ID matches.
    - The table appears in the Default Dimensions lookup automatically only when it has the Global Dimension Code[20] fields, no field related to Dimension Set Entry, and a single Code field primary key.
    - A document carrying dimensions stores a Dimension Set ID computed with AddDimSource and GetDefaultDimID, not copied dimension codes.
[3] `microsoft/knowledge/data-modeling/dimension-management-wiring.md`: Master-vs-document dimension models and the contract's Dimension Set ID recompute from type and customer.
    - The master table carries no Dimension Set ID; ValidateDimValueCode and SaveDefaultDim take the shortcut dimension number, not the field ID.
    - When the field linking the document to a master changes, AddDimSource for that master and call GetDefaultDimID with InheritFromDimSetID = 0.
    - Run the same recompute (clear the shortcut field, GetDefaultDimID with no source added) when the lookup on the new key fails; do not exit early.
    - Validate the document's own shortcut dimension fields through ValidateShortcutDimValues.
[4] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Classify Service Contract Type and derive its key and pages.
    - Master: primary key Code[20] named No., description in DataCaptionFields, Card + List pages.
    - Supplemental: primary key Code[10] named Code, one plural List page set as LookupPageID.
[5] `microsoft/knowledge/data-modeling/master-data-must-be-inserted-with-trigger.md`: Callers creating contract types must run OnInsert so default dimensions are maintained.
    - Create custom master records with initializing OnInsert logic with Insert(true), then validate and Modify(true).
    - Temporary and buffer records are out of scope.
[6] `microsoft/knowledge/data-modeling/delete-master-data-with-trigger.md`: Callers deleting contract types must run OnDelete so default dimensions are removed.
    - Outside the owning table's triggers, delete master and reference records with Delete(true)/DeleteAll(true).
[7] `microsoft/knowledge/data-modeling/owning-table-must-delete-dependents-in-ondelete.md`: Service Contract Type owns its Default Dimension rows.
    - The owning table deletes its dependents in OnDelete; AL has no cascading delete.
    - Declare Permissions = tabledata <dependent> = rd on the owning table so the trigger works for non-SUPER users.
[8] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Size of Service Contract Type Code on the contract.
    - A field with an unconditional TableRelation has the same type and exact length as the related field.
[9] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification of the new table and the tableextension field.
    - A table-level DataClassification is the default for the table's own Normal fields.
    - Fields added by a tableextension inherit nothing and must declare DataClassification explicitly.
[10] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of the new fields.
    - No field ships with DataClassification = ToBeClassified.
[11] `microsoft/knowledge/style/page-name-must-match-source-table.md`: Names of the new list and card pages.
    - The page name must describe the entity of its SourceTable.
[12] `microsoft/knowledge/style/pages-must-not-contain-business-logic.md`: Keep dimension handling out of the new and extended pages.
    - Business operations and invariants that must hold for every entry point belong in a codeunit or the table, not in a page trigger.
[13] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips for the new page fields; table-field inheritance applies from BC24 (runtime 13.0).
    - From runtime 13.0, define tooltips on table fields and let bound page fields inherit them; for older targets, add page-level tooltips.
    - Tooltip text must say what the value is used for, not repeat the caption.
[14] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Structure of the shipped permission sets.
    - Ship focused building blocks with Assignable = false and assignable role-shaped sets that include them through IncludedPermissionSets.
[15] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Content of the permission sets.
    - Enumerate each tabledata and table entry; no * grants.
    - Grant only the letters required (RIMD only for owners of the data).
[16] `microsoft/knowledge/events/prefer-reusing-or-extending-existing-events.md`: Hooking the contract type into the service contract's existing dimension computation.
    - Subscribe to an existing event where the data is exposed; do not add a parallel event beside an existing one.
[17] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for customers, dimensions and contracts.
    - Build prerequisite records with library codeunits, parents first, and Validate foreign-key fields.
[18] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: Permission test for contract type maintenance.
    - Use TestPermissions Restrictive and lower the test user with Permissions Mock or Library - Lower Permissions before the protected operation.
[19] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunit.
    - [FEATURE] once per codeunit; [SCENARIO] first in each test body, then [GIVEN]/[WHEN]/[THEN].

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
