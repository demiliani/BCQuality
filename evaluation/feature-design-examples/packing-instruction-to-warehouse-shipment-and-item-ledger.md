# Feature design

> Sales order lines get a Packing Instruction code chosen by the order taker. Warehouse workers must see it on the warehouse shipment lines and on posted warehouse shipment lines, and quality wants it on the item ledger entries after the shipment is posted.

**Result:** Complete design. **Business process:** Carry a user-chosen packing instruction from sales order lines through warehouse shipment handling (Sales Warehouse Mgt., Whse.-Post Shipment) and sales posting into item ledger entries. **Knowledge used:** 23 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Should the Packing Instruction Code also be kept on posted sales shipment, invoice, credit memo and return receipt lines and on sales line archives? The mirroring article designs them by default; answer no to drop them. _(affects: sales-shipment-line-ext, sales-invoice-line-ext, sales-cr-memo-line-ext, return-receipt-line-ext, sales-line-archive-ext, archive-keeps-code)_
2. When a user copies a sales document with Recalculate Lines on (always for posted shipments), must the Packing Instruction Code survive the copy (a subscriber to OnAfterRecalculateSalesLine) or be chosen again? _(affects: sales-line-ext, event-subscribers-codeunit)_
3. How does quality use the value on item ledger entries: as a column they filter and sort on the Item Ledger Entries list (stored field, as designed) or only occasionally per entry (a related table keyed by Entry No. shown in a FactBox)? _(affects: item-ledger-entry-ext, item-ledger-entries-page-ext)_
4. Do warehouse workers also need the code on warehouse picks, inventory picks, value entries or warehouse entries? These are separate stages and are not designed. _(affects: whse-shipment-line-ext, event-subscribers-codeunit)_
5. If the order taker changes the Packing Instruction Code on a sales line after the warehouse shipment exists, must the warehouse shipment line follow the change, or is the value at creation final? _(affects: whse-shipment-line-ext, event-subscribers-codeunit)_
6. Is the code mandatory before release or shipment, and on which sales document types (quotes, blanket orders, invoices, return orders) may users enter it besides orders? _(affects: sales-line-ext, sales-order-subform-ext)_
7. Must existing open sales lines, warehouse shipment lines or posted item ledger entries receive a value, or do they stay blank? _(affects: item-ledger-entry-ext)_
8. Which Business Central version does the app target? It decides whether tooltips can be defined once on the table fields (runtime 13.0 / BC24 or later). _(affects: packing-instructions-page, sales-order-subform-ext, whse-shipment-subform-ext, posted-whse-shipment-subform-ext, item-ledger-entries-page-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Packing Instruction | Supplemental table holding the packing instruction codes order takers choose from. Primary key Code[10] named Code; plural list page set as LookupPageID and DrillDownPageID; table-level DataClassification = CustomerContent; delete and insert through triggers like any reference data. | Code (Code[10]): Primary key; NotBlank.; Description (Text[100]): Shown in the lookup next to the code. | [2] [9] [16] |
| 2 | create | page | Packing Instructions | List page over Packing Instruction, named after its source table, used as the table's LookupPageID; tooltips defined on the table fields (inherited from runtime 13.0) or on the page for older targets. |  | [2] [9] [19] [18] |
| 3 | extend | tableextension | Sales Line | Source of the value: the order taker chooses the packing instruction on the sales line. TableRelation to Packing Instruction with the exact length of its Code key. | Packing Instruction Code (Code[10]): TableRelation = "Packing Instruction"; length exactly Code[10] to match Packing Instruction.Code; DataClassification = CustomerContent explicitly (table extensions inherit no classification); ToolTip on the field. | [3] [10] [16] |
| 4 | extend | pageextension | Sales Order Subform | Lets the order taker enter the Packing Instruction Code on sales order lines. |  | [3] [18] |
| 5 | extend | tableextension | Warehouse Shipment Line | Carries the value to warehouse shipment lines; filled by the OnBeforeCreateShptLineFromSalesLine subscriber before insert. Same field number as on Sales Line so the next hop to the posted line works by TransferFields. | Packing Instruction Code (Code[10]): Same field number, type and length as on Sales Line; DataClassification = CustomerContent explicitly. | [6] [11] [16] |
| 6 | extend | pageextension | Whse. Shipment Subform | Shows the Packing Instruction Code to warehouse workers on warehouse shipment lines. |  | [3] [18] |
| 7 | extend | tableextension | Posted Whse. Shipment Line | Posted warehouse shipment line, filled by the standard TransferFields from Warehouse Shipment Line in Whse.-Post Shipment; no subscriber. | Packing Instruction Code (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent set explicitly on the field; Editable = false. | [7] [11] [16] |
| 8 | extend | pageextension | Posted Whse. Shipment Subform | Shows the Packing Instruction Code on posted warehouse shipment lines. |  | [3] [18] |
| 9 | extend | tableextension | Item Journal Line | Intermediate carrier between Sales Line and Item Ledger Entry during sales posting; filled in OnAfterCopyItemJnlLineFromSalesLine. | Packing Instruction Code (Code[10]): DataClassification = CustomerContent explicitly. | [5] [16] |
| 10 | extend | tableextension | Item Ledger Entry | Stored field on the item ledger entry, written as part of posting in OnAfterInitItemLedgEntry. Chosen as a stored field over a related table keyed by Entry No. because quality must see it on the item ledger entries, which the articles allow only when users must see or filter it as a native list column; see the open question on how quality uses it. | Packing Instruction Code (Code[10]): DataClassification = CustomerContent explicitly; Editable = false; never modified after posting. | [5] [12] [13] [16] |
| 11 | extend | pageextension | Item Ledger Entries | Shows the Packing Instruction Code as a column for quality. |  | [5] [12] [18] |
| 12 | extend | tableextension | Sales Shipment Line | Mirror on Sales Shipment Line, a TransferFields target of Sales Line chosen by the mirroring article (pending the open question); filled by InitFromSalesLine with no subscriber. Keeping the field also lets Copy Document from posted lines carry it. | Packing Instruction Code (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent set explicitly on the field; Editable = false. | [4] [3] [11] [14] |
| 13 | extend | tableextension | Sales Invoice Line | Mirror on Sales Invoice Line, a TransferFields target of Sales Line chosen by the mirroring article (pending the open question); filled by InitFromSalesLine with no subscriber. Keeping the field also lets Copy Document from posted lines carry it. | Packing Instruction Code (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent set explicitly on the field; Editable = false. | [4] [3] [11] [14] |
| 14 | extend | tableextension | Sales Cr.Memo Line | Mirror on Sales Cr.Memo Line, a TransferFields target of Sales Line chosen by the mirroring article (pending the open question); filled by InitFromSalesLine with no subscriber. Keeping the field also lets Copy Document from posted lines carry it. | Packing Instruction Code (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent set explicitly on the field; Editable = false. | [4] [3] [11] [14] |
| 15 | extend | tableextension | Return Receipt Line | Mirror on Return Receipt Line, a TransferFields target of Sales Line chosen by the mirroring article (pending the open question); filled by InitFromSalesLine with no subscriber. Keeping the field also lets Copy Document from posted lines carry it. | Packing Instruction Code (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent set explicitly on the field; Editable = false. | [4] [3] [11] [14] |
| 16 | extend | tableextension | Sales Line Archive | Mirror on the archive line table chosen by the article (pending the open question); archiving and restore copy it with TransferFields. No restore subscriber is needed because the field is not defaulted from master data. | Packing Instruction Code (Code[10]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent set explicitly on the field; Editable = false. | [4] [15] [11] |
| 17 | create | codeunit | Packing Instruction Events | Holds the three subscribers that carry the value from Sales Line to Warehouse Shipment Line and from Sales Line through Item Journal Line to Item Ledger Entry; assigns only, never calls Modify. |  | [6] [5] |
| 18 | create | permissionset | Packing Instr. Objects | Non-assignable building block granting the new table data (RIMD for maintainers, R for readers), the Packing Instructions page and the subscriber codeunit, enumerated without wildcards; included through IncludedPermissionSets in role-shaped assignable sets (for example an order-taker/reader set and an administrator set). |  | [2] [20] [21] |

## 3. How the data flows

- **Packing Instruction.Code** → **Sales Line.Packing Instruction Code**: entered by the user. Order taker picks the code through the TableRelation lookup. [10] [9]
- **Sales Line** → **Warehouse Shipment Line**: copied in an event subscriber. OnBeforeCreateShptLineFromSalesLine on Sales Warehouse Mgt. when a warehouse shipment is created from a released sales order, before the line is inserted. [6]
- **Warehouse Shipment Line** → **Posted Whse. Shipment Line**: standard TransferFields copy. Whse.-Post Shipment copies the line with TransferFields; same field number on both tables. [7] [11]
- **Sales Line** → **Item Journal Line**: copied in an event subscriber. OnAfterCopyItemJnlLineFromSalesLine on Item Journal Line when Sales-Post ships the line, whether posting starts from the warehouse shipment, an inventory pick or the sales order. [5] [8]
- **Item Journal Line** → **Item Ledger Entry**: copied in an event subscriber. OnAfterInitItemLedgEntry on Item Jnl.-Post Line, before the entry is inserted, so the value is written as part of posting. [5] [13]
- **Sales Line** → **Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line**: standard TransferFields copy. InitFromSalesLine; same field number on each target (pending the open question on posted lines and archives). [4] [11]
- **Sales Line** → **Sales Line Archive**: standard TransferFields copy. Archiving copies the line with TransferFields; restore copies it back the same way. [4] [15]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Sales Warehouse Mgt. | `OnBeforeCreateShptLineFromSalesLine` | Copy Packing Instruction Code from the Sales Line to the Warehouse Shipment Line passed by var, before insert. | Assign only; no Modify (the line is inserted after the event). · Do not use OnAfterCreateShptLineFromSalesLine or OnBeforeWhseShptLineInsert. | [6] |
| Item Journal Line | `OnAfterCopyItemJnlLineFromSalesLine` | Copy Packing Instruction Code from the Sales Line to the Item Journal Line during sales posting. | Assign only; no Modify. | [5] |
| Item Jnl.-Post Line | `OnAfterInitItemLedgEntry` | Copy Packing Instruction Code from the Item Journal Line to the new Item Ledger Entry before it is inserted. | No filter on the source document: other item postings leave the journal field empty, so their entries stay empty. · Never find and modify item ledger entries after posting. | [5] [13] |

## 5. Setup, permissions and lifecycle

- **permissions**: Ship the non-assignable Packing Instr. Objects building block and include it in role-shaped assignable permission sets; no wildcard entries. [2] [20] [21]
- **privacy**: Table-level DataClassification = CustomerContent on Packing Instruction; explicit DataClassification = CustomerContent on every field added by a table extension; no ToBeClassified left at release. [16] [17]
- **upgrade**: No upgrade code: the new fields have no InitValue and empty is a valid state, so existing open lines and posted history stay blank (see the open question on back-fill). [22]
- **setup**: Users maintain packing instruction codes on the Packing Instructions list before order takers can choose them; no setup table or number series is needed for a Supplemental table. [9] [2]

## 6. Tests

1. **sales-line-accepts-only-existing-code** [23] [10]
    - Given A Packing Instruction record created in the test and a sales order line built with LibrarySales for an item from LibraryInventory
    - When Packing Instruction Code is validated with the existing code, then with a code that does not exist
    - Then The existing code is stored; the non-existing code raises the TableRelation error
2. **whse-shipment-line-gets-code** [6] [23]
    - Given A released sales order at a location that requires shipment, whose line has a Packing Instruction Code
    - When A warehouse shipment is created from the sales order
    - Then The Warehouse Shipment Line for that sales line carries the same Packing Instruction Code
3. **posted-whse-shipment-line-gets-code** [7] [23]
    - Given The warehouse shipment from the previous scenario
    - When The warehouse shipment is posted (ship)
    - Then The Posted Whse. Shipment Line carries the Packing Instruction Code
4. **item-ledger-entry-gets-code-from-whse-shipment** [5] [23]
    - Given A sales order line with a Packing Instruction Code shipped through a warehouse shipment
    - When The warehouse shipment is posted
    - Then The Item Ledger Entry of the shipment carries the Packing Instruction Code, written at insert
5. **item-ledger-entry-gets-code-from-sales-posting** [5] [4] [23]
    - Given A sales order line with a Packing Instruction Code at a location without warehouse shipments
    - When The sales order is posted (ship and invoice)
    - Then The Item Ledger Entry carries the Packing Instruction Code, and Sales Shipment Line and Sales Invoice Line carry it too
6. **item-journal-posting-leaves-code-empty** [5] [23]
    - Given An item journal line created with LibraryInventory, with no packing instruction
    - When The item journal is posted
    - Then The resulting Item Ledger Entry has an empty Packing Instruction Code and posting succeeds (guard: no source-document filter)
7. **archive-keeps-code** [4] [15] [23]
    - Given A sales order line with a Packing Instruction Code
    - When The sales order is archived
    - Then The Sales Line Archive record carries the Packing Instruction Code

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown; tooltip placement depends on runtime 13.0 (BC24).
- Keeping an existing warehouse shipment line in sync when the sales line value changes later is not covered by BCQuality knowledge; if required, it rests on the agent's judgment.
- The page names Sales Order Subform, Whse. Shipment Subform, Posted Whse. Shipment Subform and Item Ledger Entries are not named by an opened article; confirm them in the target version's symbols.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Process map: chose the Sales whole-path and item ledger rows, the Warehouse receipts/shipments and posted documents rows, and the cross-cutting rows (mirrored definitions, copy document, archive, posted entries, upgrade, privacy, tests).
    - A field reaches only the stages the plan names; plan one row group per process the request touches.
    - Fill posted entries during posting, never by modifying them afterwards.
    - Whether a field should reach a stage the request does not name is a question for the requester, one question per group of stages.
    - Tests post through each chosen entry point and read the value back from every target.
[2] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Decisions for the new Packing Instruction reference table: table type, data rules, privacy, pages, permissions, tests.
    - Every new object needs permissions and every field a data classification.
    - Ship permission sets for new tables and pages, composed from included sets and without wildcards.
    - A row the request does not settle is a question for the requester, not a default.
[3] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Sales field path: posted lines and archive by TransferFields, item ledger through the item journal line, page extensions, permissions and read-back tests.
    - Decide which stages the field must reach and plan one step per stage.
    - Name the page extensions that show the field and a test that posts a document and reads the value back from every target.
    - Do not plan to fill ledger entries after posting by finding and modifying them.
[4] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring the line field on Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line and Sales Line Archive.
    - Same field number, name, type and length on the source and every target table the plan needs.
    - No subscriber for these stages; the standard TransferFields does the copy.
    - Keep mirrored fields non-editable on posted tables.
[5] `microsoft/knowledge/sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md`: Item ledger hop: Item Journal Line and Item Ledger Entry fields with two subscribers.
    - Add the field to Item Journal Line and Item Ledger Entry and subscribe to OnAfterCopyItemJnlLineFromSalesLine and OnAfterInitItemLedgEntry.
    - Store the field on the ledger entry only when users must see or filter it as a native list column or it is read on almost every access; otherwise prefer a related table keyed by entry number.
    - No source-document filter is needed; other postings leave the field empty.
    - Value entries, warehouse entries and other inventory records are separate stages, extended only when the plan names them.
    - Never find item ledger entries after posting and Modify them.
[6] `microsoft/knowledge/warehouse/carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.md`: Sales line to warehouse shipment line hop.
    - Add the field to the warehouse line with the same number and type as on the source line.
    - Copy it in OnBeforeCreateShptLineFromSalesLine on Sales Warehouse Mgt., before insert.
    - Do not copy in OnAfterCreateShptLineFromSalesLine with Modify, nor re-read the source line in OnBeforeWhseShptLineInsert.
    - Other source types (return orders, transfers) need their own subscriber; plan one per source type the feature needs.
[7] `microsoft/knowledge/warehouse/carry-warehouse-document-fields-to-posted-warehouse-documents.md`: Warehouse shipment line to posted warehouse shipment line hop.
    - Posted Whse. Shipment Line is filled with TransferFields from Warehouse Shipment Line; same number, name, type and length, no subscriber.
    - Posted Whse. Shipment Header is filled field by field and would need OnBeforePostedWhseShptHeaderInsert (not needed for a line field).
[8] `microsoft/knowledge/warehouse/inventory-picks-and-put-aways-post-through-the-source-document.md`: Confirms that inventory-pick posting reaches the item ledger through sales posting, so the same item ledger subscribers cover that entry point; frames the open question on inventory pick lines.
    - Treat the source line as the carrier of any value that must reach item ledger entries.
    - To show the value on an inventory pick, add it to Warehouse Activity Line and copy it in the creation event of each source the feature needs.
[9] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Classifying Packing Instruction as a Supplemental table.
    - Supplemental: primary key Code[10] named Code; one List page, plural name, set as LookupPageID.
[10] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing the Packing Instruction Code relation field.
    - For an unconditional relation, give the field the same type and exact length as the related field.
[11] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: All mirrored copies of the field across TransferFields targets.
    - Define the mirrored field with the exact same field number, data type and length on every table in the cascade, at creation time.
[12] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choosing a stored Item Ledger Entry field over a related table.
    - Put optional, sparse or integration attributes in a related table keyed by the ledger entry number.
    - Use a stored tableextension field only when the value must appear as a native list column and is read on almost every access.
[13] `microsoft/knowledge/scm/post-item-ledger-changes-through-item-journals.md`: Writing the value only within the owning sales/item posting workflow.
    - Supported posting events enrich journal/source data within the owning workflow.
    - No independent inserts or overwrites of item ledger entries outside posting.
[14] `microsoft/knowledge/sales-purchase/copy-document-recalculate-lines-drops-custom-line-fields.md`: Copy Document open question and mirroring on posted lines.
    - Decide per field whether it must survive a copy; if so, subscribe to OnAfterRecalculateSalesLine and assign without Modify.
    - Lines copied from posted documents or archives need the field with the same number on those tables.
[15] `microsoft/knowledge/sales-purchase/restore-archived-sales-document-revalidates-custom-fields.md`: Archive mirror and the decision that no restore subscriber is needed.
    - Mirror the field on Sales Line Archive with the same number.
    - Reassign in OnAfterTransferFromArchToSalesLine only when the field is also defaulted from master data.
[16] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification on the new table and on every table extension field.
    - A table-level classification covers fields of that table.
    - Every Normal field a tableextension adds must set its own DataClassification.
[17] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of the classification.
    - No field may ship with DataClassification = ToBeClassified.
[18] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips on the new and extended fields shown on pages.
    - From runtime 13.0 (BC24) define the tooltip on the table field and let bound page fields inherit it; before that, page-level tooltips are needed (applies from BC24; target version unknown).
    - Tooltip text answers what the value is used for, not just its name.
[19] `microsoft/knowledge/style/page-name-must-match-source-table.md`: Naming the Packing Instructions page.
    - The page name must describe the table it shows.
[20] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Permission set structure.
    - Building blocks are Assignable = false and are included in role-shaped assignable sets through IncludedPermissionSets.
[21] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Permission set entries.
    - Enumerate each tabledata and table entry explicitly; grant only the letters required.
[22] `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`: No upgrade code for the new fields.
    - Upgrade code is needed only when existing rows must carry a non-default value; optional fields where empty is valid need none.
[23] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build customers, items and sales documents with the Library codeunits, parents first, validating foreign keys.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

