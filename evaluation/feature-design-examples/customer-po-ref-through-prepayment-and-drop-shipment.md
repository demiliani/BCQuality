# Feature design

> Sales order lines carry the customer's PO reference. When we buy the goods as a drop shipment or special order, the reference must be on the vendor purchase lines, whether buyers use Get Sales Order on the purchase order or the requisition worksheet. The header Delivery Window must also show on customer ledger entries for prepayment invoices, not just normal invoices.

**Result:** Complete design. **Business process:** Sales order purchasing for drop shipments and special orders (purchase order Get Sales Order / Get Special Order and requisition worksheet), and sales prepayment invoice posting to the customer ledger. **Knowledge used:** 10 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What are the name, field number, type and length of the existing customer PO reference field on Sales Line? The Requisition Line and Purchase Line fields must match it. _(affects: requisition-line-po-ref, purchase-line-po-ref)_
2. Confirm that Delivery Window already exists on Sales Header, Gen. Journal Line and Cust. Ledger Entry with an OnAfterCopyGenJnlLineFromSalesHeader / OnAfterCopyCustLedgerEntryFromGenJnlLine pair for normal invoices, and in which codeunit. _(affects: gen-journal-line-delivery-window, cust-ledger-entry-delivery-window, prepayment-delivery-window-codeunit)_
3. Should prepayment credit memo customer entries also carry Delivery Window? The request names prepayment invoices only. _(affects: prepayment-delivery-window-codeunit, prepayment-invoice-delivery-window)_
4. Must Delivery Window also reach the prepayment G/L entries? That needs a subscriber to OnAfterCopyGenJnlLineFromSalesHeaderPrepmt. _(affects: prepayment-delivery-window-codeunit)_
5. Do buyers also use the Create Purchase Order action on the sales order (Purch. Doc. From Sales Doc.)? It builds requisition lines without Get Sales Orders and is not covered by this design. _(affects: po-ref-linking-codeunit)_
6. Must the customer PO reference go further than the open purchase line, for example to posted purchase receipts and invoices, purchase archives or the vendor ledger? _(affects: purchase-line-po-ref)_
7. Should the reference be shown and editable on the purchase order subform and the requisition worksheet? The request only requires it on the purchase lines. _(affects: purchase-line-po-ref, requisition-line-po-ref)_
8. Should existing open drop shipment or special order purchase lines, or already posted prepayment customer entries, be backfilled? _(affects: purchase-line-po-ref, cust-ledger-entry-delivery-window)_
9. Which Business Central version and countries does the app target? The hot-ledger guidance applies from BC23. _(affects: cust-ledger-entry-delivery-window)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Requisition Line | Hold the customer PO reference between Get Sales Orders and Req. Wksh.-Make Order, because the purchase line on the requisition route sees only the requisition line, not the sales line. | Customer PO Ref. (Same type and length as the existing Sales Line field): DataClassification = CustomerContent; exact type, length and field number to be confirmed against the existing Sales Line field. | [1] [7] |
| 2 | extend | tableextension | Purchase Line | Store the customer PO reference on drop shipment and special order purchase lines. A matching field number with Sales Line copies nothing on its own; the value is assigned by event subscribers. | Customer PO Ref. (Same type and length as the existing Sales Line field): DataClassification = CustomerContent. | [1] [7] |
| 3 | extend | tableextension | Gen. Journal Line | Carrier of Delivery Window from Sales Header to Cust. Ledger Entry. The request implies normal invoices already carry it, so reuse the existing field; create it only if it does not exist. | Delivery Window (Same type as the Sales Header field): DataClassification = CustomerContent. Expected to exist already. | [3] [7] |
| 4 | extend | tableextension | Cust. Ledger Entry | Delivery Window on the customer entry, filled during posting before insert. Stored on the ledger because users must see it on customer ledger entries; reuse the existing field that normal invoices already fill. | Delivery Window (Same type as the Sales Header field): Non-editable, DataClassification = CustomerContent. Expected to exist already. | [3] [5] [7] |
| 5 | create | codeunit | Customer PO Ref. Linking | Event subscribers that copy the customer PO reference from the sales line to the purchase line on the purchase-order route and through the requisition line on the worksheet route. |  | [1] |
| 6 | extend | codeunit | Existing Delivery Window posting subscriber codeunit | Add a subscriber for the prepayment customer journal line next to the existing normal-invoice subscriber. The existing Gen. Journal Line to Cust. Ledger Entry subscriber then carries the value on. |  | [2] [3] |

## 3. How the data flows

