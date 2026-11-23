# Feature design

> We sell through the web shop and through field sales, and sales prices for an item must be able to differ per sales channel. A price list line without a channel applies to every channel. The order taker picks the channel on each sales order line and the price must follow when the channel changes. The sales line must also show the price agreement number of the price list line that set its price. Pricing staff maintain these prices in the price worksheet.

**Result:** Complete design. **Business process:** Make sales prices on price list lines depend on a sales channel picked on each sales order line, and show the applied line's price agreement number on the sales line; this extends the standard price list calculation (Sales Line - Price, Price Calculation - V16) and price worksheet maintenance. **Knowledge used:** 21 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Within one price level the cheapest line wins, so a cheaper generic line beats a channel-specific one. Must a channel-specific line always win over a cheaper generic line? If yes, add OnAfterIsImprovedLine and OnAfterIsDegradedLine subscribers on Price Calculation - V16 and a test where the generic line is cheaper. _(affects: obj-channel-pricing-codeunit, t-channel-price-applied)_
2. Are sales channels user-maintained records (Sales Channel table, as designed) or a fixed list (enum)? Should installation create the web shop and field sales channels? _(affects: obj-sales-channel, obj-sales-channels-page, obj-sales-line-ext, obj-price-list-line-ext)_
3. The channel filter applies to every sales amount type, so line discounts on price lists can also be channel-specific. Is that wanted, or must the filter apply to prices only? _(affects: obj-channel-pricing-codeunit, obj-price-list-line-ext)_
4. The design mirrors Sales Channel Code and Price Agreement No. on Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line and Sales Line Archive so the values survive posting and archiving. Are any of these not needed, should the posted line pages show the fields, and must the values also reach Item Ledger Entry or Cust. Ledger Entry? _(affects: obj-sales-shipment-line-ext, obj-sales-invoice-line-ext, obj-sales-cr-memo-line-ext, obj-return-receipt-line-ext, obj-sales-line-archive-ext, t-posting-mirrors-fields)_
5. When Copy Document recalculates lines (Include Header off, or copying a posted shipment or return receipt), custom line fields are not copied. Must Sales Channel Code survive a document copy (subscriber to OnAfterRecalculateSalesLine of Copy Document Mgt.)? _(affects: obj-channel-pricing-codeunit, obj-sales-line-ext)_
6. Restoring an archived order revalidates the lines and reruns the price calculation. Should the restored line keep the archived Price Agreement No., or the one of the price list line that applies at restore time? _(affects: t-archive-restore, obj-sales-line-archive-ext)_
7. Suggest Lines in the price list and worksheet builds lines without a channel (generic). Should it ever set a channel or an agreement number on suggested lines? _(affects: obj-price-worksheet-ext, obj-price-worksheet-line-ext)_
8. The request names sales order lines. Should the channel also be entered on quotes, blanket orders, invoices, return orders and credit memos, and should it default from the header or the customer? _(affects: obj-sales-order-subform-ext, obj-sales-line-ext)_
9. Is Price Agreement No. a free code typed by pricing staff (Code[20] as designed) or a reference to an agreement record or number series? _(affects: obj-price-list-line-ext, obj-price-worksheet-line-ext, obj-sales-line-ext)_
10. Should Sales Channel Code be blocked or hidden on purchase and project price list lines, where it has no effect? _(affects: obj-price-list-lines-ext, obj-price-list-line-ext)_
11. Which Business Central version does the app target? From BC24 table-field tooltips are inherited by page fields; earlier targets need page-level tooltips. _(affects: obj-sales-order-subform-ext, obj-price-worksheet-ext, obj-price-list-lines-ext, obj-sales-channels-page)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Sales Channel | Supplemental table listing the sales channels (for example web shop and field sales) that price list lines and sales lines refer to. Primary key Code[10] named Code, one list page set as LookupPageID. Whether a table (rather than an enum) is wanted is open question q-channel-values. | Code (Code[10]): Primary key.; Description (Text[100]) | [13] [14] [16] |
| 2 | create | page | Sales Channels | List page for Sales Channel, plural name, set as LookupPageID and DrillDownPageID of the table; tooltips on the table fields. |  | [13] [14] [20] |
| 3 | extend | tableextension | Sales Line | Adds the channel the order taker picks and the agreement number of the price list line that set the unit price. Validating the channel recalculates the price through UpdateUnitPrice(FieldNo("Sales Channel Code")), which plans and then runs the recalculation. | Sales Channel Code (Code[10]): TableRelation "Sales Channel"; length equals the related key. OnValidate: if Type = Item and No. <> '' then UpdateUnitPrice(FieldNo("Sales Channel Code")). DataClassification CustomerContent declared explicitly.; Price Agreement No. (Code[20]): Editable = false; set only by the OnAfterSetPrice subscriber. DataClassification CustomerContent declared explicitly. | [2] [7] [3] [15] [16] |
| 4 | extend | tableextension | Price List Line | Adds the channel a sales price applies to (blank = every channel) and the price agreement number carried to the sales line. | Sales Channel Code (Code[10]): TableRelation "Sales Channel". Same field number as on Price Worksheet Line, Price Calculation Buffer and Sales Line. Blank means the line is generic.; Price Agreement No. (Code[20]): Same field number as on Price Worksheet Line. | [2] [3] [15] [16] |
| 5 | extend | tableextension | Price Worksheet Line | Twins of the custom Price List Line fields with the same field numbers, names and types, so CopyToWorksheetLine and ImplementNewPrices carry them with TransferFields. | Sales Channel Code (Code[10]): Same number, name, type and length as on Price List Line.; Price Agreement No. (Code[20]): Same number, name, type and length as on Price List Line. | [5] [2] [3] [12] |
| 6 | extend | tableextension | Price Calculation Buffer | Carries the sales line's channel into the calculation, which never reads the document line directly. | Sales Channel Code (Code[10]): Filled in OnAfterFillBuffer of Sales Line - Price. Buffer table is temporary. | [2] |
| 7 | extend | tableextension | Sales Shipment Line | Mirror of the two Sales Line fields so posting (InitFromSalesLine) or archiving keeps the channel and the agreement number. Chosen by the mirroring rule, not by the request; see open question q-mirror-targets. | Sales Channel Code (Code[10]): Same field number, name, type and length as on Sales Line; non-editable on this table; filled by the standard TransferFields call, no subscriber.; Price Agreement No. (Code[20]): Same field number, name, type and length as on Sales Line; non-editable on this table; filled by the standard TransferFields call, no subscriber. | [9] [10] [12] |
| 8 | extend | tableextension | Sales Invoice Line | Mirror of the two Sales Line fields so posting (InitFromSalesLine) or archiving keeps the channel and the agreement number. Chosen by the mirroring rule, not by the request; see open question q-mirror-targets. | Sales Channel Code (Code[10]): Same field number, name, type and length as on Sales Line; non-editable on this table; filled by the standard TransferFields call, no subscriber.; Price Agreement No. (Code[20]): Same field number, name, type and length as on Sales Line; non-editable on this table; filled by the standard TransferFields call, no subscriber. | [9] [10] [12] |
| 9 | extend | tableextension | Sales Cr.Memo Line | Mirror of the two Sales Line fields so posting (InitFromSalesLine) or archiving keeps the channel and the agreement number. Chosen by the mirroring rule, not by the request; see open question q-mirror-targets. | Sales Channel Code (Code[10]): Same field number, name, type and length as on Sales Line; non-editable on this table; filled by the standard TransferFields call, no subscriber.; Price Agreement No. (Code[20]): Same field number, name, type and length as on Sales Line; non-editable on this table; filled by the standard TransferFields call, no subscriber. | [9] [10] [12] |
| 10 | extend | tableextension | Return Receipt Line | Mirror of the two Sales Line fields so posting (InitFromSalesLine) or archiving keeps the channel and the agreement number. Chosen by the mirroring rule, not by the request; see open question q-mirror-targets. | Sales Channel Code (Code[10]): Same field number, name, type and length as on Sales Line; non-editable on this table; filled by the standard TransferFields call, no subscriber.; Price Agreement No. (Code[20]): Same field number, name, type and length as on Sales Line; non-editable on this table; filled by the standard TransferFields call, no subscriber. | [9] [10] [12] |
| 11 | extend | tableextension | Sales Line Archive | Mirror of the two Sales Line fields so posting (InitFromSalesLine) or archiving keeps the channel and the agreement number. Chosen by the mirroring rule, not by the request; see open question q-mirror-targets. | Sales Channel Code (Code[10]): Same field number, name, type and length as on Sales Line; non-editable on this table; filled by the standard TransferFields call, no subscriber.; Price Agreement No. (Code[20]): Same field number, name, type and length as on Sales Line; non-editable on this table; filled by the standard TransferFields call, no subscriber. | [9] [10] [12] [11] |
| 12 | extend | pageextension | Sales Order Subform | Lets the order taker pick Sales Channel Code on each line and shows Price Agreement No. read-only. Tooltips are defined on the table fields and inherited where the target runtime supports it (BC24+); otherwise declared on the page. |  | [9] [20] [21] |
| 13 | extend | pageextension | Price List Lines | Shows Sales Channel Code and Price Agreement No. on the price list lines so pricing staff can maintain them on sales price lists. |  | agent judgment |
| 14 | extend | pageextension | Price Worksheet | Shows Sales Channel Code and Price Agreement No. on the price worksheet, where pricing staff maintain the prices. |  | [5] [20] |
| 15 | create | codeunit | Sales Channel Pricing | Holds the event subscribers: fill the buffer, filter price list lines by channel with a blank fallback, add the channel to the duplicate key, and copy the applied line's agreement number to the sales line. |  | [2] [3] [4] |
| 16 | create | permissionset | Sales Channel - Objects | Assignable = false building block: execute on the new table, page and codeunit, listed object by object without wildcards. |  | [17] [18] [13] |
| 17 | create | permissionset | Sales Channel - Edit | Assignable set for pricing staff: includes Sales Channel - Objects and grants tabledata Sales Channel = RIMD. |  | [17] [18] [13] |
| 18 | create | permissionset | Sales Channel - Read | Assignable set for order takers: includes Sales Channel - Objects and grants tabledata Sales Channel = R. |  | [17] [18] [13] |

