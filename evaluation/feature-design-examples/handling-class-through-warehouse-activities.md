# Feature design

> Sales lines get a Handling Class. Warehouse staff must see it on picks created from warehouse shipments and on inventory picks at our basic-warehouse locations. It must stay on registered picks, posted inventory picks, warehouse entries and the item ledger entries of the shipment. Bin-to-bin internal movements also need a Move Reason that is kept on the registered inventory movement.

**Result:** Complete design. **Business process:** Outbound warehouse handling of sales orders (warehouse picks from shipments and inventory picks), sales shipment posting, and bin-to-bin internal movements. **Knowledge used:** 15 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Is Handling Class a fixed set of values (Enum) or a list users maintain (Code field with a TableRelation to a new Handling Class table)? What length if Code? _(affects: sales-line-ext, whse-shipment-line-ext, whse-activity-line-ext, registered-whse-activity-line-ext, posted-invt-pick-line-ext, whse-journal-line-ext, whse-entry-ext, item-journal-line-ext, item-ledger-entry-ext)_
2. Is Move Reason a fixed set of values (Enum) or a user-maintained code table? _(affects: internal-movement-line-ext, whse-activity-line-ext, registered-invt-movement-line-ext)_
3. Is Move Reason entered per internal movement line or once on the Internal Movement header? The confirmed creation event passes the line. _(affects: internal-movement-line-ext, move-reason-subscribers)_
4. Is Handling Class entered manually on each sales line, or defaulted from the item, customer or sales header? _(affects: sales-line-ext)_
5. May warehouse staff change Handling Class on a pick or inventory pick? If yes, must the change flow back to the sales line (and so to the item ledger) on inventory pick posting? _(affects: whse-activity-line-ext, handling-class-subscribers)_
6. If Handling Class changes on the sales line after the warehouse shipment, pick or inventory pick exists, must the existing warehouse documents be updated? _(affects: sales-line-ext, whse-shipment-line-ext, whse-activity-line-ext)_
7. Must Handling Class also reach posted sales shipment/invoice lines, sales line archives or posted warehouse shipment lines? These are not designed because the request does not name them. _(affects: sales-line-ext, whse-shipment-line-ext)_
8. Must users see or filter Handling Class as a native column on Item Ledger Entries? If not, a related table keyed by Entry No. is preferred over a stored field on this hot ledger. _(affects: item-ledger-entry-ext, item-ledger-entries-ext)_
9. Are movement-worksheet movements, pick-worksheet picks, internal picks, sales return orders or transfers in scope? Only internal movements, picks from warehouse shipments and inventory picks from sales lines are designed. _(affects: handling-class-subscribers, move-reason-subscribers)_
10. Must Move Reason also reach the warehouse entries written when an inventory movement is registered? _(affects: move-reason-subscribers)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Sales Line | Holds the Handling Class the user enters on the sales line. The sales line is the carrier for item ledger entries, because inventory pick posting and warehouse shipment posting both post through Sales-Post, which never reads the activity line. | Handling Class (Enum or Code with TableRelation (see open question handling-class-value-type)): Same field number, type and length on every table that carries Handling Class. Editable on the sales line. | [6] [4] [8] [13] [14] |
| 2 | extend | tableextension | Warehouse Shipment Line | Carries Handling Class from the sales line to the pick; the shipment line is built field by field, so a subscriber copies it. | Handling Class (Enum or Code with TableRelation (see open question handling-class-value-type)): Same field number, type and length on every table that carries Handling Class. Non-editable. | [2] [8] [14] |
| 3 | extend | tableextension | Warehouse Activity Line | Shows Handling Class on warehouse picks and inventory picks, and Move Reason on inventory movements created from internal movements. | Handling Class (Enum or Code with TableRelation (see open question handling-class-value-type)): Same field number, type and length on every table that carries Handling Class. Read-only for warehouse staff unless open question pick-editability decides otherwise.; Move Reason (Enum or Code with TableRelation (see open question move-reason-value-type)): Same field number, type and length on Warehouse Activity Line and Registered Invt. Movement Line. Filled from the internal movement line at creation. | [1] [4] [5] [8] [14] |
| 4 | extend | tableextension | Registered Whse. Activity Line | Keeps Handling Class on registered picks; Whse.-Activity-Register copies it by TransferFields, so no subscriber is needed. | Handling Class (Enum or Code with TableRelation (see open question handling-class-value-type)): Same field number, type and length on every table that carries Handling Class. Non-editable. | [1] [8] [14] |
| 5 | extend | tableextension | Posted Invt. Pick Line | Keeps Handling Class on posted inventory picks; Whse.-Activity-Post copies the activity line by TransferFields. | Handling Class (Enum or Code with TableRelation (see open question handling-class-value-type)): Same field number, type and length on every table that carries Handling Class. Non-editable. | [4] [8] [14] |
| 6 | extend | tableextension | Warehouse Journal Line | Intermediate carrier: every Warehouse Entry is built from a Warehouse Journal Line. | Handling Class (Enum or Code with TableRelation (see open question handling-class-value-type)): Same field number, type and length on every table that carries Handling Class. Filled by subscribers on registration, inventory pick posting and shipment posting. | [3] [1] [14] |
| 7 | extend | tableextension | Warehouse Entry | Keeps Handling Class on warehouse entries (written only at locations that use bins). | Handling Class (Enum or Code with TableRelation (see open question handling-class-value-type)): Same field number, type and length on every table that carries Handling Class. Non-editable; copied in OnBeforeInsertWhseEntry, not mirrored by TransferFields. | [3] [14] |
| 8 | extend | tableextension | Item Journal Line | Intermediate carrier from the sales line to the item ledger entry and, at bin locations during shipment posting, to the warehouse journal line. | Handling Class (Enum or Code with TableRelation (see open question handling-class-value-type)): Same field number, type and length on every table that carries Handling Class. | [7] [3] [14] |
| 9 | extend | tableextension | Item Ledger Entry | Keeps Handling Class on the item ledger entries of the shipment, written as part of posting. Stored field because the request requires it on the entry; see open question item-ledger-storage for the related-table alternative. | Handling Class (Enum or Code with TableRelation (see open question handling-class-value-type)): Same field number, type and length on every table that carries Handling Class. Non-editable. | [7] [9] [14] |
| 10 | extend | tableextension | Internal Movement Line | Holds the Move Reason the user enters on a bin-to-bin internal movement line. | Move Reason (Enum or Code with TableRelation (see open question move-reason-value-type)): Same field number, type and length on Warehouse Activity Line and Registered Invt. Movement Line. Editable; see open question move-reason-header-or-line. | [5] [13] [14] |
| 11 | extend | tableextension | Registered Invt. Movement Line | Keeps Move Reason on the registered inventory movement; Whse.-Activity-Register routes inventory movements here and copies by TransferFields. | Move Reason (Enum or Code with TableRelation (see open question move-reason-value-type)): Same field number, type and length on Warehouse Activity Line and Registered Invt. Movement Line. Non-editable. | [5] [8] [14] |
| 12 | create | codeunit | Handling Class Whse. Flow | Event subscribers that copy Handling Class along each event-copy hop (shipment line, pick, inventory pick, warehouse journal line, warehouse entry, item journal line, item ledger entry). |  | [2] [1] [4] [3] [7] |
| 13 | create | codeunit | Move Reason Invt. Movement | Event subscriber that copies Move Reason from the internal movement line to the inventory movement activity line at creation. |  | [5] |
| 14 | extend | pageextension | Sales Order Subform (confirm exact page name in the target version's symbols) | Lets users enter Handling Class on sales order lines. Define the tooltip once on the table field (runtime 13.0 / BC24 or later) so bound page fields inherit it; on earlier runtimes add a page-level ToolTip. |  | [10] [11] |
| 15 | extend | pageextension | Whse. Pick Subform (confirm exact page name in the target version's symbols) | Shows Handling Class on warehouse pick lines created from warehouse shipments. Define the tooltip once on the table field (runtime 13.0 / BC24 or later) so bound page fields inherit it; on earlier runtimes add a page-level ToolTip. |  | [10] [11] |
| 16 | extend | pageextension | Invt. Pick Subform (confirm exact page name in the target version's symbols) | Shows Handling Class on inventory pick lines at basic-warehouse locations. Define the tooltip once on the table field (runtime 13.0 / BC24 or later) so bound page fields inherit it; on earlier runtimes add a page-level ToolTip. |  | [10] [11] |
| 17 | extend | pageextension | Registered Pick Subform (confirm exact page name in the target version's symbols) | Shows Handling Class on registered pick lines. Define the tooltip once on the table field (runtime 13.0 / BC24 or later) so bound page fields inherit it; on earlier runtimes add a page-level ToolTip. |  | [10] [11] |
| 18 | extend | pageextension | Posted Invt. Pick Subform (confirm exact page name in the target version's symbols) | Shows Handling Class on posted inventory pick lines. Define the tooltip once on the table field (runtime 13.0 / BC24 or later) so bound page fields inherit it; on earlier runtimes add a page-level ToolTip. |  | [10] [11] |
| 19 | extend | pageextension | Warehouse Entries (confirm exact page name in the target version's symbols) | Shows Handling Class on warehouse entries. Define the tooltip once on the table field (runtime 13.0 / BC24 or later) so bound page fields inherit it; on earlier runtimes add a page-level ToolTip. |  | [10] [11] |
| 20 | extend | pageextension | Item Ledger Entries (confirm exact page name in the target version's symbols) | Shows Handling Class on item ledger entries. Define the tooltip once on the table field (runtime 13.0 / BC24 or later) so bound page fields inherit it; on earlier runtimes add a page-level ToolTip. |  | [10] [11] |
| 21 | extend | pageextension | Internal Movement Subform (confirm exact page name in the target version's symbols) | Lets users enter Move Reason on internal movement lines. Define the tooltip once on the table field (runtime 13.0 / BC24 or later) so bound page fields inherit it; on earlier runtimes add a page-level ToolTip. |  | [10] [11] |
| 22 | extend | pageextension | Invt. Movement Subform (confirm exact page name in the target version's symbols) | Shows Move Reason on inventory movement lines. Define the tooltip once on the table field (runtime 13.0 / BC24 or later) so bound page fields inherit it; on earlier runtimes add a page-level ToolTip. |  | [10] [11] |
| 23 | extend | pageextension | Registered Invt. Mov. Subform (confirm exact page name in the target version's symbols) | Shows Move Reason on registered inventory movement lines. Define the tooltip once on the table field (runtime 13.0 / BC24 or later) so bound page fields inherit it; on earlier runtimes add a page-level ToolTip. |  | [10] [11] |

## 3. How the data flows

- **User** → **Sales Line.Handling Class**: entered by the user. Entered on the sales order line; defaulting from master data is an open question. [6]
- **Sales Line** → **Warehouse Shipment Line**: copied in an event subscriber. OnBeforeCreateShptLineFromSalesLine on Sales Warehouse Mgt., before the line is inserted (no Modify). [2]
- **Warehouse Shipment Line** → **Warehouse Activity Line (pick: take, place and breakbulk lines)**: copied in an event subscriber. OnAfterTransferFromShptLine on Warehouse Activity Line, raised by Create Pick for every temporary line. [1]
- **Warehouse Activity Line (pick)** → **Registered Whse. Activity Line**: standard TransferFields copy. CreateRegActivLine in Whse.-Activity-Register; same field number and type required. [1] [8]
- **Warehouse Activity Line (pick registration)** → **Warehouse Journal Line**: copied in an event subscriber. OnBeforeWhseJnlRegisterLine on Whse.-Activity-Register; only at Bin Mandatory locations, one per take or place line. [1] [3]
- **Warehouse Journal Line** → **Warehouse Entry**: copied in an event subscriber. OnBeforeInsertWhseEntry on Whse. Jnl.-Register Line; covers every path that creates warehouse entries. [3]
- **Sales Line** → **Item Journal Line**: copied in an event subscriber. OnAfterCopyItemJnlLineFromSalesLine on Item Journal Line; runs for warehouse shipment posting and for inventory pick posting, both of which run Sales-Post. [7] [4]
- **Item Journal Line** → **Item Ledger Entry**: copied in an event subscriber. OnAfterInitItemLedgEntry on Item Jnl.-Post Line, before the entry is inserted. [7]
- **Item Journal Line (warehouse shipment posting at a bin location)** → **Warehouse Journal Line**: copied in an event subscriber. OnAfterCreateWhseJnlLine on WMS Management; item tracking splits copy the whole record. [3]
- **Sales Line** → **Warehouse Activity Line (inventory pick)**: copied in an event subscriber. OnBeforeNewWhseActivLineInsertFromSales on Create Inventory Pick/Movement. [4]
- **Warehouse Activity Line (inventory pick)** → **Posted Invt. Pick Line**: standard TransferFields copy. Whse.-Activity-Post copies the activity line by TransferFields. [4] [8]
- **Warehouse Activity Line (inventory pick posting at a bin location)** → **Warehouse Journal Line**: copied in an event subscriber. CreateWhseJnlLine during inventory pick posting raises OnAfterCreateWhseJnlLine; confirm publisher and signature in symbols (see unresolved). [4] [3]
- **User** → **Internal Movement Line.Move Reason**: entered by the user. [5]
- **Internal Movement Line** → **Warehouse Activity Line (Invt. Movement, take and place lines)**: copied in an event subscriber. OnCreateInvtMvntWithoutSourceOnAfterTransferFields on Create Inventory Pick/Movement; CreatePickOrMoveLine inserts take and place lines from the same record. The internal movement line is deleted afterwards, so it cannot be read later. [5]
- **Warehouse Activity Line (Invt. Movement)** → **Registered Invt. Movement Line**: standard TransferFields copy. Whse.-Activity-Register branches on activity type; inventory movements go to Registered Invt. Movement Line by TransferFields. [5] [8]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Sales Warehouse Mgt." | `OnBeforeCreateShptLineFromSalesLine` | Copy Handling Class from Sales Line to the Warehouse Shipment Line before insert. | Assign only; no Modify and no re-read of the sales line. | [2] |
| Table "Warehouse Activity Line" | `OnAfterTransferFromShptLine` | Copy Handling Class from the shipment line to every pick take, place and breakbulk line. | Do not use OnBeforeWhseActivLineInsert on Create Pick: it does not pass the shipment line and misses breakbulk and place lines. | [1] |
| Codeunit "Whse.-Activity-Register" | `OnBeforeWhseJnlRegisterLine` | Copy Handling Class from the activity line to the warehouse journal line when a pick is registered. | No Modify of registered lines or entries after registration. | [1] |
| Codeunit "Whse. Jnl.-Register Line" | `OnBeforeInsertWhseEntry` | Copy Handling Class from the warehouse journal line to the warehouse entry. | Never patch warehouse entries after posting. | [3] |
| Codeunit "WMS Management" | `OnAfterCreateWhseJnlLine` | Copy Handling Class from the item journal line to the warehouse journal line during warehouse shipment posting at bin locations. |  | [3] |
| Table "Item Journal Line" | `OnAfterCopyItemJnlLineFromSalesLine` | Copy Handling Class from the sales line to the item journal line. |  | [7] |
| Codeunit "Item Jnl.-Post Line" | `OnAfterInitItemLedgEntry` | Copy Handling Class from the item journal line to the new item ledger entry before insert. | No source-document filter needed: other journal lines leave the field empty. · Never find and Modify item ledger entries after posting. | [7] |
| Codeunit "Create Inventory Pick/Movement" | `OnBeforeNewWhseActivLineInsertFromSales` | Copy Handling Class from the sales line to the inventory pick line. | Do not use OnBeforeNewWhseActivLineInsertFromPurchase on this codeunit; it serves outbound purchase lines. | [4] |
| Codeunit "Whse.-Activity-Post" (confirm in symbols) | `OnAfterCreateWhseJnlLine` | Copy Handling Class from the inventory pick activity line to the warehouse journal line when an inventory pick is posted at a bin location. | Confirm the publisher and signature in the target version before implementing. | [4] |
| Codeunit "Create Inventory Pick/Movement" | `OnCreateInvtMvntWithoutSourceOnAfterTransferFields` | Copy Move Reason from the internal movement line to the inventory movement activity line. | Do not read the internal movement during registration; it is deleted after the inventory movement is created. | [5] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification on every new table-extension field (a table extension has no table-level value to inherit); choose the value that matches what Handling Class and Move Reason store, and resolve any ToBeClassified. [14]
- **permissions**: If Handling Class or Move Reason become code tables (open questions), plan each as a new entity: table type, list page, permission set composed from included sets, classification. Table extensions and subscriber codeunits alone need no new permission set entries. [15]
- **install**: No install or upgrade code: existing documents and entries keep an empty value. Confirm no backfill of open sales lines or existing entries is wanted. agent judgment

## 6. Tests

1. **whse-shipment-line-gets-handling-class** [2] [12]
    - Given A location requiring shipment and pick, an item with inventory and a released sales order line with a Handling Class (fixtures from LibrarySales, LibraryInventory, LibraryWarehouse, LibraryRandom)
    - When A warehouse shipment is created from the sales order
    - Then The warehouse shipment line has the sales line's Handling Class
2. **pick-lines-get-handling-class** [1] [12]
    - Given A warehouse shipment whose line has a Handling Class at a bin location
    - When A pick is created from the shipment
    - Then Every take and place (and breakbulk) Warehouse Activity Line has that Handling Class
3. **registered-pick-and-whse-entries-keep-handling-class** [1] [3] [12]
    - Given A created pick with Handling Class at a Bin Mandatory location
    - When The pick is registered
    - Then Each Registered Whse. Activity Line and each Warehouse Entry created by registration has the Handling Class
4. **shipment-posting-ile-and-whse-entries** [7] [3] [12]
    - Given A registered pick for a warehouse shipment whose sales line has a Handling Class
    - When The warehouse shipment is posted
    - Then The item ledger entries of the shipment and the warehouse entries written from the shipment bin have the Handling Class
5. **inventory-pick-gets-handling-class** [4] [12]
    - Given A basic-warehouse location requiring pick (not shipment), a released sales order line with a Handling Class
    - When An inventory pick is created
    - Then The inventory pick lines have the Handling Class
6. **inventory-pick-posting-keeps-handling-class** [4] [7] [3] [12]
    - Given An inventory pick with Handling Class at a basic-warehouse location with bins
    - When The inventory pick is posted
    - Then The Posted Invt. Pick Line, the item ledger entries of the shipment and the warehouse entries have the Handling Class
7. **unrelated-item-journal-leaves-handling-class-empty** [7] [12]
    - Given An item journal line posted directly
    - When It is posted
    - Then The item ledger entry has an empty Handling Class and posting does not fail
8. **internal-movement-move-reason-registered** [5] [12]
    - Given A location with bins and an internal movement line with a Move Reason
    - When An inventory movement is created from it and registered
    - Then The take and place inventory movement lines and the Registered Invt. Movement Line have the Move Reason

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are not stated; tooltip inheritance applies only from BC24 (runtime 13.0).
- The publisher and signature of OnAfterCreateWhseJnlLine on the inventory pick posting path are not stated explicitly by the opened article (it describes CreateWhseJnlLine within Whse.-Activity-Post); confirm in the target version's symbols before implementing.
- Page extension target names (subform and entry list pages) rest on agent judgment; confirm them in symbols.
- The decision that no install or upgrade code is needed rests on agent judgment; no BCQuality article covers it for this feature.

## Sources

[1] `microsoft/knowledge/warehouse/carry-fields-to-warehouse-picks-put-aways-and-registered-activities.md`: Pick creation from shipments, registration to Registered Whse. Activity Line and the registration hop to warehouse journal lines.
    - Same field number and type on Warehouse Activity Line and Registered Whse. Activity Line so registration copies it with no subscriber.
    - Copy on picks from shipments in OnAfterTransferFromShptLine on Warehouse Activity Line; it runs for every take, place and breakbulk line.
    - For warehouse entries, copy to the warehouse journal line in OnBeforeWhseJnlRegisterLine on Whse.-Activity-Register, then to the entry in OnBeforeInsertWhseEntry.
    - Do not use OnBeforeWhseActivLineInsert on Create Pick; do not find registered lines and Modify them.
    - Registration writes warehouse entries only at Bin Mandatory locations; pick worksheet and internal pick use other builders and events.
[2] `microsoft/knowledge/warehouse/carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.md`: Sales line to warehouse shipment line hop.
    - Add the field to the warehouse line with the same number and type as on the source line.
    - Copy in OnBeforeCreateShptLineFromSalesLine on Sales Warehouse Mgt., before insert.
    - Do not copy in OnAfterCreateShptLineFromSalesLine with Modify, nor re-read the source line in OnBeforeWhseShptLineInsert.
    - Other sources (returns, transfers) raise their own events; plan one subscriber per source type needed.
[3] `microsoft/knowledge/warehouse/carry-fields-to-warehouse-entries-through-the-warehouse-journal-line.md`: Warehouse journal line and warehouse entry hops, including shipment posting at bin locations.
    - Add the field to Warehouse Journal Line and Warehouse Entry; copy in OnBeforeInsertWhseEntry on Whse. Jnl.-Register Line.
    - For document posting, put the value on the item journal line first, then copy it in OnAfterCreateWhseJnlLine on WMS Management.
    - For other paths such as registering a pick, confirm where the warehouse journal line is built; do not assume CreateWhseJnlLine.
    - Do not find warehouse entries after posting and Modify them.
[4] `microsoft/knowledge/warehouse/inventory-picks-and-put-aways-post-through-the-source-document.md`: Inventory picks at basic-warehouse locations: creation, posted inventory pick lines, and item ledger entries via the source line.
    - The source line is the carrier for any value that must reach item ledger entries; the item journal line is built by sales posting, which never reads the activity line.
    - Copy to the inventory pick line in OnBeforeNewWhseActivLineInsertFromSales on Create Inventory Pick/Movement.
    - Same field number on Posted Invt. Pick Line so TransferFields copies it.
    - If users enter the value on the activity line, write it back in OnUpdateSourceDocumentOnBeforeModifySalesLine; several activity lines merge into one buffer line per source line.
    - At bin locations CreateWhseJnlLine builds warehouse entries from each activity line and raises OnAfterCreateWhseJnlLine.
[5] `microsoft/knowledge/warehouse/carry-fields-through-warehouse-movements-and-internal-movements.md`: Move Reason on internal movements, inventory movement lines and Registered Invt. Movement Line.
    - Decide which movement documents the feature covers.
    - Same field number on Warehouse Activity Line and Registered Invt. Movement Line; registration copies by TransferFields.
    - Copy at creation in OnCreateInvtMvntWithoutSourceOnAfterTransferFields on Create Inventory Pick/Movement.
    - Do not extend only Registered Whse. Activity Line; inventory movements land in Registered Invt. Movement Line.
    - Do not read the internal movement during registration; it is usually deleted and not referenced by the activity line.
[6] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Deciding which sales stages Handling Class must reach and which are left to the requester.
    - Decide which stages the field must reach before writing code and plan one step per stage.
    - Item ledger entry is reached by two subscribers through Item Journal Line.
    - Name page extensions, permission entries and a test that posts and reads the value back from every target.
    - Do not fill ledger entries after posting by finding and modifying them.
[7] `microsoft/knowledge/sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md`: Sales line to item journal line to item ledger entry.
    - Add the field to Item Journal Line and Item Ledger Entry; copy in OnAfterCopyItemJnlLineFromSalesLine and OnAfterInitItemLedgEntry.
    - Store the field on the ledger entry only when users must see or filter it as a native list column, or it is read on almost every access.
    - Other item journal postings leave the field empty; no source-document filter is needed.
    - Do not find item ledger entries after posting and Modify them.
[8] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Mirrored Handling Class and Move Reason definitions across TransferFields targets.
    - Define mirrored fields with the exact same field number, data type and length on every table in the cascade.
    - A shorter length on one side compiles but fails at runtime when a longer value is copied.
[9] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Storage choice for Handling Class on Item Ledger Entry.
    - Prefer a related table keyed by Entry No. for optional, sparse or integration attributes.
    - Use a stored table-extension field only when the value must appear as a native list column and is read on almost every access.
[10] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips for the new page fields.
    - On runtime 13.0 (BC24) or later define the tooltip on the table field and omit duplicate page-level tooltips.
    - On earlier runtimes add page-level tooltips.
    - Tooltip text must state what the value is for, without inventing behavior.
[11] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Tooltip inheritance for bound page fields (applies from BC24 / runtime 13.0).
    - A bound page field inherits the source field's ToolTip when it declares none; do not add duplicates.
    - A field with neither an inline nor an inherited tooltip is a real gap.
[12] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for locations, items, sales orders and warehouse documents.
    - Build fixtures with Library codeunits, not hand-rolled Init/Insert.
    - Create parents first and Validate foreign-key fields.
[13] `microsoft/knowledge/style/fixed-choice-set-must-use-enum-not-integer.md`: Value type decision for Handling Class and Move Reason.
    - A fixed set of named, mutually exclusive choices is typed as Enum, not a raw Integer.
[14] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: DataClassification of the new table-extension fields.
    - Every Normal field a tableextension adds must set its own DataClassification.
    - Choose the classification that matches the data stored; ToBeClassified is not a safe default.
[15] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Conditional: only if Handling Class or Move Reason become user-maintained code tables.
    - Plan table type, pages, permissions, classification, install and tests for a new record type.
    - A row the request does not settle is a question for the requester, not a default.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
