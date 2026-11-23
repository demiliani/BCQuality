# Feature design

> Our new Maintenance Order document has a customer, an item, an equipment record (our own master table) and a maintenance contract. Its dimensions must come from the default dimensions of all four. Service contracts must also pick up the equipment's default dimensions when an equipment number is entered.

**Result:** Complete design. **Business process:** Dimension management for a custom Maintenance Order document and for standard service contracts: building a Dimension Set ID from the default dimensions of several master records. **Knowledge used:** 18 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Is a maintenance contract the caller's own master table, or the standard Service Contract Header? A standard service contract carries a Dimension Set ID, not its own Default Dimension rows, so the fourth source and its table relation depend on this. _(affects: maintenance-contract-default-dimensions, maintenance-order-header-dimensions, order-dimensions-merge-all-four-sources, order-cleared-source-drops-its-dimension)_
2. What does the Equipment table already have: its primary key type and length, global dimension fields, and Default Dimension handling on insert, rename and delete? _(affects: equipment-default-dimensions, maintenance-order-header-dimensions, service-contract-equipment-field)_
3. Which source should win when customer, item, equipment and contract give different values for the same dimension, and should the app create the source code and Default Dimension Priority rows or leave them to users? _(affects: maintenance-order-header-dimensions, order-dimension-conflict-follows-priority)_
4. On service contracts, should the equipment's dimensions win over the contract's standard sources (bill-to customer, salesperson, responsibility center, contract template, service order type) when they conflict, and under which source code are those priorities set up? _(affects: service-contract-dimension-subscriber, service-contract-picks-up-equipment-dimensions)_
5. Changing a source field rebuilds the dimensions and replaces manual changes. Should the Maintenance Order ask for confirmation first, as Sales Header does? _(affects: maintenance-order-header-dimensions, order-shortcut-dimension-updates-set)_
6. Does the Maintenance Order have lines? If so, should lines inherit the header set as InheritFromDimSetID and add their own sources such as an item? _(affects: maintenance-order-header-dimensions)_
7. Is a Maintenance Order posted or turned into journals, posted records or service documents? If so, the whole Dimension Set ID must be copied to those targets, never only the shortcut codes; that stage is not designed here. _(affects: maintenance-order-header-dimensions)_
8. Should Equipment No. be editable on a service contract whose Change Status is not Open, given that the contract does not recalculate dimensions in that state? _(affects: service-contract-equipment-field, service-contract-not-open-keeps-dimensions)_
9. Should the equipment dimensions also reach service contract lines, service invoices created from the contract or other documents? The request only asks for the contract header. _(affects: service-contract-dimension-subscriber)_
10. Which pages show Equipment No. (service contract card, list, quote) and should the Maintenance Order pages show shortcut dimension fields and a Dimensions action? _(affects: service-contract-equipment-page, maintenance-order-header-dimensions)_
11. Do existing Equipment records, maintenance contracts or Maintenance Orders already hold data that needs Default Dimension rows or a Dimension Set ID created by upgrade code? _(affects: equipment-default-dimensions, maintenance-order-header-dimensions)_
12. Which Business Central version does the app target? It decides whether tooltips can be defined on table fields (runtime 13.0/BC24 or later). _(affects: service-contract-equipment-page)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Maintenance Order Header (new document table) | Give the new Maintenance Order document one Dimension Set ID built from the default dimensions of its customer, item, equipment and maintenance contract. Only the dimension-related fields and procedures are designed here; the document's other fields, numbering and pages are outside this request. Each source field's OnValidate calls CreateDimFromDefaultDim(FieldNo); CreateDimFromDefaultDim clears the shortcut fields and rebuilds the set from all four sources with InheritFromDimSetID = 0 and the document's own source code, so a cleared or replaced source leaves no stale values. A local InitDefaultDimensionSources(DefaultDimSource, FieldNo) adds one AddDimSource per source, passing FieldNo = FieldNo(<source field>) as FirstPos so the field just changed goes first, then raises a local, empty-bodied integration event OnAfterInitDefaultDimensionSources(var MaintenanceOrderHeader, var DefaultDimSource, FieldNo) so other apps can add sources. | Customer No. (Code[20]): TableRelation = Customer; OnValidate calls CreateDimFromDefaultDim(FieldNo("Customer No.")). Length must equal Customer."No.".; Item No. (Code[20]): TableRelation = Item; OnValidate calls CreateDimFromDefaultDim(FieldNo("Item No.")). Length must equal Item."No.".; Equipment No. (Code[20]): TableRelation = Equipment; OnValidate calls CreateDimFromDefaultDim(FieldNo("Equipment No.")). Type and length must equal the Equipment primary key; Code[20] is assumed until the Equipment table is confirmed.; Contract No. (Code[20]): TableRelation = Maintenance Contract; OnValidate calls CreateDimFromDefaultDim(FieldNo("Contract No.")). Type and length must equal the related key; see open question on which table a maintenance contract is.; Shortcut Dimension 1 Code (Code[20]): CaptionClass '1,2,1'; OnValidate calls DimensionManagement.ValidateShortcutDimValues(1, ..., "Dimension Set ID") so a manual change updates the same set.; Shortcut Dimension 2 Code (Code[20]): CaptionClass '1,2,2'; OnValidate calls ValidateShortcutDimValues(2, ..., "Dimension Set ID").; Dimension Set ID (Integer): Field 480 as in the sample; TableRelation = "Dimension Set Entry"; Editable = false. The document stores dimensions only as this set ID, never as separate code fields. | [1] [2] [3] [5] [6] [7] [9] [10] |
| 2 | extend | table | Equipment (existing master table in the caller's own app; change in place) | Make Equipment own its Default Dimension rows, following the Customer pattern, so it can be a dimension source for Maintenance Orders and service contracts. Add Global Dimension 1 Code and Global Dimension 2 Code if absent, validated through a ValidateShortcutDimCode procedure that calls ValidateDimValueCode and, when the record is not temporary, SaveDefaultDim. Call UpdateDefaultDim in OnInsert, RenameDefaultDim in OnRename and DeleteDefaultDim in OnDelete. The table keeps no Dimension Set ID field and a primary key of one Code field, so DefaultDimObjectNoList includes it in the Default Dimensions lookup automatically. No repository was supplied, so what Equipment already has is unknown. | Global Dimension 1 Code (Code[20]): CaptionClass '1,1,1'; TableRelation to Dimension Value where Global Dimension No. = 1 and not Blocked; OnValidate calls ValidateShortcutDimCode(1, ...).; Global Dimension 2 Code (Code[20]): CaptionClass '1,1,2'; TableRelation to Dimension Value where Global Dimension No. = 2 and not Blocked; OnValidate calls ValidateShortcutDimCode(2, ...). | [2] [3] [1] |
| 3 | extend | table | Maintenance Contract (assumed to be a master table in the caller's own app; change in place) | If a maintenance contract is the caller's own master table, give it the same Default Dimension ownership as Equipment (global dimension fields validated through ValidateDimValueCode and SaveDefaultDim; UpdateDefaultDim, RenameDefaultDim and DeleteDefaultDim in OnInsert, OnRename and OnDelete) so it can be the fourth dimension source. Conditional on the open question about which table a maintenance contract is. | Global Dimension 1 Code (Code[20]): CaptionClass '1,1,1'; validated as on Equipment.; Global Dimension 2 Code (Code[20]): CaptionClass '1,1,2'; validated as on Equipment. | [2] [3] [1] |
| 4 | extend | tableextension | Service Contract Header | Add Equipment No. to the standard service contract. Its OnValidate calls the contract's CreateDimFromDefaultDim(FieldNo("Equipment No.")) so the contract's Dimension Set ID is rebuilt with the equipment as a source; the source itself is added by the subscriber in service-contract-dimension-subscriber. Service Contract Header's CreateDim exits when Change Status is not Open. | Equipment No. (Code[20]): Field number in the app's range; TableRelation = Equipment with the same type and length as the Equipment key; DataClassification = CustomerContent set explicitly, because a table extension inherits no table-level classification. | [1] [9] [10] [11] |
| 5 | extend | pageextension | Service Contract (card page of Service Contract Header) | Show Equipment No. on the service contract card so users can enter it. Give it tooltip text on the table field (inherited by the page from runtime 13.0/BC24) or on the page control for earlier targets; the text should say that the equipment's default dimensions are added to the contract's dimensions. Which pages show the field is an open question. |  | [14] |
| 6 | create | codeunit | Serv. Contract Equipment Dims (event subscriber codeunit) | Subscribe to Service Contract Header.OnAfterInitDefaultDimensionSources and add Equipment as a dimension source with AddDimSource(DefaultDimSource, Database::Equipment, ServiceContractHeader."Equipment No.", FieldNo = ServiceContractHeader.FieldNo("Equipment No.")). Reuses the standard event rather than adding a parallel mechanism. |  | [1] [8] |
| 7 | create | codeunit | Maint. Master Global Dim Sync (event subscriber codeunit) | Subscribe to Default Dimension.OnAfterUpdateGlobalDimCode and write the new value into Global Dimension 1/2 Code of the Equipment (and, if it is a custom master, Maintenance Contract) record whose table ID and key match, so editing defaults on the Default Dimensions page keeps the record's global dimension fields in sync. |  | [2] |
| 8 | create | permissionset | Maintenance dimension objects (non-assignable building block) | List the new table data and objects explicitly (Maintenance Order Header tabledata and the subscriber codeunits), with only the letters each role needs and no wildcards; mark it Assignable = false and include it through IncludedPermissionSets in the app's role-shaped sets. If the app already has a building block covering Maintenance Order Header, add the new objects there instead. |  | [12] [13] [4] |

## 3. How the data flows

- **Customer Default Dimension rows (via Maintenance Order Header."Customer No.")** → **Maintenance Order Header."Dimension Set ID"**: field validation. Customer No. OnValidate -> CreateDimFromDefaultDim -> AddDimSource for all four sources -> GetRecDefaultDimID with InheritFromDimSetID 0; Customer goes first in the list. [1] [3]
- **Item Default Dimension rows (via Maintenance Order Header."Item No.")** → **Maintenance Order Header."Dimension Set ID"**: field validation. Same recalculation from Item No. OnValidate; Item goes first. [1] [3]
- **Equipment Default Dimension rows (via Maintenance Order Header."Equipment No.")** → **Maintenance Order Header."Dimension Set ID"**: field validation. Same recalculation from Equipment No. OnValidate; Equipment goes first. [1] [3] [2]
- **Maintenance Contract Default Dimension rows (via Maintenance Order Header."Contract No.")** → **Maintenance Order Header."Dimension Set ID"**: field validation. Same recalculation from Contract No. OnValidate; the contract goes first. [1] [3] [2]
- **Maintenance Order Header shortcut dimension fields (user)** → **Maintenance Order Header."Dimension Set ID"**: entered by the user. ValidateShortcutDimValues updates the same set ID; a later source change rebuilds the set and replaces this manual value (see open question on confirmation). [3] [1]
- **Equipment."Global Dimension 1/2 Code"** → **Default Dimension (Table ID = Equipment, No. = Equipment No.)**: field validation. ValidateShortcutDimCode -> ValidateDimValueCode and SaveDefaultDim; OnInsert UpdateDefaultDim, OnRename RenameDefaultDim, OnDelete DeleteDefaultDim. [2] [3]
- **Default Dimension (Table ID = Equipment) edited on the Default Dimensions page** → **Equipment."Global Dimension 1/2 Code"**: copied in an event subscriber. Default Dimension.OnAfterUpdateGlobalDimCode subscriber; same hop for Maintenance Contract if it is a custom master. [2]
- **Equipment Default Dimension rows (via Service Contract Header."Equipment No.")** → **Service Contract Header."Dimension Set ID"**: field validation. Equipment No. OnValidate -> Service Contract Header.CreateDimFromDefaultDim -> InitDefaultDimensionSources raises OnAfterInitDefaultDimensionSources, where the subscriber adds Equipment; the standard sources (bill-to customer, salesperson, responsibility center, contract template, service order type) stay in the list. No effect when Change Status is not Open. [1]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Service Contract Header" | `OnAfterInitDefaultDimensionSources(var ServiceContractHeader, var DefaultDimSource, FieldNo)` | Add Equipment as a default-dimension source of a standard service contract. | Pass FirstPos = (FieldNo = ServiceContractHeader.FieldNo("Equipment No.")) so the equipment goes first only when it is the field just changed · Rely on Default Dimension Priority rows, not list order, to settle conflicts with the contract's standard sources | [1] [8] |
| Table "Default Dimension" | `OnAfterUpdateGlobalDimCode(GlobalDimCodeNo, TableID, AccNo, NewDimValue)` | Keep Equipment (and a custom Maintenance Contract) Global Dimension 1/2 Code in sync with its Default Dimension rows. | Exit when TableID is not Database::Equipment (or the Maintenance Contract table) · Exit when the record cannot be found with Get(AccNo) · Update only Global Dimension 1 or 2 according to GlobalDimCodeNo | [2] |

## 5. Setup, permissions and lifecycle

- **setup**: Create a source code for maintenance orders (the good sample uses 'MAINT') and pass it to GetRecDefaultDimID; ask the requester for Default Dimension Priority rows for that source code that rank Customer, Item, Equipment and Maintenance Contract, because list order alone must not settle conflicts. Whether the app creates the source code and priority rows itself or documents them as user setup is an open question. [1]
- **setup**: For service contracts, conflicts between Equipment and the contract's standard sources are settled by Default Dimension Priority rows for the source code the service contract passes; which source code that is and the wanted ranking are open questions. [1]
- **privacy**: Classify Maintenance Order Header at table level (CustomerContent) and give the Equipment No. field on the Service Contract Header extension an explicit DataClassification; leave no field at ToBeClassified. [10] [11]
- **permissions**: Add Maintenance Order Header tabledata and the new codeunits to a non-assignable building-block permission set, listed explicitly without wildcards, and include it in the app's role-shaped sets. [12] [13] [4]

## 6. Tests

1. **order-dimensions-merge-all-four-sources** [15] [16] [17] [18] [1]
    - Given A customer, an item, an equipment and a maintenance contract created with library codeunits, each with a default dimension on a different dimension, and a Maintenance Order with Customer No., Item No. and Equipment No. validated
    - When Contract No. is validated on the Maintenance Order
    - Then The order's Dimension Set ID contains all four default dimension values
2. **order-dimension-conflict-follows-priority** [15] [16] [17] [18] [1]
    - Given Customer and Equipment both have a default value for the same dimension, Default Dimension Priority rows for the maintenance source code rank Equipment above Customer, and an order with Equipment No. validated
    - When Customer No. is validated (so Customer is first in the list)
    - Then The dimension carries the Equipment value, not the Customer value
3. **order-replaced-equipment-drops-stale-dimension** [15] [16] [17] [18] [1] [3]
    - Given An order whose equipment E1 has a default value for dimension D, and equipment E2 with no default for D
    - When Equipment No. is changed from E1 to E2
    - Then Dimension D is no longer in the order's Dimension Set ID, while the customer, item and contract dimensions remain
4. **order-cleared-source-drops-its-dimension** [15] [16] [17] [18] [1] [3]
    - Given An order with all four sources whose contract has a default value for dimension D
    - When Contract No. is cleared
    - Then Dimension D is removed and the other three sources' dimensions remain
5. **order-shortcut-dimension-updates-set** [15] [16] [17] [18] [3]
    - Given An order with a Dimension Set ID built from its sources
    - When Shortcut Dimension 1 Code is validated with another value
    - Then The Dimension Set ID changes to a set containing the new value and the other dimensions unchanged
6. **order-extensibility-event-adds-source** [15] [16] [17] [18] [1] [5]
    - Given A manually bound test subscriber to Maintenance Order Header.OnAfterInitDefaultDimensionSources that adds an extra table as a source, and a record of that table with a default dimension
    - When Customer No. is validated on an order
    - Then The order's Dimension Set ID contains the extra source's default dimension
7. **equipment-global-dimension-saves-default-dimension** [15] [16] [17] [18] [2] [3]
    - Given An equipment record
    - When Global Dimension 1 Code is validated with a dimension value
    - Then A Default Dimension row exists for table Equipment, the equipment number and global dimension 1 with that value
8. **equipment-default-dimension-syncs-global-field** [15] [16] [17] [18] [2]
    - Given An equipment record without global dimension values
    - When A Default Dimension row for global dimension 1 is created for it as on the Default Dimensions page
    - Then Equipment."Global Dimension 1 Code" holds the new value
9. **equipment-rename-moves-default-dimensions** [15] [16] [17] [18] [2]
    - Given An equipment record with Default Dimension rows
    - When The equipment is renamed
    - Then The Default Dimension rows carry the new number and none remain under the old number
10. **equipment-delete-removes-default-dimensions** [15] [16] [17] [18] [2]
    - Given An equipment record with Default Dimension rows
    - When The equipment is deleted with Delete(true)
    - Then No Default Dimension rows remain for it
11. **service-contract-picks-up-equipment-dimensions** [15] [16] [17] [18] [1]
    - Given An open service contract for a customer with a default dimension, and an equipment with a default value on another dimension
    - When Equipment No. is validated on the service contract
    - Then The contract's Dimension Set ID contains both the customer's and the equipment's default dimension values
12. **service-contract-not-open-keeps-dimensions** [15] [16] [17] [18] [1]
    - Given A service contract whose Change Status is not Open, and an equipment with a default dimension
    - When Equipment No. is validated on the contract
    - Then The contract's Dimension Set ID is unchanged

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown: no repository or app.json was supplied
- The exact source code that Service Contract Header passes when building its dimensions is not stated in BCQuality knowledge
- The Maintenance Order document's own numbering, pages, setup and posting are outside this request and are not designed

## Sources

[1] `microsoft/knowledge/feature-design/plan-the-dimension-sources-of-a-custom-document.md`: Core mechanism: building the Maintenance Order's set from four sources, the publisher on the new table, the service contract subscriber, priorities and the tests for merge, conflict and stale values.
    - Add one AddDimSource per source (customer, item, equipment, contract) and build the set from the whole list with GetDefaultDimID/GetRecDefaultDimID
    - Each source field's OnValidate calls CreateDimFromDefaultDim(FieldNo); pass FieldNo = Rec.FieldNo(<field>) as FirstPos so the field just changed goes first
    - Pass a source code and use Default Dimension Priority rows to settle conflicts; never rely on list order alone
    - Publish OnAfterInitDefaultDimensionSources on your own table so other apps can add sources
    - To add a custom master to a standard service contract, subscribe to Service Contract Header.OnAfterInitDefaultDimensionSources and call AddDimSource, then call CreateDimFromDefaultDim from the field's OnValidate
    - Service Contract Header.CreateDim exits when Change Status is not Open
    - Recalculation replaces manual changes; decide whether to confirm as Sales Header does
    - Do not compute the set from only the validated field's source, and do not pass the current Dimension Set ID as InheritFromDimSetID
[2] `microsoft/knowledge/finance-extensions/give-a-new-master-table-default-dimensions.md`: Making Equipment (and a custom Maintenance Contract) own Default Dimension rows and keep global dimension fields in sync.
    - Add Global Dimension 1/2 Code with CaptionClass '1,1,1' and '1,1,2', validated through ValidateShortcutDimCode calling ValidateDimValueCode and SaveDefaultDim
    - Call UpdateDefaultDim in OnInsert, RenameDefaultDim in OnRename and DeleteDefaultDim in OnDelete
    - Subscribe to Default Dimension.OnAfterUpdateGlobalDimCode and update the record's global dimension field when its table ID matches
    - A custom document keeps Dimension Set ID and shortcut fields on the header and writes dimensions only as dimension sets, not as its own code fields
[3] `microsoft/knowledge/data-modeling/dimension-management-wiring.md`: Separating the master model (Default Dimension rows) from the document model (Dimension Set ID), the InheritFromDimSetID = 0 rule and shortcut-field validation on the order.
    - Master tables persist Default Dimension rows via ValidateDimValueCode and SaveDefaultDim (shortcut dimension number, not field ID) and carry no Dimension Set ID
    - Documents build sources with AddDimSource and call GetDefaultDimID with InheritFromDimSetID 0
    - Run the same recompute when the source key is blank or invalid; do not exit early and keep the previous record's dimensions
    - Validate document shortcut fields through ValidateShortcutDimValues so the same Dimension Set ID is updated
[4] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Map for the cross-cutting decisions of the new document: privacy, permissions and the questions about numbering, pages, setup and install.
    - A row the request does not settle is a question for the requester, not a default to assume
    - Ship permission sets for new tables and pages, composed from included sets and without wildcards
    - Classify at table level where possible and resolve every ToBeClassified
[5] `microsoft/knowledge/events/publish-thin-onbefore-onafter-integration-events.md`: Shape of the OnAfterInitDefaultDimensionSources publisher on Maintenance Order Header.
    - Declare the publisher [IntegrationEvent(false, false)] local procedure with an empty body; the calling routine owns the logic
    - Pass records by var and include the parameters a subscriber needs
[6] `microsoft/knowledge/events/declare-event-publishers-local-or-internal.md`: Access modifier of the new publisher.
    - Declare the publisher local when only the declaring object raises it; subscribers do not need it public
[7] `microsoft/knowledge/events/name-events-by-publisher-position.md`: Naming the new publisher by its position at the end of InitDefaultDimensionSources.
    - An event at the very end of a routine is named OnAfter<Name>
[8] `microsoft/knowledge/events/prefer-reusing-or-extending-existing-events.md`: Using the standard Service Contract Header event rather than a parallel mechanism.
    - When the data you need is already exposed at an existing event, subscribe to it rather than adding a new one
[9] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing Equipment No. and the other relation fields.
    - A field with an unconditional TableRelation must have the exact type and length of the related field; read the related key's declared length rather than assuming Code[20]
[10] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification of the new table and of the tableextension field.
    - A table-level DataClassification is the default for the table's own Normal fields
    - A tableextension inherits nothing; every Normal field it adds needs an explicit DataClassification
[11] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of the new fields.
    - No field may ship with DataClassification = ToBeClassified
[12] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Structure of the permission set for the new objects.
    - Use small building-block sets marked Assignable = false and include them in role-shaped sets through IncludedPermissionSets
[13] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Content of the permission set.
    - Enumerate each tabledata and table entry explicitly; no * grants
    - Grant only the letters each role needs
[14] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltip for Equipment No. on the service contract card.
    - Applies from runtime 13.0 (BC24): define the tooltip on the table field and let the page inherit it; before that, set it on the page control
    - Describe what the value is used for or affects; do not invent effects
[15] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for customers, items, service contracts and dimensions in every test.
    - Create prerequisite records with the Library codeunits, parents first, and Validate foreign-key fields
[16] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunits.
    - [FEATURE] on the codeunit, [SCENARIO] first in each test, [GIVEN]/[WHEN]/[THEN] marking the parts
[17] `microsoft/knowledge/testing/test-one-when-per-test.md`: Shape of each test scenario.
    - Exactly one [WHEN] per test; preconditions belong in [GIVEN]
[18] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Test data choices.
    - Create the records the test needs instead of relying on existing ones; keep values that define the scenario, such as which dimension conflicts, explicit

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