## 3. How the data flows

- **Sales Channel** → **Price List Line.Sales Channel Code**: entered by the user. Pricing staff pick the channel on a sales price list line; blank leaves the line generic. [2]
- **Price List Line** → **Price Worksheet Line**: standard TransferFields copy. CopyToWorksheetLine / InsertWorksheetLine copy by field number. [5]
- **Price Worksheet Line** → **Price List Line**: standard TransferFields copy. ImplementNewPrices (Implement Price Change) copies back by field number and activates the draft lines. [5]
- **Price List Line** → **Price List Line (Copy Lines target)**: other. CopyLine assigns the whole source record, so custom fields survive without a subscriber. [5]
- **Sales Channel** → **Sales Line.Sales Channel Code**: entered by the user. Order taker picks the channel on the sales order line; OnValidate calls UpdateUnitPrice so the price follows a change. [2] [7]
- **Sales Line.Sales Channel Code** → **Price Calculation Buffer.Sales Channel Code**: copied in an event subscriber. OnAfterFillBuffer of Sales Line - Price. [2]
- **Price Calculation Buffer.Sales Channel Code** → **Price List Line filter**: copied in an event subscriber. OnAfterSetFilters of Price Calculation Buffer Mgt. sets SetFilter("Sales Channel Code", '%1\|%2', channel, ''); RestoreFilters reapplies it for every source and level. [2] [4]
- **Price List Line.Price Agreement No.** → **Sales Line.Price Agreement No.**: copied in an event subscriber. OnAfterSetPrice of Sales Line - Price receives the applied line; GetLineWithCalculatedPrice assigns the line back, so no Modify. Runs for the automatic calculation and the Get Price lookup. [3] [4]
- **Sales Line** → **Sales Shipment Line**: standard TransferFields copy. InitFromSalesLine during posting copies both fields by field number. [10] [9]
- **Sales Line** → **Sales Invoice Line**: standard TransferFields copy. InitFromSalesLine during posting copies both fields by field number. [10] [9]
- **Sales Line** → **Sales Cr.Memo Line**: standard TransferFields copy. InitFromSalesLine during posting copies both fields by field number. [10] [9]
- **Sales Line** → **Return Receipt Line**: standard TransferFields copy. InitFromSalesLine during posting copies both fields by field number. [10] [9]
- **Sales Line** → **Sales Line Archive**: standard TransferFields copy. ArchiveManagement copies both fields by field number. [10] [11]
- **Sales Line Archive** → **Sales Line**: standard TransferFields copy. RestoreSalesDocument copies the archived line back, then revalidates No., Quantity and Unit Price, which reruns the price calculation with the restored channel; see q-restore-agreement. [11]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Sales Line - Price | `OnAfterFillBuffer` | Copy Sales Line.Sales Channel Code into the Price Calculation Buffer. |  | [2] |
| Price Calculation Buffer Mgt. | `OnAfterSetFilters` | Narrow price list lines to the line's channel or blank, so lines without a channel apply to every channel and documents without a channel still find generic prices. | Exit unless PriceCalculationBuffer."Price Type" = Sale, so purchase calculations (including the resource unit-cost pass of Sales Line - Price) are unaffected. · Use SetFilter with '%1\|%2' (value or blank), never SetRange. | [2] [4] [8] |
| Price List Management | `OnAfterSetAssetFilters` | Make the channel part of the duplicate key, so lines that differ only by channel are not reported as duplicates when a price list is activated. |  | [2] |
| Sales Line - Price | `OnAfterSetPrice` | Copy Price Agreement No. of the applied price list line to the sales line; clear it when the price comes from the fallback line. | Exit unless AmountType = Price, so the discount pass does not overwrite the value. · Exit unless the sales line is an Item line and PriceListLine."Price Type" = Sale (resource lines also run a Purchase calculation for unit cost). · If PriceListLine.IsRealLine() is false, clear Price Agreement No. · Assign without Modify; the line is assigned back by GetLineWithCalculatedPrice. | [3] [8] |

