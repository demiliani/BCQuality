# Feature design

> Default a Handling Class on purchase orders from the buy-from vendor and on purchase lines from the item, push buyer changes on the order header to existing lines, and block release of a purchase order without a Handling Class.

**Result:** Complete design. **Business process:** Purchasing: purchase order entry, release and posting. **Knowledge used:** 17 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is Handling Class: a code that relates to a new Handling Class table (with its own page, permissions and setup), an enum, or a free code? The design assumes Code[10] without a relation. _(affects: vendor-ext, item-ext, purchase-header-ext, purchase-line-ext)_
2. Must Handling Class reach posted receipts, invoices, credit memos, return shipments and archives? The mirroring article requires them unless you exclude a document type; the request does not mention them. _(affects: purch-rcpt-header-ext, purch-inv-header-ext, purch-cr-memo-hdr-ext, return-shipment-header-ext, purchase-header-archive-ext, purch-rcpt-line-ext, purch-inv-line-ext, purch-cr-memo-line-ext, return-shipment-line-ext, purchase-line-archive-ext)_
3. Should a header change update all lines, or only lines of type Item? Should non-item lines get a Handling Class at all? _(affects: handling-class-subscribers, purchase-line-ext)_
4. When a line is added after the buyer changed the header Handling Class, should the line take the item's value (as the request states) or the header's value? _(affects: handling-class-subscribers, purchase-line-ext)_
5. When Buy-from Vendor No. changes on an order that already has lines, should the new vendor's Handling Class also be pushed to the lines? The vendor default is a plain assignment and does not run the line update. _(affects: handling-class-subscribers, purchase-header-ext)_
6. Should the defaults and the release rule also apply to purchase quotes, invoices, credit memos, return orders and blanket orders, or only to orders? _(affects: handling-class-subscribers)_
7. Existing vendors, items and open purchase orders will have a blank Handling Class after installation, so open orders cannot be released until it is filled. Is a data migration or default needed? _(affects: vendor-ext, item-ext, purchase-header-ext)_
8. Copy Document copies posted and archived headers back into Purchase Header. Should a copied order keep the source Handling Class or take the vendor's current value? _(affects: purchase-header-ext)_
9. Should Handling Class also reach warehouse receipt lines, item ledger entries or vendor ledger entries? Not designed because the request does not ask for it. _(affects: purchase-line-ext)_
10. Should posted purchase documents and archives show Handling Class on their pages? _(affects: purch-rcpt-header-ext, purch-inv-header-ext, purch-cr-memo-hdr-ext, return-shipment-header-ext, purchase-header-archive-ext, purch-rcpt-line-ext, purch-inv-line-ext, purch-cr-memo-line-ext, return-shipment-line-ext, purchase-line-archive-ext)_
11. Which object ID range and field number should be used? No repository or app.json was supplied. _(affects: vendor-ext, item-ext, purchase-header-ext, purchase-line-ext, handling-class-subscribers)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Vendor | Holds the vendor's Handling Class, the source of the purchase order header default. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). | [9] [10] [7] |
| 2 | extend | tableextension | Item | Holds the item's Handling Class, the source of the purchase line default. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). | [9] [10] [7] |
| 3 | extend | tableextension | Purchase Header | Holds the order's Handling Class. Its OnValidate calls UpdatePurchLinesByFieldNo(FieldNo("Handling Class"), CurrFieldNo <> 0) so a change by the buyer is pushed to existing lines with the standard confirmation and Modify(true) per line, never ModifyAll. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). OnValidate: UpdatePurchLinesByFieldNo. | [2] [4] [6] [9] [10] |
| 4 | extend | tableextension | Purchase Line | Holds the line's Handling Class, defaulted from the item and updated from the header. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). | [1] [2] [4] [6] [9] [10] |
| 5 | extend | tableextension | Purch. Rcpt. Header | Mirrors Purchase Header "Handling Class" so the standard TransferFields copy reaches Purch. Rcpt. Header. Chosen by the mirroring article, not by the request (see q-posted-and-archive-stages). Non-editable. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). Editable = false. | [4] [6] [5] [9] [10] |
| 6 | extend | tableextension | Purch. Inv. Header | Mirrors Purchase Header "Handling Class" so the standard TransferFields copy reaches Purch. Inv. Header. Chosen by the mirroring article, not by the request (see q-posted-and-archive-stages). Non-editable. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). Editable = false. | [4] [6] [5] [9] [10] |
| 7 | extend | tableextension | Purch. Cr. Memo Hdr. | Mirrors Purchase Header "Handling Class" so the standard TransferFields copy reaches Purch. Cr. Memo Hdr.. Chosen by the mirroring article, not by the request (see q-posted-and-archive-stages). Non-editable. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). Editable = false. | [4] [6] [5] [9] [10] |
| 8 | extend | tableextension | Return Shipment Header | Mirrors Purchase Header "Handling Class" so the standard TransferFields copy reaches Return Shipment Header. Chosen by the mirroring article, not by the request (see q-posted-and-archive-stages). Non-editable. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). Editable = false. | [4] [6] [5] [9] [10] |
| 9 | extend | tableextension | Purchase Header Archive | Mirrors Purchase Header "Handling Class" so the standard TransferFields copy reaches Purchase Header Archive. Chosen by the mirroring article, not by the request (see q-posted-and-archive-stages). Non-editable. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). Editable = false. | [4] [6] [5] [9] [10] |
| 10 | extend | tableextension | Purch. Rcpt. Line | Mirrors Purchase Line "Handling Class" so InitFromPurchLine or archiving TransferFields reaches Purch. Rcpt. Line. Chosen by the mirroring article, not by the request (see q-posted-and-archive-stages). Non-editable. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). Editable = false. | [4] [6] [5] [9] [10] |
| 11 | extend | tableextension | Purch. Inv. Line | Mirrors Purchase Line "Handling Class" so InitFromPurchLine or archiving TransferFields reaches Purch. Inv. Line. Chosen by the mirroring article, not by the request (see q-posted-and-archive-stages). Non-editable. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). Editable = false. | [4] [6] [5] [9] [10] |
| 12 | extend | tableextension | Purch. Cr. Memo Line | Mirrors Purchase Line "Handling Class" so InitFromPurchLine or archiving TransferFields reaches Purch. Cr. Memo Line. Chosen by the mirroring article, not by the request (see q-posted-and-archive-stages). Non-editable. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). Editable = false. | [4] [6] [5] [9] [10] |
| 13 | extend | tableextension | Return Shipment Line | Mirrors Purchase Line "Handling Class" so InitFromPurchLine or archiving TransferFields reaches Return Shipment Line. Chosen by the mirroring article, not by the request (see q-posted-and-archive-stages). Non-editable. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). Editable = false. | [4] [6] [5] [9] [10] |
| 14 | extend | tableextension | Purchase Line Archive | Mirrors Purchase Line "Handling Class" so InitFromPurchLine or archiving TransferFields reaches Purchase Line Archive. Chosen by the mirroring article, not by the request (see q-posted-and-archive-stages). Non-editable. | Handling Class (Code[10]): Same field number, name, type and length on every table that carries it; explicit DataClassification (no ToBeClassified). Type and length are open (see q-handling-class-type). Editable = false. | [4] [6] [5] [9] [10] |
| 15 | create | codeunit | Purch. Handling Class Mgt. | Static event subscribers: buy-from vendor default on the header, item default on the line, header-to-line propagation and the release restriction. |  | [1] [2] [3] |
| 16 | extend | pageextension | Vendor Card | Lets users maintain the vendor's Handling Class. Tooltip on the table field when the target runtime is 13.0 (BC24) or later, otherwise on the page control. |  | [13] |
| 17 | extend | pageextension | Item Card | Lets users maintain the item's Handling Class. Tooltip placement as for the Vendor Card. |  | [13] |
| 18 | extend | pageextension | Purchase Order | Lets the buyer change the order's Handling Class. ShowMandatory = true, because release enforces the value with TestField; the property is presentation only and the release check stays the guarantee. |  | [12] [13] |
| 19 | extend | pageextension | Purchase Order Subform | Shows the line's Handling Class so the buyer can see the item default and the propagated value. |  | [13] |

