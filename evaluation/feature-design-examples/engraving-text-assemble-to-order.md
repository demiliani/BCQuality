# Feature design

> For assemble-to-order items, the sales order taker types an Engraving Text on the sales line. The text must appear on the linked assembly order, stay up to date when the sales line text is changed later, and be kept on the posted assembly order. Component consumption entries must record which engraving they were used for.

**Result:** Complete design. **Business process:** Assemble-to-order sales: sales line to linked assembly order synchronization, assembly posting and component consumption item ledger entries. **Knowledge used:** 14 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is the maximum length of the Engraving Text? It must be the same Text length on every table that carries it. _(affects: sales-line-ext, assembly-header-ext, posted-assembly-header-ext, item-journal-line-ext, item-ledger-entry-ext, sales-shipment-line-ext, sales-invoice-line-ext, sales-cr-memo-line-ext, return-receipt-line-ext, sales-line-archive-ext, maximum-length-engraving-posts-through-every-target)_
2. Should Engraving Text be editable only on sales lines that are assemble-to-order, and what should happen to a value typed on a line that is not, or that stops being, assemble-to-order? _(affects: sales-line-ext, sales-order-subform-ext)_
3. May users edit the engraving directly on the assembly order? Every synchronization copies the sales line value over it, so the design keeps it read-only there unless you decide otherwise. _(affects: assembly-header-ext, assembly-order-ext)_
4. Must users see or filter the engraving as a column on item ledger entries, or is it read on almost every access? If not, BCQuality guidance prefers a related table keyed by Entry No. over a stored field on Item Ledger Entry. _(affects: item-ledger-entry-ext, item-ledger-entries-ext, engraving-consumption-posting, component-consumption-entries-carry-engraving)_
5. Should the assembly output entry of the assembled item also record the engraving, or only the component consumption entries the request names? _(affects: engraving-consumption-posting, item-ledger-entry-ext)_
6. The mirroring guidance puts a Sales Line field on Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line and Sales Line Archive. Do you want the engraving on all of them, or can some document types be excluded? Which posted sales pages should show it? _(affects: sales-shipment-line-ext, sales-invoice-line-ext, sales-cr-memo-line-ext, return-receipt-line-ext, sales-line-archive-ext, posted-sales-lines-and-archive-carry-engraving)_
7. Which object and field ID range should the extension use? No repository or app.json was supplied. _(affects: sales-line-ext, assembly-header-ext, posted-assembly-header-ext, item-journal-line-ext, item-ledger-entry-ext, sales-shipment-line-ext, sales-invoice-line-ext, sales-cr-memo-line-ext, return-receipt-line-ext, sales-line-archive-ext, ato-engraving-sync, engraving-consumption-posting, sales-order-subform-ext, assembly-order-ext, posted-assembly-order-ext, item-ledger-entries-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Sales Line | Holds the Engraving Text the order taker types on an assemble-to-order sales line. Its OnValidate calls the public AutoAsmToOrder() so that a change to the engraving alone reaches an existing linked assembly order. | Engraving Text (Text[length to confirm, see open question field-length]): DataClassification = CustomerContent; ToolTip on the table field (inherited by bound page fields from BC24/runtime 13.0). OnValidate: AutoAsmToOrder(). Field number is reused on every TransferFields target of Sales Line. | [1] [4] [6] [8] [9] |
| 2 | extend | tableextension | Assembly Header | Carries the engraving on the linked assemble-to-order assembly order; filled from the sales line on creation and on every synchronization. Uses the same field number, type and length as Posted Assembly Header so assembly posting (and the undo of a posted assembly) copies it by TransferFields. | Engraving Text (Text[length to confirm, see open question field-length]): Same field number, type and length as on Posted Assembly Header; DataClassification = CustomerContent. Whether users may edit it here is an open question. | [1] [2] [6] [8] |
| 3 | extend | tableextension | Posted Assembly Header | Keeps the engraving on the posted assembly order; filled by the standard TransferFields(AssemblyHeader) in Assembly-Post, no subscriber. | Engraving Text (Text[length to confirm, see open question field-length]): Same field number, type and length as on Assembly Header; DataClassification = CustomerContent; Editable = false. | [2] [4] [6] [8] |
| 4 | extend | tableextension | Item Journal Line | Carries the engraving on the consumption journal lines Assembly-Post builds field by field for item components, so it can reach the item ledger entry. | Engraving Text (Text[length to confirm, see open question field-length]): DataClassification = CustomerContent. Empty for every journal line not built from an assembly component, so other postings leave the entry empty. | [2] [5] [8] |
| 5 | extend | tableextension | Item Ledger Entry | Records on each component consumption entry which engraving it was used for, written when the entry is created during posting. A stored field on this hot ledger is justified only when users must see or filter it as a native list column or it is read on almost every access (applies from BC23); otherwise the articles prefer a related table keyed by Entry No. The choice is open question ledger-storage. | Engraving Text (Text[length to confirm, see open question field-length]): DataClassification = CustomerContent; Editable = false. | [2] [5] [7] [8] |
| 6 | extend | tableextension | Sales Shipment Line | Mirrors the Sales Line field so the standard TransferFields from Sales Line (posting through InitFromSalesLine, or archiving) carries the engraving to Sales Shipment Line. Chosen by the mirroring article, not by the request: see open question posted-sales-lines. | Engraving Text (Text[length to confirm, see open question field-length]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. | [4] [3] [6] [8] |
| 7 | extend | tableextension | Sales Invoice Line | Mirrors the Sales Line field so the standard TransferFields from Sales Line (posting through InitFromSalesLine, or archiving) carries the engraving to Sales Invoice Line. Chosen by the mirroring article, not by the request: see open question posted-sales-lines. | Engraving Text (Text[length to confirm, see open question field-length]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. | [4] [3] [6] [8] |
| 8 | extend | tableextension | Sales Cr.Memo Line | Mirrors the Sales Line field so the standard TransferFields from Sales Line (posting through InitFromSalesLine, or archiving) carries the engraving to Sales Cr.Memo Line. Chosen by the mirroring article, not by the request: see open question posted-sales-lines. | Engraving Text (Text[length to confirm, see open question field-length]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. | [4] [3] [6] [8] |
| 9 | extend | tableextension | Return Receipt Line | Mirrors the Sales Line field so the standard TransferFields from Sales Line (posting through InitFromSalesLine, or archiving) carries the engraving to Return Receipt Line. Chosen by the mirroring article, not by the request: see open question posted-sales-lines. | Engraving Text (Text[length to confirm, see open question field-length]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. | [4] [3] [6] [8] |
| 10 | extend | tableextension | Sales Line Archive | Mirrors the Sales Line field so the standard TransferFields from Sales Line (posting through InitFromSalesLine, or archiving) carries the engraving to Sales Line Archive. Chosen by the mirroring article, not by the request: see open question posted-sales-lines. | Engraving Text (Text[length to confirm, see open question field-length]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. | [4] [3] [6] [8] |
| 11 | create | codeunit | ATO Engraving Sync | Subscribers on table Assemble-to-Order Link that copy the engraving to the assembly header on every synchronization and force a synchronization when only the engraving differs. |  | [1] |
| 12 | create | codeunit | Engraving Consumption Posting | Subscribers on Assembly-Post and Item Jnl.-Post Line that carry the engraving from the assembly header to each item component consumption journal line and from there to the new item ledger entry. |  | [2] [5] |
| 13 | extend | pageextension | Sales Order Subform | Lets the order taker type the Engraving Text on the sales line. Bound field inherits the table-field tooltip from BC24/runtime 13.0; on earlier runtimes it needs a page-level tooltip. |  | [9] |
| 14 | extend | pageextension | Assembly Order | Shows the engraving on the linked assembly order. |  | [9] |
| 15 | extend | pageextension | Posted Assembly Order | Shows the engraving on the posted assembly order. |  | [9] |
| 16 | extend | pageextension | Item Ledger Entries | Shows the engraving as a column on item ledger entries so consumption can be traced to its engraving; only if open question ledger-storage confirms a native list column. |  | [9] [7] |

## 3. How the data flows

- **Order taker** → **Sales Line.Engraving Text**: entered by the user. Typed on the Sales Order Subform for an assemble-to-order line. [1]
- **Sales Line** → **Assembly Header (new or synchronized assemble-to-order link)**: copied in an event subscriber. OnBeforeAsmHeaderModify on Assemble-to-Order Link, raised by SynchronizeAsmFromSalesLine just before Modify(true); covers first creation and every later synchronization. [1]
- **Sales Line (engraving changed later)** → **Existing Assembly Header**: field validation. Engraving Text OnValidate calls AutoAsmToOrder(); OnBeforeNeedsSynchronization returns Result := true, IsHandled := true only when the engraving differs, so the synchronization (and OnBeforeAsmHeaderModify) runs. [1]
- **Assembly Header** → **Posted Assembly Header**: standard TransferFields copy. Assembly-Post TransferFields(AssemblyHeader); the undo of a posted assembly copies back the same way. [2] [6]
- **Assembly Header** → **Item Journal Line (item component consumption)**: copied in an event subscriber. OnBeforePostItemConsumption(var AssemblyHeader; var AssemblyLine; var ItemJournalLine) on Assembly-Post, raised just before each item component line is posted. Not OnAfterCreateItemJnlLineFromAssemblyLine, which only resource lines raise. [2]
- **Item Journal Line** → **Item Ledger Entry (consumption)**: copied in an event subscriber. OnAfterInitItemLedgEntry on Item Jnl.-Post Line, after the entry is initialized and before it is inserted. [2] [5]
- **Sales Line** → **Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line**: standard TransferFields copy. InitFromSalesLine calls TransferFields(SalesLine); no subscriber. [4] [3]
- **Sales Line** → **Sales Line Archive**: standard TransferFields copy. Archiving copies lines with TransferFields; no subscriber. [4] [3]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Assemble-to-Order Link" | `OnBeforeAsmHeaderModify(var AssemblyHeader; var SalesLine)` | Copy Sales Line.Engraving Text to Assembly Header.Engraving Text on creation and on every synchronization. |  | [1] |
| Table "Assemble-to-Order Link" | `OnBeforeNeedsSynchronization(AssemblyHeader; SalesLine; var Result; var IsHandled)` | Force a synchronization when only the engraving changed, so the existing assembly order stays up to date. | Set Result := true and IsHandled := true only when SalesLine.Engraving Text differs from AssemblyHeader.Engraving Text · Leave Result and IsHandled untouched otherwise, so the standard comparison still decides for item, quantity, date and the other standard fields | [1] |
| Codeunit "Assembly-Post" | `OnBeforePostItemConsumption(var AssemblyHeader; var AssemblyLine; var ItemJournalLine)` | Copy AssemblyHeader.Engraving Text to the consumption Item Journal Line of each item component. | Do not use OnAfterCreateItemJnlLineFromAssemblyLine for component items: it is raised only for resource lines | [2] |
| Codeunit "Item Jnl.-Post Line" | `OnAfterInitItemLedgEntry(var NewItemLedgEntry; var ItemJournalLine)` | Copy ItemJournalLine.Engraving Text to the new Item Ledger Entry so the value is written as part of posting. | Never find and Modify item ledger entries after posting · No source-document filter: journal lines from other postings leave the field empty | [5] [3] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification = CustomerContent on Engraving Text in every table extension; a tableextension has no table-level value to inherit, and the text is data belonging to the tenant's customer. [8]
- **other**: Define the ToolTip on the table fields and let bound page fields inherit it (BC24/runtime 13.0 or later); on earlier runtimes add page-level tooltips on each page extension. Describe what the engraving is used for, not 'Specifies the Engraving Text'. [9]
- **other**: Assign one field number, type and length for Engraving Text and reuse it on Sales Line and all its TransferFields targets, and on Assembly Header and Posted Assembly Header, at creation time. [4] [6]
- **install**: No install or upgrade code: the feature adds only new, empty fields and no setup data. agent judgment
- **permissions**: No new permission set: the feature adds no tables and no exposed pages, queries or web-service codeunits. agent judgment

## 6. Tests

1. **ato-line-copies-engraving-to-new-assembly-order** [1] [10] [11] [14]
    - Given an assemble-to-order item (components are items) created with the test library codeunits, the full posting-group chain for the customer and items, and component inventory; a sales order for a customer created with LibrarySales
    - When An assemble-to-order sales line is created and an engraving value from LibraryUtility is validated on it
    - Then The linked Assembly Header (via Assemble-to-Order Link) has the same Engraving Text
2. **engraving-change-updates-existing-assembly-order** [1] [13] [14]
    - Given an assemble-to-order item (components are items) created with the test library codeunits, the full posting-group chain for the customer and items, and component inventory; an assemble-to-order sales line with an engraving and its linked assembly order already created
    - When Only the Engraving Text on the sales line is changed to a new value
    - Then The linked Assembly Header carries the new value
3. **standard-change-still-synchronizes** [1] [13]
    - Given an assemble-to-order item (components are items) created with the test library codeunits, the full posting-group chain for the customer and items, and component inventory; an assemble-to-order sales line with an engraving and its linked assembly order
    - When Only the sales line quantity is changed (engraving unchanged)
    - Then The Assembly Header quantity follows the sales line and its Engraving Text is unchanged, proving OnBeforeNeedsSynchronization does not replace the standard comparison
4. **posting-keeps-engraving-on-posted-assembly-order** [2] [12] [10]
    - Given an assemble-to-order item (components are items) created with the test library codeunits, the full posting-group chain for the customer and items, and component inventory; an assemble-to-order sales order with an engraving
    - When The sales order is shipped
    - Then The Posted Assembly Header for the linked assembly order carries the Engraving Text
5. **component-consumption-entries-carry-engraving** [2] [5] [12]
    - Given an assemble-to-order item (components are items) created with the test library codeunits, the full posting-group chain for the customer and items, and component inventory; an assemble-to-order sales order with an engraving
    - When The sales order is shipped
    - Then Every Item Ledger Entry of entry type Assembly Consumption for the posted assembly order's item components carries the Engraving Text (fails if the value was copied in the resource-only event)
6. **posted-sales-lines-and-archive-carry-engraving** [4] [3] [12]
    - Given an assemble-to-order item (components are items) created with the test library codeunits, the full posting-group chain for the customer and items, and component inventory; an assemble-to-order sales order with an engraving
    - When The sales order is shipped and invoiced
    - Then The Sales Shipment Line and Sales Invoice Line for the line carry the Engraving Text; a separate test archives the order and reads it from Sales Line Archive
7. **maximum-length-engraving-posts-through-every-target** [6] [11]
    - Given an assemble-to-order item (components are items) created with the test library codeunits, the full posting-group chain for the customer and items, and component inventory; an assemble-to-order sales order whose engraving fills the full field length
    - When The sales order is shipped
    - Then Posting succeeds and the Posted Assembly Header, Sales Shipment Line and consumption Item Ledger Entries hold the full value, proving the mirrored fields share type and length

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined (no repository or app.json); the hot-ledger guidance applies from BC23 and table-field tooltip inheritance from BC24/runtime 13.0.
- Install/upgrade (none needed) and permissions (no new permission set) rest on agent judgment; no BCQuality article was cited for them.
- The page extension targets (Sales Order Subform, Assembly Order, Posted Assembly Order, Item Ledger Entries) are agent judgment; BCQuality knowledge covers only their tooltips.
- Whether Copy Document carries the engraving to sales lines of a new document is not covered by BCQuality knowledge (the opened article covers header copying only).

## Sources

[1] `microsoft/knowledge/manufacturing/carry-sales-line-fields-to-assemble-to-order-assembly-headers.md`: Copying the engraving from the sales line to the assemble-to-order assembly header and keeping it current on later changes.
    - Add the field to Assembly Header and copy it from the sales line in OnBeforeAsmHeaderModify on table Assemble-to-Order Link; that covers first creation and every later synchronization.
    - For a change to the custom field alone to reach an existing assembly order, call AutoAsmToOrder() in the sales line field's OnValidate and subscribe to OnBeforeNeedsSynchronization.
    - In OnBeforeNeedsSynchronization set Result := true and IsHandled := true only when the custom field differs; leave both untouched otherwise.
    - Do not copy only in OnBeforeAsmHeaderModify and expect later edits to flow: NeedsSynchronization compares only standard fields.
    - Do not answer OnBeforeNeedsSynchronization with IsHandled := true on every call; it stops item, quantity and date changes from reaching the assembly order.
[2] `microsoft/knowledge/manufacturing/carry-assembly-fields-through-assembly-posting.md`: Carrying the engraving to the posted assembly order and to component consumption item ledger entries.
    - Posted Assembly Header is created with TransferFields(AssemblyHeader): give the field the same number, type and length on both tables; the undo of a posted assembly copies back the same way.
    - For item ledger entries, add the field to Item Journal Line, copy it in the event of the line kind that must carry it, then to the entry with OnAfterInitItemLedgEntry.
    - Use OnBeforePostItemConsumption for component items.
    - Do not use OnAfterCreateItemJnlLineFromAssemblyLine for component consumption: it is raised only for resource lines.
[3] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Deciding which sales posting stages the sales line field must reach and planning one step per stage, with pages and a posting test per target.
    - Plan one extension step per stage the field must reach; posted lines and Sales Line Archive are reached by TransferFields from Sales Line.
    - Name the page extensions that show the field and a test that posts a document and reads the value back from every target.
    - Do not plan to fill ledger entries after posting by finding and modifying them.
[4] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring the Sales Line field on posted sales line tables and Sales Line Archive.
    - Give the field the same number, name, type and length on the source and on every target table the plan needs; for a line field, on the posted line tables and the archive, unless the plan states a document type never needs it.
    - No subscriber is needed for TransferFields stages; keep mirrored fields non-editable on posted tables.
    - Do not use a different field number on a posted table and patch it with an OnAfter...Insert subscriber and Modify.
[5] `microsoft/knowledge/sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md`: The Item Journal Line to Item Ledger Entry hop and the choice of storing the field on the entry.
    - Add the field to Item Journal Line and Item Ledger Entry and copy it to the new entry in OnAfterInitItemLedgEntry, so it is written as part of posting.
    - Store the field on the ledger entry only when users must see or filter it as a native list column, or it is read on almost every access; for optional or integration-only attributes prefer a related table keyed by the entry number.
    - Other postings reaching OnAfterInitItemLedgEntry leave the journal field empty, so no source-document filter is needed.
    - Do not find item ledger entries after posting and Modify them.
[6] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field type and length across every TransferFields cascade the engraving is mirrored on.
    - Define a mirrored field with the exact same field number, data type and length on every table in the cascade, at creation time.
    - A shorter length on one side compiles and runs until a value exceeds it, then raises a runtime error.
[7] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Storage decision for the engraving on Item Ledger Entry (applies from BC23; bc-version unknown).
    - Put optional, sparse or integration attributes in a related table keyed by the ledger entry number, shown from a FactBox or FlowField.
    - Use a tableextension stored field on a hot ledger only when the value must appear as a native list column and is read on almost every access.
[8] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of every Engraving Text field.
    - Every Normal field a tableextension adds must set its own DataClassification; do not leave ToBeClassified.
    - Data belonging to the tenant's customers is CustomerContent; do not classify it as SystemMetadata.
[9] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips for the engraving on the page extensions.
    - On runtime 13.0 (BC24) or later define tooltip text on the table field and let bound page fields inherit it; before runtime 13.0 user-facing page fields need page-level tooltips.
    - Make the tooltip say what the value is used for; do not generate 'Specifies the <field name>.' or invent effects.
[10] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Building test fixtures.
    - Create customers, items and sales documents with the test Library codeunits (LibrarySales, LibraryInventory, LibraryRandom), parents first, validating foreign keys.
    - Do not hand-roll Init/Insert fixtures with invented keys.
[11] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Test values.
    - Create the records the test owns instead of assuming existing ones; fill every mandatory field.
    - Values that define the scenario, such as a value at the field's full length for a length test, stay explicit and deliberately chosen.
[12] `microsoft/knowledge/testing/given-blocks-must-cover-full-precondition-chain.md`: Preconditions of posting tests.
    - A posting test sets up the full posting-group chain and the setup records the posting path reads, not just the primary document.
[13] `microsoft/knowledge/testing/test-one-when-per-test.md`: Test shape.
    - Each test has exactly one WHEN; preconditions such as creating the linked assembly order belong in GIVEN.
[14] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Test codeunit structure.
    - Tag the test codeunit with [FEATURE] and each test with [SCENARIO], [GIVEN], [WHEN] and [THEN] comments.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
