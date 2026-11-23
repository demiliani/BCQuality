---
bc-version: [all]
domain: projects
keywords: [job-ledger-entry, job-journal-line, job-transfer-line, fromjnllinetoledgentry, onafterfromjnllinetoledgentry, job-jnl-post-line, project, createjobledgentry]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry project journal fields to the project ledger through Job Transfer Line

## Description

Every `Job Ledger Entry` is created by `Job Jnl.-Post Line` in `CreateJobLedgEntry`, whatever the source: a project journal, a purchase line posted to a project, a project planning line invoiced through sales, or a general journal line with a project. That procedure initializes the entry and calls `"Job Transfer Line".FromJnlLineToLedgEntry`, which assigns named fields from `Job Journal Line` one by one and ends with the integration event `OnAfterFromJnlLineToLedgEntry`.

Because the copy is field by field, giving the `Job Journal Line` field and the `Job Ledger Entry` field the same number does nothing. A custom field reaches the ledger only if an extension copies it.

## Best Practice

Add the field to `Job Journal Line` and `Job Ledger Entry`, and subscribe to `OnAfterFromJnlLineToLedgEntry` on codeunit `Job Transfer Line` to copy it while the entry is being built. One subscriber then covers every source, because all of them post through `CreateJobLedgEntry`. Make sure the value is on the project journal line first; for lines that `Job Transfer Line` builds from purchase lines, planning lines or general journal lines, see [carry document fields to the project journal line](carry-document-fields-to-job-journal-line-on-every-source-path.md).

`Job Jnl.-Post Line` also raises `OnBeforeJobLedgEntryInsert` just before the insert, which is an acceptable alternative when the value is computed rather than copied.

See sample: [`carry-job-journal-fields-to-job-ledger-through-job-transfer-line.good.al`](carry-job-journal-fields-to-job-ledger-through-job-transfer-line.good.al).

## Anti Pattern

Rely on matching field numbers, as for posted sales documents, or subscribe to `OnAfterJobLedgEntryInsert` and call `Modify` on the inserted entry. The first leaves the field blank; the second adds a write for every posted project entry and edits a ledger entry after the posting engine created it.

See sample: [`carry-job-journal-fields-to-job-ledger-through-job-transfer-line.bad.al`](carry-job-journal-fields-to-job-ledger-through-job-transfer-line.bad.al).

## References

- [Job Jnl.-Post Line, CreateJobLedgEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Posting/JobJnlPostLine.Codeunit.al).
- [Job Transfer Line, FromJnlLineToLedgEntry and its event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Journal/JobTransferLine.Codeunit.al).
