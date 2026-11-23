# Feature design

> Each customer subscription contract line gets a Cost Center Reference. When recurring billing creates the invoices, every invoice line must show the reference, and it must still be visible on the posted invoice lines and archived billing lines.

**Result:** Complete design. **Business process:** Subscription Billing recurring billing: billing proposal, contract invoice creation and sales invoice posting with billing line archiving. **Knowledge used:** 13 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is the Cost Center Reference: free Code[20] text, a relation to an existing table (for example cost centers or a dimension value), or another type/length? Is it mandatory on a contract line before billing? _(affects: contract-line-ext, billing-line-ext, billing-line-archive-ext, sales-line-ext, sales-invoice-line-ext, sales-cr-memo-line-ext, sales-shipment-line-ext, return-receipt-line-ext, sales-line-archive-ext, max-length-value-reaches-all-targets)_
2. When billing lines of several periods for one subscription line are grouped into one invoice line and carry different references (the contract line changed between proposals), which reference wins: the latest billing line, the earliest, the current contract line value, or should billing stop with an error? _(affects: cc-ref-billing-codeunit, grouped-billing-periods-winner)_
3. The articles also mirror the field on Sales Cr.Memo Line (contract and corrective credit memos), Sales Shipment Line, Return Receipt Line and Sales Line Archive. Keep all of them, or exclude any? _(affects: sales-cr-memo-line-ext, sales-shipment-line-ext, return-receipt-line-ext, sales-line-archive-ext, contract-credit-memo-carries-reference, cancel-posted-contract-invoice, article-chosen-targets)_
4. May a user change the reference on an unposted contract invoice line, or should it be read-only there (the app's change checks do not cover extension fields)? Should changing it on the contract line update billing lines already proposed? _(affects: sales-line-ext, sales-invoice-subform-ext, billing-line-ext)_
5. Must existing contract lines or already-created billing lines and open contract invoices be filled when the extension is installed, or does the reference apply only to billing created afterwards? _(affects: contract-line-ext, billing-line-ext)_
6. Should the reference also be shown on the billing proposal (billing lines) page, posted credit memo subform or reports, in addition to the contract line, invoice line, posted invoice line and archived billing line pages? _(affects: contract-line-subform-ext, archived-billing-lines-page-ext)_
7. Which BC version / runtime does the app target? From BC24 (runtime 13.0) the tooltip goes on the table field and is inherited by pages; earlier targets need page-level tooltips. _(affects: contract-line-subform-ext, sales-invoice-subform-ext, posted-sales-invoice-subform-ext, archived-billing-lines-page-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Cust. Sub. Contract Line (Subscription Billing) | Holds the Cost Center Reference the user enters per customer subscription contract line; the source of every later copy. | "Cost Center Reference" (Code[20] (provisional; see open question cc-ref-type)): DataClassification = CustomerContent set on the field (a tableextension has no table-level value to inherit). Table-field ToolTip when the target runtime supports it. | [1] [5] [10] [8] |
| 2 | extend | tableextension | Billing Line (Subscription Billing) | Carries the reference from the contract line into the billing proposal and, as a temporary record, into Create Billing Documents. | "Cost Center Reference" (Code[20] (provisional; see open question cc-ref-type)): Same field number, name, type and length as on Cust. Sub. Contract Line; DataClassification = CustomerContent; Editable = false. Same number and type as on Billing Line Archive so TransferFields carries it on archiving. | [1] [5] [10] |
| 3 | extend | tableextension | Billing Line Archive (Subscription Billing) | Keeps the reference visible on archived billing lines; filled by the app's TransferFields from Billing Line when the invoice is posted. | "Cost Center Reference" (Code[20] (provisional; see open question cc-ref-type)): Same field number, name, type and length as on Cust. Sub. Contract Line; DataClassification = CustomerContent; Editable = false. | [1] [5] [10] |
| 4 | extend | tableextension | Sales Line | Shows the reference on every contract invoice and credit memo line; filled before insert from the temporary billing line. | "Cost Center Reference" (Code[20] (provisional; see open question cc-ref-type)): Same field number, name, type and length as on Cust. Sub. Contract Line; DataClassification = CustomerContent. Same number and type as on the posted and archive line tables. | [1] [3] [5] [10] |
| 5 | extend | tableextension | Sales Invoice Line | Keeps the reference on posted invoice lines; filled by TransferFields in InitFromSalesLine. | "Cost Center Reference" (Code[20] (provisional; see open question cc-ref-type)): Same field number, name, type and length as on Cust. Sub. Contract Line; DataClassification = CustomerContent; Editable = false. | [1] [3] [5] [10] |
| 6 | extend | tableextension | Sales Cr.Memo Line | Keeps the reference on posted credit memo lines: contract credit memos follow the same billing path, and corrective credit memos copy it from the posted invoice line. Chosen by the articles, not by the request (see open question article-chosen-targets). | "Cost Center Reference" (Code[20] (provisional; see open question cc-ref-type)): Same field number, name, type and length as on Cust. Sub. Contract Line; DataClassification = CustomerContent; Editable = false. | [1] [3] [7] [5] [10] |
| 7 | extend | tableextension | Sales Shipment Line | Mirrors the field on the remaining posted sales line TransferFields target. Chosen by the mirroring article only (see open question article-chosen-targets). | "Cost Center Reference" (Code[20] (provisional; see open question cc-ref-type)): Same field number, name, type and length as on Cust. Sub. Contract Line; DataClassification = CustomerContent; Editable = false. | [3] [5] [10] |
| 8 | extend | tableextension | Return Receipt Line | Mirrors the field on the remaining posted sales line TransferFields target. Chosen by the mirroring article only (see open question article-chosen-targets). | "Cost Center Reference" (Code[20] (provisional; see open question cc-ref-type)): Same field number, name, type and length as on Cust. Sub. Contract Line; DataClassification = CustomerContent; Editable = false. | [3] [5] [10] |
| 9 | extend | tableextension | Sales Line Archive | Mirrors the field on the sales line archive TransferFields target. Chosen by the mirroring article only (see open question article-chosen-targets). | "Cost Center Reference" (Code[20] (provisional; see open question cc-ref-type)): Same field number, name, type and length as on Cust. Sub. Contract Line; DataClassification = CustomerContent; Editable = false. | [3] [4] [5] [10] |
| 10 | create | codeunit | CC Ref Billing (new subscriber codeunit) | Static event subscribers that copy the reference contract line -> billing line -> temporary billing line -> sales line, each before the respective insert, with no Modify and no UI. |  | [1] [2] [6] [11] |
| 11 | extend | pageextension | Customer contract line subpage (Subscription Billing; confirm object name in symbols) | Lets the user enter the Cost Center Reference on each customer subscription contract line. |  | [4] [8] [9] |
| 12 | extend | pageextension | Sales Invoice Subform | Shows the reference on every line of the contract invoice before posting. |  | [4] [8] [9] |
| 13 | extend | pageextension | Posted Sales Invoice Subform | Shows the reference on posted invoice lines. |  | [4] [8] [9] |
| 14 | extend | pageextension | Archived billing lines page (Subscription Billing; confirm object name in symbols) | Shows the reference on archived billing lines. |  | [4] [8] [9] |

## 3. How the data flows

- **User** → **Cust. Sub. Contract Line."Cost Center Reference"**: entered by the user. Entered on the customer contract line subpage extension. [1]
- **Cust. Sub. Contract Line** → **Billing Line**: copied in an event subscriber. Billing Proposal OnAfterUpdateBillingLineFromSubscriptionLine: Get the contract line by SubscriptionLine."Subscription Contract No." and "Subscription Contract Line No." (customer partner only) and assign; runs before the insert, no Modify. [1] [11]
- **Billing Line** → **Temporary Billing Line (Create Billing Documents)**: copied in an event subscriber. Create Billing Documents OnBeforeInsertTempBillingLine. The temporary line groups all billing lines of one subscription line; the winner rule is open (cc-ref-period-conflict). [1]
- **Temporary Billing Line** → **Sales Line (contract invoice / credit memo)**: copied in an event subscriber. Create Billing Documents OnBeforeInsertSalesLineFromContractLine: assign from TempBillingLine; the line is inserted right after, so no Modify and no lookup by Document No. [1] [2]
- **Sales Line** → **Sales Invoice Line**: standard TransferFields copy. Standard posting, InitFromSalesLine; requires same field number and type. [1] [3] [5]
- **Billing Line** → **Billing Line Archive**: standard TransferFields copy. The app archives billing lines with TransferFields when the invoice is posted. [1] [5]
- **Sales Line** → **Sales Cr.Memo Line**: standard TransferFields copy. Contract credit memos are created through the same events and posted with TransferFields. [1] [3] [5]
- **Sales Invoice Line** → **Sales Line (corrective credit memo)**: standard TransferFields copy. Cancel/Correct via Copy Document Mgt. copies the line with TransferFields; the reference is business data, so it stays mirrored with no code. [7]
- **Sales Line** → **Sales Shipment Line / Return Receipt Line**: standard TransferFields copy. Article-chosen target; kept unless the requester excludes it. [3] [5]
- **Sales Line** → **Sales Line Archive**: standard TransferFields copy. Article-chosen target; kept unless the requester excludes it. [3] [4] [5]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Billing Proposal" (8062) | `OnAfterUpdateBillingLineFromSubscriptionLine(var BillingLine, SubscriptionLine)` | Copy the reference from the Cust. Sub. Contract Line to the new Billing Line. | Exit when SubscriptionLine.Partner is not Customer (vendor contract lines are a different table). · SetLoadFields on the contract line before Get; exit quietly when Get fails. · No Modify: the event runs before the insert. · No UI calls: billing can run from a job queue (Auto Contract Billing). | [1] [11] [6] |
| Codeunit "Create Billing Documents" (8060) | `OnBeforeInsertTempBillingLine(var TempBillingLine, var BillingLine)` | Copy the reference from the Billing Line to the grouping temporary billing line, which does not carry custom fields by itself. | Apply the agreed winner rule when grouped billing lines carry different references (open question cc-ref-period-conflict); otherwise the last line read silently wins. · No UI calls. | [1] [6] |
| Codeunit "Create Billing Documents" (8060) | `OnBeforeInsertSalesLineFromContractLine(var SalesLine, var TempBillingLine)` | Copy the reference from the temporary billing line to the Sales Line before it is inserted. | Read from TempBillingLine, never look up Billing Line by the sales line's Document No. (not yet linked). · No Modify and no later patch with Modify(true) after OnAfterInsertSalesLineFromBillingLine. · No UI calls: billing may run in a job queue; documents committed before an error stay. | [1] [2] [6] |

## 5. Setup, permissions and lifecycle

- **setup**: Add a dependency on the Subscription Billing app (publisher Microsoft, id 3099ffc7-4cf7-4df6-9b96-7e4bc2bb587c) in app.json. [1]
- **privacy**: Set DataClassification = CustomerContent on every Cost Center Reference field, since table extensions have no table-level value to inherit; never leave ToBeClassified. [10]
- **permissions**: Decide permission set entries for new objects; this design adds only table extensions, page extensions and a non-exposed subscriber codeunit. [4]
- **background**: Keep all three subscribers non-interactive because Auto Contract Billing (codeunit 8014) runs Create Billing Documents from a job queue entry; let errors propagate. [2] [6]
- **upgrade**: No data upgrade is designed: existing contract lines and already-created billing lines start blank. Whether to backfill is an open question (cc-ref-backfill). agent judgment

## 6. Tests

1. **contract-line-to-billing-line** [1] [12] [13]
    - Given A customer subscription contract with a contract line whose Cost Center Reference is a random Code[20] value
    - When A billing proposal is created for the contract
    - Then Every Billing Line for that contract line carries the same Cost Center Reference
2. **billing-line-to-invoice-line** [1] [2] [12] [13]
    - Given Billing lines with a Cost Center Reference from the contract line
    - When Create Billing Documents creates the sales invoice
    - Then Each contract invoice Sales Line carries the reference (proving the temporary-line and sales-line hops) and no error is raised by the contract-change checks
3. **post-invoice-to-posted-and-archive** [1] [3] [12] [13]
    - Given A contract invoice whose lines carry the reference
    - When The invoice is posted
    - Then Each Sales Invoice Line and each Billing Line Archive record for it carries the reference
4. **max-length-value-reaches-all-targets** [5] [13]
    - Given A contract line with a Cost Center Reference of the full field length
    - When The proposal is created, the invoice created and posted
    - Then The full value is read back unchanged on Billing Line, Sales Line, Sales Invoice Line and Billing Line Archive (no TransferFields length error)
5. **contract-credit-memo-carries-reference** [1] [3] [12] [13]
    - Given A contract line with a reference and billing that produces a credit memo
    - When The credit memo is created and posted
    - Then The Sales Line and the Sales Cr.Memo Line carry the reference
6. **cancel-posted-contract-invoice** [7] [12] [13]
    - Given A posted contract invoice whose lines carry the reference
    - When The posted invoice is cancelled (corrective credit memo)
    - Then The posted Sales Cr.Memo Line carries the same reference
7. **vendor-partner-guard** [1]
    - Given A vendor subscription contract with billing lines
    - When A billing proposal is created
    - Then The subscriber exits without error and does not try to read a customer contract line
8. **grouped-billing-periods-winner** [1]
    - Given Two billing periods for one subscription line whose billing lines carry different references
    - When Create Billing Documents groups them into one sales line
    - Then The sales line carries the reference chosen by the agreed winner rule (cc-ref-period-conflict)
9. **billing-without-ui** [6] [2]
    - Given Billing configured to run without a user (no UI handlers registered)
    - When Create Billing Documents runs as Auto Contract Billing would
    - Then Documents are created with the reference and no UI callback is raised
10. **article-chosen-targets** [3] [12] [13]
    - Given A contract invoice line with the reference
    - When The document is archived (and, if kept, shipped or returned)
    - Then Sales Line Archive (and Sales Shipment Line / Return Receipt Line if kept) carry the reference

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined (no repository supplied); ui/bound-page-field-inherits-source-field-tooltip applies from BC24 only.
- Page object names for the customer contract line subpage and the archived billing lines page are not named in BCQuality knowledge; confirm them in Subscription Billing symbols.
- Upgrade/backfill step rests on agent judgment; not covered by BCQuality knowledge (see open question cc-ref-backfill).
- Subscription Billing test library codeunits for creating contracts and running billing are not covered by BCQuality knowledge; tests rely on agent judgment for contract fixtures.

## Sources

[1] `microsoft/knowledge/subscription-billing/carry-contract-line-fields-to-billing-lines-and-contract-invoices.md`: Defines the full path contract line -> billing line -> temporary billing line -> sales line -> posted line / billing line archive and the three events used.
    - Add the field to Cust. Sub. Contract Line, Billing Line, Sales Line and Sales Invoice Line, and to Billing Line Archive when users need it on archived billing lines.
    - Use the same field number and type on Billing Line and Billing Line Archive, and on the sales and posted line tables.
    - Subscribe to OnAfterUpdateBillingLineFromSubscriptionLine, OnBeforeInsertTempBillingLine and OnBeforeInsertSalesLineFromContractLine; no Modify is needed because each runs before its insert.
    - Do not copy only in OnBeforeInsertSalesLineFromContractLine without filling the temporary line, and do not look up Billing Line by the sales line's Document No.
    - Decide which value wins when billing lines grouped into one temporary line differ; otherwise the last line read silently wins.
    - Credit memos follow the same path; the design needs a dependency on Subscription Billing (3099ffc7-4cf7-4df6-9b96-7e4bc2bb587c).
[2] `microsoft/knowledge/subscription-billing/contract-invoice-documents-are-locked-set-values-before-insert.md`: Sets values before the sales line insert and rules out patching the created contract invoice; background-billing guard.
    - Set line values in OnBeforeInsertSalesLineFromContractLine, read from TempBillingLine.
    - Do not adjust created contract invoice lines afterwards with Modify(true); Modify(false) to bypass checks is no better.
    - Subscribers in this path must not need UI; an error stops the run but documents committed before it stay.
    - Own extension fields that the app does not check can still be changed later.
[3] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring the line field on every sales TransferFields target (posted lines and Sales Line Archive).
    - Give the field the same number, name, type and length on the source and every target table the plan needs.
    - For a line field, cover the line tables: Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line and Sales Line Archive, unless the plan states a document type never needs it.
    - No subscriber is needed for these stages; keep mirrored fields non-editable on posted tables.
    - Do not patch posted lines with an OnAfter insert subscriber and Modify.
[4] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Stage map for a custom sales field: posted lines, archive, page extensions, permission entries and read-back tests.
    - Decide which stages the field must reach and plan one step per stage.
    - Name the page extensions that show the field and permission set entries for any new objects.
    - Test by posting a document and reading the value back from every target.
[5] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Type and length agreement across all mirrored tables.
    - Define the mirrored field with exactly the same field number, data type and length on every table in the cascade, at creation time.
    - A shorter length on one side compiles but fails at runtime once a value exceeds it.
[6] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Billing can run from Auto Contract Billing in a job queue, so subscribers must be non-interactive.
    - No Confirm, Page/Report RunModal, upload/download or Message-based notification in code reached from the job queue.
    - Let failures propagate to the job queue log.
[7] `microsoft/knowledge/sales-purchase/corrective-credit-memo-copies-custom-fields-from-the-posted-invoice.md`: Corrective credit memos copy mirrored line fields from the posted invoice.
    - Mirrored business data comes back on the corrective credit memo and needs no code.
    - Per-document state must be cleared in OnAfterCopySalesHeaderDone; the reference is treated here as business data.
    - Test Cancel on an invoice with the field filled and read the posted credit memo back.
[8] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltip placement for the new page fields.
    - From runtime 13.0 (BC24) define the tooltip on the table field and let bound page fields inherit it; before that, page-level tooltips are needed.
    - Tooltip text must say what the value is used for, not just repeat the caption, and must not invent behavior.
[9] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Confirms bound page fields inherit the table-field tooltip; applies from BC24.
    - Do not duplicate a page-level ToolTip when the source table field supplies one (runtime 13.0 or later).
    - Add a page-level ToolTip only when none can be inherited or different help is needed.
[10] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of the new table extension fields.
    - Every Normal field added by a tableextension must set its own DataClassification.
    - Choose the classification matching the stored data at definition time; ToBeClassified is not a safe default.
[11] `microsoft/knowledge/performance/use-setloadfields-for-partial-records.md`: Partial load of the contract line in the billing-line subscriber.
    - Call SetLoadFields with the fields read immediately before the Get.
    - Skip it where the read path reads most fields or the table is temporary.
[12] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for customers, items and sales documents.
    - Build prerequisite records with Library codeunits (LibrarySales, LibraryInventory, LibraryRandom), parents first, validating foreign keys.
[13] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Test values for the reference.
    - Generate incidental values with library codeunits; do not depend on existing records.
    - Use deliberately chosen values when the scenario depends on length, such as a full-length reference.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
