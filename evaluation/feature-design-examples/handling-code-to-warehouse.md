# Feature design

> Sales order lines need a Handling Code chosen by the order taker, for example fragile or refrigerated. Warehouse staff must see it on the warehouse shipment lines and on posted warehouse shipments, and the code must be stored on the warehouse entries so we can analyse handling by bin.

**Result:** Complete design. **Business process:** Sales order fulfilment through warehouse shipment posting at bin locations (sales posting and warehouse handling). **Knowledge used:** 21 BCQuality articles.

**Why:** Every stage the request names (sales order line, warehouse shipment line, posted warehouse shipment line, warehouse entry) is reached by a confirmed hop; open questions remain for the requester.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Should handling codes be a user-maintained list (a Handling Code table, as designed) or a fixed set defined in code (an enum)? Should the app ship default codes such as FRAGILE and REFRIGERATED? _(affects: handling-code-table, handling-codes-page, sales-line-ext, handling-code-permissions)_
2. Which object ID range and field number should the app use? The same field number must be used on every table in the path. _(affects: sales-line-ext, whse-shipment-line-ext, posted-whse-shipment-line-ext, item-journal-line-ext, whse-journal-line-ext, warehouse-entry-ext, posted-sales-lines-mirror)_
3. Do the locations involved require picks (or use directed put-away and pick)? Warehouse entries created when registering picks are built from warehouse journal lines in other code; if handling by storage bin must include pick entries, that path must be confirmed in the target version and designed separately. _(affects: warehouse-entry-ext, handling-code-posting-subscribers)_
4. Is a stored Handling Code column on Warehouse Entry acceptable for the by-bin analysis, or should it live in a related table keyed by Entry No. to avoid the companion-table cost on posting? _(affects: warehouse-entry-ext)_
5. Should the code also be kept on posted sales shipment, invoice, credit memo and return receipt lines and on the sales line archive (designed because standard TransferFields would otherwise drop it), or can any of these be excluded? Should it be shown on those pages? _(affects: posted-sales-lines-mirror)_
6. Should the code also be stored on Item Ledger Entry? It is currently only carried on the item journal line to reach the warehouse journal line. _(affects: item-journal-line-ext)_
7. Is the code needed only for sales orders, or also for other outbound sources such as purchase return orders and transfer orders, which create warehouse shipment lines through their own events? _(affects: whse-shipment-line-ext, handling-code-posting-subscribers)_
8. If the order taker changes the code after the warehouse shipment line exists, must the change reach the open shipment line? The designed copy runs only when the shipment line is created. _(affects: whse-shipment-line-ext, handling-code-posting-subscribers)_
9. Must existing open sales orders, warehouse shipments or historical warehouse entries be backfilled, or does the code apply only to new orders? _(affects: sales-line-ext, warehouse-entry-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Handling Code | Supplemental table holding the handling codes the order taker chooses from (for example FRAGILE, REFRIGERATED). Supplemental type: primary key Code[10] named Code, plus a description; table-level DataClassification. Whether a lookup table or a fixed enum is wanted is an open question. | Code (Code[10]): Primary key.; Description (Text[100]): Length rests on judgment. | [8] [15] [11] |
| 2 | create | page | Handling Codes | List page for the Handling Code table, plural name matching the source table, set as the table's LookupPageID. Field tooltips defined on the table fields. |  | [8] [18] [16] |
| 3 | extend | tableextension | Sales Line | Source field entered by the order taker. Unconditional TableRelation to "Handling Code".Code, so the field has the exact type and length Code[10]. Explicit DataClassification (a table extension inherits none). Table-field ToolTip. | Handling Code (Code[10]): TableRelation = "Handling Code".Code; DataClassification = CustomerContent; ToolTip on the table field. | [1] [9] [11] [12] [16] |
| 4 | extend | pageextension | Sales Order Subform | Shows the editable Handling Code on sales order lines for the order taker; inherits the table-field tooltip on runtime 13.0 or later. |  | [1] [16] [17] |
| 5 | extend | tableextension | Warehouse Shipment Line | Carries the code onto warehouse shipment lines, filled by subscriber when the line is created from the sales line. Same field number as Sales Line so the next hop can copy it by TransferFields. | Handling Code (Code[10]): Same field number, name, type and length as on Sales Line (number to be chosen from the app's ID range). DataClassification = CustomerContent. | [2] [7] [11] |
| 6 | extend | pageextension | Whse. Shipment Subform | Shows the Handling Code to warehouse staff on warehouse shipment lines (confirm the subform page name in the target version's symbols). |  | [16] [17] |
| 7 | extend | tableextension | Posted Whse. Shipment Line | Posted warehouse shipment line is filled by TransferFields from Warehouse Shipment Line, so the mirrored field with the same number, name, type and length needs no subscriber. Non-editable. The code is line-level, so Posted Whse. Shipment Header (filled field by field) is not extended. | Handling Code (Code[10]): Same field number, name, type and length as on Sales Line (number to be chosen from the app's ID range). Editable = false; DataClassification = CustomerContent. | [3] [7] [11] |
| 8 | extend | pageextension | Posted Whse. Shipment Subform | Shows the Handling Code to warehouse staff on posted warehouse shipment lines (confirm the subform page name in the target version's symbols). |  | [16] [17] |
| 9 | extend | tableextension | Item Journal Line | Intermediate carrier: document posting builds the warehouse journal line from the item journal line, so the value must be on the item journal line first. Item Ledger Entry itself is not extended unless the requester asks (open question). | Handling Code (Code[10]): DataClassification = CustomerContent. | [4] [5] [11] |
| 10 | extend | tableextension | Warehouse Journal Line | Intermediate carrier from which Whse. Jnl.-Register Line creates the warehouse entry. | Handling Code (Code[10]): DataClassification = CustomerContent. | [4] [11] |
| 11 | extend | tableextension | Warehouse Entry | Stored, non-editable field so the code can be filtered and analysed by bin as the request requires. The hot-ledger article prefers a related table for optional attributes and allows a stored field only when the value must appear as a native list column and is read on almost every access (applies from BC23); the request asks for the code to be stored on the entries for by-bin analysis, so a stored field is chosen and the trade-off is raised as an open question. | Handling Code (Code[10]): Editable = false; DataClassification = CustomerContent. | [4] [10] [11] |
| 12 | extend | pageextension | Warehouse Entries | Shows the Handling Code as a list column next to Bin Code for analysis by bin. |  | [16] [17] |
| 13 | extend | tableextension | Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line, Sales Line Archive | Chosen by article, not by the request: posted sales lines and the line archive are filled by TransferFields from Sales Line, so the field is mirrored with the same number, name, type and length on each (one table extension per table), non-editable on posted tables. The requester may exclude any of these (open question). | Handling Code (Code[10]): Same field number, name, type and length as on Sales Line (number to be chosen from the app's ID range). Editable = false; DataClassification = CustomerContent. | [6] [1] [7] [11] |
| 14 | create | codeunit | Handling Code Whse. Posting | Event subscriber codeunit holding the four copy subscribers listed under subscriptions. Assign only; no Modify. |  | [2] [5] [4] |
| 15 | create | permissionset | Handling Code (non-assignable building block) and role-shaped assignable set(s) | Explicit grants for the new table, list page and subscriber codeunit, no wildcards: RIMD on tabledata Handling Code for whoever maintains the codes, R for order takers and warehouse staff. Non-assignable building block included in assignable role sets. |  | [15] [13] [14] |

## 3. How the data flows

- **User (order taker)** → **Sales Line.Handling Code**: entered by the user. Validated against the Handling Code table relation on the sales order subform. [1] [9]
- **Sales Line.Handling Code** → **Warehouse Shipment Line.Handling Code**: copied in an event subscriber. OnBeforeCreateShptLineFromSalesLine on Sales Warehouse Mgt., before the line is inserted. [2]
- **Warehouse Shipment Line.Handling Code** → **Posted Whse. Shipment Line.Handling Code**: standard TransferFields copy. Whse.-Post Shipment creates the posted line with TransferFields; same field number required. [3] [7]
- **Sales Line.Handling Code** → **Item Journal Line.Handling Code**: copied in an event subscriber. OnAfterCopyItemJnlLineFromSalesLine on Item Journal Line, raised when posting the warehouse shipment posts the sales line. [5] [4]
- **Item Journal Line.Handling Code** → **Warehouse Journal Line.Handling Code**: copied in an event subscriber. OnAfterCreateWhseJnlLine on WMS Management, during document posting at a location that uses bins. Item-tracking splits copy the whole record. [4]
- **Warehouse Journal Line.Handling Code** → **Warehouse Entry.Handling Code**: copied in an event subscriber. OnBeforeInsertWhseEntry on Whse. Jnl.-Register Line; covers every path that creates warehouse entries, but only paths that put the value on the warehouse journal line carry it. [4]
- **Sales Line.Handling Code** → **Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line, Sales Line Archive**: standard TransferFields copy. InitFromSalesLine and archiving use TransferFields; no subscriber. [6] [1]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Sales Warehouse Mgt." | `OnBeforeCreateShptLineFromSalesLine` | Copy Sales Line.Handling Code to the warehouse shipment line before insert. | Assign the field only; do not call Modify (the record is inserted after the event). · Confirm the event signature in the target version's symbols. | [2] |
| Table "Item Journal Line" | `OnAfterCopyItemJnlLineFromSalesLine` | Copy Sales Line.Handling Code to the item journal line built during sales posting. | Assign the field only; do not call Modify (the record is inserted after the event). | [5] |
| Codeunit "WMS Management" | `OnAfterCreateWhseJnlLine` | Copy Item Journal Line.Handling Code to the warehouse journal line. | Assign the field only; do not call Modify (the record is inserted after the event). | [4] |
| Codeunit "Whse. Jnl.-Register Line" | `OnBeforeInsertWhseEntry` | Copy Warehouse Journal Line.Handling Code to the new warehouse entry. | Assign the field only; do not call Modify (the record is inserted after the event). · Never patch warehouse entries after posting. | [4] |

## 5. Setup, permissions and lifecycle

- **permissions**: Ship a non-assignable building-block permission set for the Handling Code table, Handling Codes page and subscriber codeunit, with explicit least-privilege grants and no wildcards, and include it in assignable role sets for code maintainers, order takers and warehouse staff. [15] [13] [14]
- **privacy**: Give every field added by a table extension an explicit DataClassification; use a table-level classification on the new Handling Code table; no ToBeClassified left at release. [11] [12]
- **setup**: Users maintain handling codes on the Handling Codes list page before order takers can choose them; whether the app ships default codes (for example FRAGILE, REFRIGERATED) is an open question, so no install code is designed. agent judgment

## 6. Tests

1. **code-reaches-warehouse-shipment-line** [2] [19] [20]
    - Given A handling code, an item, a customer and a location that requires shipment, created with the library codeunits; a released sales order whose line has the handling code.
    - When A warehouse shipment is created from the sales order.
    - Then The warehouse shipment line has the sales line's handling code.
2. **code-reaches-posted-whse-shipment-line** [3] [19] [20]
    - Given A warehouse shipment created from a sales order line with a handling code.
    - When The warehouse shipment is posted (ship).
    - Then The posted warehouse shipment line has the same handling code.
3. **code-reaches-warehouse-entries-by-bin** [4] [5] [19] [20]
    - Given A location that requires shipment and uses bins, inventory in a bin, and a released sales order line with a handling code; a warehouse shipment created from it.
    - When The warehouse shipment is posted (ship).
    - Then Every warehouse entry created for the sales line carries the handling code, together with its bin code, including when the line is split by item tracking.
4. **other-paths-leave-entry-blank** [4] [5] [20]
    - Given A bin location with inventory and no sales document.
    - When A warehouse or item journal adjustment that does not come from a sales line is posted or registered.
    - Then The created warehouse entries have a blank handling code and posting succeeds.
5. **code-mirrored-on-posted-sales-lines** [6] [19] [20]
    - Given A sales order line with a handling code.
    - When The order is shipped and invoiced, and archived.
    - Then The Sales Shipment Line, Sales Invoice Line and Sales Line Archive carry the same handling code.
6. **unknown-handling-code-rejected** [9] [19] [20]
    - Given A sales order line and a code that does not exist in Handling Code.
    - When The code is validated into Sales Line.Handling Code.
    - Then Validation fails with the table-relation error.
7. **order-taker-role-can-choose-code** [21] [13] [20]
    - Given A test user lowered with Permissions Mock or Library - Lower Permissions to the order-taker role that includes the Handling Code building block.
    - When The user sets a handling code on a sales order line.
    - Then The value is saved; a user without the role cannot insert handling codes.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version is unknown (no repository or app.json supplied): prefer-related-table-over-extension-on-hot-ledgers applies from BC23 and bound-page-field-inherits-source-field-tooltip from BC24; tooltip placement depends on the target runtime.
- countries and application-area are unknown; all cited articles are w1 / all and therefore apply.
- Warehouse entries created by registering picks or other warehouse activities are not designed: the request does not state whether picks are used, and the path that builds those warehouse journal lines is not confirmed by BCQuality knowledge.
- Handling Code table fields beyond the primary key (Description length) and the setup concern of maintaining codes rest on the agent's judgment, not on BCQuality knowledge.
- Page object names Sales Order Subform, Whse. Shipment Subform, Posted Whse. Shipment Subform and Warehouse Entries are not confirmed by BCQuality knowledge; confirm them in the target version's symbols.

## Sources

[1] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Overall path of the Sales Line field through posting, page extensions, permissions and the read-back test.
    - Decide which stages the field must reach and plan one step per stage before writing code.
    - For each stage name the page extensions that show the field, permission set entries for new objects, and a test that posts and reads the value back from every target.
    - Do not plan only the tables the requester named; do not fill ledger entries after posting by finding and modifying them.
[2] `microsoft/knowledge/warehouse/carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.md`: Sales Line to Warehouse Shipment Line hop.
    - Add the field to the warehouse line with the same number and type as on the source line.
    - Copy it in OnBeforeCreateShptLineFromSalesLine on Sales Warehouse Mgt., which runs just before the insert.
    - Plan one subscriber per source type and confirm each event in the target version's symbols.
    - Do not copy in OnAfterCreateShptLineFromSalesLine with Modify, and do not re-read the source line in OnBeforeWhseShptLineInsert.
[3] `microsoft/knowledge/warehouse/carry-warehouse-document-fields-to-posted-warehouse-documents.md`: Warehouse Shipment Line to Posted Whse. Shipment Line hop; decision not to extend the posted shipment header.
    - Posted Whse. Shipment Line is filled by TransferFields: give the field the same number, name, type and length; no subscriber needed.
    - Posted Whse. Shipment Header is filled field by field and would need OnBeforePostedWhseShptHeaderInsert; it is not used because the code is line-level.
    - Do not patch posted warehouse documents with Modify after posting.
[4] `microsoft/knowledge/warehouse/carry-fields-to-warehouse-entries-through-the-warehouse-journal-line.md`: Item Journal Line to Warehouse Journal Line to Warehouse Entry hops.
    - Add the field to Warehouse Journal Line and Warehouse Entry and copy it in OnBeforeInsertWhseEntry on Whse. Jnl.-Register Line.
    - For document posting, put the value on the item journal line first, then copy it to the warehouse journal line in OnAfterCreateWhseJnlLine on WMS Management.
    - For any other path, such as registering a pick, confirm in the target version where its warehouse journal line is built; do not assume it passes through CreateWhseJnlLine.
    - Do not modify warehouse entries after posting, and do not expect the value on the warehouse shipment line to reach warehouse entries.
[5] `microsoft/knowledge/sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md`: Sales Line to Item Journal Line hop that feeds the warehouse journal line.
    - Copy the value from the sales line to the item journal line in OnAfterCopyItemJnlLineFromSalesLine on Item Journal Line.
    - Journal lines from other paths leave the field empty, so the entry stays empty; no source-document filter is needed.
    - Value entries, warehouse entries and other inventory records are separate stages; extend them only when the plan names them.
    - Do not find and modify ledger entries after posting.
[6] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring the line field on posted sales lines and the line archive.
    - Give the field the same number, name, type and length on every TransferFields target the plan needs, unless the plan states a document type never needs it.
    - No subscriber is needed for these stages; keep the mirrored fields non-editable on posted tables.
    - Do not use a different field number and patch with an OnAfter...Insert subscriber and Modify.
[7] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definitions on every TransferFields-linked table.
    - Define a mirrored field with the exact same field number, data type and length on every table in the cascade, at creation time.
[8] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Shape of the new Handling Code table and its page.
    - Identify the table type first: a Supplemental table has primary key Code[10] named Code and one List page with a plural name set as LookupPageID.
[9] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Length of the Handling Code field on Sales Line and its relation.
    - With an unconditional TableRelation, give the field the same type and exact length as the related field (Code[10]); read the related field's declared length before adding the relation.
[10] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choice between a stored Warehouse Entry field and a related table (applies from BC23; target version unknown).
    - Put optional, sparse or integration attributes in a related table keyed by the ledger entry number.
    - Use a stored table extension field only when the value must appear as a native list column and is read on almost every access.
[11] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: DataClassification on every new field.
    - Every Normal field added by a table extension must declare its own DataClassification; table extensions inherit nothing.
    - Use a table-level classification on the new table when it describes its fields.
[12] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of classifications.
    - Resolve every ToBeClassified to a real classification before release, decided from the data's content.
[13] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Permission set structure.
    - Use small non-assignable building blocks and assignable role-shaped sets that include them through IncludedPermissionSets.
[14] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Permission grants.
    - Enumerate each tabledata and table entry explicitly with only the letters required; no wildcard grants.
[15] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Decisions for the new Handling Code table: classification, pages, permissions, tests.
    - Plan table type, privacy, pages, permissions and tests for a new kind of record; a decision the request does not settle is a question for the requester, not a default.
    - Do not design only the table and its page.
[16] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips on the new page and page extensions.
    - On runtime 13.0 or later, define shared tooltip text on the table field and omit duplicate page-level tooltips; before that, add page-level tooltips.
    - Tooltip text must say what the value is used for, without inventing behavior.
[17] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Tooltip inheritance on page extensions (applies from BC24; target version unknown).
    - A bound page field inherits the source table field's ToolTip on runtime 13.0 or later; add a page-level override only when different help is needed.
[18] `microsoft/knowledge/style/page-name-must-match-source-table.md`: Name of the Handling Codes list page.
    - The page name must describe its source table.
[19] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build customers, items, sales documents and random values with the library codeunits, creating parents before dependents and validating foreign-key fields.
[20] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Test codeunit structure.
    - Tag the test codeunit with [FEATURE] and each test with [SCENARIO], [GIVEN], [WHEN] and [THEN] comments.
[21] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: Permission test for the order-taker role.
    - Use TestPermissions Restrictive and lower the test user with Permissions Mock or Library - Lower Permissions before the protected operation.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
