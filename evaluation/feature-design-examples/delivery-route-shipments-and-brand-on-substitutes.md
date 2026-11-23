# Feature design

> Sales orders get a delivery route. Warehouse staff must be able to pull only the released sales orders for one route into a warehouse shipment through the source document filters. Items also get a brand code that must default onto sales lines, including when the salesperson picks a substitute or a catalog item, and a substitute line must remember the brand that was originally ordered.

**Result:** Complete design. **Business process:** Adds a delivery route to sales orders that warehouse shipments filter on through Warehouse Request and Get Source Documents, and a brand code that defaults from the item onto sales lines through standard item, catalog item and substitution routes; changes sales order entry, release, warehouse shipment creation and sales posting. **Knowledge used:** 10 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Should Delivery Route and Brand Code be validated against new lookup tables (a route list and a brand list)? If yes, those tables need their own design (table type, pages, permission set, classification), and the field lengths must match the related key. _(affects: sales-header-route, item-brand, nonstock-item-brand, sales-line-brand)_
2. Where does the delivery route come from on a new sales order: typed by the user only, or defaulted from the customer or ship-to address? _(affects: sales-header-route)_
3. May the route change on a released order? The design requires reopen and release; the alternative is to update the Warehouse Request directly when the route changes. _(affects: sales-header-route, route-change-requires-open-order)_
4. Besides the source document filter, should the route also filter the single-document path (Get Source Doc. Outbound / Source Documents list, OnGetSingleOutboundDocOnAfterSetFilters) and inventory picks (Create Invt Put-away/Pick/Mvmt), and should the route be carried on purchase return orders or transfers through their own release codeunits? _(affects: route-whse-codeunit, source-doc-filter-card-route)_
5. Should Delivery Route or Brand Code also appear on warehouse shipment lines, picks and posted warehouse shipments? That is a separate copy step not designed here. _(affects: route-whse-codeunit, sales-line-brand)_
6. The design mirrors Delivery Route on all posted sales headers and Sales Header Archive, and Brand Code / Requested Brand on all posted sales lines and Sales Line Archive. Are any of these document types (credit memos, return receipts, archives) not needed? _(affects: posted-headers-route, posted-invoice-header-route, posted-crmemo-header-route, return-receipt-header-route, sales-header-archive-route, posted-lines-brand, posted-invoice-line-brand, posted-crmemo-line-brand, return-receipt-line-brand, sales-line-archive-brand)_
7. Should the route or the brand reach customer ledger entries, item ledger entries or G/L entries? Not designed. _(affects: sales-line-brand, sales-header-route)_
8. When a document is copied, should Delivery Route flow back from posted or archived headers, and should Requested Brand survive Copy Document when lines are recalculated (it is dropped on that path; Brand Code is re-defaulted from the item)? _(affects: sales-header-route, sales-line-brand)_
9. Should new items get a brand from the item template (add Brand Code to Item Templ. with the same number, name, type and length)? _(affects: item-brand)_
10. Should Requested Brand be filled only on substituted lines, or on every line (equal to Brand Code when no substitution happened)? And should it be cleared if the user later changes No. manually? _(affects: sales-line-brand, substitute-keeps-requested-brand)_
11. Existing items, open orders and posted history will have blank route and brand. Is upgrade or install code needed to fill them? _(affects: item-brand, sales-line-brand, sales-header-route)_
12. Do quotes, blanket orders, return orders or purchase documents need the route or brand defaults, or only sales orders? _(affects: sales-header-route, sales-line-brand)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Sales Header | Holds the delivery route of the sales order. The route is captured on Warehouse Request at release, so the OnValidate trigger requires Status = Open; users reopen and release again to change it, which rewrites the request. | Delivery Route (Code[20]): Entered by the user; OnValidate tests Status = Open. DataClassification = CustomerContent. Same field number, name, type and length on every mirrored table. | [2] [6] [7] [9] |
| 2 | extend | tableextension | Warehouse Request | Carries the delivery route of the released sales order so Get Source Documents can filter on it; a field on Sales Header is invisible to Get Source Documents. | Delivery Route (Code[20]): Filled at release only; DataClassification = CustomerContent. | [2] [9] |
| 3 | extend | tableextension | Warehouse Source Filter | Stores the delivery route filter that a warehouse user sets on a source document filter. | Delivery Route Filter (Code[100]): Filter expression applied to Warehouse Request."Delivery Route"; DataClassification = CustomerContent. | [2] [9] |
| 4 | extend | pageextension | Source Document Filter Card | Shows Delivery Route Filter so warehouse staff can pull only one route's released sales orders into a warehouse shipment. |  | [2] |
| 5 | create | codeunit | Delivery Route Warehouse Mgt. | Event subscribers that copy the route to Warehouse Request at release and apply the route filter to Warehouse Request. |  | [2] |
| 6 | extend | tableextension | Sales Shipment Header | Mirror of Delivery Route so sales posting copies it by TransferFields. | Delivery Route (Code[20]): Same field number, name, type and length as on Sales Header; Editable = false; DataClassification = CustomerContent. | [6] [7] [5] [9] |
| 7 | extend | tableextension | Sales Invoice Header | Mirror of Delivery Route for the TransferFields copy at invoice posting. | Delivery Route (Code[20]): Same field number, name, type and length as on Sales Header; Editable = false; DataClassification = CustomerContent. | [6] [7] [9] |
| 8 | extend | tableextension | Sales Cr.Memo Header | Mirror of Delivery Route for the TransferFields copy at credit memo posting. | Delivery Route (Code[20]): Same field number, name, type and length as on Sales Header; Editable = false; DataClassification = CustomerContent. | [6] [7] [9] |
| 9 | extend | tableextension | Return Receipt Header | Mirror of Delivery Route for the TransferFields copy at return receipt posting. | Delivery Route (Code[20]): Same field number, name, type and length as on Sales Header; Editable = false; DataClassification = CustomerContent. | [6] [7] [9] |
| 10 | extend | tableextension | Sales Header Archive | Mirror of Delivery Route so archiving and restore copy it by TransferFields. | Delivery Route (Code[20]): Same field number, name, type and length as on Sales Header; Editable = false; DataClassification = CustomerContent. | [6] [8] [7] [9] |
| 11 | extend | tableextension | Item | Holds the item's brand code, the master value that defaults onto sales lines. | Brand Code (Code[20]): DataClassification = CustomerContent. | [4] [3] [9] |
| 12 | extend | tableextension | Nonstock Item | Holds the catalog item's brand so the item created from it gets a brand; CreateNewItem inserts the item without its OnInsert trigger, so the brand is assigned in OnCreateNewItemOnBeforeItemModify. | Brand Code (Code[20]): Same type and length as Item."Brand Code"; DataClassification = CustomerContent. | [3] [9] |
| 13 | extend | tableextension | Sales Line | Holds the brand defaulted from the item on every route that sets the line's item, and the brand originally ordered when the line was substituted. | Brand Code (Code[20]): Defaulted from the item; same field number, name, type and length on every mirrored line table; DataClassification = CustomerContent.; Requested Brand (Code[20]): Brand of the line before substitution; same field number, name, type and length on every mirrored line table; DataClassification = CustomerContent. | [4] [3] [6] [7] [9] |
| 14 | extend | tableextension | Sales Shipment Line | Mirror of Brand Code and Requested Brand so InitFromSalesLine copies them by TransferFields. | Brand Code (Code[20]): Mirror of the Sales Line field: same number, name, type and length; Editable = false; DataClassification = CustomerContent.; Requested Brand (Code[20]): Mirror of the Sales Line field: same number, name, type and length; Editable = false; DataClassification = CustomerContent. | [6] [7] [5] [9] |
| 15 | extend | tableextension | Sales Invoice Line | Mirror of the line brand fields for the TransferFields copy at invoice posting. | Brand Code (Code[20]): Mirror of the Sales Line field: same number, name, type and length; Editable = false; DataClassification = CustomerContent.; Requested Brand (Code[20]): Mirror of the Sales Line field: same number, name, type and length; Editable = false; DataClassification = CustomerContent. | [6] [7] [9] |
| 16 | extend | tableextension | Sales Cr.Memo Line | Mirror of the line brand fields for the TransferFields copy at credit memo posting. | Brand Code (Code[20]): Mirror of the Sales Line field: same number, name, type and length; Editable = false; DataClassification = CustomerContent.; Requested Brand (Code[20]): Mirror of the Sales Line field: same number, name, type and length; Editable = false; DataClassification = CustomerContent. | [6] [7] [9] |
| 17 | extend | tableextension | Return Receipt Line | Mirror of the line brand fields for the TransferFields copy at return receipt posting. | Brand Code (Code[20]): Mirror of the Sales Line field: same number, name, type and length; Editable = false; DataClassification = CustomerContent.; Requested Brand (Code[20]): Mirror of the Sales Line field: same number, name, type and length; Editable = false; DataClassification = CustomerContent. | [6] [7] [9] |
| 18 | extend | tableextension | Sales Line Archive | Mirror of the line brand fields so archiving copies them and restore can put the archived Brand Code back. | Brand Code (Code[20]): Mirror of the Sales Line field: same number, name, type and length; Editable = false; DataClassification = CustomerContent.; Requested Brand (Code[20]): Mirror of the Sales Line field: same number, name, type and length; Editable = false; DataClassification = CustomerContent. | [6] [8] [7] [9] |
| 19 | create | codeunit | Brand Code Defaults | Event subscribers that default Brand Code from the item, give catalog-created items their brand, keep the requested brand on substitutes and restore the archived brand. |  | [3] [4] [8] |
| 20 | extend | pageextension | Sales Order | Shows Delivery Route on the sales order; the matching posted and archive pages show it read-only. |  | [5] |
| 21 | extend | pageextension | Sales Order Subform | Shows Brand Code and Requested Brand on sales order lines. |  | [5] |
| 22 | extend | pageextension | Item Card | Lets users maintain Brand Code on the item. |  | [4] |
| 23 | extend | pageextension | Catalog Item Card | Lets users maintain Brand Code on the catalog item. |  | [3] |