## 3. How the data flows

- **Vendor."Handling Class"** → **Purchase Header."Handling Class"**: copied in an event subscriber. Plain assignment in a subscriber to OnAfterCopyBuyFromVendorFieldsFromVendor, raised when Buy-from Vendor No. is validated. Handling is delivery-type data, so it follows the buy-from party, not pay-to. [1]
- **Item."Handling Class"** → **Purchase Line."Handling Class"**: copied in an event subscriber. Plain assignment in a subscriber to OnAfterAssignItemValues on Purchase Line, raised by CopyFromItem when No. is validated for an item. [1]
- **Buyer (Purchase Order page)** → **Purchase Header."Handling Class"**: entered by the user. Field is ShowMandatory on the Purchase Order page. [12]
- **Purchase Header."Handling Class"** → **Purchase Line."Handling Class" (existing lines)**: field validation. Header OnValidate calls UpdatePurchLinesByFieldNo; subscriber to OnUpdatePurchLinesByChangedFieldName (plural "Lines") validates the line field from the header when ChangedFieldNo is the Handling Class field. [2]
- **Purchase Header."Handling Class"** → **Purch. Rcpt. Header."Handling Class"**: standard TransferFields copy. Standard TransferFields by field number; no subscriber. [4] [6]
- **Purchase Header."Handling Class"** → **Purch. Inv. Header."Handling Class"**: standard TransferFields copy. Standard TransferFields by field number; no subscriber. [4] [6]
- **Purchase Header."Handling Class"** → **Purch. Cr. Memo Hdr.."Handling Class"**: standard TransferFields copy. Standard TransferFields by field number; no subscriber. [4] [6]
- **Purchase Header."Handling Class"** → **Return Shipment Header."Handling Class"**: standard TransferFields copy. Standard TransferFields by field number; no subscriber. [4] [6]
- **Purchase Header."Handling Class"** → **Purchase Header Archive."Handling Class"**: standard TransferFields copy. Standard TransferFields by field number; no subscriber. [4] [6]
- **Purchase Line."Handling Class"** → **Purch. Rcpt. Line."Handling Class"**: standard TransferFields copy. Standard TransferFields (InitFromPurchLine or archiving) by field number; no subscriber. [4] [6]
- **Purchase Line."Handling Class"** → **Purch. Inv. Line."Handling Class"**: standard TransferFields copy. Standard TransferFields (InitFromPurchLine or archiving) by field number; no subscriber. [4] [6]
- **Purchase Line."Handling Class"** → **Purch. Cr. Memo Line."Handling Class"**: standard TransferFields copy. Standard TransferFields (InitFromPurchLine or archiving) by field number; no subscriber. [4] [6]
- **Purchase Line."Handling Class"** → **Return Shipment Line."Handling Class"**: standard TransferFields copy. Standard TransferFields (InitFromPurchLine or archiving) by field number; no subscriber. [4] [6]
- **Purchase Line."Handling Class"** → **Purchase Line Archive."Handling Class"**: standard TransferFields copy. Standard TransferFields (InitFromPurchLine or archiving) by field number; no subscriber. [4] [6]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Purchase Header" | `OnAfterCopyBuyFromVendorFieldsFromVendor` | Default the header Handling Class from the buy-from vendor with a plain assignment from the Vendor record the event passes. | Declare only the parameters used, with the names the publisher declares; confirm the signature in the target version's symbols. | [1] |
| Table "Purchase Line" | `OnAfterAssignItemValues` | Default the line Handling Class from the Item record the event passes. | Use the purchase-side parameters (CurrentFieldNo, PurchHeader), not the sales-side ones; declare only the parameters used. | [1] |
| Table "Purchase Header" | `OnUpdatePurchLinesByChangedFieldName` | Validate Purchase Line "Handling Class" from the header when the header field changes. | Act only when ChangedFieldNo = PurchHeader.FieldNo("Handling Class"). · Spell the event with plural "Lines" exactly as the purchase publisher declares it. | [2] |
| Table "Purchase Header" | `OnCheckPurchaseReleaseRestrictions` | Block release of a purchase order without a Handling Class: Sender.TestField("Handling Class"). The header arrives as Sender (IncludeSender). Because posting releases an open document, this also stops posting an open order outside preview. | Act only when Sender."Document Type" = Order. · Raised from Release Purchase Document; not raised in posting preview or when release restrictions are skipped. · Add the check; do not take over the standard release check with IsHandled. | [3] [11] |

