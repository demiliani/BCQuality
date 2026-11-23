---
bc-version: [all]
domain: feature-design
keywords: [approval-workflow, workflow-setup, workflow-template, onafterinitworkflowtemplates, oninsertworkflowtemplates, onaddworkflowcategoriestolibrary, insertdocapprovalworkflowsteps, insertworkflowtemplate, event-conditions, custom-document]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Ship a workflow template for a custom record approval through Workflow Setup

## Description

`"Workflow Setup"` (codeunit 1502) builds the workflow templates users pick on the Workflow Templates page. `InitWorkflow` runs each time that page opens. It refreshes the event and response libraries and the categories. It builds the templates only when no template with the template prefix (`MS-` by default) exists. At the end of that build it raises `OnInsertWorkflowTemplates`. After that check, on every run, it raises `OnAfterInitWorkflowTemplates`. Categories come from `OnAddWorkflowCategoriesToLibrary` and `InsertWorkflowCategory`. No event named `OnAddWorkflowTemplatesToLibrary` exists.

So a subscriber to `OnInsertWorkflowTemplates` runs only when the template set is built from empty. That happens in a new company, or when a user chooses Reset Microsoft Templates on the Workflow Templates page. An extension installed in a company that already has templates never gets its template that way. Microsoft's own Sustainability app inserts its approval template from `OnAfterInitWorkflowTemplates`, after checking that the template code does not exist yet.

The public helpers on `"Workflow Setup"` build the template:

- `InsertWorkflowTemplate(var Workflow, WorkflowCode: Code[17], Description, CategoryCode)` adds the prefix to the code. If the workflow exists, the insert is skipped silently, and the steps that follow would be added twice.
- `InsertDocApprovalWorkflowSteps(Workflow, SendConditions, SendEventCode, CancelConditions, CancelEventCode, WorkflowStepArgument, ShowConfirmationMessage)` wires the document chain. On send it restricts usage, sets Pending Approval, and creates and sends the requests. The last approval allows usage and releases. A reject rejects all and opens the record. A cancel cancels all, allows usage, opens and shows a message. `InsertRecApprovalWorkflowSteps` is the variant for records without a status.
- `InsertEventArgument` raises an error when the condition text is empty. The condition is request page XML whose `DataItem name` is the table name. At run time `"Workflow Management"` turns it into filters on the record's table.
- `InitWorkflowStepArgument` sets approver type, limit type, due date and confirmation. `MarkWorkflowAsTemplate` sets `Template`.

## Best Practice

Subscribe to `OnAfterInitWorkflowTemplates`. Exit when `Workflow.Get(WorkflowSetup.GetWorkflowTemplateCode(YourCode))` finds the template. Otherwise call `InsertWorkflowTemplate`, `InitWorkflowStepArgument`, `InsertDocApprovalWorkflowSteps` and `MarkWorkflowAsTemplate`. Add your category in `OnAddWorkflowCategoriesToLibrary`. Build the conditions as the standard does: `StrSubstNo` of the XML with `Encode(YourRecord.GetView(false))`. Use your own event codes, the ones registered through `OnAddWorkflowEventsToLibrary`.

The document chain calls the status responses and Release; handle them first, see [handle the status responses](custom-approval-records-must-handle-status-responses.md). If the template uses the Approver Chain limit type, fill the amount and handle the limit, see [fill the approval entry argument](fill-the-approval-entry-argument-for-a-custom-record.md). Ship the template disabled. Users create and enable a workflow from it after they set up approvers.

See sample: [`ship-a-workflow-template-for-a-custom-record-approval.good.al`](ship-a-workflow-template-for-a-custom-record-approval.good.al).

## Anti Pattern

Insert the template only from `OnInsertWorkflowTemplates`. It never appears in the companies where the extension is installed later. Inserting `Workflow` and `Workflow Step` rows directly from install code is no better. That gives an enabled workflow without conditions, which a reinstall duplicates and which runs before any approver is set up. Calling the helpers without the existence check adds a second set of steps each time the page opens.

See sample: [`ship-a-workflow-template-for-a-custom-record-approval.bad.al`](ship-a-workflow-template-for-a-custom-record-approval.bad.al).

## References

- [Workflow Setup, InitWorkflow, template events and helpers](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/Workflow/WorkflowSetup.Codeunit.al).
- [Workflow Templates page, InitWorkflow on open and Reset Microsoft Templates](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/Workflow/WorkflowTemplates.Page.al).
- [Sust. Workflow Event Handling, a first-party template from OnAfterInitWorkflowTemplates](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Sustainability/app/src/Workflow/SustWorkflowEventHandling.Codeunit.al).
- [Workflow Management, event condition evaluation](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/Workflow/WorkflowManagement.Codeunit.al).
- [Walkthrough: implementing new workflow events and responses](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-walkthrough-workflow-events-responses).