## 3. How the data flows

- **User** → **Sales Header.Delivery Route**: entered by the user. Allowed only while the order is Open. [2]
- **Sales Header.Delivery Route** → **Warehouse Request.Delivery Route**: copied in an event subscriber. OnBeforeCreateWhseRequest on Whse.-Sales Release, on every release, for each location request. [2]
- **Warehouse Source Filter.Delivery Route Filter** → **Warehouse Request filter used by Get Source Documents**: copied in an event subscriber. OnSetFiltersOnSourceTables on Warehouse Source Filter sets the filter before the report reads released, not completely handled requests; only that route's released orders reach the warehouse shipment. [2]
- **Sales Header.Delivery Route** → **Sales Shipment Header, Sales Invoice Header, Sales Cr.Memo Header, Return Receipt Header, Sales Header Archive**: standard TransferFields copy. Standard posting and archiving copy by field number; no subscriber. [6] [5] [1]
- **User** → **Item.Brand Code and Nonstock Item.Brand Code**: entered by the user. [3]
- **Nonstock Item.Brand Code** → **Item.Brand Code (item created from the catalog item)**: copied in an event subscriber. OnCreateNewItemOnBeforeItemModify on Catalog Item Management; runs for ShowNonstock, NonstockAutoItem and catalog substitutes. [3]
- **Item.Brand Code** → **Sales Line.Brand Code**: copied in an event subscriber. OnAfterAssignItemValues on Sales Line covers typed items, catalog items, substitutes (validated on a temporary line) and item references; no IsTemporary guard. [4] [3]
- **Sales Line.Brand Code (line before substitution)** → **Sales Line.Requested Brand (substitute line)**: copied in an event subscriber. OnItemSubstGetOnAfterSubstSalesLineItem on Item Subst. [3]
- **Sales Line.Brand Code, Requested Brand** → **Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line, Sales Line Archive**: standard TransferFields copy. InitFromSalesLine and archiving copy by field number. [6] [5] [1]
- **Sales Line Archive.Brand Code** → **Sales Line.Brand Code (restored document)**: copied in an event subscriber. Restore revalidates No., which re-defaults today's item brand; OnAfterTransferFromArchToSalesLine puts the archived value back without Modify. [8]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Whse.-Sales Release | `OnBeforeCreateWhseRequest` | Copy Sales Header.Delivery Route to the Warehouse Request being created or rewritten at release. | Assign only; the publisher inserts or modifies the request after the event. | [2] |
| Warehouse Source Filter | `OnSetFiltersOnSourceTables` | Apply Delivery Route Filter to the Warehouse Request filter record passed by var. | Set the filter only when Delivery Route Filter is not blank. | [2] |
| Sales Line | `OnAfterAssignItemValues` | Default Sales Line.Brand Code from Item.Brand Code for every route that validates No. | No IsTemporary guard: substitutes are validated on a temporary line. · Declare only the parameters used, with the names the Sales Line publisher declares. | [4] [3] |
| Catalog Item Management | `OnCreateNewItemOnBeforeItemModify` | Assign Nonstock Item.Brand Code to the item created from the catalog item. | Assign only when the catalog item's brand is not blank. | [3] |
| Item Subst. | `OnItemSubstGetOnAfterSubstSalesLineItem` | Set Requested Brand on the new line (first parameter) from the line before substitution (second parameter). | Take the source line's Requested Brand when it is already filled, otherwise its Brand Code, so a second substitution keeps the brand originally ordered. | [3] |
| ArchiveManagement | `OnAfterTransferFromArchToSalesLine` | Put the archived Brand Code back after restore revalidated No. and re-defaulted the item's current brand. | Assign without Modify; the restore modifies the line right after the event. | [8] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification = CustomerContent on every field added by the table extensions; a tableextension has no table-level value to inherit. [9]

