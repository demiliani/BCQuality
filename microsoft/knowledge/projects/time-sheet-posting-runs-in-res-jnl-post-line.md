---
bc-version: [all]
domain: projects
keywords: [time-sheet-detail, time-sheet-posting-entry, res-jnl-post-line, res-journal-line, res-ledger-entry, copyfromjobjnlline, onaftercopyfromresjnlline, onaftercopyresjnllinefromjobjnlline, service-line, resource]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Time sheet posting runs in Res. Jnl.-Post Line

## Description

Time sheet hours are marked as posted in one place: codeunit `Res. Jnl.-Post Line`. For a usage entry, it calls its local procedure `PostTimeSheetDetail` when the `Res. Journal Line` has a `Time Sheet No.`. That procedure adds the quantity to `Posted Quantity` on `Time Sheet Detail` and calls `CreateTSPostingEntry` in `Time Sheet Management` to insert a `Time Sheet Posting Entry`. It sets `Posted` on the line when no unposted detail is left. It also replaces `Chargeable` on the `Res. Ledger Entry` with the value from `Time Sheet Line`.

Every source reaches it through a resource journal line:

| Source | How the resource journal line is built |
| --- | --- |
| Resource journal (report `Suggest Res. Jnl. Lines`) | `Res. Journal Line` posted directly |
| Project journal, resource line | `Job Jnl.-Post Line`.`PostResource` calls `CopyFromJobJnlLine` (event `OnAfterCopyResJnlLineFromJobJnlLine`) |
| Service order shipped or consumed | `Serv-Posting Journals Mgt.` calls `Service Line`.`CopyToResJournalLine` (event `OnAfterCopyToResJournalLine`) |

Each copy assigns named fields one by one, including the three time sheet fields. `Res. Ledger Entry`.`CopyFromResJnlLine` does the same and raises `OnAfterCopyFromResJnlLine`.

## Best Practice

Do not write your own code that updates `Time Sheet Detail` or inserts `Time Sheet Posting Entry`. Post the hours through a journal or document that ends in `Res. Jnl.-Post Line`, and keep the three time sheet fields on the line. To carry a custom field to `Res. Ledger Entry`, add it to `Res. Journal Line` and the ledger. Copy it with the event of each source path the design needs, then copy it to the ledger with `OnAfterCopyFromResJnlLine`. Use `OnAfterCreateTSPostingEntry` only to react to a posting entry, not to create one.

For the project ledger side of the same project journal line, see [carry project journal fields to the project ledger](carry-job-journal-fields-to-job-ledger-through-job-transfer-line.md). For how the journal line is suggested, see [carry time sheet fields to the project journal](carry-time-sheet-fields-to-job-journal-through-suggest-lines.md). Limits on what can be posted are in [time sheet hours post per day](time-sheet-hours-post-per-day-only-when-approved.md).

See sample: [`time-sheet-posting-runs-in-res-jnl-post-line.good.al`](time-sheet-posting-runs-in-res-jnl-post-line.good.al).

## Anti Pattern

Post the resource usage with a custom `Res. Journal Line` that leaves `Time Sheet No.` empty, then set `Posted` on the time sheet line yourself. No posting entry and no posted quantity are recorded, so the time sheet totals are wrong and the hours can be suggested again. Or extend only `Job Journal Line` and `Res. Ledger Entry`: the resource journal line in between is built field by field, so the field stays empty.

See sample: [`time-sheet-posting-runs-in-res-jnl-post-line.bad.al`](time-sheet-posting-runs-in-res-jnl-post-line.bad.al).

## References

- [Res. Jnl.-Post Line, PostTimeSheetDetail](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Resources/Journal/ResJnlPostLine.Codeunit.al).
- [Res. Journal Line, CopyFromJobJnlLine and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Resources/Journal/ResJournalLine.Table.al).
- [Res. Ledger Entry, CopyFromResJnlLine and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Resources/Ledger/ResLedgerEntry.Table.al).
- [Job Jnl.-Post Line, PostResource](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Posting/JobJnlPostLine.Codeunit.al).
- [Serv-Posting Journals Mgt., resource journal lines from service lines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Posting/ServPostingJournalsMgt.Codeunit.al).
- [Time Sheet Management, CreateTSPostingEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/TimeSheet/TimeSheetManagement.Codeunit.al).