- **Sales Line.Customer PO Ref.** → **Purchase Line.Customer PO Ref. (Get Sales Order / Get Special Order on the purchase order)**: copied in an event subscriber. OnAfterTransfldsFromSalesToPurchLine on Copy Document Mgt., raised before the purchase line is inserted; one subscriber covers drop shipments and special orders. [1]
- **Sales Line.Customer PO Ref.** → **Requisition Line.Customer PO Ref. (Get Sales Orders on the requisition worksheet)**: copied in an event subscriber. OnBeforeInsertReqWkshLine on report Get Sales Orders; assign without Modify. [1]
- **Requisition Line.Customer PO Ref.** → **Purchase Line.Customer PO Ref. (Carry Out Action Message / Req. Wksh.-Make Order)**: copied in an event subscriber. OnAfterInitPurchOrderLine on Req. Wksh.-Make Order; runs before insert, so assign without Modify. [1]
- **Sales Header.Delivery Window** → **Gen. Journal Line.Delivery Window (prepayment customer line)**: copied in an event subscriber. OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost on Gen. Journal Line. OnAfterCopyGenJnlLineFromSalesHeader is never raised by Sales-Post Prepayments. [2]
- **Gen. Journal Line.Delivery Window** → **Cust. Ledger Entry.Delivery Window**: copied in an event subscriber. Existing OnAfterCopyCustLedgerEntryFromGenJnlLine subscriber, shared with normal invoices; assigned while the entry is initialized, before insert. [3] [2]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Copy Document Mgt." | `OnAfterTransfldsFromSalesToPurchLine` | Copy FromSalesLine.Customer PO Ref. to ToPurchaseLine for drop shipments (Get Sales Order) and special orders (Get Special Order). | Assign only; no Modify, the event runs before the purchase line is inserted. | [1] |
| Report "Get Sales Orders" | `OnBeforeInsertReqWkshLine` | Copy SalesLine.Customer PO Ref. to ReqLine. | Assign only; no Modify, the event runs before insert. | [1] |
| Codeunit "Req. Wksh.-Make Order" | `OnAfterInitPurchOrderLine` | Copy RequisitionLine.Customer PO Ref. to PurchaseLine. | Assign only; no Modify, the event runs before insert. | [1] |
| Table "Gen. Journal Line" | `OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost` | Copy SalesHeader.Delivery Window to the prepayment customer journal line. | Assign during the copy; never find and Modify the posted Cust. Ledger Entry after posting. | [2] [3] [6] |
| Table "Cust. Ledger Entry" | `OnAfterCopyCustLedgerEntryFromGenJnlLine` | Existing subscriber; copies Delivery Window from the journal line to the customer entry. Reused unchanged for prepayment entries; create it only if it does not exist. | Assign before insert; no Modify. | [3] [2] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification = CustomerContent on every new table extension field (Requisition Line, Purchase Line, and Gen. Journal Line / Cust. Ledger Entry if they must be created); a tableextension field cannot inherit a table-level value. [7]
- **permissions**: No new tables, pages or exposed objects are designed, so no permission set entry is planned. Revisit if a page or new table is added. agent judgment
- **upgrade**: No upgrade step: open drop shipment or special order purchase lines and existing prepayment customer entries are not backfilled. Confirm with the requester. agent judgment

## 6. Tests

1. **drop-shipment-get-sales-order** [1] [8] [10]
    - Given A customer, item and vendor created with LibrarySales/LibraryPurchase/LibraryInventory; a sales order line marked Drop Shipment with a random Customer PO Ref.; a purchase order for the vendor with the same Sell-to Customer No.
    - When Get Sales Order (Purch.-Get Drop Shpt.) is run on the purchase order
    - Then The created purchase line has the sales line's Customer PO Ref.
2. **special-order-get-special-order** [1] [8] [10]
    - Given A sales order line marked Special Order with a random Customer PO Ref., built with the test libraries; a purchase order for the vendor
    - When Get Special Order is run on the purchase order
    - Then The created purchase line has the sales line's Customer PO Ref.
3. **drop-shipment-requisition-worksheet** [1] [8]
    - Given A drop shipment sales order line with a random Customer PO Ref. and a requisition worksheet batch
    - When Get Sales Orders is run on the worksheet and the line is carried out (Req. Wksh.-Make Order)
    - Then The requisition line and the created purchase line both have the sales line's Customer PO Ref.
4. **special-order-requisition-worksheet** [1] [8]
    - Given A special order sales order line with a random Customer PO Ref. and a requisition worksheet batch
    - When Get Sales Orders is run on the worksheet and the line is carried out (Req. Wksh.-Make Order)
    - Then The created purchase line has the sales line's Customer PO Ref.
5. **prepayment-invoice-delivery-window** [2] [9] [8]
    - Given A sales order with a prepayment % and a Delivery Window, with the full posting chain set up: customer and gen. posting groups, VAT posting setup and the prepayment accounts on General Posting Setup
    - When The prepayment invoice is posted (Sales-Post Prepayments)
    - Then The Cust. Ledger Entry for the prepayment invoice has the order's Delivery Window
6. **final-invoice-after-prepayment** [2] [3] [9]
    - Given The same prepayment order after its prepayment invoice was posted
    - When The order is shipped and invoiced with Sales-Post
    - Then The final invoice's Cust. Ledger Entry still has the Delivery Window, proving the normal-invoice subscriber and the prepayment subscriber coexist

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Target bc-version, countries and application-area are unknown; no repository was supplied, so existing objects could not be confirmed.
- Permission set decision rests on the agent's judgment; not covered by BCQuality knowledge.
- No-backfill decision for existing open lines and posted entries rests on the agent's judgment; not covered by BCQuality knowledge.

