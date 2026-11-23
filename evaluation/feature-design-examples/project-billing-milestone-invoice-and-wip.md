# Feature design

> Project planning lines get a Billing Milestone code. When we create sales invoices from the project, each invoice line must show the milestone of the planning line it came from. Finance also wants a new WIP method that recognizes sales as the milestone value reached on each project task.

**Result:** Complete design. **Business process:** Project invoicing from planning lines (Job Create-Invoice, then Sales-Post) and project WIP calculation and posting (Job Calculate WIP, then Job Post WIP to G/L). **Knowledge used:** 8 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Is Billing Milestone a free code, or must it reference a milestone master table (with description, value or a 'reached' status)? A master table adds a table, list page, TableRelation (same length) and permission set entries. _(affects: tabext-job-planning-line, permset-billing-milestone, tabext-job-task)_
2. How is the 'milestone value reached' on a task determined: entered manually on the task, or derived from planning lines (for example the line amounts of planning lines whose milestone is marked reached)? Who sets it and when, relative to running Job Calculate WIP? _(affects: tabext-job-task, pageext-job-task-lines, codeunit-milestone-wip-method)_
3. Which Recognized Costs method should be paired with the Milestone Value sales method on the Job WIP Method, or is a matching custom cost method also needed? _(affects: enumext-wip-recognized-sales, codeunit-milestone-wip-method)_
4. Should the app create the Job WIP Method record that uses Milestone Value (code, description, WIP posting options) at install, or will Finance create it? _(affects: enumext-wip-recognized-sales)_
5. Must the milestone also appear on posted shipment lines, return receipt lines and archived lines? The mirroring guidance adds them by default; confirm or exclude them. _(affects: tabext-sales-shipment-line, tabext-return-receipt-line, tabext-sales-line-archive)_
6. Must the milestone survive Copy Document when lines are recalculated (for example copying a posted invoice without header)? If yes, a subscriber to Copy Document Mgt.OnAfterRecalculateSalesLine is needed. _(affects: tabext-sales-line)_
7. Should the Sale project ledger entries posted from the invoice also carry the milestone? That would need Job Transfer Line subscribers and a Job Ledger Entry field. _(affects: codeunit-project-invoice-milestone)_
8. Where must the milestone be shown besides the invoice subforms: credit memo and posted credit memo subforms, the printed invoice layout, reports or APIs? _(affects: pageext-sales-invoice-subform, pageext-posted-sales-invoice-subform)_
9. Is Billing Milestone mandatory on billable planning lines (blocking invoice creation when blank), and how should existing planning lines be handled? _(affects: tabext-job-planning-line, codeunit-project-invoice-milestone)_
10. Which object and field ID range should the extension use? The Billing Milestone field number must be identical on all seven tables. _(affects: tabext-sales-line, tabext-sales-invoice-line, tabext-sales-cr-memo-line)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Job Planning Line | Holds the Billing Milestone code that the user assigns to each project planning line; it is the source of the value copied to the invoice line. | Billing Milestone (Code[20]): DataClassification = CustomerContent. Whether it needs a TableRelation to a milestone master table is an open question (oq-milestone-master). | [1] [7] |
| 2 | extend | tableextension | Sales Line | Carries the milestone on the project sales invoice and credit memo lines that Job Create-Invoice creates. Its field number is the one mirrored on every posted and archive line table. | Billing Milestone (Code[20]): DataClassification = CustomerContent. Field number, type and length are reused exactly on every TransferFields target table below. | [1] [4] [5] [7] |
| 3 | extend | tableextension | Sales Invoice Line | Mirrors the milestone so the posted invoice line keeps it (InitFromSalesLine uses TransferFields). | Billing Milestone (Code[20]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. Filled by the standard TransferFields call, no subscriber. | [4] [5] [3] [7] |
| 4 | extend | tableextension | Sales Cr.Memo Line | Mirrors the milestone on posted credit memo lines: project credit memos created by Job Create-Invoice and corrective credit memos copied from a posted invoice. | Billing Milestone (Code[20]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. Filled by the standard TransferFields call, no subscriber. | [4] [5] [6] [7] |
| 5 | extend | tableextension | Sales Shipment Line | Mirrors the milestone on the posted shipment line table. Chosen by the mirroring article, not by the request; the requester may exclude it (oq-posted-scope). | Billing Milestone (Code[20]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. Filled by the standard TransferFields call, no subscriber. | [4] [5] [7] |
| 6 | extend | tableextension | Return Receipt Line | Mirrors the milestone on the return receipt line table. Chosen by the mirroring article, not by the request; the requester may exclude it (oq-posted-scope). | Billing Milestone (Code[20]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. Filled by the standard TransferFields call, no subscriber. | [4] [5] [7] |
| 7 | extend | tableextension | Sales Line Archive | Mirrors the milestone on archived sales lines. Chosen by the mirroring article, not by the request; the requester may exclude it (oq-posted-scope). | Billing Milestone (Code[20]): Same field number, name, type and length as on Sales Line; DataClassification = CustomerContent; Editable = false. Filled by the standard TransferFields call, no subscriber. | [4] [5] [7] |
| 8 | extend | pageextension | Sales Invoice Subform | Shows the milestone on each line of the unposted project sales invoice. |  | [3] |
| 9 | extend | pageextension | Posted Sales Invoice Subform | Shows the milestone, read-only, on each line of the posted sales invoice. |  | [3] |
| 10 | extend | pageextension | Job Planning Lines | Lets the user enter the Billing Milestone on project planning lines. Rests on judgment; no BCQuality article covers project pages. |  | agent judgment |
| 11 | create | codeunit | Project Invoice Milestone | Subscriber codeunit that copies the milestone from the planning line to the sales line inside Job Create-Invoice.CreateSalesLine, before the line is inserted. One subscriber covers both entry points (CreateSalesInvoiceLines and CreateSalesInvoiceJobTask). |  | [1] |
| 12 | extend | tableextension | Job Task | Holds the milestone value reached on each project task, which the new WIP method recognizes as sales. How it is filled is an open question (oq-milestone-value-source). | Milestone Value Reached (Decimal): DataClassification = CustomerContent. Amount in the project's currency context; source of Recognized Sales Amount when the task's WIP method uses Milestone Value. | [2] [7] |
| 13 | extend | pageextension | Job Task Lines | Shows (and, if it is user-entered, lets the user maintain) Milestone Value Reached per task. Rests on judgment; no BCQuality article covers project pages. |  | agent judgment |
| 14 | extend | enumextension | Job WIP Recognized Sales Type | Adds the value 'Milestone Value' that a Job WIP Method can select in its Recognized Sales field. |  | [2] |
| 15 | create | codeunit | Milestone WIP Method | Subscriber codeunit that computes Recognized Sales Amount for tasks whose WIP method uses 'Milestone Value', inside Job Calculate WIP before the WIP buffers are built, so WIP entries and G/L postings agree with the task. |  | [2] |
| 16 | create | permissionset | Billing Milestone | Grants execute on the new codeunits; extend it if a milestone master table is added (oq-milestone-master). |  | [3] |

## 3. How the data flows

- **User** → **Job Planning Line."Billing Milestone"**: entered by the user. Entered on the Job Planning Lines page. [1]
- **Job Planning Line."Billing Milestone"** → **Sales Line."Billing Milestone"**: copied in an event subscriber. Job Create-Invoice.OnBeforeInsertSalesLine, using the JobPlanningLine parameter of the line being invoiced; assignment only, the standard Insert(true) writes it. Covers invoices and credit memos created from planning lines and from report Job Create Sales Invoice. [1]
- **Sales Line."Billing Milestone"** → **Sales Invoice Line."Billing Milestone"**: standard TransferFields copy. InitFromSalesLine during Sales-Post; requires the same field number, type and length. [4] [5] [3]
- **Sales Line."Billing Milestone"** → **Sales Cr.Memo Line."Billing Milestone"**: standard TransferFields copy. Project credit memo lines posted by Sales-Post. [4] [5]
- **Sales Line."Billing Milestone"** → **Sales Shipment Line / Return Receipt Line."Billing Milestone"**: standard TransferFields copy. Article-chosen stage (oq-posted-scope). [4] [5]
- **Sales Line."Billing Milestone"** → **Sales Line Archive."Billing Milestone"**: standard TransferFields copy. Archiving copies lines with TransferFields; article-chosen stage (oq-posted-scope). [4] [5]
- **Sales Invoice Line."Billing Milestone"** → **Sales Line."Billing Milestone" (corrective credit memo)**: standard TransferFields copy. Cancel/Correct copy the posted invoice lines with TransferFields and no recalculation, so the milestone (business data) returns on the corrective credit memo and is posted to Sales Cr.Memo Line. No code needed. [6]
- **User or derivation (oq-milestone-value-source)** → **Job Task."Milestone Value Reached"**: entered by the user. Mechanism depends on the answer to oq-milestone-value-source. agent judgment
- **Job Task."Milestone Value Reached"** → **Job Task."Recognized Sales Amount"**: copied in an event subscriber. Job Calculate WIP.OnBeforeCalcRecognizedSales when the task's Job WIP Method has Recognized Sales = Milestone Value; sets IsHandled. [2]
- **Job Task recognized amounts** → **Job WIP Entry**: other. Standard CreateTempJobWIPBuffers and CreateWIPEntries build the buffers and entries from the amount set above; no custom code. [2]
- **Job WIP Entry** → **Job WIP G/L Entry and G/L Entry**: other. Standard report Job Post WIP to G/L (CalcGLWIP) reverses earlier WIP and posts through Gen. Jnl.-Post Line; no custom G/L posting. [2]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Job Create-Invoice" | `OnBeforeInsertSalesLine(var SalesLine, var SalesHeader, Job, JobPlanningLine, JobInvCurrency)` | Copy JobPlanningLine."Billing Milestone" to SalesLine."Billing Milestone" before the sales line is inserted. | Assign only; no Modify, the standard Insert(true) writes the value. · Read the value from the JobPlanningLine parameter; never look up a planning line by Job No. and Job Task No. · Do not subscribe to OnAfterCreateSalesInvoiceLines to patch lines afterwards. | [1] |
| Codeunit "Job Calculate WIP" | `OnBeforeCalcRecognizedSales(var JobTask, var JobWIPTotal, var JobWIPMethod, var IsHandled)` | For the Milestone Value method, set JobTask."Recognized Sales Amount" from JobTask."Milestone Value Reached" and set IsHandled. | Exit unless JobWIPMethod."Recognized Sales" is Milestone Value; leave IsHandled untouched for every other method. · Set the amount here, before the WIP buffers are built; never overwrite recognized amounts in OnAfterJobTaskCalcWIP or a separate action. · Do not post WIP to G/L from custom code; Job Post WIP to G/L must post and reverse it. | [2] |

## 5. Setup, permissions and lifecycle

- **setup**: A Job WIP Method record whose Recognized Sales is 'Milestone Value' must exist and be assigned to the projects/tasks that use it; users create it unless install code does (oq-wip-method-record). [2]
- **privacy**: Set DataClassification = CustomerContent on every new table-extension field (Billing Milestone on all seven tables, Milestone Value Reached on Job Task); a tableextension has no table-level value to inherit. [7]
- **permissions**: Ship permission set Billing Milestone with execute entries for the two new codeunits (and any milestone master table/page if oq-milestone-master adds one). [3]

## 6. Tests

1. **invoice-from-planning-lines-carries-milestone** [1] [8]
    - Given A project task with two billable planning lines carrying different Billing Milestone codes, built with the test Library codeunits
    - When Sales invoice lines are created from the planning lines (Job Create-Invoice.CreateSalesInvoiceLines)
    - Then Each sales line has the milestone of the planning line it came from (matched by Job Contract Entry No.), not the other line's value
2. **invoice-from-report-carries-milestone** [1] [8]
    - Given A project task with billable planning lines carrying Billing Milestone codes
    - When Report Job Create Sales Invoice is run for the task (CreateSalesInvoiceJobTask)
    - Then Every created sales line carries the milestone of its own planning line
3. **posted-invoice-line-keeps-milestone** [1] [4] [8]
    - Given A project sales invoice created from planning lines with milestones
    - When The invoice is posted
    - Then Each Sales Invoice Line carries the milestone, and the Job Planning Line Invoice rows are moved to Posted Invoice (Job Contract Entry No. path intact)
4. **project-credit-memo-keeps-milestone** [1] [4] [8]
    - Given Planning lines with milestones invoiced as a project credit memo
    - When The credit memo is created from the project and posted
    - Then Sales Line and Sales Cr.Memo Line carry the planning line's milestone
5. **cancel-posted-invoice-keeps-milestone** [6] [8]
    - Given A posted project sales invoice whose lines carry milestones
    - When The user runs Cancel on the posted invoice
    - Then The posted corrective credit memo lines carry the same milestones
6. **archive-keeps-milestone** [4] [8]
    - Given A project sales invoice with milestones on its lines
    - When The document is archived
    - Then Sales Line Archive carries the milestones
7. **wip-milestone-method-recognizes-milestone-value** [2] [8]
    - Given A project whose WIP method has Recognized Sales = Milestone Value and a posting task with Milestone Value Reached set
    - When Job Calculate WIP is run
    - Then The task's Recognized Sales Amount equals Milestone Value Reached and the Job WIP Entry recognized-sales amounts are built from that value
8. **wip-milestone-method-posts-to-gl-and-reverses** [2] [8]
    - Given WIP calculated with the Milestone Value method
    - When Job Post WIP to G/L is run, Milestone Value Reached is changed, and WIP is calculated and posted again
    - Then Job WIP G/L Entries and G/L Entries match the task's recognized amount, and the earlier WIP posting is reversed
9. **wip-standard-method-unaffected** [2] [8]
    - Given A project whose WIP method uses a standard Recognized Sales value and tasks with Milestone Value Reached filled
    - When Job Calculate WIP is run
    - Then Recognized Sales Amount equals the standard method's result; the subscriber does not set IsHandled
10. **wip-completed-project-uses-invoiced-price** [2] [8]
    - Given A completed project whose WIP method uses Milestone Value
    - When Job Calculate WIP is run
    - Then Recognized sales come from the invoiced price, as standard, not from Milestone Value Reached

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined from the request; all cited articles declare universal applicability.
- Page extensions on Job Planning Lines and Job Task Lines rest on the agent's judgment; no BCQuality article covers project pages.
- The source and data flow of Job Task "Milestone Value Reached" rest on the agent's judgment until oq-milestone-value-source is answered.
- Whether Job WIP Method validation restricts combinations with a new Recognized Sales value is not covered by BCQuality knowledge.

## Sources

[1] `microsoft/knowledge/projects/carry-job-planning-line-fields-to-project-sales-invoice-lines.md`: Copying the planning line milestone to project sales invoice/credit memo lines and the guards on that subscriber.
    - Add the field to Sales Line and copy it from JobPlanningLine in Job Create-Invoice.OnBeforeInsertSalesLine, so it is part of the insert with no extra write.
    - One subscriber covers both CreateSalesInvoiceLines and CreateSalesInvoiceJobTask, which both call CreateSalesLine.
    - Do not subscribe to OnAfterCreateSalesInvoiceLines and find the planning line by Job No. and Job Task No.: a task has several planning lines, so the wrong value is copied, and each line costs a Modify.
    - Never create project invoice lines in custom code without Job Contract Entry No.; posting then skips PostInvoiceContractLine, Job Planning Line Invoice and the Sale project ledger entry.
    - When posted documents or the project ledger need the value, keep following the path (TransferFields to posted lines; Job Transfer Line for the ledger).
[2] `microsoft/knowledge/projects/add-custom-project-wip-methods-through-the-recognition-events.md`: The new Milestone Value WIP method: enum extension, recognition subscriber, setup record, and the standard WIP entry and G/L posting path.
    - Add the method value with an enumextension on Job WIP Recognized Sales Type; the CalcRecognizedSales case statement has no else branch, so a value with no code behind it leaves the amount at zero.
    - Subscribe to Job Calculate WIP.OnBeforeCalcRecognizedSales; when JobWIPMethod uses the new value, set JobTask."Recognized Sales Amount" and set IsHandled.
    - Do not overwrite recognized amounts in OnAfterJobTaskCalcWIP or a separate action: WIP buffers already hold the old amounts and the next calculation's DeleteWIP clears them.
    - Do not post custom G/L journal lines for WIP; Job Post WIP to G/L does not know about them and never reverses them.
    - Users must still create a Job WIP Method record that uses the new value.
    - When the project is complete, CalcWIP sets amounts from invoiced price and usage cost and returns before the method is used.
[3] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Deciding which sales stages the line field must reach, plus page extensions, permission set entries and a post-and-read-back test per stage.
    - Decide which stages the field must reach and plan one step per stage; do not plan only the tables the requester named.
    - Posted lines and Sales Line Archive are reached by TransferFields from Sales Line.
    - Name the page extensions that show the field, the permission set entries for any new objects, and a test that posts a document and reads the value back from every target.
    - Do not plan to fill ledger entries after posting by finding and modifying them.
[4] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring Billing Milestone on every posted and archive sales line table.
    - Give the field the same field number, name, type and length on Sales Line and on every target line table the plan needs (posted shipment, invoice, credit memo, return receipt lines and Sales Line Archive), unless the plan states a document type never needs it.
    - No subscriber is needed for these stages; keep the mirrored fields non-editable on posted tables.
    - Do not use a different field number or copy the value in an OnAfter...Insert subscriber with Modify.
[5] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definition consistency across the TransferFields cascade.
    - Define a mirrored field with the exact same field number, data type and length on every table in the cascade, at creation time; a shorter length fails at runtime only when a long value appears.
[6] `microsoft/knowledge/sales-purchase/corrective-credit-memo-copies-custom-fields-from-the-posted-invoice.md`: Classifying the mirrored milestone as business data that should return on corrective credit memos.
    - Every field mirrored on the posted invoice comes back on a Cancel/Correct credit memo; business data stays mirrored and needs no code.
    - Per-document state must be cleared in Copy Document Mgt.OnAfterCopySalesHeaderDone; the milestone is not such state.
    - Test Cancel on an invoice that has the custom fields filled and read the posted credit memo back.
[7] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: DataClassification on every new table-extension field.
    - Every Normal field a tableextension adds must set its own DataClassification; ToBeClassified is not a safe default.
    - Choose the value that matches the data stored, at field definition time.
[8] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Building project, customer and document fixtures in the tests.
    - Create fixtures with the test Library codeunits, not hand-rolled Init/Insert with invented keys.
    - Create parents before dependents and Validate foreign-key fields so TableRelations run as in production.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
