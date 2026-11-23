---
bc-version: [all]
domain: feature-design
keywords: [approval-workflow, workflow-response-handling, approvals-mgmt, onopendocument, onreleasedocument, onsetstatustopendingapproval, unsupportedrecordtypeerr, custom-document, status]
technologies: [al]
countries: [w1]
application-area: [all]
---

# A custom record in an approval workflow must handle the status responses

## Description

The standard approval workflow responses change the status of the record being approved. `"Workflow Response Handling"` implements Open Document and Release Document, and `"Approvals Mgmt."` implements Set Status to Pending Approval. Each one switches on the table of the record: standard tables such as `Sales Header` and `Purchase Header` are handled in the `case` statement, and every other table falls to an integration event.

For a custom table, the response raises `OnOpenDocument`, `OnReleaseDocument` or `OnSetStatusToPendingApproval`. If no subscriber sets the `Handled` flag, the response stops with "Record type %1 is not supported by this workflow response." The workflow can be enabled and the request sent, and the error only appears when the first approval step runs.

## Best Practice

For each custom table that goes through an approval workflow, subscribe to all three events and handle only your own table:

- `OnSetStatusToPendingApproval` on `"Approvals Mgmt."`: set your status to Pending Approval, modify the record, and set `IsHandled`.
- `OnReleaseDocument` on `"Workflow Response Handling"`: set your status to Released, modify, and set `Handled`.
- `OnOpenDocument` on `"Workflow Response Handling"`: set your status back to Open, modify, and set `Handled`.

Check `RecRef.Number` first and exit for any other table, so the subscriber never claims a record it does not own. Keep the status change in a procedure on the table or a codeunit, so the page actions and the workflow use the same code.

See sample: [`custom-approval-records-must-handle-status-responses.good.al`](custom-approval-records-must-handle-status-responses.good.al).

## Anti Pattern

Register the workflow events, link the standard responses and enable the workflow, but leave the status responses unhandled. Or handle them without checking the table, which sets `Handled` for records of other extensions and silently skips their status change.

See sample: [`custom-approval-records-must-handle-status-responses.bad.al`](custom-approval-records-must-handle-status-responses.bad.al).

## References

- [Workflow Response Handling, OpenDocument and ReleaseDocument](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/Workflow/WorkflowResponseHandling.Codeunit.al).
- [Approvals Mgmt., SetStatusToPendingApproval](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/OtherCapabilities/Approvals/ApprovalsMgmt.Codeunit.al).
