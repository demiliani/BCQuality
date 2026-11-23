// Demonstration only; independently authored, not copied from BaseApp.
// Anti-pattern: patches the lines after creation and guesses the planning line by job and task.
codeunit 50122 "Project Invoice Milestone Bad"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnAfterCreateSalesInvoiceLines', '', false, false)]
    local procedure PatchMilestones(var SalesHeader: Record "Sales Header"; NewInvoice: Boolean)
    var
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                // A task has many planning lines: this picks any of them, not the one that was invoiced.
                JobPlanningLine.SetRange("Job No.", SalesLine."Job No.");
                JobPlanningLine.SetRange("Job Task No.", SalesLine."Job Task No.");
                if JobPlanningLine.FindFirst() then begin
                    SalesLine."Billing Milestone" := JobPlanningLine."Billing Milestone";
                    SalesLine.Modify(); // One extra write per line.
                end;
            until SalesLine.Next() = 0;
    end;
}
