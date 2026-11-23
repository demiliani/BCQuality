# Feature design

> Released production orders get a Customer Batch Reference on each order line. Operators post output and consumption from the production journal, from the output journal using Explode Routing, and with Calc. Consumption. The reference must be stored on the capacity ledger entries and on the item ledger entries for output and consumption, and it must stay on the order when it is finished.

**Result:** Complete design. **Business process:** Manufacturing: output and consumption posting for released production orders (Production Journal, Output Journal with Explode Routing, Calc. Consumption, typed journal lines) through Item Jnl.-Post Line to capacity and item ledger entries, and the production order status change from Released to Finished. **Knowledge used:** 10 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Do operators also type output or consumption lines directly in the Output Journal or Consumption Journal (without the Production Journal page, Explode Routing or Calc. Consumption)? The design covers that path because the guidance requires every path users run; confirm or exclude it. _(affects: journal-copy-codeunit, typed-journal-lines-carry-reference)_
2. What data type and length should the Customer Batch Reference have (for example Code or Text, and how many characters)? It should be identical on all four tables. _(affects: prod-order-line-ext, item-journal-line-ext, capacity-ledger-entry-ext, item-ledger-entry-ext)_
3. Will users filter, sort or report on the reference as a column on capacity and item ledger entry lists? The design stores it as the request says; if it is only looked up occasionally, a related table keyed by Entry No. is the recommended alternative on these high-volume tables. _(affects: capacity-ledger-entry-ext, item-ledger-entry-ext, posting-copy-codeunit)_
4. Can the Customer Batch Reference contain personal data, or is it a customer's batch identifier only? This decides the DataClassification value. _(affects: prod-order-line-ext, item-journal-line-ext, capacity-ledger-entry-ext, item-ledger-entry-ext)_
5. Should the reference be enterable on planned and firm planned order lines too, and editable after output has been posted? Should users be able to change it on the journal line before posting? _(affects: released-prod-order-lines-page-ext, item-journal-line-ext)_
6. Should the reference also appear on value entries, warehouse entries, ledger entry pages, the finished production order page, or reports? The request does not name these stages, so they are not designed. _(affects: capacity-ledger-entry-ext, item-ledger-entry-ext)_
7. Must existing released orders or already posted entries receive a reference (an upgrade or back-fill), or does the feature apply only from installation onward? _(affects: prod-order-line-ext, capacity-ledger-entry-ext, item-ledger-entry-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Prod. Order Line | Holds the Customer Batch Reference per production order line. The field lives only here on the order side: the status change from Released to Finished copies the whole record, table extension fields included, so no mirror table and no copy code is needed for the finished order. | Customer Batch Ref. (Code (length to be confirmed)): Set DataClassification on the field itself (a tableextension has no table-level value to inherit); CustomerContent unless the reference can identify a person. | [3] [8] |
| 2 | extend | tableextension | Item Journal Line | Carries the reference on output and consumption journal lines. No standard path builds these lines with TransferFields, so a matching field number alone copies nothing; every path is filled by an event subscriber. | Customer Batch Ref. (Code (length to be confirmed)): Same type and length as on Prod. Order Line; set DataClassification on the field. | [1] [8] |
| 3 | extend | tableextension | Capacity Ledger Entry | Stores the reference on capacity entries created by output posting. Stored field chosen because the request requires the value to be stored on the entry; per the hot-ledger guidance (applies from BC23) a stored field is justified only when users filter or report on it as a native column, otherwise a related table keyed by Entry No. is preferred - see open question. | Customer Batch Ref. (Code (length to be confirmed)): Set DataClassification on the field. | [2] [4] [8] |
| 4 | extend | tableextension | Item Ledger Entry | Stores the reference on output and consumption item ledger entries. Stored field chosen because the request requires it; same hot-ledger condition as the capacity entry applies. | Customer Batch Ref. (Code (length to be confirmed)): Set DataClassification on the field. | [2] [5] [4] [8] |
| 5 | create | codeunit | Prod. Batch Ref. Journal | Event subscribers for every path that builds output and consumption journal lines, all calling one shared copy procedure so the paths cannot drift apart. |  | [1] |
| 6 | create | codeunit | Prod. Batch Ref. Posting | Event subscribers on Item Jnl.-Post Line that copy the reference from the journal line to the capacity ledger entry and the item ledger entry before they are inserted. |  | [2] [5] [6] |
| 7 | extend | pageextension | Released Prod. Order Lines (subpage of Released Production Order) | Lets the user enter the Customer Batch Reference on each released production order line. |  | agent judgment |

## 3. How the data flows

- **User** → **Prod. Order Line**: entered by the user. Entered on the released production order line. agent judgment
- **Prod. Order Line** → **Item Journal Line (output, Production Journal page)**: copied in an event subscriber. Production Journal Mgt OnBeforeInsertOutputJnlLine passes the Prod. Order Line. [1]
- **Prod. Order Line** → **Item Journal Line (consumption, Production Journal page)**: copied in an event subscriber. Production Journal Mgt OnBeforeInsertConsumptionJnlLine passes ProdOrderComp and ProdOrderLine. [1]
- **Prod. Order Line** → **Item Journal Line (output, Explode Routing)**: copied in an event subscriber. Output Jnl.-Expl. Route OnBeforeOutputItemJnlLineInsert passes no order line; read it by the journal line's Order No. and Order Line No. [1] [7]
- **Prod. Order Line** → **Item Journal Line (consumption, Calc. Consumption)**: copied in an event subscriber. Calc. Consumption OnBeforeInsertItemJnlLine passes the Prod. Order Component; read the order line by the component's Status, Prod. Order No. and Prod. Order Line No. [1]
- **Prod. Order Line / Prod. Order Component** → **Item Journal Line (typed in output or consumption journal)**: copied in an event subscriber. Validating Item No. calls CopyFromProdOrderLine / CopyFromProdOrderComp, which raise OnAfterCopyFromProdOrderLine / OnAfterCopyFromProdOrderComp on table Item Journal Line. Path not named in the request; designed because the article requires every path users run, and raised as an open question. [1]
- **Item Journal Line (output)** → **Capacity Ledger Entry**: copied in an event subscriber. Item Jnl.-Post Line OnBeforeInsertCapLedgEntry, just before Insert(true). [2]
- **Item Journal Line (output on last operation, consumption)** → **Item Ledger Entry**: copied in an event subscriber. Item Jnl.-Post Line OnAfterInitItemLedgEntry, before insert. An output item ledger entry is created only on the last operation. [2] [5]
- **Prod. Order Line (Released)** → **Prod. Order Line (Finished)**: other. Prod. Order Status Management copies the whole record by assignment (ToProdOrderLine := FromProdOrderLine), extension fields included. No code required. [3]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Production Journal Mgt" | `OnBeforeInsertOutputJnlLine` | Copy the reference from the passed ProdOrderLine to the output journal line through the shared copy procedure. |  | [1] |
| Codeunit "Production Journal Mgt" | `OnBeforeInsertConsumptionJnlLine` | Copy the reference from the passed ProdOrderLine to the consumption journal line through the shared copy procedure. |  | [1] |
| Codeunit "Output Jnl.-Expl. Route" | `OnBeforeOutputItemJnlLineInsert` | Read the Prod. Order Line by the journal line's Order No. and Order Line No. and copy the reference. | Check cheap in-memory conditions (for example an empty Order No.) before the Get on Prod. Order Line, and load only the reference field. | [1] [7] |
| Report "Calc. Consumption" | `OnBeforeInsertItemJnlLine` | Read the Prod. Order Line from the passed ProdOrderComponent and copy the reference. | Load only the reference field when reading the Prod. Order Line. | [1] [7] |
| Table "Item Journal Line" | `OnAfterCopyFromProdOrderLine` | Copy the reference when a user types an output line in the output journal. |  | [1] |
| Table "Item Journal Line" | `OnAfterCopyFromProdOrderComp` | Copy the reference from the component's Prod. Order Line when a user types a consumption line in the consumption journal. | Check cheap in-memory conditions before reading the Prod. Order Line, and load only the reference field. | [1] [7] |
| Codeunit "Item Jnl.-Post Line" | `OnBeforeInsertCapLedgEntry` | Copy the reference from the Item Journal Line to the new Capacity Ledger Entry before insert. | Assign on the var record only; never find and Modify capacity entries after posting. | [2] [6] |
| Codeunit "Item Jnl.-Post Line" | `OnAfterInitItemLedgEntry` | Copy the reference from the Item Journal Line to the new Item Ledger Entry before insert. | Shared with every item posting (sales, purchases, transfers): copy the journal line value as is, so lines without a reference leave the entry empty; no source filter needed. · Assign on the var record only; never find and Modify item ledger entries after posting. | [2] [5] [6] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification explicitly on the Customer Batch Ref. field in all four table extensions; do not leave ToBeClassified or use SystemMetadata. Choose the value that matches the data the reference stores (see open question). [8]

## 6. Tests

1. **production-journal-output-carries-reference** [1] [2] [9] [10]
    - Given A released production order created with library codeunits, full posting setup and routing, with a Customer Batch Ref. on its line
    - When Output is posted from the Production Journal page path
    - Then The capacity ledger entries and, for the last operation, the output item ledger entry carry the reference
2. **production-journal-consumption-carries-reference** [1] [2] [9] [10]
    - Given A released production order with components and a Customer Batch Ref. on its line, complete posting and inventory setup
    - When Consumption is posted from the Production Journal page path
    - Then The consumption item ledger entries carry the reference
3. **explode-routing-output-carries-reference** [1] [2] [9] [10]
    - Given A released production order with a multi-operation routing and a Customer Batch Ref. on its line
    - When An output journal line is created with Explode Routing and posted
    - Then Every capacity ledger entry and the output item ledger entry carry the reference
4. **calc-consumption-carries-reference** [1] [2] [9] [10]
    - Given A released production order with components and a Customer Batch Ref. on its line
    - When Calc. Consumption creates consumption journal lines and they are posted
    - Then The consumption item ledger entries carry the reference
5. **typed-journal-lines-carry-reference** [1] [2] [9] [10]
    - Given A released production order with a Customer Batch Ref. on its line
    - When Output and consumption lines are typed in the output and consumption journals (Item No. validated) and posted
    - Then The journal lines, capacity ledger entries and item ledger entries carry the reference
6. **finished-order-keeps-reference** [3] [9]
    - Given A released production order with a Customer Batch Ref. on its line
    - When The order status is changed to Finished
    - Then The Prod. Order Line with Status Finished carries the same reference
7. **other-item-postings-leave-reference-empty** [5] [9] [10]
    - Given An item and a sales or item journal posting with no production order
    - When The posting creates item ledger entries
    - Then The Customer Batch Ref. on those item ledger entries is empty

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- context: bc-version, countries and application-area are unknown (no repository or app.json); the hot-ledger guidance applies from BC23.
- released-prod-order-lines-page-ext: the page that exposes the field for entry is not covered by BCQuality knowledge; it rests on agent judgment.
- User entry on Prod. Order Line: not covered by BCQuality knowledge; rests on agent judgment.
- OnAfterCopyFromProdOrderComp: named in BCQuality knowledge but its parameter list is not stated; confirm the signature against the base application symbols before implementing.
- Same type and length of the field on all four tables rests on agent judgment; no opened article states it for these field-by-field copies.

## Sources

[1] `microsoft/knowledge/manufacturing/carry-production-order-fields-to-output-and-consumption-journal-lines.md`: Journal-line stage: which paths build output and consumption lines and which event covers each.
    - Add the field to Item Journal Line; no path uses TransferFields, so a matching field number copies nothing.
    - Cover every path users run (typed lines, Production Journal page, Explode Routing, Calc. Consumption) with its own event, reading the value from the order line or component the event passes.
    - Keep the copy in one procedure that all subscribers call.
    - A path the request does not mention is a question for the requester, not one to skip silently.
[2] `microsoft/knowledge/manufacturing/carry-production-journal-fields-to-capacity-and-item-ledger.md`: Ledger stage: copying from the journal line to capacity and item ledger entries during posting.
    - Copy in OnBeforeInsertCapLedgEntry and OnAfterInitItemLedgEntry, both published by Item Jnl.-Post Line.
    - The item ledger subscriber is shared with every item posting; read the journal line's value and leave the entry empty when the line carries none.
    - Do not find capacity or item ledger entries after posting and Modify them.
    - Store the field on the entry only when users filter or report on it there; otherwise a related table keyed by entry number.
[3] `microsoft/knowledge/manufacturing/production-order-status-change-copies-whole-records.md`: Finished-order stage: the reference survives the Released-to-Finished status change.
    - Add the field once on the production order table that owns it and rely on the status change to carry it; no mirror table.
    - Use the OnCopyFrom... events only to change a value on the way.
    - Do not copy the field again in OnAfterTransProdOrder with a Modify; the old rows are deleted.
[4] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choice between a stored field and a related table on Capacity Ledger Entry and Item Ledger Entry (applies from BC23; bc-version unknown).
    - Put optional, sparse or integration attributes in a related table keyed by the ledger Entry No., shown through a FactBox or FlowField.
    - Use a stored tableextension field only when the value must appear as a native list column and is read on almost every access.
[5] `microsoft/knowledge/sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md`: Behaviour of the shared OnAfterInitItemLedgEntry subscriber for non-production postings.
    - Journal lines from other postings leave the field empty, so the entry stays empty; no source filter is needed unless the plan says otherwise.
    - Value entries, warehouse entries and other inventory records are separate stages; extend them only when the plan names them.
    - Do not find item ledger entries after posting and Modify them.
[6] `microsoft/knowledge/scm/post-item-ledger-changes-through-item-journals.md`: Guard against writing ledger entries outside the posting engine.
    - Item ledger entries are created by the owning posting workflow; supported posting events enrich journal/source data within it.
    - Do not independently insert, delete or overwrite posted item ledger transaction rows.
[7] `microsoft/knowledge/performance/guard-event-subscribers-before-db-call.md`: Guards on subscribers that read the Prod. Order Line.
    - Open the subscriber with a cheap in-memory check before any database call.
    - Issue the database call only after the guard passes, with SetLoadFields for the columns the body reads.
[8] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of the new field on four table extensions.
    - A tableextension has no table-level classification to inherit; every Normal field it adds must set its own DataClassification.
    - Do not leave ToBeClassified or under-classify as SystemMetadata; choose the value matching the stored data at definition time.
[9] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for production orders, items and journals.
    - Build fixtures with the test Library codeunits, not hand-rolled Init/Insert.
    - Create prerequisite parents first and Validate foreign keys.
[10] `microsoft/knowledge/testing/given-blocks-must-cover-full-precondition-chain.md`: Completeness of GIVEN blocks for posting tests.
    - Posting tests set up the full posting-group chain and setup records the posting path reads.
    - Do not rely on whatever posting groups happen to exist in the test company.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