## 5. Setup, permissions and lifecycle

- **privacy**: Give every Handling Class field added by a table extension an explicit DataClassification (table extensions inherit no table-level default) and resolve any ToBeClassified before release; decide the classification from what the field stores. [9] [10]
- **setup**: If Handling Class becomes its own table with a TableRelation (q-handling-class-type), plan it as a new business entity (table type, pages, data classification, permission set, tests) and size every referencing field with the exact type and length of the related key. [8] [7]

## 6. Tests

1. **header-defaults-from-buy-from-vendor** [1] [14] [15]
    - Given A vendor with a Handling Class, created with LibraryPurchase
    - When A purchase order is created and Buy-from Vendor No. is validated to that vendor
    - Then Purchase Header."Handling Class" equals the vendor's value
2. **line-defaults-from-item** [1] [14] [15]
    - Given A purchase order and an item with a Handling Class, created with library codeunits
    - When A purchase line of type Item is created and No. is validated to the item
    - Then Purchase Line."Handling Class" equals the item's value
3. **header-change-updates-existing-lines** [2] [17] [14] [15]
    - Given A purchase order with several item lines
    - When The buyer changes Handling Class on the Purchase Order test page and confirms the line-update dialog
    - Then Every existing line carries the new Handling Class; the ConfirmHandler is listed and executes
