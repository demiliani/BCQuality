# Feature design

> Default Collection Group from the bill-to customer onto sales documents and Product Line Code from the item onto sales lines, keep line Collection Group in step with the header, split sales G/L entries by Product Line Code, and block posting of orders without a Collection Group.

**Result:** Partial design: some parts could not be designed. **Business process:** Sales document entry and sales posting (invoice posting buffer to G/L). **Knowledge used:** 15 BCQuality articles.

**Why:** Material gap: copying the header Collection Group onto new sales lines needs a line-initialization event that no opened article or repository symbol confirms. All other stages are designed.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Are Collection Group and Product Line Code validated against existing tables (which, and what key length) or new setup tables to be created? If new tables are needed, they require their own design (table type, pages, permissions, classification). _(affects: customer-ext, item-ext, sales-header-ext, sales-line-ext)_
2. The request says the Collection Group defaults on sales invoices, but the bill-to event fires for every sales document type. Should the default apply to all sales documents (orders, quotes, credit memos, return orders) or only invoices? _(affects: sales-defaults-subscribers, t-collection-group-from-bill-to)_
3. Must the blank-Collection-Group check apply only to orders, or also to invoices and other posted document types? Should it also block releasing the order (release restriction event)? _(affects: collection-group-posting-check, t-order-without-collection-group-blocked)_
4. When the bill-to customer is changed on a document that already has lines, must the lines take the new customer's Collection Group as well? _(affects: sales-defaults-subscribers, t-header-change-updates-lines)_
5. The mirroring guidance puts the fields on all posted header/line tables and archives. Are any of shipments, credit memos, return receipts or archives not needed? _(affects: sales-shipment-header-ext, sales-cr-memo-header-ext, return-receipt-header-ext, sales-header-archive-ext, sales-shipment-line-ext, sales-cr-memo-line-ext, return-receipt-line-ext, sales-line-archive-ext)_
6. Copy Document copies posted and archived documents back with TransferFields, so the old Collection Group would flow into the new document. Is that wanted, or must the value be re-defaulted from the current bill-to customer? _(affects: sales-header-ext, sales-defaults-subscribers)_
7. Must Product Line Code appear as a native column on G/L entry lists and be read on almost every access (stored field), or is a related table keyed by Entry No. acceptable? Does Finance also need it on customer ledger, VAT or item ledger entries? _(affects: gl-entry-ext, t-gl-split-by-product-line)_
8. What happens to open orders that exist before the feature is installed and have no Collection Group: backfill from the bill-to customer, or require users to set it? _(affects: collection-group-posting-check)_
9. Which other pages must show the fields (quotes, credit memos, return orders, posted documents, General Ledger Entries)? _(affects: sales-document-pages-ext)_
10. Is the feature sales-only, or must purchase documents also split G/L by Product Line Code? _(affects: product-line-gl-posting)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Customer | Holds the Collection Group master value that is defaulted from the bill-to customer onto sales documents. | Collection Group (Code[n] (n = related key length)): Master value; TableRelation to the Collection Group source (q-lookup-tables). DataClassification set on the field, since a tableextension has no table-level value to inherit. | [2] [10] [11] |
| 2 | extend | tableextension | Item | Holds the Product Line Code master value that is defaulted onto sales lines. | Product Line Code (Code[n] (n = related key length)): Master value; TableRelation to the Product Line source (q-lookup-tables). DataClassification set on the field. | [2] [10] [11] |
| 3 | extend | tableextension | Sales Header | Carries Collection Group on the document header. Its OnValidate calls UpdateSalesLinesByFieldNo(FieldNo("Collection Group"), CurrFieldNo <> 0) so the standard routine confirms with the user and validates every line. | Collection Group (Code[n] (n = related key length)): Defaulted from the bill-to customer; OnValidate propagates to lines through UpdateSalesLinesByFieldNo, never ModifyAll. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables). | [3] [6] [7] [10] [11] |
| 4 | extend | tableextension | Sales Line | Carries Collection Group (follows the header) and Product Line Code (defaulted from the item) on each sales line. | Collection Group (Code[n] (n = related key length)): Set from the header by the OnUpdateSalesLineByChangedFieldName subscriber. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables).; Product Line Code (Code[n] (n = related key length)): Defaulted from the item in OnAfterAssignItemValues. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Product Line key length (see open question q-lookup-tables). | [2] [3] [6] [7] [11] |
| 5 | extend | tableextension | Sales Shipment Header | TransferFields target of Sales Header: mirrors Collection Group with the same field number, type and length so the standard copy carries it. No subscriber. Chosen by the mirroring article; see q-posted-targets. | Collection Group (Code[n] (n = related key length)): Non-editable mirror of the Sales Header/Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables). | [6] [1] [7] |
| 6 | extend | tableextension | Sales Invoice Header | TransferFields target of Sales Header: mirrors Collection Group with the same field number, type and length so the standard copy carries it. No subscriber. Chosen by the mirroring article; see q-posted-targets. | Collection Group (Code[n] (n = related key length)): Non-editable mirror of the Sales Header/Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables). | [6] [1] [7] |
| 7 | extend | tableextension | Sales Cr.Memo Header | TransferFields target of Sales Header: mirrors Collection Group with the same field number, type and length so the standard copy carries it. No subscriber. Chosen by the mirroring article; see q-posted-targets. | Collection Group (Code[n] (n = related key length)): Non-editable mirror of the Sales Header/Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables). | [6] [1] [7] |
| 8 | extend | tableextension | Return Receipt Header | TransferFields target of Sales Header: mirrors Collection Group with the same field number, type and length so the standard copy carries it. No subscriber. Chosen by the mirroring article; see q-posted-targets. | Collection Group (Code[n] (n = related key length)): Non-editable mirror of the Sales Header/Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables). | [6] [1] [7] |
| 9 | extend | tableextension | Sales Header Archive | TransferFields target of Sales Header: mirrors Collection Group with the same field number, type and length so the standard copy carries it. No subscriber. Chosen by the mirroring article; see q-posted-targets. | Collection Group (Code[n] (n = related key length)): Non-editable mirror of the Sales Header/Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables). | [6] [1] [7] |
| 10 | extend | tableextension | Sales Shipment Line | TransferFields target of Sales Line (InitFromSalesLine / archiving): mirrors Collection Group and Product Line Code with the same field numbers, types and lengths. No subscriber. Chosen by the mirroring article; see q-posted-targets. | Collection Group (Code[n] (n = related key length)): Non-editable mirror of the Sales Header/Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables).; Product Line Code (Code[n] (n = related key length)): Non-editable mirror of the Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Product Line key length (see open question q-lookup-tables). | [6] [1] [7] |
| 11 | extend | tableextension | Sales Invoice Line | TransferFields target of Sales Line (InitFromSalesLine / archiving): mirrors Collection Group and Product Line Code with the same field numbers, types and lengths. No subscriber. Chosen by the mirroring article; see q-posted-targets. | Collection Group (Code[n] (n = related key length)): Non-editable mirror of the Sales Header/Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables).; Product Line Code (Code[n] (n = related key length)): Non-editable mirror of the Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Product Line key length (see open question q-lookup-tables). | [6] [1] [7] |
| 12 | extend | tableextension | Sales Cr.Memo Line | TransferFields target of Sales Line (InitFromSalesLine / archiving): mirrors Collection Group and Product Line Code with the same field numbers, types and lengths. No subscriber. Chosen by the mirroring article; see q-posted-targets. | Collection Group (Code[n] (n = related key length)): Non-editable mirror of the Sales Header/Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables).; Product Line Code (Code[n] (n = related key length)): Non-editable mirror of the Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Product Line key length (see open question q-lookup-tables). | [6] [1] [7] |
| 13 | extend | tableextension | Return Receipt Line | TransferFields target of Sales Line (InitFromSalesLine / archiving): mirrors Collection Group and Product Line Code with the same field numbers, types and lengths. No subscriber. Chosen by the mirroring article; see q-posted-targets. | Collection Group (Code[n] (n = related key length)): Non-editable mirror of the Sales Header/Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables).; Product Line Code (Code[n] (n = related key length)): Non-editable mirror of the Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Product Line key length (see open question q-lookup-tables). | [6] [1] [7] |
| 14 | extend | tableextension | Sales Line Archive | TransferFields target of Sales Line (InitFromSalesLine / archiving): mirrors Collection Group and Product Line Code with the same field numbers, types and lengths. No subscriber. Chosen by the mirroring article; see q-posted-targets. | Collection Group (Code[n] (n = related key length)): Non-editable mirror of the Sales Header/Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Collection Group key length (see open question q-lookup-tables).; Product Line Code (Code[n] (n = related key length)): Non-editable mirror of the Sales Line field. Same field number, name, type and length on every table that mirrors it; Code length must equal the related Product Line key length (see open question q-lookup-tables). | [6] [1] [7] |
| 15 | extend | tableextension | Invoice Posting Buffer | Carries Product Line Code through the invoice posting buffer so it can be part of Group ID and reach the journal line. | Product Line Code (Code[n] (same as Sales Line)): Temporary buffer field; DataClassification set on the field. | [4] [11] |
| 16 | extend | tableextension | Gen. Journal Line | Carries Product Line Code from the buffer to the G/L entry. | Product Line Code (Code[n] (same as Sales Line)) | [4] [8] [11] |
| 17 | extend | tableextension | G/L Entry | Stores Product Line Code on each G/L entry so Finance can split G/L by it. Chosen as a stored field because the request asks for G/L entries split by the code; the hot-ledger article allows a stored field only when the value must appear as a native list column and is read on almost every access, otherwise a related table keyed by Entry No. is preferred - confirm in q-gl-storage. | Product Line Code (Code[n] (same as Sales Line)): Editable = false. A code value stays as copied on reversal. | [4] [8] [9] [11] |
| 18 | create | codeunit | Sales Defaults Propagation | Event subscribers that default Collection Group from the bill-to customer, Product Line Code from the item, and push a changed header Collection Group to existing lines. |  | [2] [3] |
| 19 | create | codeunit | Product Line G/L Posting | Event subscribers that copy Product Line Code into the Invoice Posting Buffer, add it to Group ID, and carry it to Gen. Journal Line and G/L Entry. |  | [4] [8] |
| 20 | create | codeunit | Collection Group Posting Check | Subscriber that stops posting (preview included) of a sales order whose Collection Group is blank. |  | [5] [13] |
| 21 | extend | pageextension | Customer Card | Shows Collection Group on the customer. Tooltip defined on the table field and inherited (BC24/runtime 13.0+), otherwise on the page control. |  | [12] |
| 22 | extend | pageextension | Item Card | Shows Product Line Code on the item, with an inherited or page-level tooltip. |  | [12] |
| 23 | extend | pageextension | Sales Order, Sales Invoice and their subforms | Shows Collection Group on the header and Collection Group and Product Line Code on lines. No business logic on the page; defaults come from table events. Other document pages are an open question (q-pages). |  | [12] [2] [1] |