## 6. Tests

1. **release-copies-route-to-whse-request** [2] [10]
    - Given A location that requires shipment, a customer and item created with LibrarySales and LibraryInventory, and a sales order for that location with Delivery Route R1
    - When The order is released
    - Then The Warehouse Request for the order and location has Delivery Route R1
2. **filter-card-pulls-only-one-route** [2] [10]
    - Given Released sales orders for routes R1 and R2 and an open order for R1 at a shipment-required location, and a Warehouse Source Filter with Delivery Route Filter R1
    - When Get Source Documents runs for a warehouse shipment with that filter
    - Then The shipment holds lines only from the released R1 order; the R2 order and the open R1 order are not included
3. **blank-route-filter-keeps-standard** [2]
    - Given Released orders for R1 and R2 and a source filter with a blank Delivery Route Filter
    - When Get Source Documents runs
    - Then Both orders reach the shipment
4. **route-change-requires-open-order** [2]
    - Given A released sales order with Delivery Route R1
    - When The user validates Delivery Route R2
    - Then An error requires Status Open; after reopen, change and release the Warehouse Request carries R2
5. **brand-defaults-on-typed-item** [4] [10]
    - Given An item with Brand Code B1
    - When A sales line is created for the item
    - Then Sales Line.Brand Code is B1
