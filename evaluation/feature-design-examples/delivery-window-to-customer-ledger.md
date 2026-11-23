# Feature design

> Add a Delivery Window code that the order taker selects on sales orders, carry it to posted shipments and posted invoices, and to customer ledger entries so collections can filter by it. Business process: sales order entry and sales posting (document to posted documents and customer ledger).

**Result:** Complete design. **Business process:** sales posting. **Knowledge used:** 13 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Is Delivery Window a new list of codes maintained in this app, or must it come from an existing table (for example a shipping-related setup)? Who maintains the codes and what attributes, besides code and description, does a delivery window carry? _(affects: delivery-window-table, delivery-windows-page, sales-header-ext)_
2. Should the field be available only on sales orders, or also on quotes, blanket orders, invoices, credit memos and return orders entered directly? _(affects: sales-header-ext, sales-order-page-ext, credit-memo-carries-to-posted-and-ledger)_
3. The request names posted shipments and invoices only. Knowledge requires mirroring on all four posted headers and the archive unless a document type never needs it: should credit memos, return receipts and archives carry and show the value, or should they be explicitly excluded? _(affects: sales-cr-memo-header-ext, return-receipt-header-ext, sales-header-archive-ext)_
4. Is Delivery Window mandatory before release or posting, and should it default from the customer or ship-to address? _(affects: sales-header-ext, order-taker-selects-delivery-window)_
5. May the order taker change the code after the order is released or partially shipped, and if so which posted documents should reflect the change? _(affects: sales-header-ext, sales-order-page-ext)_
6. When a user copies a posted invoice or shipment into a new sales document, should the Delivery Window flow back into the new Sales Header? _(affects: sales-header-ext)_
7. Should payments, refunds and other customer ledger entries posted from general journals carry a Delivery Window (they will be blank), and should the code also reach G/L entries? _(affects: gen-journal-line-ext, cust-ledger-entry-ext)_
8. Must documents and customer ledger entries posted before installation be backfilled, or is a blank value acceptable for history? _(affects: cust-ledger-entry-ext)_
9. Should the value also appear on list pages (Sales Orders, Posted Sales Shipments, Posted Sales Invoices), printed documents, posted credit memo pages or APIs? _(affects: posted-sales-shipment-page-ext, posted-sales-invoice-page-ext)_
10. What object and field ID range does the target app use, and is it an AppSource app or a per-tenant extension? The mirrored field number must be identical on every table. _(affects: sales-header-ext, sales-shipment-header-ext, sales-invoice-header-ext, cust-ledger-entry-ext, delivery-window-objects-permissionset)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Delivery Window | Supplemental table holding the Delivery Window codes the order taker chooses from. | Code (Code[10]): Primary key, per the Supplemental table convention.; Description (Text[100]): Description length is a design choice not set by BCQuality knowledge. | [6] [8] |
| 2 | create | page | Delivery Windows | List page (plural name) for maintaining Delivery Window codes; set as LookupPageID and DrillDownPageID of the Delivery Window table; UsageCategory = Lists and an object-level ApplicationArea so it is found in Tell Me. |  | [6] [13] |
| 3 | extend | tableextension | Sales Header | Field the order taker fills on the sales order; TableRelation to Delivery Window.Code. | Delivery Window (Code[10]): TableRelation = "Delivery Window".Code (unconditional), so the type and exact length match the related key Code[10]; DataClassification = CustomerContent; editable. | [1] [2] [5] [8] |
| 4 | extend | tableextension | Sales Shipment Header | Receives the value from Sales Header through the standard TransferFields call when a shipment is posted. | Delivery Window (Code[10]): Same field number (from the app's ID range), name, type and length as the Sales Header field; Editable = false; DataClassification = CustomerContent. | [2] [4] [8] |
| 5 | extend | tableextension | Sales Invoice Header | Receives the value from Sales Header through the standard TransferFields call when an invoice is posted. | Delivery Window (Code[10]): Same field number (from the app's ID range), name, type and length as the Sales Header field; Editable = false; DataClassification = CustomerContent. | [2] [4] [8] |
| 6 | extend | tableextension | Sales Cr.Memo Header | Mirror target required by the knowledge unless the request states credit memos never need the value (see open question). | Delivery Window (Code[10]): Same field number (from the app's ID range), name, type and length as the Sales Header field; Editable = false; DataClassification = CustomerContent. | [2] [4] [8] |
| 7 | extend | tableextension | Return Receipt Header | Mirror target required by the knowledge unless the request states return receipts never need the value (see open question). | Delivery Window (Code[10]): Same field number (from the app's ID range), name, type and length as the Sales Header field; Editable = false; DataClassification = CustomerContent. | [2] [4] [8] |
| 8 | extend | tableextension | Sales Header Archive | Mirror target so archived order versions keep the value. | Delivery Window (Code[10]): Same field number (from the app's ID range), name, type and length as the Sales Header field; Editable = false; DataClassification = CustomerContent. | [2] [4] [8] |
| 9 | extend | tableextension | Gen. Journal Line | Carrier field: sales posting builds the customer journal line field by field, so the value must be copied onto it before it can reach the customer ledger entry. | Delivery Window (Code[10]): Same type and length as the Sales Header field; DataClassification = CustomerContent. | [3] [8] |
| 10 | extend | tableextension | Cust. Ledger Entry | Stored field on the customer ledger entry so the collections team can filter Customer Ledger Entries by Delivery Window. | Delivery Window (Code[10]): Editable = false; DataClassification = CustomerContent; set during posting before insert, never by modifying posted entries. | [3] [7] [8] |
| 11 | create | codeunit | Delivery Window Posting | Holds the two event subscribers that carry the value Sales Header -> Gen. Journal Line -> Cust. Ledger Entry during posting. |  | [3] [1] |
| 12 | extend | pageextension | Sales Order | Shows the editable Delivery Window field to the order taker. |  | [1] |
| 13 | extend | pageextension | Posted Sales Shipment | Shows the non-editable Delivery Window on the posted shipment. |  | [1] |
| 14 | extend | pageextension | Posted Sales Invoice | Shows the non-editable Delivery Window on the posted invoice. |  | [1] |
| 15 | extend | pageextension | Customer Ledger Entries | Adds the Delivery Window column so collections can filter the list by it. |  | [1] |
| 16 | create | permissionset | Delivery Window - Objects | Non-assignable building block granting tabledata Delivery Window = R (plus IMD for maintainers via a separate block if required) and execute on the new table, page and codeunit. |  | [9] [10] [1] |
| 17 | create | permissionset | Delivery Window - User | Assignable role set that includes the building block through IncludedPermissionSets, so order takers can use the feature without SUPER. |  | [9] [10] |

## 3. How the data flows

- **Order taker** → **Sales Header.Delivery Window**: entered by the user. Validated against the Delivery Window table through TableRelation. [5] [6]
- **Sales Header** → **Sales Shipment Header**: standard TransferFields copy. Standard TransferFields(SalesHeader) in Sales-Post; no subscriber. [2] [4] [1]
- **Sales Header** → **Sales Invoice Header**: standard TransferFields copy. Standard TransferFields(SalesHeader) in Sales-Post; no subscriber. [2] [4] [1]
- **Sales Header** → **Sales Cr.Memo Header**: standard TransferFields copy. [2] [4]
- **Sales Header** → **Return Receipt Header**: standard TransferFields copy. [2] [4]
- **Sales Header** → **Sales Header Archive**: standard TransferFields copy. Archiving copies the header with TransferFields. [2] [4]
- **Sales Header** → **Gen. Journal Line**: copied in an event subscriber. OnAfterCopyGenJnlLineFromSalesHeader, raised at the end of CopyFromSalesHeader in Sales Post Invoice. [3] [1]
- **Gen. Journal Line** → **Cust. Ledger Entry**: copied in an event subscriber. OnAfterCopyCustLedgerEntryFromGenJnlLine, while the entry is initialized and before insert. [3] [1]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Gen. Journal Line" | `OnAfterCopyGenJnlLineFromSalesHeader` | Copy Sales Header.Delivery Window to the customer Gen. Journal Line. | Assign the field only; no Modify, no Commit, no external side effect. | [3] |
| Table "Cust. Ledger Entry" | `OnAfterCopyCustLedgerEntryFromGenJnlLine` | Copy Gen. Journal Line.Delivery Window to the Cust. Ledger Entry being initialized, before it is inserted. | Assign the field only; never find and Modify posted customer entries after posting (OnAfterPostSalesDoc runs after the commit). | [3] [7] |

## 5. Setup, permissions and lifecycle

- **setup**: Users maintain Delivery Window codes on the Delivery Windows list page before order takers can choose them; no setup table is needed. [6] [13]
- **privacy**: Set DataClassification = CustomerContent on every Delivery Window field added by a table extension and on the new table's fields; never leave ToBeClassified. [8]
- **permissions**: Ship a non-assignable building block for the new table, page and codeunit and an assignable role set that includes it; verify order entry, posting and ledger filtering as a non-SUPER user. [9] [10] [1]
- **install**: No install or upgrade code is required for the new fields; documents and entries posted before installation keep a blank Delivery Window (see open question on backfill). agent judgment

## 6. Tests

1. **order-taker-selects-delivery-window** [11] [12] [5]
    - Given A customer and item created with the Library codeunits, a Delivery Window code, and a sales order for that customer
    - When The order taker validates Delivery Window on the sales order
    - Then The sales header stores the code; validating a code that does not exist in Delivery Window raises the table-relation error
2. **ship-carries-to-posted-shipment** [11] [12] [1] [2]
    - Given A released sales order with a Delivery Window code
    - When The order is posted as Ship
    - Then The Sales Shipment Header for the order has the same Delivery Window
3. **invoice-carries-to-posted-invoice** [11] [12] [1] [2]
    - Given A sales order with a Delivery Window code
    - When The order is posted as Ship and Invoice
    - Then The Sales Invoice Header has the same Delivery Window
4. **invoice-carries-to-customer-ledger** [11] [12] [1] [3]
    - Given A sales order with a Delivery Window code
    - When The order is posted as Ship and Invoice
    - Then The Cust. Ledger Entry for the posted invoice has the same Delivery Window, and filtering Cust. Ledger Entry on that code returns it
5. **credit-memo-carries-to-posted-and-ledger** [11] [12] [2] [3]
    - Given A sales credit memo with a Delivery Window code
    - When The credit memo is posted
    - Then The Sales Cr.Memo Header and its Cust. Ledger Entry have the same Delivery Window
6. **return-order-carries-to-return-receipt** [11] [12] [2]
    - Given A sales return order with a Delivery Window code
    - When The return order is posted as Receive
    - Then The Return Receipt Header has the same Delivery Window
7. **archive-carries-delivery-window** [11] [12] [2]
    - Given A sales order with a Delivery Window code
    - When The order is archived
    - Then The Sales Header Archive version has the same Delivery Window
8. **longest-code-survives-posting** [11] [12] [4]
    - Given A Delivery Window code of the maximum field length assigned to a sales order
    - When The order is posted as Ship and Invoice
    - Then Posting succeeds and every target shows the full code, proving mirrored type and length match
9. **user-without-super-can-use-feature** [10] [12]
    - Given A user assigned only the Delivery Window role set and the standard sales roles
    - When The user sets a Delivery Window on an order, posts it and filters Customer Ledger Entries by it
    - Then Every step succeeds without SUPER

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version is unknown: no repository or app.json was supplied. Articles restricted to a version range (for example the BC23+ guidance on related tables versus stored fields on hot ledgers, and BC24+ tooltip inheritance from table fields) were not applied; the stored Cust. Ledger Entry field follows the customer-ledger article.
- countries and application-area are unknown; every cited article is w1 and [all], so the design does not depend on them.
- Copy Document flow-back: if the answer to copy-document-flow-back is no, a Copy Document subscriber is needed, but no opened article names the event; confirm it in the repository's symbols before designing it.
- Lifecycle step 'install' (no install or upgrade code) and the Description field length rest on the agent's judgment; no BCQuality article covers them.

## Sources

[1] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Stage map for the feature: which mechanism carries a sales header field to each posted table and ledger, page extensions, permissions, posting tests, and the Copy Document flow-back decision.
    - Decide which stages the field must reach and plan one step per stage before writing code.
    - For each stage name the page extensions that show the field, the permission set entries for new objects, and a test that posts a document and reads the value back from every target.
    - Copy Document copies posted and archived headers back into Sales Header with TransferFields; decide whether that is wanted, and if not, clear the field in a Copy Document subscriber.
    - Do not plan only the tables the requester named, and do not plan to fill ledger entries after posting by finding and modifying them.
[2] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Posted shipment, invoice, credit memo, return receipt and archive header extensions.
    - Give the field the same number, name, type and length on Sales Header and every TransferFields target the plan needs: all four posted header tables and the archive, unless the plan states a document type never needs it.
    - No subscriber is needed for these stages; the standard TransferFields call does the copy.
    - Keep the mirrored fields non-editable on the posted tables.
    - Do not use a different field number on a posted table or patch posted headers with an OnAfter...Insert subscriber and Modify.
[3] `microsoft/knowledge/sales-purchase/carry-sales-fields-to-customer-ledger-through-the-journal-line.md`: Carrying the value to Cust. Ledger Entry through Gen. Journal Line with two event subscribers.
    - Add the field to Gen. Journal Line and Cust. Ledger Entry and subscribe to OnAfterCopyGenJnlLineFromSalesHeader and OnAfterCopyCustLedgerEntryFromGenJnlLine.
    - Copy the value to the customer entry while it is initialized, before insert, so it is part of the posting with no extra write.
    - Do not subscribe to OnAfterPostSalesDoc to find and Modify the customer entry: it runs after the posting commit and edits a posted entry outside the posting engine.
[4] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Type and length agreement across the mirrored TransferFields cascade.
    - A deliberately mirrored field must have the exact same field number, data type and length on every table in the cascade, defined at creation time.
    - A shorter length on one side compiles and fails only at runtime when a longer value is posted.
[5] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing the Sales Header field that relates to the Delivery Window table.
    - For an unconditional TableRelation, the field must have the same type and exact length as the related field.
    - Read the related field's declared type and length from its table definition; do not assume Code[10] or Code[20].
[6] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Classifying the new Delivery Window table as a Supplemental table and shaping its key and page.
    - Identify the table type before assigning a primary key or naming the table.
    - A Supplemental table has primary key Code[10] named Code and one List page with a plural name set as LookupPageID.
    - Ledger tables such as Cust. Ledger Entry are created by posting and are never user-editable.
[7] `microsoft/knowledge/finance/do-not-modify-or-delete-posted-ledger-entries.md`: Ruling out patching posted customer ledger entries and backfill by row surgery.
    - Do not persist changes to posted financial content or delete posted rows outside the supported correction workflows.
    - Extension-only metadata updates are not financial row surgery, but a subscriber must be judged by the fields it actually changes.
[8] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: DataClassification on every new field.
    - A tableextension has no table-level classification to inherit, so every Normal field it adds must set its own DataClassification.
    - Choose the classification that matches the stored data at field definition time; ToBeClassified is not a safe default.
[9] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Permission set structure for the new objects.
    - Break grants into focused building blocks marked Assignable = false.
    - Build role-shaped Assignable = true sets that reference the building blocks through IncludedPermissionSets instead of re-enumerating objects.
[10] `microsoft/knowledge/appsource/permission-sets-cover-setup-and-usage-without-super.md`: Completeness of permission grants for setup and usage.
    - Permission sets must let assigned users complete setup and normal usage without SUPER, covering every page, codeunit and tabledata operation the app exposes.
    - Grant the minimum required operations; do not use wildcards.
    - Validate setup and representative workflows as a user assigned only those roles.
[11] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for orders, customers and items.
    - Create fixtures with the Library codeunits (LibrarySales, LibraryInventory, LibraryRandom) rather than Init/Insert with invented values.
    - Create parents before dependents and Validate foreign-key fields so TableRelation runs as in production.
[12] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunit and scenarios.
    - Put [FEATURE] before the codeunit's opening brace and [SCENARIO], [GIVEN], [WHEN], [THEN] inside each test procedure.
[13] `community/knowledge/appsource/set-usagecategory-on-searchable-entry-points.md`: Making the Delivery Windows list page discoverable.
    - A page users open directly must set UsageCategory, for example Lists, and an object-level ApplicationArea.
    - Do not infer entry-point intent from object type alone.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