4. **other-header-field-does-not-touch-lines** [2] [14] [15]
    - Given A purchase order whose lines carry item Handling Class values that differ from the header
    - When A different header field that propagates to lines through UpdatePurchLinesByFieldNo is changed
    - Then The lines' Handling Class values are unchanged (ChangedFieldNo guard)
5. **release-blocked-without-handling-class** [3] [11] [16] [14] [15]
    - Given A purchase order with lines and a blank Handling Class
    - When The order is released through Release Purchase Document
    - Then asserterror, then Assert.ExpectedTestFieldError for the Handling Class caption; the order stays Open
6. **release-succeeds-with-handling-class** [3] [14] [15]
    - Given A purchase order with lines and a Handling Class
    - When The order is released
    - Then Status is Released
7. **release-rule-limited-to-orders** [3] [14] [15]
    - Given A purchase document of another type (for example an invoice) with a blank Handling Class
    - When It is released
    - Then Release succeeds (Document Type guard)
8. **posting-open-order-without-handling-class-fails** [3] [16] [14] [15]
    - Given An open purchase order with a blank Handling Class
    - When The order is posted (receive and invoice) outside preview
    - Then Posting fails with the Handling Class TestField error and nothing is posted
9. **receipt-and-invoice-carry-handling-class** [4] [5] [14] [15]
    - Given A released purchase order with a Handling Class on header and lines
    - When The order is received and invoiced
    - Then Purch. Rcpt. Header/Line and Purch. Inv. Header/Line carry the same Handling Class values
10. **return-order-carries-handling-class** [4] [5] [14] [15]
    - Given A released purchase return order with a Handling Class on header and lines
    - When It is shipped and invoiced
    - Then Return Shipment Header/Line and Purch. Cr. Memo Hdr./Line carry the same Handling Class values
11. **archive-carries-handling-class** [4] [14] [15]
    - Given A purchase order with a Handling Class on header and lines
    - When The document is archived
    - Then Purchase Header Archive and Purchase Line Archive carry the same Handling Class values

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version unknown (no repository): tooltip placement depends on runtime 13.0 / BC24.
- countries and application-area not stated; all selected articles are w1 / all, so applicability is unaffected.
- Handling Class type Code[10] follows the knowledge samples; the real type rests on q-handling-class-type.
- Event parameter names for OnAfterCopyBuyFromVendorFieldsFromVendor are not shown in an opened sample; confirm in the target version's symbols.

## Sources

[1] `microsoft/knowledge/sales-purchase/default-sales-and-purchase-fields-from-master-data.md`: Buy-from vendor default on the header and item default on the purchase line.
    - Copy the value in a subscriber with a plain assignment from the master record the event passes, never from the page.
    - Delivery and contact data follows the buy-from party; payment, pricing and posting data follows pay-to.
    - Purchase Line OnAfterAssignItemValues passes CurrentFieldNo and PurchHeader, not the sales parameters; declare only the parameters used, with the publisher's names.
