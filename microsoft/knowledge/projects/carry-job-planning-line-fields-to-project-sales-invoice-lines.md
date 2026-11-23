---
bc-version: [all]
domain: projects
keywords: [job-create-invoice, job-planning-line, job-planning-line-invoice, onbeforeinsertsalesline, createsalesline, job-contract-entry-no, postinvoicecontractline, project-invoicing, sales-line]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry project planning line fields to the sales invoice lines it creates

## Description

Codeunit `Job Create-Invoice` turns billable `Job Planning Line` records into sales invoice or credit memo lines. Both entry points, `CreateSalesInvoiceLines` (from planning lines) and `CreateSalesInvoiceJobTask` (from report `Job Create Sales Invoice`), call the same `CreateSalesLine` procedure. `CreateSalesLine` builds the `Sales Line` field by field with `Validate`, so a custom planning line field is not carried.

`CreateSalesLine` raises `OnBeforeInsertSalesLine(SalesLine, SalesHeader, Job, JobPlanningLine, JobInvCurrency)` just before `SalesLine.Insert(true)`. It ends with `OnAfterCreateSalesLine`, which runs after the insert.

The link between the two documents is not the job number. `CreateSalesLine` validates `Sales Line."Job Contract Entry No."` with the planning line's `Job Contract Entry No.`. For each line it also inserts a `Job Planning Line Invoice` row with the job, task, planning line, document and sales line numbers.

When the invoice is posted, `Sales-Post` runs `PostJobContractLine` only when `Job Contract Entry No.` is not zero. `Job Post-Line.PostInvoiceContractLine` finds the planning line by that number, renames the `Job Planning Line Invoice` row to `Posted Invoice` or `Posted Credit Memo` with the posted number, and sets the invoiced date and amounts. It then posts a `Sale` project ledger entry through `Job Transfer Line.FromPlanningSalesLineToJnlLine`.

## Best Practice

Add the field to `Sales Line` and subscribe to `OnBeforeInsertSalesLine` on `Job Create-Invoice`. Copy the value from `JobPlanningLine` to `SalesLine` there, so it is part of the insert and needs no extra write. One subscriber covers both entry points.

When posted documents or the project ledger need the value, keep following the path. Sales line fields reach posted invoice lines by `TransferFields`. The project ledger `Sale` entry is built by `Job Transfer Line`; see [carry document fields to the project journal line](carry-document-fields-to-job-journal-line-on-every-source-path.md).

To store extra data on the `Job Planning Line Invoice` link, use `OnCreateSalesInvoiceLinesOnBeforeJobPlanningLineInvoiceInsert` and `OnCreateSalesInvoiceJobTaskOnBeforeJobPlanningLineInvoiceInsert`. They are two events, one for each entry point.

See sample: [`carry-job-planning-line-fields-to-project-sales-invoice-lines.good.al`](carry-job-planning-line-fields-to-project-sales-invoice-lines.good.al).

## Anti Pattern

Subscribe to `OnAfterCreateSalesInvoiceLines`, loop over the new sales lines and find "the" planning line by `Job No.` and `Job Task No.`. A task usually has several planning lines, so the wrong value is copied, and every line costs an extra `Modify`.

Creating project invoice lines in custom code with only `Job No.` and `Job Task No.` set is the same mistake on a bigger scale. Without `Job Contract Entry No.` the posting never calls `PostInvoiceContractLine`. No `Job Planning Line Invoice` row is updated, and no `Sale` project ledger entry is posted.

See sample: [`carry-job-planning-line-fields-to-project-sales-invoice-lines.bad.al`](carry-job-planning-line-fields-to-project-sales-invoice-lines.bad.al).

## References

- [Job Create-Invoice: CreateSalesInvoiceLines, CreateSalesInvoiceJobTask, CreateSalesLine and their events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Planning/JobCreateInvoice.Codeunit.al).
- [Job Planning Line Invoice table](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Planning/JobPlanningLineInvoice.Table.al).
- [Job Post-Line: PostInvoiceContractLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Posting/JobPostLine.Codeunit.al).
- [Sales-Post: PostJobContractLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al).
