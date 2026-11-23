# Feature design

> We resell cloud services with usage-based subscription billing. The monthly usage file from our supplier has a data center region column, and the region must be shown on the customer contract invoice lines and on the posted invoices. Each subscription line also has a support level that customers can change when the contract is renewed. The new support level must apply to the renewed term.

**Result:** Complete design. **Business process:** Carry a data center region from the supplier's usage file to customer contract invoice lines and posted invoices, and renew a per-subscription-line support level through contract renewal, both in the Subscription Billing app (usage-based billing and contract renewal). **Knowledge used:** 12 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. One contract invoice line can cover several usage data billing rows (several imported lines or charge periods). If their regions differ, which region is shown: the latest charge period, the first, or should the line be split / the values combined? _(affects: usage-region-flow, several-usage-rows-winner-rule)_
2. Should the region column be mapped to the spare Usage Data Generic Import Text1 field or to a new field added to Usage Data Generic Import, and will the app ship the Data Exch. Field Mapping or will each customer configure it on the supplier's definition? _(affects: usage-billing-region, usage-region-flow)_
3. What is the format and maximum length of the supplier's region value (for example a code like WEU or a free-text name), and should it relate to a region master table? _(affects: usage-billing-region, sales-line-region, sales-invoice-line-region, sales-cr-memo-line-region, sales-shipment-line-region, return-receipt-line-region, sales-line-archive-region)_
4. Is the region needed only on customer invoices, or also on vendor-side usage data billing rows and vendor contract invoices (which would use OnBeforeInsertPurchaseLineFromContractLine and purchase mirror tables)? _(affects: usage-billing-region, usage-region-flow, vendor-side-row-guard)_
5. Besides Sales Invoice Line, should the region also be kept on Sales Cr.Memo Line, Sales Shipment Line, Return Receipt Line and Sales Line Archive (the mirroring rule includes them by default), and should it flow back when a posted invoice is copied or corrected? _(affects: sales-cr-memo-line-region, sales-shipment-line-region, return-receipt-line-region, sales-line-archive-region, credit-memo-and-archive-carry-region)_
6. May users change the region on a contract invoice line before posting, or must it stay as imported? _(affects: sales-line-region, sales-invoice-subform-region)_
7. What are the possible support levels: a fixed list (enum) or a code table maintained by users, and does a level carry other data such as price? _(affects: subscription-line-support-level, sales-subscription-line-support-level, planned-subscription-line-support-level)_
8. How is the support level set when a subscription line is first created (from the sales order, the item's subscription package, or manually on the contract)? _(affects: subscription-line-support-level)_
9. If a renewal changes only the support level and the old term is not yet fully billed, the app would apply it immediately. Should the design defer it to the renewed term (OnCheckPerformSubscriptionLineUpdate), as designed, accepting that the subscription line then cannot be selected for another renewal while it waits? _(affects: support-level-renewal, support-level-only-change-is-deferred)_
10. Should the support level also appear on contract invoice lines and posted invoices (billing line path), or only on the subscription line? _(affects: subscription-line-support-level, support-level-renewal)_
11. Do existing subscription lines need an initial support level, and existing open usage data billing rows a region, through upgrade or install code, or do they stay blank? _(affects: subscription-line-support-level, usage-billing-region)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Usage Data Billing | Holds the data center region of each usage data billing row, copied from the imported usage line before the row is inserted. Nothing copies by field number in the usage path, so the value is assigned in a subscriber. | Usage Region (Code[20]): DataClassification CustomerContent. Filled only for customer-side rows (Partner = Customer) unless q-vendor-side says otherwise. | [1] [9] |
| 2 | extend | tableextension | Sales Line | Carries the region on contract invoice (and contract credit memo) lines. Set in OnBeforeInsertSalesLineFromContractLine before the insert, because contract invoice lines are locked once created. | Usage Region (Code[20]): Same number, type and length as on the posted and archive line tables; non-editable on contract invoices is not enforced by the app for extension fields, decide editability in q-region-editable. | [1] [3] [6] [8] [9] |
| 3 | extend | tableextension | Sales Invoice Line | Mirror of the Sales Line field so posting (InitFromSalesLine / TransferFields) carries the region to the posted invoice line without a subscriber. Non-editable. | Usage Region (Code[20]): Same field number, type and length as Sales Line. | [6] [7] [8] [2] [9] |
| 4 | extend | tableextension | Sales Cr.Memo Line | Mirror target for posted contract credit memos (credit memos follow the same contract-line path). Chosen by the mirroring article; may be excluded through q-mirror-targets. | Usage Region (Code[20]): Same field number, type and length as Sales Line. | [6] [7] [8] [2] [9] |
| 5 | extend | tableextension | Sales Shipment Line | Mirror target required by the sales mirroring rule for every posted line table the line field reaches. May be excluded through q-mirror-targets. | Usage Region (Code[20]): Same field number, type and length as Sales Line. | [6] [7] [8] [9] |
| 6 | extend | tableextension | Return Receipt Line | Mirror target required by the sales mirroring rule for every posted line table. May be excluded through q-mirror-targets. | Usage Region (Code[20]): Same field number, type and length as Sales Line. | [6] [7] [8] [9] |
| 7 | extend | tableextension | Sales Line Archive | Mirror target for archived sales lines (archiving copies lines with TransferFields). May be excluded through q-mirror-targets. | Usage Region (Code[20]): Same field number, type and length as Sales Line. | [6] [7] [8] [9] |
| 8 | create | codeunit | Usage Region Flow | Event subscriber codeunit for the region path: imported usage line to Usage Data Billing, and open Usage Data Billing rows to the contract invoice line. Contains no UI because contract billing can run from a job queue. |  | [1] [3] [11] |
| 9 | extend | pageextension | Sales Invoice Subform | Shows the region on the lines of the contract invoice before posting. |  | [7] [12] |
| 10 | extend | pageextension | Posted Sales Invoice Subform | Shows the region on posted invoice lines (read-only). |  | [7] [12] |
| 11 | extend | tableextension | Subscription Line | Holds the current support level of each subscription line. Updated by renewal only when the planned subscription line is applied, so the renewed term gets the new level. | Support Level (Code[20]): Data type to be settled in q-support-level-type; same number and type as on Planned Subscription Line. DataClassification CustomerContent. | [4] [8] [9] |
| 12 | extend | tableextension | Sales Subscription Line | Holds the support level on the renewal quote and order, where the customer's new choice is entered. | Support Level (Code[20]): Same type as on Subscription Line. DataClassification CustomerContent. | [4] [9] |
| 13 | extend | tableextension | Planned Subscription Line | Carries the renewed support level while the renewal waits to be applied; filled by the app's TransferFields from the temporary subscription line. | Support Level (Code[20]): Same field number and type as on Subscription Line so TransferFields copies it. | [4] [8] [9] |
| 14 | create | codeunit | Support Level Renewal | Event subscriber codeunit for the renewal path: current level onto the renewal quote, sales subscription line to temporary subscription line, planned line to subscription line, and the update rule that keeps the old level until the old term is billed. |  | [4] |

## 3. How the data flows

- **Supplier usage file region column** → **Usage Data Generic Import.Text1**: other. Data Exch. Field Mapping in the supplier's Data Exchange Definition maps the region column to the spare Text1 field (or a field added to Usage Data Generic Import, see q-region-import-field). Run by the Create Imported Lines step of Usage Data Import. [1]
- **Usage Data Generic Import.Text1** → **Usage Data Billing.Usage Region**: copied in an event subscriber. Assigned in OnBeforInsertUsageDataBilling from UsageDataGenericImportGlobal; no Modify, the app inserts right after. [1]
- **Usage Data Billing.Usage Region** → **Sales Line.Usage Region (contract invoice line)**: copied in an event subscriber. In OnBeforeInsertSalesLineFromContractLine, read open Usage Data Billing rows with the app's filters (Partner Customer, contract no. and line no. from TempBillingLine, Document Type None, empty Document No.) and apply the winner rule of q-region-winner. Covers contract credit memos created by the same routine. [1] [3] [2]
- **Sales Line.Usage Region** → **Sales Invoice Line.Usage Region**: standard TransferFields copy. Standard posting (InitFromSalesLine); same field number and type. [6] [7] [2] [8]
- **Sales Line.Usage Region** → **Sales Cr.Memo Line, Sales Shipment Line, Return Receipt Line, Sales Line Archive**: standard TransferFields copy. Standard posting and archiving; same field number and type. Subject to q-mirror-targets. [6] [7] [8]
- **Subscription Line.Support Level** → **Sales Subscription Line.Support Level (renewal quote)**: copied in an event subscriber. In OnAfterInsertSubscriptionLine, Get the subscription line by SalesSubscriptionLine."Subscription Line Entry No.", assign and Modify (the line is already inserted). [4]
- **User on the renewal quote or order** → **Sales Subscription Line.Support Level**: entered by the user. The customer's new support level is entered on the renewal sales subscription line. The page that shows these lines is not named by any opened article (see unresolved). [4]
- **Sales Subscription Line.Support Level** → **temporary Subscription Line.Support Level**: copied in an event subscriber. In OnAfterCopyFromSalesSubscriptionLine on table Subscription Line, run by Post Sub. Contract Renewal when the renewal order is posted (no invoice is posted for renewal lines). [4]
- **temporary Subscription Line.Support Level** → **Planned Subscription Line.Support Level**: standard TransferFields copy. The app copies the temporary line into the planned line with TransferFields; same field number and type. [4] [8]
- **Planned Subscription Line.Support Level** → **Subscription Line.Support Level**: copied in an event subscriber. In OnBeforeUpdateSubscriptionLineFromPlannedSubscriptionLine, assign without Modify. Takes effect when the planned line is applied, not when the renewal order is posted. [4]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Create Usage Data Billing | `OnBeforInsertUsageDataBilling` | Copy the region from UsageDataGenericImportGlobal (Text1 or the added field) to the Usage Data Billing row before its insert. | Assign only; no Modify (the app calls Insert(true) right after). · Exit unless UsageDataBilling.Partner is Customer, if the region is for the customer side only (q-vendor-side). · Copy with CopyStr to the target length. | [1] |
| Create Billing Documents | `OnBeforeInsertSalesLineFromContractLine` | Read the open Usage Data Billing rows of the contract line and set the region on the contract invoice line before it is inserted. | Filter Usage Data Billing exactly as the app does: Partner Customer, Subscription Contract No. and Line No. from TempBillingLine, Document Type None, Document No. empty; never by the sales line's Document No. · Apply the agreed winner/combination rule when several rows cover one invoice line (q-region-winner). · Assign only, no Modify; never patch the line after insert (Document Change Management). · No UI: billing may run from Auto Contract Billing in a job queue. | [1] [3] [11] |
| Create Sub. Contract Renewal | `OnAfterInsertSubscriptionLine` | Prefill the renewal quote's sales subscription line with the current support level so the customer sees and can change it. | Exit if the subscription line cannot be found by Subscription Line Entry No. · The record is already inserted: assign then Modify. | [4] |
| Subscription Line | `OnAfterCopyFromSalesSubscriptionLine` | Copy the renewed support level from the sales subscription line to the temporary subscription line, from which TransferFields fills the planned line. | Assign only. | [4] |
| Post Sub. Contract Renewal | `OnBeforeUpdateSubscriptionLineFromPlannedSubscriptionLine` | Apply the renewed support level to the subscription line when the planned line is applied. | Assign only; the app archives old values and calls Modify(false) right after. | [4] |
| Post Sub. Contract Renewal | `OnCheckPerformSubscriptionLineUpdate` | Change the update rule so a renewal whose price, discount, calculation base and billing rhythm are unchanged but whose support level changed waits until the subscription line is billed to its end date, so the new level applies to the renewed term only (subject to q-support-level-timing). | Only defer when the support level differs and the line is not yet billed up to its end date; leave all other cases to the app's rule. · Parameter list must be confirmed in the Subscription Billing symbols before implementation. | [4] |

## 5. Setup, permissions and lifecycle

- **setup**: In the supplier's Data Exchange Definition, add a Data Exch. Field Mapping from the region column to Usage Data Generic Import Text1 (or the added field). Decide whether the app ships this mapping or the customer maintains it (q-region-import-field). [1]
- **other**: Add a dependency on the Subscription Billing app (publisher Microsoft, id 3099ffc7-4cf7-4df6-9b96-7e4bc2bb587c). [2]
- **privacy**: Set DataClassification = CustomerContent on every added table extension field (Usage Region, Support Level); table extensions have no table-level value to inherit. [9]
- **background**: Keep both subscriber codeunits free of Confirm, Message-only feedback, RunModal and other UI: contract billing can run from Auto Contract Billing in a job queue, and an error stops the run while documents committed before it stay. [3] [11]
- **other**: Page fields for Usage Region and Support Level get tooltip text on the table field (inherited by bound page fields from runtime 13.0 / BC24) or on the page for earlier targets. [12]

## Required app dependencies

- **Subscription Billing** (`3099ffc7-4cf7-4df6-9b96-7e4bc2bb587c`, Microsoft): Extends Usage Data Billing, Subscription Line, Sales Subscription Line and Planned Subscription Line and subscribes to Create Usage Data Billing, Create Billing Documents, Create Sub. Contract Renewal and Post Sub. Contract Renewal events. [2]

## 6. Tests

1. **import-region-to-usage-billing** [1] [10]
    - Given A usage data supplier with a Data Exchange Definition mapping the region column to Text1, a customer subscription with a usage-based subscription line, and a usage file row with region WEU
    - When Usage Data Import runs Create Imported Lines, Process Imported Lines and Create Usage Data Billing
    - Then The customer-side Usage Data Billing row has Usage Region WEU
2. **usage-billing-region-to-contract-invoice-line** [1] [3]
    - Given Processed Usage Data Billing rows with region WEU for a customer contract line
    - When Create Billing Documents creates the contract invoice
    - Then The sales line for that contract line has Usage Region WEU, set before insert (no Document Change Management error)
3. **posted-invoice-line-has-region** [6] [7] [10]
    - Given A contract invoice whose line has Usage Region WEU
    - When The invoice is posted
    - Then The Sales Invoice Line has Usage Region WEU
4. **credit-memo-and-archive-carry-region** [6] [7] [8]
    - Given A contract credit memo line and an archived sales line carrying a region (for the targets kept after q-mirror-targets)
    - When The credit memo is posted and the document is archived
    - Then Sales Cr.Memo Line, Return Receipt Line/Sales Shipment Line where created, and Sales Line Archive carry the same region
5. **several-usage-rows-winner-rule** [1]
    - Given Two open Usage Data Billing rows for one contract line with different regions and charge periods
    - When The contract invoice is created
    - Then The invoice line carries the region chosen by the agreed rule (q-region-winner)
6. **vendor-side-row-guard** [1]
    - Given A usage file row linked to both customer and vendor usage-based subscription lines
    - When Create Usage Data Billing runs
    - Then Only the customer-side row gets the region (or both, per q-vendor-side)
7. **background-billing-without-ui** [3] [11]
    - Given A billing template run by Auto Contract Billing from a job queue entry
    - When The job creates contract invoices for lines with usage regions
    - Then Invoices are created with regions and no UI callback error occurs
8. **renewal-quote-prefills-support-level** [4]
    - Given A subscription line with Support Level SILVER and a Sub. Contract Renewal Line for it
    - When Create Sub. Contract Renewal creates the renewal quote
    - Then The Sales Subscription Line has Support Level SILVER
9. **renewal-applies-new-level-after-old-term-billed** [4] [10]
    - Given A renewal order whose sales subscription line has Support Level GOLD, for a subscription line billed up to its end date
    - When The renewal order is posted
    - Then The planned line is applied and the Subscription Line has Support Level GOLD for the renewed term
10. **renewal-waits-while-old-term-unbilled** [4]
    - Given A renewal order changing the support level to GOLD (and price), for a subscription line not yet billed to its end date
    - When The renewal order is posted, then the last contract invoice of the old term is posted
    - Then After order posting the Subscription Line keeps the old level and the Planned Subscription Line holds GOLD; after the old term's last invoice is posted the Subscription Line has GOLD
11. **support-level-only-change-is-deferred** [4]
    - Given A renewal that changes only the support level (price, discount, calculation base and billing rhythm unchanged) for a line not billed to its end date
    - When The renewal order is posted
    - Then The subscription line keeps the old support level until it is billed to its end date (OnCheckPerformSubscriptionLineUpdate guard)

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Page that shows Sales Subscription Lines on the renewal quote/order (where the customer's new support level is entered) and the contract/subscription line pages that display the support level: no opened article names these pages; confirm the page names in the Subscription Billing symbols and add page extensions (judgment).
- OnCheckPerformSubscriptionLineUpdate: the event is named in an opened article but its parameters are not; confirm the signature and publisher in the Subscription Billing symbols before implementing the deferral guard.
- Whether Subscription Line Archive (old values archived on renewal) should mirror the support level is not covered by BCQuality knowledge (judgment).
- Permission sets: the design adds no new tables or exposed objects; no permission set is designed (judgment).
- Page extensions Sales Invoice Subform and Posted Sales Invoice Subform are standard base application page names chosen by judgment; no opened article names them.
- context: bc-version, countries and application-area are unknown (no repository); tooltip inheritance applies from BC24.

## Sources

[1] `microsoft/knowledge/subscription-billing/carry-usage-data-values-to-contract-invoices-through-usage-data-billing.md`: Region path from the usage file through Usage Data Billing to the contract invoice line.
    - Map the region column to a spare field such as Text1 (or an added Usage Data Generic Import field) in the supplier's Data Exch. Field Mapping.
    - Copy to Usage Data Billing in OnBeforInsertUsageDataBilling without Modify; check Partner if the value is customer-side only.
    - In OnBeforeInsertSalesLineFromContractLine read Usage Data Billing with the app's filters (Partner Customer, contract no./line no. from TempBillingLine, Document Type None, empty Document No.).
    - The design must say which value wins, or how values are combined, when one invoice line covers many usage rows.
    - Nothing copies by field number in this path; do not assign in OnAfterCreateUsageDataBillingFromTempSubscriptionLine; do not read rows by the sales line's Document No.
[2] `microsoft/knowledge/subscription-billing/carry-contract-line-fields-to-billing-lines-and-contract-invoices.md`: Subscription Billing dependency, posted-line mirroring of contract invoice lines, and credit memos following the same path.
    - A design that extends Subscription Billing needs the dependency on app 3099ffc7-4cf7-4df6-9b96-7e4bc2bb587c, publisher Microsoft.
    - Posting copies the sales line to Sales Invoice Line with TransferFields: use the same number and type on sales and posted line tables.
    - Credit memos follow the same path.
    - Do not patch the sales line later with Modify(true).
[3] `microsoft/knowledge/subscription-billing/contract-invoice-documents-are-locked-set-values-before-insert.md`: Setting the region before the contract invoice line is inserted, and background-run constraints.
    - Decide every locked value before the document exists; line values go in OnBeforeInsertSalesLineFromContractLine.
    - Do not adjust the created invoice afterwards with Modify(true) or Modify(false).
    - Subscribers in this path must not need UI, because billing can run in a job queue; an error stops the run but committed documents stay.
[4] `microsoft/knowledge/subscription-billing/contract-renewal-updates-subscription-lines-through-planned-lines.md`: Renewal path for the support level through the renewal quote, planned subscription line and subscription line update.
    - Add the field to Subscription Line, Sales Subscription Line and Planned Subscription Line, with the same number and type on the subscription line and planned line.
    - Fill the quote in OnAfterInsertSubscriptionLine (read the subscription line by Subscription Line Entry No., assign, Modify).
    - Copy in OnAfterCopyFromSalesSubscriptionLine; TransferFields carries it to the planned line.
    - Apply in OnBeforeUpdateSubscriptionLineFromPlannedSubscriptionLine without Modify.
    - The new value takes effect when the planned line is applied, not when the order is posted; use OnCheckPerformSubscriptionLineUpdate to change the update rule.
    - Do not write the subscription line in OnAfterInsertPlannedSubscriptionLineFromSalesSubscriptionLine; do not subscribe to sales invoice posting events for renewals.
[5] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Process map: selected the Subscription Billing row (usage data, set before insert, renewal) and the shared rows (mirrored definitions, privacy, tests, upgrade back-fill question).
    - Open every linked article for the stages chosen.
    - Whether a field should reach a stage the request does not name is a question for the requester; one question per group of stages.
    - Do not fill other records with subscribers that modify them after posting.
[6] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring the Sales Line region on posted line tables and the line archive.
    - Same field number, name, type and length on the source and every target table the plan needs: Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line, Return Receipt Line and Sales Line Archive, unless the plan states a document type never needs it.
    - No subscriber needed for these stages; keep mirrored fields non-editable on posted tables.
[7] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Posted line stages and the page extensions and tests each stage needs.
    - Posted lines and Sales Line Archive are reached by TransferFields from Sales Line: same rule on the line tables.
    - Name the page extensions that show the field and a test that posts a document and reads the value back from every target.
[8] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Type and length of every mirrored field (region on sales/posted lines; support level on subscription and planned lines).
    - Define mirrored fields with the exact same field number, data type and length on every table in the cascade, at creation time.
[9] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of the added fields.
    - Every Normal field added in a tableextension must set its own DataClassification matching the data stored; never SystemMetadata for customer data.
[10] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for customers, items and sales documents.
    - Build fixtures with the test Library codeunits (LibrarySales, LibraryInventory, LibraryRandom), parents before dependents, validating foreign keys.
[11] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Billing subscribers run in background job queue sessions.
    - No Confirm, RunModal, Page.Run, Report.Run or Message-only feedback in code run by the job queue; let failures propagate.
[12] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips for the region and support level page fields.
    - From runtime 13.0 (BC24) define tooltip text on the table field and let bound page fields inherit it; before that, add page-level tooltips. Applies from BC24 for inheritance.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