## 3. How the data flows

- **Customer."Collection Group" (bill-to customer)** → **Sales Header."Collection Group"**: copied in an event subscriber. Plain assignment in OnAfterSetFieldsBilltoCustomer on Sales Header; runs for every creation path, not on the page. [2]
- **Item."Product Line Code"** → **Sales Line."Product Line Code"**: copied in an event subscriber. Plain assignment in OnAfterAssignItemValues on Sales Line. [2]
- **Sales Header."Collection Group" (changed)** → **Sales Line."Collection Group" (existing lines)**: field validation. Header OnValidate calls UpdateSalesLinesByFieldNo; subscriber to OnUpdateSalesLineByChangedFieldName validates the line field when ChangedFieldNo is Collection Group. [3]
- **Sales Header."Collection Group"** → **Sales Line."Collection Group" (new lines added after the header is set)**: other. No opened article or repository symbol confirms the line-initialization event that copies header values to a new line; see unresolved. agent judgment
- **Sales Header** → **Sales Shipment Header, Sales Invoice Header, Sales Cr.Memo Header, Return Receipt Header, Sales Header Archive**: standard TransferFields copy. Standard TransferFields by field number; mirrored field needs no subscriber. [6] [1] [7]
- **Sales Line** → **Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line, Sales Line Archive**: standard TransferFields copy. InitFromSalesLine and archiving call TransferFields; carries Collection Group and Product Line Code. [6] [1] [7]
- **Sales Line."Product Line Code"** → **Invoice Posting Buffer."Product Line Code" and Group ID**: copied in an event subscriber. Filled in OnPrepareLineOnAfterFillInvoicePostingBuffer; appended to Group ID in OnAfterBuildPrimaryKey so lines with different codes do not merge. [4]
- **Invoice Posting Buffer."Product Line Code"** → **Gen. Journal Line."Product Line Code"**: copied in an event subscriber. OnAfterCopyToGenJnlLine on Invoice Posting Buffer. [4]
- **Gen. Journal Line."Product Line Code"** → **G/L Entry."Product Line Code"**: copied in an event subscriber. OnAfterCopyGLEntryFromGenJnlLine on G/L Entry. On reversal, Gen. Jnl.-Post Reverse copies the code unchanged, which is correct for a code value. VAT and bank entries are not extended. [4] [8]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Sales Header" | `OnAfterSetFieldsBilltoCustomer` | Default Collection Group from the bill-to customer. | Use the bill-to event, not the sell-to event: collection data follows the bill-to party · Plain assignment from the Customer record the event passes · Do not copy on the page | [2] |
| Table "Sales Line" | `OnAfterAssignItemValues` | Default Product Line Code from the item. | Declare only the parameters used, with the names the Sales Line publisher declares | [2] |
| Table "Sales Header" | `OnUpdateSalesLineByChangedFieldName` | Validate Sales Line Collection Group from the header when the header field changes. | Act only when ChangedFieldNo = FieldNo("Collection Group") · Validate the line field; never ModifyAll · Spell the sales event with singular "Line" | [3] |
| Codeunit "Sales Post Invoice Events" | `OnPrepareLineOnAfterFillInvoicePostingBuffer` | Copy Product Line Code from the sales line into the Invoice Posting Buffer. | Subscribe on "Sales Post Invoice Events" (825), not "Sales Post Invoice" | [4] |
| Table "Invoice Posting Buffer" | `OnAfterBuildPrimaryKey` | Add Product Line Code to Group ID so lines with different codes post as separate G/L entries. | Pad the value with PadField as the standard key does · CopyStr to MaxStrLen of Group ID (Text[1000]) | [4] |
| Table "Invoice Posting Buffer" | `OnAfterCopyToGenJnlLine` | Copy Product Line Code to the Gen. Journal Line. |  | [4] |
| Table "G/L Entry" | `OnAfterCopyGLEntryFromGenJnlLine` | Copy Product Line Code to the G/L Entry. | Never fill G/L entries after posting by finding and modifying them | [4] [8] [1] |
| Codeunit "Sales-Post" | `OnAfterCheckSalesDoc` | Stop posting a sales order whose Collection Group is blank, before any entry is written and also in posting preview. | Apply only when Document Type = Order (q-check-scope) · Do not check in a page action or in OnAfterPostSalesDoc · Raise an error that tells the user what to fix | [5] [13] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification on every field added by a tableextension (no table-level value to inherit); choose the value matching the stored data and leave nothing ToBeClassified. [11]
- **setup**: Before release, define the Collection Group and Product Line sources the fields relate to and size every field to the exact related key length (q-lookup-tables). [10]
- **upgrade**: Decide how existing open sales orders without a Collection Group are handled once the posting check ships (q-existing-orders). No BCQuality article was opened for this step. agent judgment

