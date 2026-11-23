# Feature design

> Add a user-entered Customer Batch Reference to sales lines and carry it, during sales posting, onto every item ledger entry created for that line.

**Result:** Complete design. **Business process:** Sales document posting (Sales-Post creating item ledger entries through the item journal line and Item Jnl.-Post Line). **Knowledge used:** 8 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Should Customer Batch Reference be Code or Text, and what maximum length does the customer's batch reference need? _(affects: sales-line-ext, item-journal-line-ext, item-ledger-entry-ext)_
2. Which sales document types need the reference: orders and invoices only, or also return orders and credit memos (whose item ledger entries come from return receipts)? This decides which subform pages get the field. _(affects: sales-subform-ext, ship-carries-reference-to-ile)_
3. Must the reference also reach posted shipment/invoice/credit memo/return receipt lines, Sales Line Archive, value entries or warehouse entries? The request names only item ledger entries; if posted lines are added, should Copy Document copy it back? _(affects: sales-line-ext)_
4. Must posting be blocked when an item line has no Customer Batch Reference, or is an empty reference allowed? _(affects: sales-line-ext, batch-ref-posting-subscribers)_
5. Should the field be editable on non-item lines (G/L account, resource, charge), which create no item ledger entries? _(affects: sales-line-ext, sales-subform-ext)_
6. When a line is split across several item ledger entries (lot/serial tracking or partial shipments), should every entry carry the same line-level reference? Confirm with a test on a tracked item. _(affects: batch-ref-posting-subscribers, ship-and-invoice-carries-reference)_
7. What bc-version/runtime does the app target? It decides whether the tooltip lives on the table field (runtime 13.0+) or on each page control. _(affects: sales-subform-ext, item-ledger-entries-page-ext, sales-line-ext)_
8. Does the reference identify a person or only a batch? Confirm CustomerContent versus a more specific classification. _(affects: sales-line-ext, item-journal-line-ext, item-ledger-entry-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Sales Line | Hold the Customer Batch Reference the user types on each sales line; source of the posting path. | Customer Batch Reference (Code[N] (type and length to be confirmed; see open question field-type-and-length)): Set DataClassification explicitly on the field (a tableextension cannot inherit a table-level value); CustomerContent is the likely value, to be confirmed. Define the ToolTip on the table field when the target runtime is 13.0 or later. | [1] [2] [4] [5] |
| 2 | extend | tableextension | Item Journal Line | Carry the reference from the sales line to the item ledger entry during posting. | Customer Batch Reference (Code[N] (type and length to be confirmed; see open question field-type-and-length)): Same type and length as the Sales Line field so the event copy never truncates; explicit DataClassification. | [2] [4] |
| 3 | extend | tableextension | Item Ledger Entry | Store the reference on each item ledger entry created for the sales line. | Customer Batch Reference (Code[N] (type and length to be confirmed; see open question field-type-and-length)): Same type and length as the source field; Editable = false; explicit DataClassification. | [2] [4] |
| 4 | create | codeunit | Batch Ref. Item Posting (new) | Event subscribers that copy the reference Sales Line -> Item Journal Line -> Item Ledger Entry inside the posting transaction. |  | [2] [3] |
| 5 | extend | pageextension | Sales Order Subform (plus the other sales subforms named in open question document-types) | Let the user type the reference on the sales line. |  | [1] [5] [6] |
| 6 | extend | pageextension | Item Ledger Entries | Show the reference (read-only) on the item ledger entries for traceability lookups. |  | [1] [5] [6] |

## 3. How the data flows

- **User** → **Sales Line.Customer Batch Reference**: entered by the user. Typed on the sales subform page extension. [1]
- **Sales Line** → **Item Journal Line**: copied in an event subscriber. Sales-Post builds the item journal line with CopyFromSalesLine, which copies named fields only; subscriber to OnAfterCopyItemJnlLineFromSalesLine assigns the value. [2] [1]
- **Item Journal Line** → **Item Ledger Entry**: copied in an event subscriber. Subscriber to OnAfterInitItemLedgEntry sets the value on the new entry before it is inserted, so it is written as part of posting with no extra Modify. [2] [3]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Item Journal Line" | `OnAfterCopyItemJnlLineFromSalesLine` | Copy Customer Batch Reference from the Sales Line to the Item Journal Line built by Sales-Post. |  | [2] |
| Codeunit "Item Jnl.-Post Line" | `OnAfterInitItemLedgEntry` | Copy Customer Batch Reference from the Item Journal Line to the new Item Ledger Entry before insert. | No source-document filter: item journals posted directly and other documents reach this subscriber with an empty journal field, so the entry stays empty. · Assign only the custom field; do not change quantity, cost or application fields of the entry. | [2] [3] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification explicitly on all three new table-extension fields (no table-level inheritance in a tableextension); never leave ToBeClassified or use SystemMetadata for a customer-supplied reference. [4]
- **permissions**: Add the new subscriber codeunit and other new objects to the app's permission set entries, as the full-path plan requires for new objects. [1]

## 6. Tests

1. **ship-carries-reference-to-ile** [2] [7] [8]
    - Given A customer and item created with LibrarySales/LibraryInventory, and a sales order with one item line whose Customer Batch Reference is set to a generated value.
    - When The order is posted with Ship.
    - Then The item ledger entry for the shipment line (Document No. = posted shipment, Document Line No. = line) has the same Customer Batch Reference.
2. **ship-and-invoice-carries-reference** [2] [7]
    - Given A library-created sales order with one item line carrying a reference.
    - When The order is posted with Ship and Invoice.
    - Then Every item ledger entry created for that line carries the line's reference.
3. **each-line-keeps-own-reference** [2] [7] [8]
    - Given A library-created sales order with two item lines carrying different references.
    - When The order is posted.
    - Then Each line's item ledger entries carry that line's reference, not the other line's.
4. **item-journal-posting-leaves-reference-empty** [2] [7]
    - Given An item journal line created with LibraryInventory, not from a sales line.
    - When The item journal is posted.
    - Then The resulting item ledger entry has an empty Customer Batch Reference.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version is unknown (no repository or app.json supplied); all cited articles declare bc-version [all], and the tooltip placement depends on it (open question target-runtime).
- countries and application-area are unknown; all cited articles declare countries [w1] and application-area [all].
- Permission-set membership: no repository was supplied, so it is unknown whether the app already has a permission set to extend.

## Sources

[1] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Mapping which posting stages the field must reach and the extension step per stage; page extensions and permission entries per stage; post-and-read-back test.
    - Decide which stages the field must reach and plan one step per stage before writing code.
    - Item Ledger Entry is reached by a field-by-field copy into Item Journal Line, then into the entry: two subscribers.
    - Name the page extensions that show the field, the permission set entries for new objects, and a test that posts a document and reads the value back from every target.
    - Do not plan to fill ledger entries after posting by finding and modifying them.
    - If the field is mirrored on posted tables, decide whether Copy Document should copy it back.
[2] `microsoft/knowledge/sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md`: Core mechanism: Sales Line -> Item Journal Line -> Item Ledger Entry via two events.
    - Add the field to Item Journal Line and Item Ledger Entry and subscribe to OnAfterCopyItemJnlLineFromSalesLine and OnAfterInitItemLedgEntry.
    - Copy the value into the new item ledger entry before it is inserted, as part of posting.
    - No source-document filter is needed: other item postings leave the field empty.
    - Value entries, warehouse entries and other inventory records are separate stages; extend them only when the plan names them.
    - Do not find item ledger entries after posting and Modify them, and do not rely on posted sales lines to reach the item ledger.
[3] `microsoft/knowledge/scm/post-item-ledger-changes-through-item-journals.md`: Confirms that enriching the item journal line through supported posting events stays within the owning sales posting workflow.
    - Item ledger entries are created only by the posting workflow; never insert or overwrite posted quantity, remaining quantity, application or cost fields.
    - Supported posting events may enrich validated journal data within the owning workflow; an extension-owned annotation field is outside the transaction-state concern.
[4] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification on the new table-extension fields.
    - Every Normal field added by a tableextension must set its own DataClassification.
    - ToBeClassified is not a safe default; do not under-classify customer data as SystemMetadata.
    - Choose the classification at field definition time.
[5] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltip placement for the new field on the sales subform and item ledger entries page.
    - On runtime 13.0 or later, define the tooltip on the table field and omit duplicate page-level tooltips.
    - Before runtime 13.0, user-facing page fields need page-level tooltips.
    - Tooltip text must say what the value is used for, without inventing behavior.
[6] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Whether page fields can inherit the table-field tooltip.
    - A bound page field inherits the source field's ToolTip only on runtime 13.0 (BC24) or later.
    - A control with neither inline nor inherited tooltip is a real gap.
[7] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for customers, items, sales documents and item journals.
    - Create fixtures with the Library codeunits (LibrarySales, LibraryInventory, LibraryRandom), not hand-rolled Init/Insert.
    - Create parents before dependent records and Validate foreign keys.
[8] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Test values for the reference and quantities.
    - Do not rely on pre-existing business records; create what the test needs.
    - Generate incidental values such as the reference; keep scenario-defining values explicit.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
