# Feature design

> Customers need a default Delivery Window code. New customers are created from customer templates or from contacts, and the code should come from the template. Sales quotes take the code from the customer, and when a quote or blanket order becomes an order the order must keep the code the quote or blanket order had, even if it was changed by hand.

**Result:** Complete design. **Business process:** Add a customer default Delivery Window code, filled from customer templates (including customers created from contacts), defaulted onto sales quotes from the sell-to customer, and kept unchanged when Sales-Quote to Order or Blanket Sales Order to Order creates the order; this changes customer creation and the sales document process of the base application. **Knowledge used:** 13 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Does a Delivery Window table (code list) already exist, and in which app? If not, should one be created as a new Supplemental code table with its own page and permissions? Its key field type and length fix the length of every Delivery Window field. _(affects: customer-ext, customer-templ-ext, sales-header-ext, sales-header-archive-ext, sales-shipment-header-ext, sales-invoice-header-ext, sales-cr-memo-header-ext, return-receipt-header-ext)_
2. Should the Delivery Window also reach Sales Header Archive and the posted shipment, invoice, credit memo and return receipt headers? The design mirrors it on all of them as the mirroring article requires; any can be excluded. _(affects: sales-header-archive-ext, sales-shipment-header-ext, sales-invoice-header-ext, sales-cr-memo-header-ext, return-receipt-header-ext, archive-restore-keeps-archived-value, posting-carries-delivery-window)_
3. The sell-to event defaults the code on every sales document type (orders, blanket orders, invoices, credit memos, return orders), not only quotes. Is that wanted, or should the default be restricted to quotes and blanket orders? _(affects: delivery-window-subscribers, quote-takes-customer-delivery-window)_
4. When the template has no Delivery Window, should new customers get a fallback value, or stay blank? A fallback belongs in OnApplyTemplateOnBeforeCustomerModify only when the field is empty. _(affects: customer-templ-ext, customer-from-template-gets-delivery-window)_
5. Copy Document copies posted and archived headers back into Sales Header with TransferFields. Should the copied document keep the source's Delivery Window, or take it from the customer (requiring a clear in OnAfterCopySalesHeaderDone)? _(affects: sales-header-ext)_
6. Should existing customers, customer templates and open quotes, blanket orders and orders be back-filled with a Delivery Window on installation, and from what value? _(affects: customer-ext, customer-templ-ext, sales-header-ext)_
7. Should the Delivery Window be shown on posted document pages, archive pages or reports? _(affects: sales-shipment-header-ext, sales-invoice-header-ext, sales-cr-memo-header-ext, return-receipt-header-ext, sales-header-archive-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Customer | Holds the customer's default Delivery Window code, the source of the sales document default. | Delivery Window (Code): Length must equal the length of the related Delivery Window key field (see open question delivery-window-source). DataClassification = CustomerContent. Field number, name, type and length are reused on every table below. | [4] [12] [9] |
| 2 | extend | tableextension | Customer Templ. | Template field that ApplyTemplate copies to new customers created from a template or from a contact; it is copied only because number, name, type and length match the Customer field. Save as template fills it back with TransferFields. | Delivery Window (Code): Same field number, name, type and length as on Customer; DataClassification = CustomerContent. | [4] [9] |
| 3 | extend | tableextension | Sales Header | Holds the Delivery Window on quotes, blanket orders and orders. Record assignment in quote and blanket order conversion carries it to the order with no copy subscriber. | Delivery Window (Code): Same field number, name, type and length as on Customer; editable so the user can change it by hand; DataClassification = CustomerContent. | [3] [6] [7] [9] |
| 4 | extend | tableextension | Sales Header Archive | Mirror target of the archive TransferFields, so an archived quote, blanket order or order keeps the value and restore can put it back. Chosen by the mirroring article; see open question mirror-targets. | Delivery Window (Code): Same field number, name, type and length as on Sales Header; non-editable; DataClassification = CustomerContent. | [6] [7] [8] [9] |
| 5 | extend | tableextension | Sales Shipment Header | Mirror target of the posting TransferFields from Sales Header. Chosen by the mirroring article; see open question mirror-targets. | Delivery Window (Code): Same field number, name, type and length as on Sales Header; non-editable; DataClassification = CustomerContent. | [6] [7] [2] [9] |
| 6 | extend | tableextension | Sales Invoice Header | Mirror target of the posting TransferFields from Sales Header. Chosen by the mirroring article; see open question mirror-targets. | Delivery Window (Code): Same field number, name, type and length as on Sales Header; non-editable; DataClassification = CustomerContent. | [6] [7] [2] [9] |
| 7 | extend | tableextension | Sales Cr.Memo Header | Mirror target of the posting TransferFields from Sales Header. Chosen by the mirroring article; see open question mirror-targets. | Delivery Window (Code): Same field number, name, type and length as on Sales Header; non-editable; DataClassification = CustomerContent. | [6] [7] [2] [9] |
| 8 | extend | tableextension | Return Receipt Header | Mirror target of the posting TransferFields from Sales Header. Chosen by the mirroring article; see open question mirror-targets. | Delivery Window (Code): Same field number, name, type and length as on Sales Header; non-editable; DataClassification = CustomerContent. | [6] [7] [2] [9] |
| 9 | extend | pageextension | Customer Card | Shows the customer's Delivery Window. Tooltip defined once on the table field and inherited (runtime 13.0 / BC24 or later); page-level tooltip only on older targets. No business logic on the page. |  | [13] |
| 10 | extend | pageextension | Customer Templ. Card | Shows the template's Delivery Window so users can set the value new customers receive. |  | [4] [13] |
| 11 | extend | pageextension | Sales Quote | Shows and allows editing the quote's Delivery Window. |  | [13] |
| 12 | extend | pageextension | Blanket Sales Order | Shows and allows editing the blanket order's Delivery Window. |  | [13] |
| 13 | extend | pageextension | Sales Order | Shows the order's Delivery Window carried from the quote or blanket order. |  | [13] |
| 14 | create | codeunit | Delivery Window Subscribers | Event subscribers: copy the sell-to customer's Delivery Window to the sales header, and restore the archived value after an archive restore revalidates the customer. Contains no OnAfterInitRecord default, so conversion never overwrites the value carried from the quote or blanket order. |  | [5] [8] [3] |

## 3. How the data flows

- **Customer Templ."Delivery Window"** → **Customer."Delivery Window" (customer created from a template)**: other. Customer Templ. Mgt. ApplyTemplate copies by RecordRef, field by field, without Validate, only into an empty customer field. No subscriber; requires the mirrored template field. [4]
- **Customer Templ."Delivery Window"** → **Customer."Delivery Window" (customer created from a contact)**: other. Contact inserts the customer, then calls ApplyCustomerTemplate; same RecordRef copy as the template path. [4]
- **Customer."Delivery Window"** → **Sales Header."Delivery Window" (quote, and every other document type when Sell-to Customer No. is validated)**: copied in an event subscriber. Plain assignment in OnAfterCopySellToCustomerAddressFieldsFromCustomer; delivery data follows the sell-to party. [5]
- **Sales Header (quote)** → **Sales Header (order) via Sales-Quote to Order**: other. Record assignment of the quote header; Insert(true) then runs InitRecord, so no subscriber may default the field there. A hand-changed value survives. [3]
- **Sales Header (blanket order)** → **Sales Header (order) via Blanket Sales Order to Order**: other. Record assignment of the blanket header; same InitRecord rule. Header field, so OnAfterResetQuantityFields does not apply. [3]
- **Sales Header** → **Sales Header Archive**: standard TransferFields copy. ArchiveManagement, including the optional archive of the quote during conversion. [6] [8]
- **Sales Header Archive** → **Sales Header (restored document)**: copied in an event subscriber. TransferFields back, then customer revalidation overwrites the value; OnAfterTransferFromArchToSalesHeader reassigns the archived value. [8]
- **Sales Header** → **Sales Shipment Header, Sales Invoice Header, Sales Cr.Memo Header, Return Receipt Header**: standard TransferFields copy. Sales-Post TransferFields; no subscriber. [6] [2] [7]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Sales Header | `OnAfterCopySellToCustomerAddressFieldsFromCustomer` | Copy SellToCustomer."Delivery Window" to the sales header with a plain assignment when the sell-to customer is validated. | Assign from the SellToCustomer record the event passes; no page-level default · Do not default in OnAfterInitRecord; if a fallback default is ever added there, set it only when the field is empty so converted orders keep the source value | [5] [3] |
| ArchiveManagement | `OnAfterTransferFromArchToSalesHeader` | Reassign SalesHeaderArchive."Delivery Window" after restore revalidated the sell-to customer and replaced it with the current customer default. | Assign only; no Modify (the record is modified right after the event) | [8] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification = CustomerContent on the Delivery Window field in every table extension (tableextensions cannot inherit a table-level value). [9]
- **upgrade**: No InitValue is designed, so no upgrade code is required for new rows. Existing customers, templates and open documents stay blank after installation; back-filling them needs upgrade code guarded by an upgrade tag (open question existing-data). [10]

## 6. Tests

1. **customer-from-template-gets-delivery-window** [4] [11]
    - Given A Customer Templ. with Delivery Window set
    - When A customer is created from that template through Customer Templ. Mgt.
    - Then The new customer's Delivery Window equals the template value
2. **customer-from-contact-gets-delivery-window** [4] [11]
    - Given A company contact and a Customer Templ. with Delivery Window set
    - When A customer is created from the contact with that template
    - Then The new customer's Delivery Window equals the template value
3. **quote-takes-customer-delivery-window** [5] [11]
    - Given A customer (LibrarySales.CreateCustomer) with Delivery Window set
    - When A sales quote is created and Sell-to Customer No. is validated
    - Then The quote header's Delivery Window equals the customer's
4. **quote-to-order-keeps-hand-changed-value** [3] [11]
    - Given A quote whose Delivery Window was changed by hand to a value different from the customer's
    - When Sales-Quote to Order runs
    - Then The created order's Delivery Window equals the quote's hand-changed value, not the customer default
5. **blanket-to-order-keeps-hand-changed-value** [3] [11]
    - Given A blanket sales order whose Delivery Window was changed by hand
    - When Blanket Sales Order to Order runs
    - Then The created order's Delivery Window equals the blanket order's value
6. **posting-carries-delivery-window** [6] [2] [11]
    - Given A sales order with Delivery Window set, and a return order with Delivery Window set
    - When They are posted (ship and invoice; receive and credit memo)
    - Then Sales Shipment Header, Sales Invoice Header, Return Receipt Header and Sales Cr.Memo Header each hold the same value
7. **archive-restore-keeps-archived-value** [8] [11]
    - Given A quote archived with Delivery Window A, after which the customer's Delivery Window is changed to B
    - When The archived version is restored
    - Then Sales Header Archive held A and the restored quote holds A, not B

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown (no repository); tooltip placement depends on whether the target is runtime 13.0 / BC24 or later
- Page extensions for Customer Card, Sales Quote, Blanket Sales Order and Sales Order rest on the agent's judgment for placement; only tooltip guidance is cited
- Permission sets: no new table is designed; if the Delivery Window table must be created (open question delivery-window-source), its table type, page and permission set are not designed here

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Process map that selected the sales, quote/blanket conversion, template default, archive and upgrade rows.
    - Plan one row group per process the field touches and open every linked article for the chosen stages
    - Whether the field reaches stages the request does not name is a question for the requester, one per group of stages
[2] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Posted-header stages reached by Sales-Post TransferFields, and the Copy Document flow-back decision.
    - Posted headers and archive receive the field only through same-number fields
    - Copy Document copies posted and archived headers back with TransferFields; decide whether the field should flow back, and if not clear it on ToSalesHeader in OnAfterCopySalesHeaderDone
    - Never fill ledger entries by modifying them after posting
[3] `microsoft/knowledge/sales-purchase/quote-and-blanket-order-conversion-copies-custom-fields-by-assignment.md`: Quote and blanket order to order conversion carrying the hand-changed value.
    - Keep the field on Sales Header and let the record assignment carry it; no copy subscriber
    - Default logic in OnAfterInitRecord must fill the field only when empty
    - Do not write a subscriber that copies the field from quote to order and calls Modify
[4] `microsoft/knowledge/sales-purchase/templates-apply-custom-master-data-fields-by-matching-field.md`: Customer template and contact creation paths.
    - Template field must have the same number, name, type and length as the Customer field, or it is skipped silently
    - ApplyTemplate does not overwrite a value set on insert; do not default the field on Customer insert or on the card page
    - Template values are assigned without Validate; call Validate in OnApplyTemplateOnBeforeCustomerModify if validation must run
    - Test every creation path: from template and from contact
[5] `microsoft/knowledge/sales-purchase/default-sales-and-purchase-fields-from-master-data.md`: Quote default from the customer.
    - Delivery data follows the sell-to party: OnAfterCopySellToCustomerAddressFieldsFromCustomer on Sales Header
    - Copy with a plain assignment from the master record the event passes
    - Never copy master data from the page
[6] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Archive and posted-header mirror targets.
    - Same field number, name, type and length on Sales Header and on all four posted header tables and Sales Header Archive, unless the plan states a document type never needs it
    - No subscriber for these stages; keep the mirrored fields non-editable on posted tables
[7] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definitions across the TransferFields cascade.
    - Exact same field number, data type and length on every table in the cascade
[8] `microsoft/knowledge/sales-purchase/restore-archived-sales-document-revalidates-custom-fields.md`: Archive restore of a field defaulted from the customer.
    - Subscribe to OnAfterTransferFromArchToSalesHeader and reassign the archived value, without Modify
    - Test restore with a customer whose default changed after archiving
[9] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of the new field.
    - Every Normal field a tableextension adds must set its own DataClassification matching the stored data
[10] `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`: Existing customers and documents after installation.
    - InitValue does not back-fill existing rows; when a back-filled value matters, ship upgrade code guarded by an upgrade tag
[11] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build customers, templates and sales documents with library codeunits, parents first, validating foreign keys
[12] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Length of the Delivery Window code field.
    - With an unconditional TableRelation the field must have the exact type and length of the related key field; read it from the related table definition
[13] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Page extensions showing the field.
    - On runtime 13.0 (BC24) or later define the tooltip on the table field and let pages inherit it; on earlier targets add page-level tooltips
    - Tooltip text must say what the value is used for, not repeat the caption

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