## 6. Tests

1. **t-collection-group-from-bill-to** [2] [14]
    - Given Customer A (sell-to) with Collection Group X whose Bill-to Customer No. is customer B with Collection Group Y, created with LibrarySales
    - When A sales invoice is created for customer A
    - Then Sales Header Collection Group is Y, not X
2. **t-product-line-from-item** [2] [14]
    - Given An item with a Product Line Code, created with LibraryInventory
    - When A sales line is created for the item with LibrarySales.CreateSalesLine
    - Then Sales Line Product Line Code equals the item's code
3. **t-header-change-updates-lines** [3] [14]
    - Given A sales order with two item lines and Collection Group X
    - When Collection Group on the header is validated to Y from code
    - Then Both lines carry Collection Group Y
4. **t-new-line-inherits-header** [14]
    - Given A sales order header with Collection Group X
    - When A new item line is added
    - Then The new line carries Collection Group X (depends on the unresolved line-initialization event)
5. **t-posting-mirrors-values** [6] [1] [14]
    - Given A sales order with Collection Group and lines with Product Line Codes, and a sales return order with the same values
    - When Both are posted (ship and invoice; receive and invoice) and the order is archived
    - Then Shipment, invoice, credit memo, return receipt and archive headers carry Collection Group; their lines carry Collection Group and Product Line Code
