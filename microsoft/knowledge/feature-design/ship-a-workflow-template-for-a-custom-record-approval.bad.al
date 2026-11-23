// Demonstration only; independently authored, not copied from BaseApp.
// Wrong: the template is built only when the whole template set is rebuilt, and an install
// codeunit writes an enabled workflow directly into the workflow tables.
// Assumes codeunit 50151 "Capex Workflow Events" as in the good sample.
codeunit 50152 "Capex Workflow Template Bad"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        CapexWorkflowEvents: Codeunit "Capex Workflow Events";
    begin
        // Not a template, enabled at once, no event conditions, duplicated steps on reinstall.
        Workflow.Code := 'CAPEX-01';
        Workflow.Description := 'Capex approval';
        Workflow.Enabled := true;
        if Workflow.Insert() then;
        WorkflowStep."Workflow Code" := Workflow.Code;
        WorkflowStep.Type := WorkflowStep.Type::"Event";
        WorkflowStep."Function Name" := CapexWorkflowEvents.RunWorkflowOnSendCapexForApprovalCode();
        WorkflowStep."Entry Point" := true;
        WorkflowStep.Insert(true);
    end;

    // Raised only when no MS- template exists: a company that already has templates
    // never receives this one.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", 'OnInsertWorkflowTemplates', '', false, false)]
    local procedure InsertTemplateOnlyOnRebuild()
    begin
    end;
}
