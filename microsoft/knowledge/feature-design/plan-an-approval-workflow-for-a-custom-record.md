---
bc-version: [all]
domain: feature-design
keywords: [feature-design, approval-workflow, workflow-event-handling, workflow-response-handling, approvals-mgmt, workflow-management, approval-entry, status, release, reopen]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan an approval workflow for a custom record before building it

## Description

A request such as "contracts must be approved before release" reuses the standard workflow engine: approval entries, approver setup, notifications and the Requests to Approve page. The extension supplies what the engine cannot know about its table: the workflow events, the link between those events and the standard responses, the status changes, and the cleanup when a record is renamed or deleted.

The standard building blocks are `"Workflow Event Handling"` (codeunit 1520), `"Workflow Response Handling"` (1521), `"Workflow Management"` (1501), `"Workflow Setup"` (1502) and `"Approvals Mgmt."` (1535). Every row below names the extension point the plan uses.

## Best Practice

Plan one decision per row, in this order:

| Decision | What to settle | Standard extension point | Knowledge |
| --- | --- | --- | --- |
| Status | An Open, Pending Approval and Released status on the record, and which fields stay editable in each | Status field on the custom table | [pages hold no business logic](../style/pages-must-not-contain-business-logic.md) |
| Workflow events | Events such as "approval of a contract is requested" and "approval request is canceled" | Subscribe to `OnAddWorkflowEventsToLibrary` on `"Workflow Event Handling"` and call `AddEventToLibrary`; order them with `OnAddWorkflowEventPredecessorsToLibrary` on the same codeunit and `AddEventPredecessor` | [walkthrough](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-walkthrough-workflow-events-responses) |
| Raising the events | Send and Cancel actions check that an enabled workflow exists, then raise the event | `"Workflow Management".CanExecuteWorkflow` and `HandleEvent` | [pages hold no business logic](../style/pages-must-not-contain-business-logic.md), [action groups](../ui/promoted-action-groups.md) |
| Responses | Reuse the standard responses, such as `SetStatusToPendingApprovalCode`, `CreateApprovalRequestsCode`, `SendApprovalRequestForApprovalCode`, `ReleaseDocumentCode`, `OpenDocumentCode` and `CancelAllApprovalRequestsCode`, after your events | `OnAddWorkflowResponsePredecessorsToLibrary` on `"Workflow Response Handling"` and `AddResponsePredecessor` | [walkthrough](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-walkthrough-workflow-events-responses) |
| Status responses | The standard responses do not know the custom table and must be handled | `OnSetStatusToPendingApproval`, `OnReleaseDocument`, `OnOpenDocument` | [handle the status responses](custom-approval-records-must-handle-status-responses.md) |
| Approval entry details | Amount, document number or other values approvers see or limits use; the approval limit check for the custom table | `OnPopulateApprovalEntryArgument` on `"Approvals Mgmt."` (check `RecRef.Number`); `OnSufficientApproverElseCase` for Approver Chain and First Qualified Approver; `OnBeforeApprovalEntryInsert` for extension fields | [fill the approval entry argument](fill-the-approval-entry-argument-for-a-custom-record.md) |
| Table relation | Link the table to `Approval Entry` so the workflow engine follows the record | `OnAddWorkflowTableRelationsToLibrary` on codeunit `"Workflow Event Handling"` and `"Workflow Setup".InsertTableRelation` | [walkthrough](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-walkthrough-workflow-events-responses) |
| Rename and delete | Approval entries follow a renamed record and go away with a deleted one | Raise `OnRenameRecordInApprovalRequest` and `OnDeleteRecordInApprovalRequest` on `"Approvals Mgmt."` from the table triggers | [owner deletes dependents](../data-modeling/owning-table-must-delete-dependents-in-ondelete.md), [delete with trigger](../data-modeling/delete-master-data-with-trigger.md) |
| Workflow template | Whether to ship a ready, disabled template users can enable, in new and existing companies | `OnAfterInitWorkflowTemplates` on `"Workflow Setup"`, guarded by `Workflow.Get(GetWorkflowTemplateCode(...))`, then `InsertWorkflowTemplate`, `InsertDocApprovalWorkflowSteps` and `MarkWorkflowAsTemplate`; category through `OnAddWorkflowCategoriesToLibrary` | [ship a workflow template](ship-a-workflow-template-for-a-custom-record-approval.md) |
| Page actions | Send, Cancel and Approval entries actions, shown from the record's approval state | `"Approvals Mgmt."` `HasOpenApprovalEntries`, `CanCancelApprovalForRecord`, `HasOpenApprovalEntriesForCurrentUser` | [action groups](../ui/promoted-action-groups.md) |
| Permissions | Requesters, approvers and workflow administrators | Permission sets for the new objects | [included sets](../security/compose-permission-sets-with-included-sets.md), [no wildcards](../security/permission-set-avoid-wildcard-grants.md) |
| Tests | Enable a workflow, send, approve, reject, cancel, and check the status each time | `"Library - Workflow"` (codeunit 131101) | [library fixtures](../testing/use-library-codeunits-for-test-fixtures.md), [permission tests](../testing/permission-tests-must-lower-the-execution-context.md) |

Register events, responses and table relations only through these library events. Business Central removes and recreates the workflow libraries on upgrade, and only records added through the extension points come back.

When the custom record is itself new, plan it first with [plan a new business entity end to end](plan-a-new-business-entity-end-to-end.md).

## Anti Pattern

Insert rows into the workflow event, response or table relation tables from install code, or handle only the Release response. The workflow looks complete in setup, then stops with "Record type ... is not supported by this workflow response" on the first request, or loses its events after the next upgrade.

## References

- [Walkthrough: implementing new workflow events and responses](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-walkthrough-workflow-events-responses).
- [Workflow Event Handling](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/Workflow/WorkflowEventHandling.Codeunit.al) and [Approvals Mgmt.](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/OtherCapabilities/Approvals/ApprovalsMgmt.Codeunit.al).
