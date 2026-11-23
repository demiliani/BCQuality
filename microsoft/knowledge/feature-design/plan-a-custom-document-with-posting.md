---
bc-version: [all]
domain: feature-design
keywords: [feature-design, custom-document, posting-routine, posted-document, document-header, document-lines, navigate, report-selections, document-attachment, posting-preview]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan a custom document with posting

## Description

Requests such as "service visit reports that are posted", "equipment rental orders" or "quality inspection documents with a posted history" add a document of their own: a header and lines, a status, numbering, and a posting routine that turns the open document into posted records and, often, ledger entries. Each of those parts has a standard Business Central shape that users, Navigate, Report Selections, attachments, approvals and other extensions expect.

The rules for each part sit in several domains and are written for review. Without a plan, an agent builds the header, the lines and a posting codeunit, and the posted history, Find Entries, printing and attachments surface later as missing features. The master data the document refers to, its setup table, pages, classification and install code follow [plan a new business entity end to end](plan-a-new-business-entity-end-to-end.md); this map covers what a posted document adds.

## Best Practice

Plan one decision per row, in this order, and open the linked articles before designing that part:

| Decision | What to settle | Knowledge |
| --- | --- | --- |
| Master data, setup and pages | Table types, setup singleton, card and list pages, classification, install code | [plan a new business entity end to end](plan-a-new-business-entity-end-to-end.md), [table type conventions](../data-modeling/table-design-must-match-bc-table-type-conventions.md), [page type conventions](../ui/page-design-must-match-bc-page-type-conventions.md) |
| Header and lines | Document header with lines owned by it; lines deleted with the header; header defaults set in one place for every creation path | [owner deletes dependents](../data-modeling/owning-table-must-delete-dependents-in-ondelete.md), [defaults in InitRecord](../data-modeling/initialize-document-defaults-in-initrecord.md) |
| Several document types on one table | Route list pages to the right card through `Page Management` | [list page routing](../ui/list-page-document-routing-uses-page-management.md) |
| Numbering | Document series and posting series through the `No. Series` codeunit, both kept in the setup table | [number series in OnInsert](../data-modeling/master-table-no-from-number-series-in-oninsert.md), [No. Series codeunit](../data-modeling/use-no-series-codeunit-not-noseriesmanagement.md), [TestField required setup](../data-modeling/testfield-required-setup-field.md) |
| Status and release | Which statuses exist, who changes them, what release checks; whether approval holds release | none yet for a custom release routine; rests on judgment. Status changes driven by approval: [status responses](custom-approval-records-must-handle-status-responses.md) |
| Posting structure | Check one line, post one line, loop in batch; a document posting calls the line posting directly | [Check, Post Line and Post Batch](../data-modeling/check-post-line-batch-pattern.md), [implicit transaction boundary](../performance/understand-implicit-transaction-boundary.md), [no prompts inside transactions](../performance/avoid-user-prompts-inside-transactions.md) |
| Checks before posting | Report every blocking problem, not only the first | [collect validation errors](../error-handling/collect-validation-errors-with-errorbehavior.md), [Blocked at use](../data-modeling/check-blocked-in-referencing-code-not-in-master.md) |
| Ledger effects | Write G/L, item or other ledgers only through their journals and posting codeunits; never edit posted entries | [post through posting codeunits](../finance/post-ledger-entries-through-posting-codeunits.md), [journal lines from code](../finance-extensions/post-finance-journal-lines-from-code-in-a-dedicated-batch.md), [item ledger through item journals](../scm/post-item-ledger-changes-through-item-journals.md), [do not modify posted entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md) |
| Posted tables | Posted header and lines mirror the open fields by number, type and length | [mirrored fields match](../data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md), [type mismatch drops data](../data-modeling/transferfields-skip-type-mismatch-can-drop-data.md), [newest first on history pages](../ui/default-descending-sort-on-historical-pages.md) |
| Navigate | Add the posted tables to Find Entries on both the find and the show side | [extend Find Entries](../data-modeling/extend-find-entries-navigate-for-new-document-types.md) |
| Dimensions | Dimension sources of the header and lines, and the set carried to journals | [plan the dimension sources](plan-the-dimension-sources-of-a-custom-document.md), [dimension wiring](../data-modeling/dimension-management-wiring.md), [dimension set entries](../finance/write-dimensions-as-dimension-set-entries.md) |
| Posting preview | Whether the document supports Preview Posting, and how subscribers detect preview | none yet for a custom posting routine; rests on judgment. For standard routines see [after-posting hooks](../sales-purchase/choose-the-after-posting-hook-per-posting-routine.md) |
| Extensibility | Thin `OnBefore`/`OnAfter` events around check, post and release | [thin integration events](../events/publish-thin-onbefore-onafter-integration-events.md), [IsHandled for overridable behavior](../events/use-ishandled-to-make-base-behaviour-overridable.md) |
| Printing | Register the document in Report Selections; print and email through it | [Report Selection usage](../data-modeling/extend-report-selection-usage-for-new-document-types.md), [do not bypass Report Selections](../data-modeling/custom-document-dispatch-must-not-bypass-report-selections.md), [plan a printable document](plan-a-printable-document-and-its-delivery.md) |
| Archive | Whether open documents are archived before change or deletion | none yet for a custom archive; rests on judgment |
| Attachments | Map the custom key for the open and posted tables and copy attachments on posting | [document attachments on custom tables](../data-modeling/enable-document-attachments-on-custom-tables.md) |
| Approvals | Approval before release or posting | [plan an approval workflow](plan-an-approval-workflow-for-a-custom-record.md) |
| Permissions | Posted tables written by the posting codeunit; users get indirect rights where they may not insert directly | [indirect permissions](../security/indirect-permissions-for-elevated-access.md), [included sets](../security/compose-permission-sets-with-included-sets.md), [AppSource sets without SUPER](../appsource/permission-sets-cover-setup-and-usage-without-super.md) |
| Tests | Post through the routine, not by inserting posted rows; lower permissions; one action per test | [library fixtures](../testing/use-library-codeunits-for-test-fixtures.md), [posted-table license failures](../testing/triage-posted-table-license-failures-against-baseline.md), [permission tests](../testing/permission-tests-must-lower-the-execution-context.md), [one When per test](../testing/test-one-when-per-test.md) |

Whether the document needs an archive, a preview, approvals or ledger entries at all is for the requester to say. When the request does not settle a row, raise it as an open question instead of building it or leaving it out silently.

## Anti Pattern

Build the header, the lines and one codeunit that inserts posted rows and ledger entries directly, prints a hardcoded report and leaves Navigate, attachments and permissions for later. The posted history cannot be found by document number, attachments of one document appear on every document, users without SUPER cannot post, and the ledger entries bypass the posting engine.

## References

- [Document Attachment Mgmt: CopyAttachments and the events for custom tables](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Foundation/Attachment/DocumentAttachmentMgmt.Codeunit.al).
- [Identify functional table types and characteristics (training)](https://learn.microsoft.com/en-us/training/modules/identify-table-types/).