6. **t-gl-split-by-product-line** [4] [14]
    - Given A sales invoice with two lines on the same G/L account and posting groups but different Product Line Codes
    - When The invoice is posted
    - Then Two sales G/L entries exist, each with its own Product Line Code and amount, instead of one merged entry
7. **t-order-without-collection-group-blocked** [5] [15] [14]
    - Given A sales order with a blank Collection Group
    - When The order is posted, and separately posting preview is run
    - Then Both fail with the Collection Group mandatory-field error, verified with Assert.ExpectedTestFieldError (or ExpectedError with the full label text if ErrorInfo is used), and no entries exist

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Material: the event that copies Sales Header Collection Group onto a newly inserted Sales Line is not confirmed by an opened article or repository symbols; the hop to new lines and test t-new-line-inherits-header cannot be finalized until it is confirmed.
- Not covered by BCQuality knowledge: handling of existing open orders without a Collection Group at install or upgrade (lifecycle upgrade step).
- Unknown applicability: bc-version, countries and application-area were not supplied and no repository was available; tooltip inheritance applies only from BC24.

## Sources

[1] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Stage map for the custom sales fields: posted headers/lines and archives via TransferFields, ledger stages via field-by-field copy, tests and Copy Document decision.
    - Decide which stages each field must reach and plan one step per stage
    - Name the page extensions, permission entries for new objects, and a test that posts and reads the value back from every target
    - Copy Document copies posted and archived headers back with TransferFields; decide whether that is wanted, otherwise clear the field in OnAfterCopySalesHeaderDone
    - Do not fill ledger entries after posting by finding and modifying them