## 5. Setup, permissions and lifecycle

- **setup**: The feature requires the new pricing experience (SalesPrices feature key enabled, Price Calculation - V16 in Price Calculation Setup); with the key off, the Version 15.0 engine reads the old tables and ignores price list lines. State this requirement in the app documentation. [1] [4]
- **permissions**: Ship Sales Channel - Objects (non-assignable) included by Sales Channel - Edit (pricing staff, RIMD) and Sales Channel - Read (order takers, R); enumerate every object, no wildcards. [17] [18] [13]
- **privacy**: Sales Channel: table-level DataClassification CustomerContent. Every field added by a table extension declares its own DataClassification (CustomerContent on Sales Line, Price List Line, Price Worksheet Line and the posted/archive line tables; SystemMetadata on the temporary Price Calculation Buffer field). [16]

## 6. Tests

1. **t-channel-price-applied** [2] [6] [3] [19]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, an active All Customers sales price list with a generic line (no channel) and a WEB line with a lower unit price and agreement A-WEB
    - When a sales order line for the item is created and Sales Channel Code is validated to WEB
    - Then Unit Price equals the WEB line price and Price Agreement No. is A-WEB
2. **t-other-channel-line-ignored** [2] [6] [19]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, an active price list with a generic line (agreement A-GEN) and a FIELD line with a lower price
    - When a sales order line is created with Sales Channel Code WEB
    - Then Unit Price equals the generic line price and Price Agreement No. is A-GEN; the FIELD line is not used
