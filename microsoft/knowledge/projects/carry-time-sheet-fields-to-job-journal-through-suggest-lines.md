---
bc-version: [all]
domain: projects
keywords: [time-sheet-line, time-sheet-detail, job-journal-line, suggest-job-jnl-lines, onaftertransfertimesheetdetailtojobjnlline, suggest-lines-from-time-sheets, job-ledger-entry, project]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry time sheet fields to the project journal through Suggest Job Jnl. Lines

## Description

Approved project hours reach the project ledger through the project journal. The action **Suggest Lines from Time Sheets** on the project journal runs report 952 `Suggest Job Jnl. Lines`. It reads only `Time Sheet Line` records with type Job, status Approved and `Posted` false, and buffers them in a temporary `Time Sheet Line` by record assignment.

For each `Time Sheet Detail` of a buffered line, the report creates one `Job Journal Line`. It fills named fields one by one: project, project task, the resource from `Time Sheet Header`, work type, posting date (the detail date), description, quantity and `Chargeable`. It also sets `Time Sheet No.`, `Time Sheet Line No.` and `Time Sheet Date`, which link the journal line back to the time sheet. A custom field on the time sheet is not copied.

Just before `Insert`, the report raises `OnAfterTransferTimeSheetDetailToJobJnlLine` with the journal line, the temporary time sheet line and the time sheet detail. The `Job Transfer Line` events used for purchase and planning lines are not raised on this path.

## Best Practice

Add the field to `Job Journal Line` and `Job Ledger Entry`. Subscribe to `OnAfterTransferTimeSheetDetailToJobJnlLine` on report `Suggest Job Jnl. Lines`. Copy a line-level value from the temporary time sheet line, which holds every field of the real line. Copy a per-day value from `Time Sheet Detail`. Assign the field without `Modify`, because the line is not inserted yet.

From the journal line, one subscriber to `OnAfterFromJnlLineToLedgEntry` carries the value to the ledger; see [carry project journal fields to the project ledger](carry-job-journal-fields-to-job-ledger-through-job-transfer-line.md). For other sources of project journal lines, see [carry document fields to the project journal line](carry-document-fields-to-job-journal-line-on-every-source-path.md). How posting then updates the time sheet is described in [time sheet posting runs in Res. Jnl.-Post Line](time-sheet-posting-runs-in-res-jnl-post-line.md).

See sample: [`carry-time-sheet-fields-to-job-journal-through-suggest-lines.good.al`](carry-time-sheet-fields-to-job-journal-through-suggest-lines.good.al).

## Anti Pattern

Give `Time Sheet Line` and `Job Ledger Entry` fields with the same number and expect the value to follow. Or subscribe to `OnAfterJobLedgEntryInsert`, read the time sheet line again and `Modify` the new ledger entry. The first leaves the field blank. The second adds a read and a write per posted entry, and skips the journal line, where users review the value before posting.

See sample: [`carry-time-sheet-fields-to-job-journal-through-suggest-lines.bad.al`](carry-time-sheet-fields-to-job-journal-through-suggest-lines.bad.al).

## References

- [Suggest Job Jnl. Lines, one journal line per time sheet detail](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/TimeSheet/SuggestJobJnlLines.Report.al).
- [Project journal page, Suggest Lines from Time Sheets action](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Journal/JobJournal.Page.al).
- [Job Transfer Line, FromJnlLineToLedgEntry and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Journal/JobTransferLine.Codeunit.al).
- [Set up time sheets (Microsoft Learn)](https://learn.microsoft.com/en-us/dynamics365/business-central/projects-how-setup-time-sheets).