[2] `microsoft/knowledge/sales-purchase/default-sales-and-purchase-fields-from-master-data.md`: Defaulting Collection Group from the bill-to customer and Product Line Code from the item.
    - Payment, pricing and posting data follows the bill-to party: use OnAfterSetFieldsBilltoCustomer
    - Line default from the item: subscribe to OnAfterAssignItemValues and declare only used parameters with the publisher's names
    - Copy with plain assignment from the master record the event passes
    - Do not copy master data on the page
[3] `microsoft/knowledge/sales-purchase/propagate-sales-and-purchase-header-fields-to-lines.md`: Making lines follow a changed header Collection Group.
    - Call UpdateSalesLinesByFieldNo(FieldNo(field), CurrFieldNo <> 0) in the header field's OnValidate
    - Subscribe to OnUpdateSalesLineByChangedFieldName and Validate the line field when ChangedFieldNo is the field
    - Do not use ModifyAll: it skips the line OnValidate and the user confirmation
[4] `microsoft/knowledge/sales-purchase/carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.md`: Splitting G/L entries by Product Line Code through the Invoice Posting Buffer.
    - Add the field to Invoice Posting Buffer, Gen. Journal Line and G/L Entry
    - Fill the buffer in OnPrepareLineOnAfterFillInvoicePostingBuffer on "Sales Post Invoice Events", not "Sales Post Invoice"
    - Add the field to Group ID in OnAfterBuildPrimaryKey with PadField, or lines with different values merge and keep the first line's value
    - Copy in OnAfterCopyToGenJnlLine and OnAfterCopyGLEntryFromGenJnlLine