3. **t-blank-channel-uses-generic** [2] [6]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, an active price list with a generic line and a WEB line
    - When a sales order line is created without a channel
    - Then Unit Price equals the generic line price (SetFilter with blank fallback, not SetRange)
4. **t-channel-change-recalculates** [7] [2] [3]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, an existing sales order line priced from the WEB line
    - When Sales Channel Code is validated from WEB to FIELD
    - Then Unit Price and Price Agreement No. change to those of the FIELD line
5. **t-fallback-clears-agreement** [3]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, a sales order line priced from a WEB line with agreement A-WEB
    - When the channel is changed to FIELD, for which no price list line exists and no generic line exists
    - Then Unit Price falls back to the item price and Price Agreement No. is blank
6. **t-discount-pass-keeps-agreement** [3]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, an active price list line for the price with agreement A-P and an active line-discount price list line with agreement A-D
    - When a sales order line is created for the item
    - Then Price Agreement No. is A-P, not A-D
7. **t-duplicate-check-ignores-channel-variants** [2] [6]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, a draft sales price list with two lines for the same item, unit of measure and dates, one for WEB and one for FIELD
    - When the header Status is validated to Active
    - Then the price list activates without reporting duplicate price lines
8. **t-purchase-unaffected** [8] [2]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, a vendor and an active purchase price list line for the item
    - When a purchase order line for the item is created
    - Then Direct Unit Cost equals the purchase price list line amount; the channel filter is not applied to purchase calculations
