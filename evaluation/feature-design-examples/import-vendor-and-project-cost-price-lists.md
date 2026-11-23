# Feature design

> A nightly job imports vendor purchase prices and project resource cost rates from a partner file into Business Central price lists and makes them effective the same night. Each imported line carries the vendor's agreement number, which must appear on purchase lines and on project planning lines whenever that price is used. Purchasers sometimes adjust the imported prices in the price worksheet before they are implemented.

**Result:** Complete design. **Business process:** A nightly background job imports vendor purchase prices and project resource cost rates into price lists (the price list model of the new pricing experience) and activates them, and the purchase and project price calculation copies the vendor agreement number of the applied price list line to purchase lines and project planning lines, including after purchasers adjust prices in the Price Worksheet. **Knowledge used:** 20 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. How does the partner file reach Business Central for an unattended nightly run (for example external storage, an API endpoint the partner pushes to, or an on-premises folder), and what is its format (CSV, fixed width, XML) and text encoding? _(affects: partner-price-xmlport, import-job-codeunit, import-setup-table)_
2. The request says imported prices become effective the same night and that purchasers sometimes adjust them in the price worksheet before they are implemented. Should the job activate the imported prices directly (purchasers then adjust active prices through the worksheet), or write worksheet lines that a purchaser or the job implements later? _(affects: import-job-codeunit, price-worksheet-pageext)_
3. When a night's file contains a price for a vendor/item or resource that already has an imported active line, should the job update that line, end-date it and add a new line, or create a new price list per run? Activation opens the Duplicate Price Lines page on duplicates, which cannot run in the job queue, and updating active lines requires Allow Editing Active Price. _(affects: import-job-codeunit, import-setup-table)_
4. Do the project resource cost rates apply to all projects, to a specific project, or to a project task, and should they outrank other project cost prices? The file must identify the project when it is specific. _(affects: import-job-codeunit)_
5. How are the partner's vendor, item, resource and unit of measure identifiers mapped to Business Central numbers, and in which currency and date range are the prices valid? _(affects: import-buffer-table, import-job-codeunit)_
6. What is the maximum length and format of the vendor agreement number (assumed Code[20])? _(affects: price-list-line-ext, price-worksheet-line-ext, purchase-line-ext, job-planning-line-ext, posted-purchase-line-mirrors)_
7. May purchasers edit the agreement number in the price worksheet or on purchase and planning lines, or is it always the imported value? _(affects: price-worksheet-pageext, purchase-subform-pageext, job-planning-lines-pageext)_
8. The design mirrors the agreement number on posted purchase receipt, invoice, credit memo and return shipment lines and on the purchase line archive, as the purchase mirroring article requires unless excluded. Should any of these be excluded? _(affects: posted-purchase-line-mirrors)_
9. Must the agreement number continue past the planning line and purchase line into project journal lines and project ledger entries (Job Transfer Line from planning lines and from purchase lines with a project), into sales invoice lines created from planning lines (Job Create-Invoice), or onto sales lines of type Resource whose unit cost uses the purchase calculation? _(affects: job-planning-line-ext, purchase-line-ext, agreement-subscribers-codeunit)_
10. When a purchase document is copied with Recalculate Lines on, the price is recalculated and the agreement number follows the current price; with it off the source value is kept. Is that acceptable, or must the source agreement number always survive a copy? _(affects: purchase-line-ext)_
11. Lines added with Suggest Lines in the worksheet or price list carry no agreement number. Should they stay blank? _(affects: price-worksheet-line-ext, price-list-line-ext)_
12. Which purchase document subforms (order, invoice, credit memo, quote, return order) should show the agreement number? _(affects: purchase-subform-pageext)_
13. Who creates and schedules the nightly job queue entry (an administrator, or a setup action), at what time, and under which user? ActivateDraftLines activates only lines last modified by the user running it. _(affects: import-job-codeunit, import-setup-page, permission-set)_
14. Which Business Central version and runtime does the app target? Tooltip inheritance from table fields requires BC24 (runtime 13.0). _(affects: price-list-lines-pageext, price-worksheet-pageext, purchase-subform-pageext, job-planning-lines-pageext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Price List Line | Store the vendor's agreement number on every imported purchase and project cost price list line, so the price calculation can hand it to the document line that uses the price. | Vendor Agreement No. (Code[20]): Same field number, name, type and length as on Price Worksheet Line, Purchase Line and Job Planning Line. DataClassification set on the field. ToolTip on the table field. Length Code[20] is an assumption until question q-agreement-format is answered. | [3] [6] [17] [18] |
| 2 | extend | tableextension | Price Worksheet Line | Twin of the Price List Line field with the same field number, name and type, so the worksheet round trip (copy to worksheet, adjust, Implement Price Change) keeps the agreement number. | Vendor Agreement No. (Code[20]): Same field number as on Price List Line; TransferFields copies it in both directions. | [6] [15] [17] |
| 3 | extend | tableextension | Purchase Line | Show which vendor agreement the applied purchase price came from. Filled only by the OnAfterSetPrice subscriber, never looked up again. | Vendor Agreement No. (Code[20]): Same field number, type and length as the posted purchase line and archive mirrors. | [3] [7] [14] [17] |
| 4 | extend | tableextension | Job Planning Line | Show which vendor agreement the applied project resource cost came from. Filled only by the OnAfterSetPrice subscriber on the Purchase (cost) pass. | Vendor Agreement No. (Code[20]): Filled from the Purchase-type price list line that set Unit Cost / Direct Unit Cost (LCY). | [3] [7] [17] |
| 5 | extend | tableextension | Purch. Rcpt. Line | Mirror of the Purchase Line field so posting keeps it (InitFromPurchLine uses TransferFields). One table extension each on Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line, Return Shipment Line and Purchase Line Archive, non-editable. Chosen by the article, not by the request; see question q-posted-mirrors. | Vendor Agreement No. (Code[20]): Same field number, name, type and length on Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line, Return Shipment Line and Purchase Line Archive; non-editable. | [14] [15] [17] |
| 6 | create | table | Partner Price Import Setup | Singleton setup (Primary Key Code[10], blank) holding the import parameters the job needs, such as the file source settings decided in q-file-transport and the default handling of re-imported prices. |  | [16] |
| 7 | create | page | Partner Price Import Setup | Card page over the singleton setup with InsertAllowed = false, DeleteAllowed = false and an open-time guard that inserts the blank row when missing. |  | [16] |
| 8 | create | table | Partner Price Import Buffer | Temporary buffer (TableType = Temporary) that receives one row per partner file line: price kind (vendor purchase price or project resource cost rate), vendor, asset (item or resource), project, unit of measure, currency, dates, amount and agreement number. Rests on judgment; no BCQuality article covers the staging shape. |  | agent judgment |
| 9 | create | xmlport | Partner Price Import | Import-direction XMLport that reads the partner file into the temporary buffer. If the file is delimited or fixed-width text, set TextEncoding explicitly to the partner's encoding. Called without capturing the Xmlport.Import return value, so a failed import raises an error and stops the run. |  | [11] [10] |
| 10 | create | codeunit | Partner Price Import Job | Job queue entry point (TableNo = Job Queue Entry) run nightly. Non-interactive: no Confirm, Page.Run(Modal), Report.Run(Modal), upload, download or File type I/O. Gets the file as a stream, imports it through the XMLport, then creates price list headers and lines through header defaults (vendor purchase lists with Direct Unit Cost; project lists with Price Type Purchase set before Source Type, Unit Cost and Direct Unit Cost), copies the agreement number to each line before Insert(true), and activates through Validate(Status, Active) + Modify(true), or ActivateDraftLines after changes to an active list. Errors that invalidate the run propagate to the job queue log. |  | [2] [8] [9] [12] [10] [4] [7] |
| 11 | create | codeunit | Vendor Agreement Price Subscr. | Event subscribers that copy the agreement number from the applied price list line to Purchase Line and Job Planning Line in OnAfterSetPrice of each document's own Line With Price codeunit. Leaves the price selection to the standard calculation. |  | [3] [7] [5] [1] |
| 12 | extend | pageextension | Price List Lines | Show the agreement number on the price list lines subpage so purchasers see which agreement each imported line carries. Tooltip inherited from the table field where the runtime supports it. |  | [18] |
| 13 | extend | pageextension | Price Worksheet | Show the worksheet twin field on the Price Worksheet page, where purchasers adjust imported prices before Implement Price Change. |  | [6] [18] |
| 14 | extend | pageextension | Purchase Order Subform | Show the agreement number on purchase document lines (non-editable). Which other purchase subforms get it is question q-pages. |  | [18] |
| 15 | extend | pageextension | Job Planning Lines | Show the agreement number on project planning lines (non-editable). |  | [18] |
| 16 | create | permissionset | Partner Price Import | Assignable permission set covering setup and normal use without SUPER: the setup table and page, the XMLport, the job codeunit, the subscriber codeunit, and the tabledata the job writes (Price List Header, Price List Line). Validate the nightly run as a user holding only the app roles. |  | [13] |

## 3. How the data flows

- **Partner file** → **Partner Price Import Buffer (temporary)**: other. Xmlport.Import from an InStream, without capturing the return value; TextEncoding explicit for text formats. How the file reaches Business Central unattended is open (q-file-transport): File type I/O is OnPrem-only, and upload is a client callback a job queue handler must not make. [10] [11] [12] [8]
- **Partner Price Import Buffer (vendor purchase price rows)** → **Price List Header / Price List Line (vendor purchase price list)**: field validation. Header: validate Source Type Vendor (derives Price Type Purchase and Source Group) and Source No., currency and dates, Insert(true). Line: Price List Code, SetNextLineNo, CopyFrom(header), validate Asset Type, Asset No., unit of measure, Minimum Quantity and Direct Unit Cost; assign Vendor Agreement No.; Insert(true). Activate with Validate(Status, Active) + Modify(true). [4] [7]
- **Partner Price Import Buffer (project resource cost rows)** → **Price List Header / Price List Line (project purchase price list)**: field validation. Header: set Price Type Purchase before validating Source Type (All Jobs / Job / Job Task, see q-project-source), number series from Jobs Setup. Line: CopyFrom(header), Asset Type Resource, validate Unit Cost (and Direct Unit Cost), assign Vendor Agreement No., Insert(true); activate through the Status validation. [4] [7]
- **Price List Line** → **Price Worksheet Line**: standard TransferFields copy. CopyToWorksheetLine / InsertWorksheetLine copy by field number; the twin field keeps the agreement number. [6]
- **Purchaser** → **Price Worksheet Line**: entered by the user. Purchaser adjusts the imported amount in the Price Worksheet before Implement Price Change. Whether the agreement number itself may be edited is q-agreement-editable. [6]
- **Price Worksheet Line** → **Price List Line**: standard TransferFields copy. ImplementNewPrices: PriceListLine.TransferFields(PriceWorksheetLine), modified line set to Draft, then ActivateDraftLines. Custom code calls ImplementNewPrices and never writes Price List Line itself. [6] [4]
- **Price List Line (applied by Purchase Line - Price)** → **Purchase Line**: copied in an event subscriber. OnAfterSetPrice of Purchase Line - Price; assigned without Modify because GetLineWithCalculatedPrice writes the line back. [3] [7]
- **Price List Line (applied by Job Planning Line - Price, Purchase pass)** → **Job Planning Line**: copied in an event subscriber. OnAfterSetPrice of Job Planning Line - Price on the Purchase pass, which sets Unit Cost and Direct Unit Cost (LCY) for resources. [3] [7]
- **Purchase Line** → **Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line, Return Shipment Line, Purchase Line Archive**: standard TransferFields copy. Standard InitFromPurchLine and archiving copy by field number; no subscriber. Article-chosen stage, see q-posted-mirrors. [14] [15]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Purchase Line - Price | `OnAfterSetPrice` | Copy Vendor Agreement No. from the applied price list line to the purchase line whenever that purchase price is used, for the automatic calculation and for Get Price (Pick). | Exit unless AmountType is Price, so the discount pass cannot overwrite the value with its own line. · Exit unless CurrPriceType is Purchase. · When PriceListLine.IsRealLine() is false (fallback, Line No. 0), clear the agreement number because the price no longer comes from a price list. · Assign without Modify; the line is a copy written back by GetLineWithCalculatedPrice. · Do not look the price list line up again in OnAfterApplyPrice or OnAfterUpdateUnitPrice. | [3] [7] [5] |
| Job Planning Line - Price | `OnAfterSetPrice` | Copy Vendor Agreement No. from the applied project cost price list line to the project planning line whenever that resource cost rate is used. | Exit unless AmountType is Price. · Exit unless CurrPriceType is Purchase: the planning line is priced twice (Sale for the price, Purchase for the cost) and the imported rates are costs. This deliberately differs from the article's sample, which copies on the Sale pass. · When PriceListLine.IsRealLine() is false, clear the agreement number. · Assign without Modify. | [3] [7] |

## 5. Setup, permissions and lifecycle

- **setup**: State that the app requires the new pricing experience (price lists, SalesPrices feature key on). With the key off the Version 15.0 implementation reads the old tables and the imported price lists are ignored. [1] [5]
- **setup**: Partner Price Import Setup is a singleton card: blank Primary Key Code[10], InsertAllowed/DeleteAllowed false, row inserted on first open, read with Get(). [16]
- **setup**: Re-imports that change active price list lines need Allow Editing Active Price in Purchases & Payables Setup (purchase price type); Modify(true) then sets the line to Draft and ActivateDraftLines must run as the job queue user. With the setting off, validations on active lines fail on TestStatusDraft. Choice depends on q-reimport. [4]
- **background**: One recurring nightly job queue entry runs Partner Price Import Job. The handler is non-interactive and lets errors that invalidate the run propagate so the entry shows the error and applies its retries. Price list activation must not reach the Duplicate Price Lines page, which is UI; see q-reimport. [2] [8] [9] [4]
- **permissions**: Ship an assignable permission set that covers the setup page, the job codeunit, the XMLport, the subscriber codeunit and the Price List Header/Line tabledata the job writes; test the setup and a nightly run as a user without SUPER. [13]
- **privacy**: Set DataClassification on every Vendor Agreement No. field in each table extension (a tableextension has no table-level value to inherit); never leave ToBeClassified or use SystemMetadata for it. [17]

## 6. Tests

1. **import-vendor-price-creates-active-purchase-line** [4] [7] [19] [20]
    - Given Extended price calculation enabled with Library - Price Calculation; a vendor and an item created with library codeunits; a partner file row for that vendor and item with a fixed direct unit cost and agreement number.
    - When The import job codeunit runs.
    - Then A price list header with Price Type Purchase and Source Type Vendor exists, and its line has Status Active, Price Type Purchase, the Direct Unit Cost and the agreement number.
2. **import-resource-cost-creates-active-project-line** [4] [7] [19]
    - Given Extended price calculation enabled; a project and a resource created with library codeunits; a partner file row with a fixed resource cost rate and agreement number.
    - When The import job codeunit runs.
    - Then A project price list with Source Group Job and Price Type Purchase exists, and its active line carries the Unit Cost and the agreement number.
3. **purchase-line-gets-agreement-no** [3] [7] [5] [19]
    - Given An imported, active vendor purchase price list line with an agreement number.
    - When A purchase order line is created for that vendor and item with library codeunits.
    - Then Direct Unit Cost equals the imported amount and Vendor Agreement No. equals the imported agreement number.
4. **purchase-line-discount-pass-keeps-agreement** [3]
    - Given An imported vendor price line with an agreement number and a separate active purchase line discount for the same vendor and item without an agreement number.
    - When A purchase line is created for that vendor and item.
    - Then Vendor Agreement No. still equals the price line's agreement number (the Discount pass did not overwrite it).
5. **purchase-line-fallback-clears-agreement** [3]
    - Given A purchase line that got its price and agreement number from an imported price list line.
    - When The line's Buy-from Vendor context changes to a vendor with no imported price (or the price list line is no longer applicable) and the price is recalculated.
    - Then Vendor Agreement No. is blank because the fallback line (IsRealLine false) carries no agreement.
6. **planning-line-gets-agreement-on-cost-pass** [3] [7] [19]
    - Given An imported active project resource cost line with an agreement number and a project sales price for the same resource without one.
    - When A Job Planning Line of type Resource is created for that project and resource.
    - Then Unit Cost equals the imported rate and Vendor Agreement No. equals the imported agreement number; the Sale pass did not clear it.
7. **worksheet-round-trip-keeps-agreement** [6]
    - Given An imported active vendor price list line with an agreement number copied to the Price Worksheet.
    - When The worksheet line's Direct Unit Cost is changed and Implement Price Change (ImplementNewPrices) runs.
    - Then The price list line has the new amount, Status Active and the original agreement number.
8. **failed-file-import-propagates-error** [9] [10]
    - Given A partner file that the XMLport cannot import.
    - When The import job codeunit runs.
    - Then The run ends with an error (the job queue entry would show it) and no price list header or line is created or activated.
9. **import-job-runs-without-ui** [8]
    - Given A valid partner file and no UI handlers registered.
    - When The import job codeunit runs as a job queue entry would run it.
    - Then The run completes without any Confirm, page or report call (an unhandled UI call would abort the test).
10. **text-file-encoding-preserved** [11]
    - Given A partner text file in the partner's encoding containing non-ASCII characters in a description or agreement field (only when the format is VariableText or FixedText).
    - When The import job codeunit runs.
    - Then The imported values equal the original characters.
11. **posted-purchase-lines-keep-agreement** [14]
    - Given A purchase order line priced from an imported line with an agreement number.
    - When The order is archived, then received and invoiced; a credit memo and a return shipment are posted for the same item.
    - Then Purchase Line Archive, Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line and Return Shipment Line carry the same agreement number (only if q-posted-mirrors keeps these stages).

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Transport of the partner file into Business Central for an unattended job is not covered by BCQuality knowledge; File type I/O is OnPrem-only and upload is a client callback a job queue handler must not make (q-file-transport).
- Partner Price Import Buffer (temporary staging table) rests on the agent's judgment; no BCQuality article covers its shape.
- Creating and scheduling the recurring job queue entry is not covered by BCQuality knowledge (q-job-queue-entry).
- Avoiding the Duplicate Price Lines page during background activation is only described, not prescribed, by BCQuality knowledge (q-reimport).
- bc-version, countries and application-area are not stated in the request; all cited articles are [all]/w1/[all], so applicability is unaffected except the BC24 tooltip condition.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-pricing-rule.md`: Decision map for the pricing part of the design: price list data plus calculation events, documents in scope, maintenance, worksheet and tests.
    - Prefer price list data plus events of the standard calculation over code that computes prices.
    - A pricing extension built on price lists must state that it requires the new pricing experience.
    - Do not subscribe to OnUpdateUnitPriceOnBeforeFindPrice with IsHandled to compute the price from a custom table.
    - Whether a new rule should outrank existing prices is a business decision; raise it as an open question instead of choosing a level.
[2] `microsoft/knowledge/feature-design/plan-api-exposure-and-background-sync.md`: Background-processing row of the planning map: the nightly import runs from a job queue entry whose handler has no UI and propagates failures.
    - Job queue handler: no UI, failures propagated so the entry shows an error.
    - Facts the request leaves open, such as who calls whom and how often, are questions for the requester.
[3] `microsoft/knowledge/pricing/copy-applied-price-list-line-fields-in-onaftersetprice.md`: Copying the agreement number from the applied price list line to Purchase Line and Job Planning Line, with its guards.
    - Copy custom price list line fields in OnAfterSetPrice of the document's Line With Price codeunit; SetPrice never copies them.
    - Copy only for the amount type the field belongs to; the event runs once for Discount and once for Price.
    - Check the price type on documents that compute costs too.
    - Decide what a fallback line (IsRealLine false) means; usually clear the value.
    - Assign without Modify; the line is written back by GetLineWithCalculatedPrice.
    - Do not look the price list line up again in OnAfterApplyPrice or OnAfterUpdateUnitPrice.
    - Add the same field with the same number to Price Worksheet Line.
[4] `microsoft/knowledge/pricing/create-price-lists-from-code-through-header-defaults-and-status-validation.md`: Creating and activating the vendor and project price lists from the import job, and re-activating changed lines.
    - Header: Init, set Price Type for project lists, validate Source Type and Source No., currency and dates, then Insert(true).
    - Line: Price List Code, SetNextLineNo, CopyFrom(header), validate Asset Type, Asset No., unit of measure, Minimum Quantity and amount, then Insert(true).
    - Activate with Validate(Status, Active) on the header and Modify(true); never assign Status and Modify.
    - After code changes to an active list, call ActivateDraftLines; it activates only Draft lines last modified by the current user.
    - Activation resolves duplicate prices and opens the Duplicate Price Lines page when duplicates exist.
    - With Allow Editing Active Price on, Modify(true) on an active line sets it back to Draft; with it off, validations fail on TestStatusDraft.
[5] `microsoft/knowledge/pricing/document-line-price-selection-runs-by-source-level-then-best-price.md`: Leaving price selection to the standard calculation, and enabling the extended calculation in tests.
    - Change the result through the events of the calculation and leave the selection to it.
    - Do not read Price List Line with a custom query after IsHandled in OnUpdateUnitPriceOnBeforeFindPrice.
    - With the SalesPrices feature key off, the Version 15.0 implementation reads the old tables and price list lines are ignored.
    - Tests bind Library - Price Calculation and call EnableExtendedPriceCalculation.
[6] `microsoft/knowledge/pricing/price-worksheet-and-copy-lines-carry-custom-fields-by-field-number.md`: Keeping the agreement number through the Price Worksheet adjustment and Implement Price Change.
    - Give every custom Price List Line field a twin on Price Worksheet Line with the same field number, name and type, and show it on the worksheet page.
    - Suggest Lines builds new lines without custom values; fill values it cannot know in OnAddLineOnAfterPopulatePriceListLineFields.
    - Code that implements worksheet lines calls ImplementNewPrices and does not write Price List Line itself.
[7] `microsoft/knowledge/pricing/purchase-and-project-prices-use-their-own-price-type-sources-and-fields.md`: Price types, amount fields and per-document events for vendor purchase prices and project resource cost rates.
    - For each document in scope, name the price type, the Line With Price codeunit and the amount field.
    - Subscribe to each codeunit's own events; sales, purchase and project codeunits publish their own with different parameters.
    - Write purchase prices to Direct Unit Cost and project cost prices to Unit Cost.
    - Set Price Type explicitly before validating Source Type when creating project price lists.
    - Job Planning Line is priced twice, Sale and Purchase; for resources the Purchase pass copies Unit Cost and Direct Unit Cost (LCY).
[8] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Shape of the nightly job queue handler and the no-UI test.
    - Make the job queue entry point non-interactive: no Confirm, Page.Run(Modal), Report.Run(Modal), Hyperlink, upload or download.
    - Do not use Message as the only success or failure notification.
    - Use GuiAllowed only to isolate optional UI behavior, never to skip a required decision.
[9] `microsoft/knowledge/performance/job-queue-handlers-must-propagate-failures.md`: Failure handling of the nightly import.
    - Let an error that invalidates the whole run propagate out of the job queue entry point.
    - Per-item failures may be collected only if the batch persists or emits an observable aggregate outcome.
[10] `microsoft/knowledge/xmlport/xmlport-import-export-return-value-controls-failure-handling.md`: Calling the import XMLport from the job.
    - Omit the Xmlport.Import return value when a failed import must stop the process.
    - If the return value is used, every later step must depend on it; never capture it and continue as if the import succeeded.
[11] `microsoft/knowledge/xmlport/xmlport-text-encoding-defaults-to-msdos.md`: Encoding of a text-format partner file (applies only if the format is VariableText or FixedText).
    - Set TextEncoding explicitly on every VariableText or FixedText XMLport to the encoding the partner uses.
    - Not applicable when Format is Xml.
[12] `microsoft/knowledge/appsource/file-datatype-saas.md`: Ruling out File type I/O for reading the partner file.
    - File.Open/Create/Read/Write are OnPrem-only and no server path exists online.
    - Use the stream-based equivalents and stage the content in a TempBlob between the stream and the parsing code.
[13] `microsoft/knowledge/appsource/permission-sets-cover-setup-and-usage-without-super.md`: Permission set for setup and the nightly run.
    - Provide assignable permission sets that cover setup and normal usage without SUPER.
    - Grant the minimum required operations; no wildcards.
[14] `microsoft/knowledge/sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md`: Article-chosen stages: posted purchase lines and the purchase line archive.
    - Give the field the same number, name, type and length on Purchase Line and on every posted and archive line table the plan needs: Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line, Return Shipment Line and Purchase Line Archive.
    - No subscriber is needed; keep the mirrored fields non-editable on posted tables.
[15] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definitions of every mirrored agreement number field.
    - Define a mirrored field with the exact same number, data type and length on every table in the TransferFields cascade.
[16] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Shape of the import setup table and card.
    - Primary Key Code[10] as the sole key, blank value, one row.
    - Card page with InsertAllowed = false, DeleteAllowed = false and an open-time guard that inserts the missing row.
[17] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Classification of the new fields.
    - Every Normal field added by a tableextension must set its own DataClassification.
    - Do not leave ToBeClassified or under-classify as SystemMetadata.
[18] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Tooltips of the agreement number on the page extensions (applies from BC24, runtime 13.0).
    - On runtime 13.0 or later a bound page field inherits the table field's ToolTip; do not duplicate it on the page.
    - A field with neither inline nor inherited ToolTip is a real gap.
[19] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for vendors, items, resources, projects and purchase documents in the tests.
    - Build prerequisite records with the test Library codeunits, parents first, validating foreign keys.
[20] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Test values.
    - Generate incidental values with library codeunits; keep scenario-defining amounts and dates explicit and fixed.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v2. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