6. **substitute-keeps-requested-brand** [3]
    - Given Item A with brand B1 and substitute item S with brand B2, and a sales line for item A
    - When The salesperson picks S through Item Subst. (ShowItemSub)
    - Then The line has No. S, Brand Code B2 and Requested Brand B1
7. **second-substitution-keeps-original-brand** [3]
    - Given A line already substituted from A (B1) to S (B2)
    - When The salesperson substitutes again to item T with brand B3
    - Then Brand Code is B3 and Requested Brand stays B1
8. **catalog-item-brand-reaches-line** [3]
    - Given A catalog item with Brand Code B4 and no item yet
    - When The salesperson picks it on a sales line (ShowNonstock)
    - Then The created Item has Brand Code B4 and the sales line has Brand Code B4
9. **item-reference-brand** [3]
    - Given An item with brand B1 and a customer item reference for it
    - When Item Reference No. is validated on a sales line
    - Then Sales Line.Brand Code is B1
10. **posting-carries-route-and-brand** [6] [5] [10]
    - Given A sales order with Delivery Route R1 and a substituted line (Brand Code B2, Requested Brand B1)
    - When The order is posted as ship and invoice, and a return order with the same values is posted
    - Then Posted shipment, invoice and return receipt headers carry R1 and their lines carry B2 and B1; a posted credit memo does the same