9. **t-worksheet-round-trip** [5]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, an active price list line with channel WEB and agreement A-WEB
    - When the line is copied into the Price Worksheet, its price changed, and Implement Price Change is run
    - Then the resulting active Price List Line keeps Sales Channel Code WEB and Price Agreement No. A-WEB
10. **t-copy-lines-keeps-fields** [5]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, a price list line with channel WEB and agreement A-WEB
    - When Copy Lines copies it into another sales price list
    - Then the copied line has Sales Channel Code WEB and Price Agreement No. A-WEB
11. **t-posting-mirrors-fields** [9] [10] [19]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, a sales order line priced from the WEB line with agreement A-WEB
    - When the order is posted with Ship and Invoice
    - Then the Sales Shipment Line and Sales Invoice Line carry Sales Channel Code WEB and Price Agreement No. A-WEB; a return order and a credit memo posted the same way carry the values on Return Receipt Line and Sales Cr.Memo Line
12. **t-archive-restore** [11] [10]
    - Given Given extended price calculation enabled with Library - Price Calculation (EnableExtendedPriceCalculation), sales channels WEB and FIELD, a customer and an item created with library codeunits, a sales order line with channel WEB and agreement A-WEB that is archived
    - When the archived version is restored
    - Then Sales Line Archive held both values and the restored line has Sales Channel Code WEB and a Price Agreement No. per the answer to q-restore-agreement

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined from the request; no repository was supplied.
- obj-price-list-lines-ext (showing the fields on the Price List Lines page) is not covered by an opened BCQuality article and rests on the agent's judgment.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-pricing-rule.md`: Overall decision map for the pricing rule and the new-experience requirement
    - Keep the rule in price list data plus events of the standard calculation; do not compute prices in OnUpdateUnitPriceOnBeforeFindPrice with IsHandled.
    - A pricing extension built on price lists must state that it requires the new pricing experience.
    - Whether a new rule should outrank existing prices is a business decision; raise it as a question.
[2] `microsoft/knowledge/pricing/custom-price-list-line-attribute-needs-buffer-filter-and-duplicate-check.md`: Channel as a price list line attribute: buffer field, blank-fallback filter, duplicate key, recalculation
    - Add the field to Price List Line, Price Worksheet Line (same number), Price Calculation Buffer and Sales Line.
    - Fill the buffer in OnAfterFillBuffer of each line type in scope.
    - Filter in OnAfterSetFilters with SetFilter(Field, '%1\|%2', Value, ''), never SetRange.
    - A specific line wins over a cheaper generic one only if OnAfterIsImprovedLine/OnAfterIsDegradedLine say so.
    - Add the attribute to the duplicate filters in OnAfterSetAssetFilters of Price List Management.
    - Do not model the attribute as a new price source.
[3] `microsoft/knowledge/pricing/copy-applied-price-list-line-fields-in-onaftersetprice.md`: Carrying Price Agreement No. from the applied price list line to the sales line
    - Copy in OnAfterSetPrice of Sales Line - Price, the only event that receives the applied line.
    - Copy only for AmountType Price; check the price type because resource lines also run a Purchase calculation.
    - Clear the value when IsRealLine() is false (fallback price).
    - Do not look the price list line up again in OnAfterApplyPrice/OnAfterUpdateUnitPrice.
    - Give the field a twin with the same number on Price Worksheet Line.