[5] `microsoft/knowledge/sales-purchase/validate-sales-and-purchase-documents-before-posting-or-release.md`: Blocking posting of an order without a Collection Group.
    - A rule that must stop every posting, including preview, belongs in OnAfterCheckSalesDoc
    - Use the release restriction event only for rules about releasing; post restriction events only for rules that must not block preview
    - Do not check in the page action or after posting in OnAfterPostSalesDoc
    - Raise errors that tell the user what to fix
[6] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Carrying Collection Group and Product Line Code to posted documents and archives.
    - Same field number, name, type and length on the source and every target table the plan needs: four posted header tables and the archive, and the line equivalents, unless the plan states a document type never needs it
    - No subscriber is needed for these stages
    - Keep mirrored fields non-editable on posted tables
[7] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definitions across the TransferFields cascade.
    - Mirrored fields must have the exact same field number, data type and length on every table in the cascade, set at creation time
[8] `microsoft/knowledge/finance-extensions/carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md`: Gen. Journal Line to G/L Entry copy and reversal behavior of Product Line Code.
    - Subscribe to the copy event of each entry table the design needs; do not extend VAT or bank entries unless their reports need the value
    - State what reversal does with each custom field: a code can stay as copied, a custom amount or quantity must be negated
[9] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choosing between a stored G/L Entry field and a related table.
    - Put optional, sparse or integration attributes in a related table keyed by ledger Entry No.
    - Use a stored tableextension field only when the value must appear as a native list column and is read on almost every access
[10] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing Collection Group and Product Line Code fields against their related tables.
    - Read the related field's type and length before adding a TableRelation
    - An unconditional relation requires the same type and exact length as the related field
[11] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of every added field.
    - A tableextension field must set its own DataClassification
    - Choose the value matching the stored data at definition time; do not leave ToBeClassified
[12] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips for the new page fields.
    - On runtime 13.0 (BC24) or later define the tooltip on the table field and let bound page fields inherit it; earlier targets need page-level tooltips (applies from BC24)
    - Tooltip text must say what the value is used for, not just repeat the caption
[13] `microsoft/knowledge/error-handling/prefer-errorinfo-for-actionable-errors.md`: Shape of the posting-check error.
    - For a recoverable failure use ErrorInfo with a recommended action only when the solution is genuinely known and the user can apply it
[14] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Create customers, items and sales documents with the Library codeunits, parents first, and Validate foreign keys
[15] `microsoft/knowledge/testing/asserterror-needs-expectederror-and-code.md`: Negative test for the posting check.
    - Follow every asserterror with a check of the specific expected error, e.g. Assert.ExpectedTestFieldError for a mandatory field
    - Do not rely on ExpectedErrorCode alone or on a fragment shared by other errors

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
