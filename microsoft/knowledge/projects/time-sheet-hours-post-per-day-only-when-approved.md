---
bc-version: [all]
domain: projects
keywords: [time-sheet-detail, time-sheet-line, approved, posted-quantity, getmaxqtytopost, checktslinedetailposting, use-time-sheet, job-journal-line, res-journal-line]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Time sheet hours post per day, and only when approved

## Description

A time sheet line is not one posting unit. Each day is a `Time Sheet Detail` keyed by time sheet, line and date. `Suggest Job Jnl. Lines` and `Suggest Res. Jnl. Lines` create one journal line per detail, with quantity `GetMaxQtyToPost` (quantity minus posted quantity). Both reports read only lines with status Approved and `Posted` false.

The journal check codeunits enforce the same rules on any line that has a `Time Sheet No.`. `Time Sheet Management`.`CheckTSLineDetailPosting` gets the detail for the line's `Time Sheet Date`. It requires status Approved and `Posted` false, and rejects a quantity above the open quantity. Posting may be partial: the detail becomes `Posted` only when posted quantity equals quantity, and the line only when all its details are posted. A line cannot be reopened after it is posted, because `ReopenApproved` tests `Posted` false.

When a resource has `Use Time Sheet`, validating it on a `Job Journal Line` or a `Res. Journal Line` without a `Time Sheet No.` raises an error. The resource journal skips this check for system-created entries.

## Best Practice

Design the feature per day, not per time sheet line. Create journal lines from `Time Sheet Detail`, set `Time Sheet No.`, `Time Sheet Line No.` and `Time Sheet Date` before validating the resource, and take the quantity from `GetMaxQtyToPost`. The simplest way is to run the suggest report for the journal batch. Filter on status Approved and on unposted details. Expect several journal lines, and several ledger entries, for one time sheet line. Tests should cover a partly posted day and a rejected line.

For the copy events on the suggested lines, see [carry time sheet fields to the project journal](carry-time-sheet-fields-to-job-journal-through-suggest-lines.md). For where the posted flags are set, see [time sheet posting runs in Res. Jnl.-Post Line](time-sheet-posting-runs-in-res-jnl-post-line.md).

See sample: [`time-sheet-hours-post-per-day-only-when-approved.good.al`](time-sheet-hours-post-per-day-only-when-approved.good.al).

## Anti Pattern

Build one journal line per time sheet line with its total quantity, or include submitted lines to save a step. The line has no single `Time Sheet Date`, so the detail check fails or the quantity exceeds one day. Submitted hours fail the approval test at posting. Or validate the resource before setting `Time Sheet No.`, which fails for every resource that uses time sheets.

See sample: [`time-sheet-hours-post-per-day-only-when-approved.bad.al`](time-sheet-hours-post-per-day-only-when-approved.bad.al).

## References

- [Time Sheet Management, CheckTSLineDetailPosting and CheckJobJnlLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/TimeSheet/TimeSheetManagement.Codeunit.al).
- [Time Sheet Detail, GetMaxQtyToPost](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/TimeSheet/TimeSheetDetail.Table.al).
- [Suggest Res. Jnl. Lines, approved and unposted lines only](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/TimeSheet/SuggestResJnlLines.Report.al).
- [Job Jnl.-Check Line, time sheet check](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Posting/JobJnlCheckLine.Codeunit.al).
- [Job Journal Line, CheckResource and Use Time Sheet](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Journal/JobJournalLine.Table.al).
- [Time Sheet Approval Management, ReopenApproved](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/TimeSheet/TimeSheetApprovalManagement.Codeunit.al).
- [Use time sheets (Microsoft Learn)](https://learn.microsoft.com/en-us/dynamics365/business-central/projects-how-use-time-sheets).