[4] `microsoft/knowledge/pricing/document-line-price-selection-runs-by-source-level-then-best-price.md`: How the standard calculation selects a line and which events change it
    - Change the result through events of the calculation and leave selection to it.
    - Levels decide before amounts; within a level the cheapest line wins.
    - Tests call EnableExtendedPriceCalculation of Library - Price Calculation because the feature key decides the engine.
[5] `microsoft/knowledge/pricing/price-worksheet-and-copy-lines-carry-custom-fields-by-field-number.md`: Keeping both fields through the price worksheet, Copy Lines and Suggest Lines
    - Every custom Price List Line field needs a twin on Price Worksheet Line with the same number, name and type, shown on the worksheet page.
    - Copy Lines keeps custom fields by record assignment; Suggest Lines never fills them.
    - Implement worksheet lines through ImplementNewPrices, not by writing Price List Line.
[6] `microsoft/knowledge/pricing/create-price-lists-from-code-through-header-defaults-and-status-validation.md`: Building active price lists in tests and the duplicate check on activation
    - Create lines through CopyFrom(PriceListHeader) and activate with Validate(Status, Active) on the header, never by assigning Status.
    - Library - Price Calculation builds headers and lines the same way.
[7] `microsoft/knowledge/data-modeling/new-price-source-must-add-candidate-and-trigger-recalculation.md`: Recalculating the price when the channel changes on an existing line
    - Call SalesLine.UpdateUnitPrice(FieldNo(<field>)) from the field's validation; UpdateUnitPriceByField alone recalculates nothing unless the field was planned.
[8] `microsoft/knowledge/pricing/purchase-and-project-prices-use-their-own-price-type-sources-and-fields.md`: Keeping the rule to sales and guarding purchase calculations
    - Subscribe to the Line With Price codeunit of each document in scope; sales, purchase and project use different price types, sources and amount fields.
    - Sales Line - Price also runs with the Purchase price type for resource unit costs.
[9] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Deciding which posting stages the two sales line fields reach and the pages that show them
    - Plan one step per stage the field must reach, the page extensions that show it, and a test that posts and reads the value back from every target.
[10] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring the fields on posted line and archive tables
    - Same field number, name, type and length on every TransferFields target the plan needs; keep mirrored fields non-editable on posted tables; no subscriber needed.
[11] `microsoft/knowledge/sales-purchase/restore-archived-sales-document-revalidates-custom-fields.md`: Archive and restore of sales lines
    - Mirror the field on Sales Line Archive with the same number.
    - Restore revalidates standard fields, which reruns defaults; reassign archived values in OnAfterTransferFromArchToSalesLine without Modify only when needed.
[12] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Type and length of the mirrored fields
    - Mirrored fields must have the exact same field number, data type and length on every table in the cascade.
[13] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Decisions for the new Sales Channel entity: table type, privacy, pages, permissions
    - Plan table type, privacy, pages and permission sets for a new record type; a row the request does not settle is a question, not a default.
[14] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Sales Channel as a Supplemental table
    - Supplemental table: primary key Code[10] named Code, one List page with plural name set as LookupPageID.
[15] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Length of fields related to Sales Channel
    - A field with an unconditional TableRelation has the same type and exact length as the related key.
[16] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Data classification of the new table and extension fields
    - A table-level classification is inherited by the table's own fields; every Normal field added by a tableextension must declare its own DataClassification.
[17] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Permission set structure
    - Use non-assignable building blocks composed into assignable role sets through IncludedPermissionSets.
[18] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Permission set grants
    - Enumerate each object and grant only the needed letters; no * wildcards.
[19] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures
    - Create customers, items and sales documents with the test library codeunits, parents before dependents; validate foreign keys.
[20] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips on the new page fields
    - User-facing page fields need an explicit or inherited tooltip; define shared text on the table field from runtime 13.0; add page-level tooltips on earlier targets.
[21] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Tooltip inheritance from the table fields (applies from BC24)
    - From BC24 a bound page field inherits the table field's ToolTip; do not duplicate it on the page.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v2. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