11. **archive-restore-keeps-brand** [8] [6]
    - Given A sales order with a line of brand B1 that is archived, after which the item's brand changes to B5
    - When The archived version is restored
    - Then The restored line keeps Brand Code B1 and Requested Brand, and the header keeps Delivery Route

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Target BC version, countries and application area are unknown; all cited articles apply to all versions and w1.
- The rule that a second substitution keeps the first Requested Brand (subscription guard and test second-substitution-keeps-original-brand) rests on judgment; the article only states which parameter is the original line.
- Field lengths (Code[20], filter Code[100]) rest on judgment pending the master-lists question.
- Event signatures must be confirmed against the target version's symbols; no repository was supplied.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Map of the field paths: selecting the sales, warehouse request and cross-cutting rows (master data defaults, catalog items and substitutions, archive and restore, privacy, tests).
    - Plan one row group per process the request touches and open every linked article for the stages chosen.
    - Whether a field should reach a stage the request does not name, such as archives or ledger entries, is a question for the requester; raise one question per group of stages.
[2] `microsoft/knowledge/warehouse/warehouse-requests-decide-which-source-documents-reach-warehouse-documents.md`: Delivery route on Warehouse Request, copied at release and filtered through the source document filter.
    - A filter the warehouse uses must be on Warehouse Request; a field on Sales Header is invisible to Get Source Documents.
    - Copy the header value in OnBeforeCreateWhseRequest on each release codeunit the feature needs.
    - Add the filter field to Warehouse Source Filter and Source Document Filter Card and apply it in OnSetFiltersOnSourceTables.
    - Single-document shipments go through GetSingleOutboundDoc and are filtered in OnGetSingleOutboundDocOnAfterSetFilters.
    - The value is captured at release; if it can change on a released document, plan a reopen and release or update the request.
    - Do not drop documents with SkipRecord in OnAfterSalesHeaderOnAfterGetRecord, and do not write Warehouse Request from a Sales Header OnModify subscriber.
[3] `microsoft/knowledge/inventory/catalog-items-substitutions-and-item-references-set-sales-lines-differently.md`: Brand defaults on catalog items and substitutes, and the requested brand on substitute lines.
    - Keep the general item default in OnAfterAssignItemValues and do not guard it with IsTemporary.
    - Give items created from catalog items the value in OnCreateNewItemOnBeforeItemModify; CreateNewItem inserts without OnInsert.
    - Carry a value from the original item to the substitute line in OnItemSubstGetOnAfterSubstSalesLineItem: first parameter is the new line, second the line before substitution.
    - Do not default the line field from the page's No. validation or the item's OnInsert.
[4] `microsoft/knowledge/sales-purchase/default-sales-and-purchase-fields-from-master-data.md`: Line default of Brand Code from the item.
    - Subscribe to OnAfterAssignItemValues on Sales Line and declare only the parameters used, with the publisher's names.
    - Copy with a plain assignment from the master record the event passes; never from the page.
[5] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Stages a sales field must reach, page extensions per stage and the posting test.
    - Decide which stages the field must reach and plan one step per stage.
    - Name the page extensions that show the field and a test that posts a document and reads the value from every target.
    - Copy Document copies posted and archived headers back with TransferFields; decide whether that is wanted and clear it in OnAfterCopySalesHeaderDone if not.
    - Do not fill ledger entries after posting by modifying them.
[6] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring Delivery Route on posted headers and archive, and the brand fields on posted lines and line archive.
    - Same field number, name, type and length on the source and every target the plan needs: all four posted header tables and the archive, and the line tables, unless the plan states a document type never needs it.
    - No subscriber is needed for these stages; keep the mirrored fields non-editable on posted tables.
[7] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Type and length of mirrored fields.
    - Define a mirrored field with the exact same field number, data type and length on every table in the TransferFields cascade.
[8] `microsoft/knowledge/sales-purchase/restore-archived-sales-document-revalidates-custom-fields.md`: Keeping the archived Brand Code when an archived order is restored.
    - Mirror the field on Sales Header Archive and Sales Line Archive with the same number.
    - For a field defaulted from master data, reassign the archived value in OnAfterTransferFromArchToSalesHeader / OnAfterTransferFromArchToSalesLine without Modify.
    - Test restore with an item whose default changed after archiving.
[9] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of every added field.
    - Every Normal field a tableextension adds must set its own DataClassification matching the data it stores; never leave ToBeClassified or under-classify as SystemMetadata.
[10] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for customers, items, sales orders and warehouse locations.
    - Build fixtures with the Library codeunits, create parents first and Validate foreign keys; do not hand-roll Init/Insert.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

