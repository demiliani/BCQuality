---
bc-version: [all]
domain: projects
keywords: [purchase-line, job-post-line, postjobonpurchaseline, frompurchaselinetojnlline, postjobpurchaselines, res-jnl-post-line, res-ledger-entry, onaftercopyresjnllinefrompurchaseline, onbeforeresledgentryinsert, project-usage]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Project purchases post usage only for item and G/L account lines

## Description

A purchase line with a project number posts two things: the purchase itself, and project usage through a separate `Job Journal Line`. Codeunit `Job Post-Line`.`PostJobOnPurchaseLine` builds that line with `Job Transfer Line`.`FromPurchaseLineToJnlLine`, which ends with `OnAfterFromPurchaseLineToJnlLine`. It handles only purchase lines of type `Item` or `G/L Account`. For any other type it exits, and `Purch.-Post` never prepares a project line for it either.

The two supported types post at different moments:

- `Item`: the project journal line gets `Job Posting Only` set and is posted at once by `Job Jnl.-Post Line`. The purchase posting itself posts the item entries, so the project line adds no second item entry.
- `G/L Account`: the project journal line is held in a temporary table. `PostJobPurchaseLines` posts it after the G/L entries exist and passes the G/L entry number. The event `OnPostJobPurchaseLinesOnBeforeJobJnlPostLine` runs just before.

Both reach `Job Ledger Entry` through `CreateJobLedgEntry` and `OnAfterFromJnlLineToLedgEntry`.

A purchase line of type `Resource` takes another path. `Purch.-Post` builds a `Res. Journal Line` with `CopyFrom(PurchaseHeader)` and `CopyFrom(PurchaseLine)`. Their events are `OnAfterCopyResJnlLineFromPurchaseHeader` and `OnAfterCopyResJnlLineFromPurchaseLine`. The line has entry type `Purchase` and is posted only when `Qty. to Invoice` is not zero. The copy does not set `Job No.`, and no project journal line is created. A resource purchased for a project therefore posts a resource ledger entry and no project usage.

Codeunit 212 `Res. Jnl.-Post Line` creates every `Res. Ledger Entry` the same way, whatever the source. It calls `CopyFromResJnlLine`, which assigns named fields and raises `OnAfterCopyFromResJnlLine`. For `Sale` entries it then reverses the sign of quantity, cost and price. It raises `OnBeforeResLedgEntryInsert(var ResLedgerEntry; ResJournalLine)` just before the insert.

## Best Practice

For a custom purchase line value that must reach the project ledger, add the field to `Job Journal Line` and `Job Ledger Entry`. Copy it in `OnAfterFromPurchaseLineToJnlLine`, then in `OnAfterFromJnlLineToLedgEntry`. One subscriber pair covers item and G/L account lines, and the value is set before the deferred G/L account lines are posted. Other sources of project journal lines are listed in [carry document fields to the project journal line](carry-document-fields-to-job-journal-line-on-every-source-path.md). The ledger hop is described in [carry project journal fields to the project ledger](carry-job-journal-fields-to-job-ledger-through-job-transfer-line.md).

When project cost comes from a purchase, design it as an item or G/L account line with the project. Post resource time through a project journal resource line, which posts both the resource and the project ledger. For a value on resource ledger entries, add it to `Res. Journal Line` and `Res. Ledger Entry`. Copy it in the event of each source, such as `OnAfterCopyResJnlLineFromPurchaseLine`, then in `OnAfterCopyFromResJnlLine`. Read signed amounts in `OnBeforeResLedgEntryInsert`, after the sign change.

See sample: [`project-purchases-post-usage-only-for-item-and-gl-account-lines.good.al`](project-purchases-post-usage-only-for-item-and-gl-account-lines.good.al).

## Anti Pattern

Add the field to `Purchase Line` and `Job Ledger Entry` with the same number and expect it to arrive. Every hop copies named fields, so it stays empty. Or design resource purchases with a project number and expect project usage. They post only a resource ledger entry, and the project shows no cost.

See sample: [`project-purchases-post-usage-only-for-item-and-gl-account-lines.bad.al`](project-purchases-post-usage-only-for-item-and-gl-account-lines.bad.al).

## References

- [Job Post-Line: PostJobOnPurchaseLine and PostJobPurchaseLines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Posting/JobPostLine.Codeunit.al).
- [Job Transfer Line: FromPurchaseLineToJnlLine and FromJnlLineToLedgEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Journal/JobTransferLine.Codeunit.al).
- [Purch.-Post: PostResourceLine, PostResJnlLine and project line preparation](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Posting/PurchPost.Codeunit.al).
- [Res. Journal Line: CopyFrom purchase header and line](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Resources/Journal/ResJournalLine.Table.al).
- [Res. Jnl.-Post Line, resource ledger insert](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Resources/Journal/ResJnlPostLine.Codeunit.al).
- [Res. Ledger Entry: CopyFromResJnlLine and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Resources/Ledger/ResLedgerEntry.Table.al).