## Sources

[1] `microsoft/knowledge/sales-purchase/carry-sales-line-fields-to-drop-shipment-and-special-order-purchase-lines.md`: Both routes from sales lines to drop shipment and special order purchase lines; the three subscribers, the Requisition Line field and the route tests.
    - The linked purchase line is never created with TransferFields; a matching field number on Purchase Line copies nothing.
    - Purchase order route (Get Sales Order and Get Special Order): subscribe to OnAfterTransfldsFromSalesToPurchLine and copy FromSalesLine to ToPurchaseLine; one subscriber covers both.
    - Requisition route: add the field to Requisition Line, copy it in OnBeforeInsertReqWkshLine on Get Sales Orders, then to the purchase line in OnAfterInitPurchOrderLine on Req. Wksh.-Make Order; both run before insert, so assign without Modify.
    - Do not subscribe only to OnAfterPurchaseLineInsert on Purch.-Get Drop Shpt. and Modify the line: it covers one route and adds a write per line.
    - The Create Purchase Order action on a sales order (Purch. Doc. From Sales Doc.) builds requisition lines without Get Sales Orders; if users rely on it, test that path separately.
    - Test both routes, for a drop shipment and for a special order.
[2] `microsoft/knowledge/sales-purchase/prepayment-posting-uses-its-own-copy-events.md`: Delivery Window on prepayment invoice customer entries: the prepayment-specific copy event and the prepayment test.
    - Sales-Post Prepayments never calls CopyFromSalesHeader, so OnAfterCopyGenJnlLineFromSalesHeader does not run for prepayments.
    - For a header field on the customer entry, subscribe to OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost next to the normal-invoice subscriber; the existing OnAfterCopyCustLedgerEntryFromGenJnlLine subscriber carries it on.
    - If the value must also reach the prepayment G/L entries, subscribe to OnAfterCopyGenJnlLineFromSalesHeaderPrepmt as well.
    - Include a prepayment order in the tests whenever the feature touches posted invoices or ledger entries.
[3] `microsoft/knowledge/sales-purchase/carry-sales-fields-to-customer-ledger-through-the-journal-line.md`: The Gen. Journal Line and Cust. Ledger Entry fields and the journal-line-to-entry subscriber the prepayment flow reuses.
    - Add the field to Gen. Journal Line and Cust. Ledger Entry and copy it in the two copy events while the entry is initialized, before insert.
    - Store the field on the ledger entry only when users must see or filter it as a native list column or it is read on almost every access; otherwise prefer a related table keyed by entry number.
    - Do not subscribe to OnAfterPostSalesDoc and Modify the customer entry: it runs after the posting commit and edits a posted ledger entry outside the posting engine.
[4] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Stage planning for sales fields through posting; source of the open questions on posted documents, archives, pages and Copy Document.
    - Decide which stages the field must reach and plan one step per stage; each stage uses a different mechanism.
    - For each stage name the page extensions that show the field, permission set entries for new objects, and a test that posts and reads the value back from every target.
    - Do not plan to fill ledger entries after posting by finding and modifying them.
[5] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Justifies keeping Delivery Window as a stored field on Cust. Ledger Entry. Applies from BC23; the target version is unknown.
    - Put optional, sparse or integration attributes in a related table keyed by the ledger entry number.
    - Use a tableextension stored field only when the value must appear as a native list column and is read on almost every access.
[6] `microsoft/knowledge/finance/do-not-modify-or-delete-posted-ledger-entries.md`: Guard on the prepayment subscriber: the value is set during posting, not patched onto the posted customer entry.
    - Do not persist changes to posted financial records outside the supported posting and correction workflows; a subscriber inside a supported workflow is judged by the fields it changes.
[7] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Classification of every new table extension field.
    - A tableextension field cannot inherit a table-level DataClassification; every Normal field it adds must set its own.
    - Classify customer data as CustomerContent; do not leave it ToBeClassified or mark it SystemMetadata.
[8] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for all tests.
    - Build customers, vendors, items and documents with the Library codeunits (LibrarySales, LibraryPurchase, LibraryInventory, LibraryERM, LibraryRandom), parents first, validating foreign keys.
[9] `microsoft/knowledge/testing/given-blocks-must-cover-full-precondition-chain.md`: Precondition chain for the prepayment posting tests.
    - A posting test's GIVEN must set up the full posting-group chain and the setup records the specific posting path reads, not just the sales header.
[10] `microsoft/knowledge/testing/ui-handlers-in-tests.md`: Tests that drive Get Sales Order or Get Special Order through the purchase order page.
    - Every UI call on the executed path needs a matching handler in HandlerFunctions, and every nonoptional listed handler must execute.
    - Each executed handler must contribute meaningful evidence; assert the semantic postcondition.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
