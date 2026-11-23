// Demonstration only; independently authored, not copied from BaseApp.
// Ships a disabled approval template for a custom table, in new and existing companies.
// Assumes table 50140 "Capex Request" and codeunit 50151 "Capex Workflow Events", which registers
// its events in OnAddWorkflowEventsToLibrary and exposes their function-name codes.
codeunit 50150 "Capex Workflow Template"
{
    var
        WorkflowSetup: Codeunit "Workflow Setup";
        CapexTemplateCodeTxt: Label 'CAPEXAPW', Locked = true;
        CapexTemplateDescTxt: Label 'Capex Request Approval Workflow';
        CapexCategoryTxt: Label 'CAPEX', Locked = true;
        CapexCategoryDescTxt: Label 'Capital Expenditure';
        CapexConditionTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Capex Request">%1</DataItem></DataItems></ReportParameters>', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", 'OnAddWorkflowCategoriesToLibrary', '', false, false)]
    local procedure AddCategory()
    begin
        WorkflowSetup.InsertWorkflowCategory(CapexCategoryTxt, CapexCategoryDescTxt);
    end;

    // Raised every time the Workflow Templates page initializes, not only when templates are built.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", 'OnAfterInitWorkflowTemplates', '', false, false)]
    local procedure InsertTemplate()
    var
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        CapexWorkflowEvents: Codeunit "Capex Workflow Events";
        BlankDateFormula: DateFormula;
    begin
        if Workflow.Get(WorkflowSetup.GetWorkflowTemplateCode(CapexTemplateCodeTxt)) then
            exit;

        WorkflowSetup.InsertWorkflowTemplate(Workflow, CapexTemplateCodeTxt, CapexTemplateDescTxt, CapexCategoryTxt);
        WorkflowSetup.InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
            0, '', BlankDateFormula, true);
        WorkflowSetup.InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildCapexConditions(), CapexWorkflowEvents.RunWorkflowOnSendCapexForApprovalCode(),
            BuildCapexConditions(), CapexWorkflowEvents.RunWorkflowOnCancelCapexApprovalRequestCode(),
            WorkflowStepArgument, true);
        WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure BuildCapexConditions(): Text
    var
        CapexRequest: Record "Capex Request";
    begin
        exit(StrSubstNo(CapexConditionTxt, WorkflowSetup.Encode(CapexRequest.GetView(false))));
    end;
}