[2] `microsoft/knowledge/sales-purchase/propagate-sales-and-purchase-header-fields-to-lines.md`: Pushing a changed header Handling Class to existing purchase lines.
    - Call UpdatePurchLinesByFieldNo(FieldNo(<field>), CurrFieldNo <> 0) from the header field's OnValidate.
    - Subscribe to OnUpdatePurchLinesByChangedFieldName (plural) and Validate the line field when ChangedFieldNo is the custom field.
    - Do not use ModifyAll: it skips line OnValidate, gives no confirmation and runs for code-originated changes.
[3] `microsoft/knowledge/sales-purchase/validate-sales-and-purchase-documents-before-posting-or-release.md`: Placing the 'cannot release without Handling Class' rule.
    - A release rule belongs in the release restriction event of that side (OnCheckPurchaseReleaseRestrictions), which passes the header as Sender.
    - The release restriction event is not raised in preview or when release restrictions are skipped; posting releases an open document, so the rule also stops posting an open document outside preview.
    - Do not check the rule in the page action or after posting.
[4] `microsoft/knowledge/sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md`: Mirroring the header and line field on posted receipt, invoice, credit memo, return shipment and archive tables.
    - Same field number, name, type and length on Purchase Header/Line and on every target the plan needs; unless the plan excludes a document type, that means all four posted tables and the archive.
    - No subscriber is needed for these stages; keep mirrored fields non-editable on posted tables.
    - Do not patch posted headers in a subscriber with Modify.
[5] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Purchase follows the same posting map as sales; tests post and read back from every target.
    - Decide which stages the field must reach and plan one step per stage; planning only the named tables leaves posted documents and archives blank.
    - Name page extensions and permission entries for new objects per stage and add a test that posts and reads the value back from every target.
    - Do not copy a sales subscriber to purchases without checking the purchase event's parameters; Copy Document copies posted and archived headers back with TransferFields, so decide whether that is wanted.
[6] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Keeping the mirrored Handling Class definitions identical across the TransferFields cascade.
    - Define a mirrored field with the exact same field number, data type and length on every table in the cascade, at creation time.
[7] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Conditional: applies only if Handling Class gets a TableRelation to its own table (q-handling-class-type).
    - For an unconditional relation, give the field the same type and exact length as the related field; read the related length from its definition rather than assuming Code[10] or Code[20].
[8] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Conditional: applies only if Handling Class becomes a new table (q-handling-class-type).
    - Plan table type, numbering, setup, data rules, privacy, pages, permissions, install/upgrade and tests for a new entity; a decision the request does not settle is a question, not a default.
[9] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classifying the fields added by table extensions.
    - A tableextension inherits no table-level DataClassification; every Normal field it adds needs an explicit valid DataClassification.
[10] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of the new fields.
    - Resolve ToBeClassified to a real classification before shipping; decide from the data's content, not convenience.
[11] `microsoft/knowledge/error-handling/fielderror-vs-testfield.md`: Choosing TestField for the release check.
    - Use TestField for a simple presence check; it adds field and record context, so do not hand-build an Error naming the field.
[12] `microsoft/knowledge/ui/showmandatory-on-code-required-page-fields.md`: Marking Handling Class mandatory on the Purchase Order page.
    - Set ShowMandatory = true on a visible, editable field the user must supply before an action can complete, and keep the enforcement in code; the property enforces nothing.
[13] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltip placement for the new page fields; the target runtime is unknown.
    - On runtime 13.0 (BC24) or later define the tooltip on the table field and omit duplicate page-level tooltips; on earlier targets put the tooltip on the page control.
    - Tooltip text must say what the value is used for, without inventing effects.
[14] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for vendors, items and purchase documents.
    - Create fixtures with library codeunits (LibraryPurchase, LibraryInventory, LibraryRandom), parents first, validating foreign-key fields; do not hand-roll Init/Insert records.
[15] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunit.
    - [FEATURE] on the codeunit, [SCENARIO] as the first comment in each test, and [GIVEN]/[WHEN]/[THEN] marking setup, action and assertions.
[16] `microsoft/knowledge/testing/asserterror-needs-expectederror-and-code.md`: Negative release and posting tests.
    - Follow every asserterror with a check of the specific error; for a TestField failure use Assert.ExpectedTestFieldError.
[17] `microsoft/knowledge/testing/ui-handlers-in-tests.md`: The header-change test that goes through the line-update confirmation.
    - List a handler for every UI call the scenario triggers and make each listed nonoptional handler execute; assert the semantic result, not just that the handler ran.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
