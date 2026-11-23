# Feature design

> Transfer orders need a Carrier Booking Reference entered by the warehouse planner. It must be visible on posted transfer shipments and posted transfer receipts, and on the item ledger entries created when the transfer is shipped and received.

**Result:** Complete design. **Business process:** Transfer order posting (two-step shipment and receipt through TransferOrder-Post Shipment and TransferOrder-Post Receipt) and the item ledger entries it creates. **Knowledge used:** 13 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What data type and maximum length does a carrier booking reference need (Code or Text, how many characters), and does it identify a person or only a shipment? _(affects: transfer-header-ext, transfer-shipment-header-ext, transfer-receipt-header-ext, item-journal-line-ext, item-ledger-entry-ext)_
2. Must users see and filter the reference as a column on the Item Ledger Entries list, or is it enough to show it in a FactBox? The answer decides between a stored Item Ledger Entry field and a related table keyed by Entry No. _(affects: item-ledger-entry-ext, item-ledger-entries-page-ext)_
3. Are direct transfers (posted by TransferOrder-Post Transfer) in scope? If so, Direct Trans. Header, Direct Trans. Line and the direct-transfer item journal event must be added. _(affects: carrier-ref-transfer-posting)_
4. Should the reference also appear on Transfer Shipment Line and Transfer Receipt Line, or only on the posted headers as requested? _(affects: transfer-shipment-header-ext, transfer-receipt-header-ext, carrier-ref-transfer-posting)_
5. May the planner change the reference after the transfer is released or partly shipped? The receipt copies the Transfer Header value at receipt time, so a change between shipment and receipt gives the two legs different values. _(affects: transfer-order-page-ext, transfer-header-ext)_
6. Are locations that require warehouse shipment or receipt in scope? Those post through the warehouse workflow, which invokes the same transfer codeunits; confirm whether the field must also appear on warehouse documents. _(affects: carrier-ref-transfer-posting)_
7. Which Business Central version does the app target? It decides tooltip inheritance (BC24) and whether the hot-ledger guidance (BC23) applies. _(affects: transfer-order-page-ext, posted-transfer-shipment-page-ext, posted-transfer-receipt-page-ext, item-ledger-entries-page-ext, item-ledger-entry-ext)_
8. Should the reference also show on list pages (Transfer Orders, Posted Transfer Shipments, Posted Transfer Receipts)? _(affects: transfer-order-page-ext, posted-transfer-shipment-page-ext, posted-transfer-receipt-page-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Transfer Header | Holds the Carrier Booking Reference the warehouse planner enters on the transfer order. Header-level field, because the request attaches the reference to the transfer order, not to individual lines. | Carrier Booking Ref. (Code or Text; length to be confirmed (q-field-type)): DataClassification set on the field (a tableextension has no table-level value to inherit); CustomerContent unless the requester says the value identifies a person. On BC24/runtime 13.0 or later, define the ToolTip here so bound page fields inherit it. | [1] [6] [7] [8] |
| 2 | extend | tableextension | Transfer Shipment Header | Stores the reference on the posted transfer shipment. Same field definition as on Transfer Header; the matching field number is not what copies it - CopyFromTransferHeader copies named fields only, so a subscriber fills it. | Carrier Booking Ref. (Code or Text; length to be confirmed (q-field-type)): Editable = false; own DataClassification. | [1] [6] |
| 3 | extend | tableextension | Transfer Receipt Header | Stores the reference on the posted transfer receipt, filled by a subscriber to the table's own OnAfterCopyFromTransferHeader event. | Carrier Booking Ref. (Code or Text; length to be confirmed (q-field-type)): Editable = false; own DataClassification. | [1] [6] |
| 4 | extend | tableextension | Item Journal Line | Carries the reference from the transfer posting codeunits to Item Jnl.-Post Line. Item Journal Line has no copy method or event for a Transfer Line, so the transfer codeunit events fill it. | Carrier Booking Ref. (Code or Text; length to be confirmed (q-field-type)): Own DataClassification. Not shown on journal pages unless the requester asks. | [2] [3] [6] |
| 5 | extend | tableextension | Item Ledger Entry | Stores the reference on the item ledger entries created by the shipment and receipt (from-location, in-transit and to-location entries). Stored field chosen because the request requires the value to be visible on the entries; the performance article (applies from BC23) prefers a related table keyed by Entry No. unless the value must appear as a native list column or is read on almost every access, so the storage choice is confirmed in q-ile-storage. | Carrier Booking Ref. (Code or Text; length to be confirmed (q-field-type)): Editable = false; own DataClassification. | [2] [3] [5] [6] |
| 6 | extend | pageextension | Transfer Order | Lets the warehouse planner enter the Carrier Booking Reference on the transfer order. No business logic on the page. Tooltip inherited from the table field on runtime 13.0 or later; a page-level ToolTip is needed on earlier runtimes. |  | [7] [8] [12] |
| 7 | extend | pageextension | Posted Transfer Shipment | Shows the reference on the posted transfer shipment (read-only). |  | [7] [8] [12] |
| 8 | extend | pageextension | Posted Transfer Receipt | Shows the reference on the posted transfer receipt (read-only). |  | [7] [8] [12] |
| 9 | extend | pageextension | Item Ledger Entries | Shows the reference as a column on the item ledger entries list. If q-ile-storage chooses a related table instead, this becomes a FactBox or FlowField-based display. |  | [5] [7] [8] [12] |
| 10 | create | codeunit | Carrier Ref. Transfer Posting | Holds the event subscribers that carry the reference through transfer posting: posted header copy events, the shipment and receipt item journal line events, and the item ledger entry initialization event. Writes only to records not yet inserted; never modifies posted documents or ledger entries after posting. |  | [1] [2] [3] [4] |

## 3. How the data flows

- **Warehouse planner** → **Transfer Header."Carrier Booking Ref."**: entered by the user. Entered on the Transfer Order page. [12]
- **Transfer Header** → **Transfer Shipment Header**: copied in an event subscriber. OnAfterCopyFromTransferHeader on Transfer Shipment Header, raised by CopyFromTransferHeader in TransferOrder-Post Shipment before the posted header is inserted. Assign without Modify. [1]
- **Transfer Header** → **Transfer Receipt Header**: copied in an event subscriber. OnAfterCopyFromTransferHeader on Transfer Receipt Header, raised in TransferOrder-Post Receipt before insert. Assign without Modify. [1]
- **Transfer Shipment Header (shipment leg)** → **Item Journal Line**: copied in an event subscriber. OnAfterCreateItemJnlLine on TransferOrder-Post Shipment passes var ItemJournalLine, TransferLine, TransferShipmentHeader and TransferShipmentLine; copy the header-level value from the TransferShipmentHeader parameter. [2]
- **Transfer Receipt Header (receipt leg)** → **Item Journal Line**: copied in an event subscriber. OnBeforePostItemJournalLine on TransferOrder-Post Receipt passes var ItemJournalLine, TransferLine, TransferReceiptHeader and TransferReceiptLine; copy the header-level value from the TransferReceiptHeader parameter. [2]
- **Item Journal Line** → **Item Ledger Entry**: copied in an event subscriber. OnAfterInitItemLedgEntry on Item Jnl.-Post Line runs for both entries InsertTransferEntry creates per journal line, so the from-location, in-transit and to-location entries all receive the value during posting. Other item postings leave the journal field empty, so their entries stay empty. [2] [3]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Transfer Shipment Header" | `OnAfterCopyFromTransferHeader` | Copy the reference from Transfer Header to the posted shipment header. | Assign the field only; the record is not inserted yet, so do not call Modify. · Do not patch the posted header after posting from OnAfterTransferOrderPostShipment. | [1] |
| Table "Transfer Receipt Header" | `OnAfterCopyFromTransferHeader` | Copy the reference from Transfer Header to the posted receipt header. | Assign the field only; do not call Modify. | [1] |
| Codeunit "TransferOrder-Post Shipment" | `OnAfterCreateItemJnlLine` | Copy the reference into the shipment leg's item journal line. | Decide here, not in OnAfterInitItemLedgEntry, if only some legs should carry the value. | [2] |
| Codeunit "TransferOrder-Post Receipt" | `OnBeforePostItemJournalLine` | Copy the reference into the receipt leg's item journal line. | Decide here, not in OnAfterInitItemLedgEntry, if only some legs should carry the value. | [2] |
| Codeunit "Item Jnl.-Post Line" | `OnAfterInitItemLedgEntry` | Copy the reference from the item journal line to each new item ledger entry before it is inserted. | Copy unconditionally from the journal line; do not filter by source document. · Never find and Modify item ledger entries after posting. | [2] [3] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification on the Carrier Booking Ref. field in each of the five table extensions; none may be left ToBeClassified or set to SystemMetadata if the value holds customer data. [6]

## 6. Tests

1. **planner-can-enter-reference-on-transfer-order** [13] [9] [10]
    - Given An open transfer order created with the library codeunits.
    - When The Transfer Order test page is opened with OpenEdit.
    - Then The Carrier Booking Ref. field is Editable() and a value entered is stored on Transfer Header.
2. **shipment-carries-reference-to-posted-shipment-and-ledger** [1] [2] [4] [9] [11] [10]
    - Given From, to and in-transit locations, an item with inventory at the from-location, and a transfer order with a random Carrier Booking Ref., all built with library codeunits (full posting setup included).
    - When The shipment is posted through TransferOrder-Post Shipment.
    - Then The Transfer Shipment Header and every item ledger entry posted for the shipment (from-location and in-transit) carry the reference.
3. **receipt-carries-reference-to-posted-receipt-and-ledger** [1] [2] [4] [9] [11] [10]
    - Given A shipped transfer order with a Carrier Booking Ref., set up as in the shipment test.
    - When The receipt is posted through TransferOrder-Post Receipt.
    - Then The Transfer Receipt Header and every item ledger entry posted for the receipt (in-transit and to-location) carry the reference.
4. **other-item-postings-leave-reference-empty** [3] [9] [10]
    - Given An item and an item journal line posted directly, not from a transfer.
    - When The item journal is posted.
    - Then The resulting item ledger entry has an empty Carrier Booking Ref., proving the OnAfterInitItemLedgEntry subscriber copies only what the journal line carries.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined from the request; no repository was supplied.
- Reading the header-level value from the TransferShipmentHeader and TransferReceiptHeader parameters of the item journal line events assumes the posted header was filled by the copy subscriber before the lines are posted; this rests on agent judgment and is verified by the shipment and receipt tests.
- No permission set is designed: the feature adds only table and page extensions and a subscriber codeunit, and no opened article requires an entry for them; this rests on agent judgment.

## Sources

[1] `microsoft/knowledge/warehouse/posted-transfer-documents-copy-fields-one-by-one.md`: Copying the reference to Transfer Shipment Header and Transfer Receipt Header, and the direct-transfer events if those are in scope.
    - Transfer posting fills posted headers and lines with CopyFromTransferHeader/CopyFromTransferLine, which copy named fields one by one; a matching field number does not copy a custom field.
    - Add the field to each posted transfer table the plan needs and copy it in a subscriber to that table's own OnAfterCopyFromTransferHeader (headers) or OnAfterCopyFromTransferLine (lines) event.
    - When direct transfers are in scope, also subscribe to OnAfterCopyFromTransferLine on Direct Trans. Line and OnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert on TransferOrder-Post Transfer.
    - The record is not inserted when these events run: assign the field without Modify.
    - Do not patch the posted header after posting from OnAfterTransferOrderPostShipment.
[2] `microsoft/knowledge/warehouse/carry-transfer-line-fields-to-item-ledger.md`: Carrying the reference from transfer posting into Item Journal Line and on to Item Ledger Entry for the shipment and receipt legs.
    - Item Journal Line has no copy method or event for a Transfer Line; use the posting codeunit events: OnAfterCreateItemJnlLine on TransferOrder-Post Shipment, OnBeforePostItemJournalLine on TransferOrder-Post Receipt, OnAfterCreateItemJnlLine on TransferOrder-Post Transfer for direct transfers.
    - Add the field to Item Journal Line and Item Ledger Entry and copy journal line to entry in OnAfterInitItemLedgEntry.
    - If only some legs should carry the value, decide it in the journal-line subscribers, not in OnAfterInitItemLedgEntry.
    - Do not look for OnAfterCopyItemJnlLineFromTransferLine and do not patch item ledger entries after posting.
[3] `microsoft/knowledge/sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md`: The OnAfterInitItemLedgEntry subscriber shape and the rule that other item postings leave the field empty.
    - OnAfterInitItemLedgEntry on Item Jnl.-Post Line runs after the entry is initialized and before it is inserted; copy from the journal line there.
    - Store the field on the ledger entry only when users must see or filter it as a native list column or it is read on almost every access; otherwise prefer a related table.
    - Other postings reach the same subscriber with an empty journal field, so no source-document filter is needed unless the plan says otherwise.
    - Value entries and warehouse entries are separate stages; extend them only when the plan names them.
    - Do not find and Modify item ledger entries after posting.
[4] `microsoft/knowledge/scm/post-transfers-through-shipment-and-receipt-codeunits.md`: Keeping posting inside the standard transfer codeunits and driving the tests through them.
    - Non-direct transfer orders post through TransferOrder-Post Shipment and TransferOrder-Post Receipt with the actual Transfer Header.
    - Required warehouse shipment or receipt enters the warehouse posting workflow, which invokes the transfer poster with its real source context.
    - Metadata enrichment within the normal shipment/receipt workflow is distinct from replacing the posting operation; ad-hoc item postings cannot substitute for transfer posting.
    - Transfers do not have one fixed item-entry count; tests must not assume one.
[5] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choosing a stored field on Item Ledger Entry versus a related table (applies from BC23).
    - Put optional, sparse or integration attributes in a related table keyed by the ledger Entry No., shown through a FactBox or FlowField.
    - Use a tableextension stored field on a hot ledger such as Item Ledger Entry only when the value must appear as a native list column and is read on almost every access.
[6] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: DataClassification on every new extension field.
    - A tableextension has no table-level classification to inherit; every Normal field it adds must set its own DataClassification.
    - Choose the value matching the data actually stored; ToBeClassified is a placeholder, and SystemMetadata for customer data is an under-classification.
[7] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltip for the field on the four page extensions.
    - On runtime 13.0 (BC24) or later, define the ToolTip on the table field and omit duplicate page-level ToolTips.
    - Before runtime 13.0, user-facing page fields need page-level ToolTips.
    - Describe what the value is used for; do not invent effects, defaults or constraints.
[8] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Tooltip inheritance on bound page fields (applies from BC24).
    - A page field bound to a table field inherits the source field's ToolTip when the control declares none, on runtime 13.0 or later.
    - Do not add a duplicate page-level ToolTip when one can be inherited.
[9] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Building locations, items, inventory and transfer orders in tests.
    - Use the test Library codeunits to create fixtures, not hand-rolled Init/Insert.
    - Create parents before dependents and Validate foreign-key fields.
[10] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunit.
    - Put [FEATURE] once on the codeunit and [SCENARIO], [GIVEN], [WHEN], [THEN] in each test.
[11] `microsoft/knowledge/testing/given-blocks-must-cover-full-precondition-chain.md`: Preconditions of the posting tests.
    - A posting test's GIVEN sets up the full chain the posting path reads (posting setup, locations, dates), not just the primary record.
[12] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Planning every stage the field reaches, with page extensions and a read-back test per target.
    - Decide which stages the field must reach before coding and plan one step per stage.
    - For each stage name the page extensions that show the field and a test that posts and reads the value back from every target.
    - Do not plan to fill ledger entries after posting by finding and modifying them.
[13] `microsoft/knowledge/testing/use-testpage-editable-to-verify-field-editability.md`: Testing that the planner can edit the field on the Transfer Order page.
    - Open the TestPage with OpenEdit and assert TestPageField.Editable(); do not assert Enabled() for an editability claim.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
