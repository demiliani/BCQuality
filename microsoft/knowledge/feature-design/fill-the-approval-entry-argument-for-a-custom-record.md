---
bc-version: [all]
domain: feature-design
keywords: [approval-workflow, approvals-mgmt, approval-entry, onpopulateapprovalentryargument, onsufficientapproverelsecase, onbeforeapprovalentryinsert, approver-chain, approval-limit, user-setup, custom-document]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Fill the approval entry argument for a custom record, and handle its approval limit

## Description

When the Create Approval Requests response runs, `"Approvals Mgmt."` (codeunit 1535) first builds a template record, `ApprovalEntryArgument`, in `PopulateApprovalEntryArgument`. It sets `Table ID`, `Record ID to Approve`, `Approval Code` and `Workflow Step Instance ID`, with a blank `Document Type`. Then it fills the business values for known tables only: `Purchase Header`, `Sales Header`, `Customer`, `Gen. Journal Line` and a few others. For any other table it raises `OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")`.

The argument drives three things:

- `MakeApprovalEntry` copies `Document Type`, `Document No.`, `Salespers./Purch. Code`, `Amount`, `Amount (LCY)`, `Currency Code` and `Available Credit Limit (LCY)` to each approval entry. Extension fields are not copied. `OnBeforeApprovalEntryInsert(var ApprovalEntry, ApprovalEntryArgument, WorkflowStepArgument, ApproverId, var IsHandled)` runs just before the insert.
- Approver type `Salesperson/Purchaser` calls `TestField` on `Salespers./Purch. Code` of the argument.
- `IsSufficientApprover` checks the limit for the Approver Chain and First Qualified Approver limit types. It compares `Amount (LCY)` with `User Setup` limits only for `Purchase Header`, `Sales Header` and `Gen. Journal Line`. For any other table the result starts as true, and only `OnSufficientApproverElseCase(UserSetup, ApprovalEntryArgument, var IsSufficient)` can change it.

So for a custom table without subscribers, the approval entries show no amount or document number, and the first approver always counts as sufficient. An Approver Chain workflow never escalates.

## Best Practice

For a custom record with an amount:

- Subscribe to `OnPopulateApprovalEntryArgument`. Exit unless `RecRef.Number` is your table. Fill `Document No.`, `Amount`, `Amount (LCY)` and `Currency Code`. Fill `Salespers./Purch. Code` if the workflow may use the Salesperson/Purchaser approver type.
- If the workflow uses Approver Chain or First Qualified Approver, subscribe to `OnSufficientApproverElseCase`. Check `ApprovalEntryArgument."Table ID"` and compare `Amount (LCY)` with the limit your design chooses. That can be an existing `User Setup` limit or a new field on `User Setup`, and it can honor an unlimited flag. Treat a user who is their own approver as sufficient, as the standard checks do.
- To show an extra value on the approval entries, add it to `Approval Entry` and copy it from the argument in `OnBeforeApprovalEntryInsert`.

Use `OnAfterPopulateApprovalEntryArgument` only to adjust values the standard sets, because it runs for every table. This row completes [plan an approval workflow for a custom record](plan-an-approval-workflow-for-a-custom-record.md). The status responses are in [handle the status responses](custom-approval-records-must-handle-status-responses.md).

See sample: [`fill-the-approval-entry-argument-for-a-custom-record.good.al`](fill-the-approval-entry-argument-for-a-custom-record.good.al).

## Anti Pattern

Write the amount into `Approval Entry` from its `OnBeforeInsertEvent`, and rely on the standard approval limits. The limit check runs on the argument before any entry exists, so every approver is sufficient. The trigger subscriber also fires for every approval entry of every table. Filling the argument without checking `RecRef.Number` overwrites the values of other extensions' tables.

See sample: [`fill-the-approval-entry-argument-for-a-custom-record.bad.al`](fill-the-approval-entry-argument-for-a-custom-record.bad.al).

## References

- [Approvals Mgmt., PopulateApprovalEntryArgument, MakeApprovalEntry and IsSufficientApprover](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/OtherCapabilities/Approvals/ApprovalsMgmt.Codeunit.al).
- [Walkthrough: implementing new workflow events and responses](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-walkthrough-workflow-events-responses).
