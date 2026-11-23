// Demonstration only; independently authored, not copied from BaseApp.
// The value is set on the sales line inside Job Create-Invoice, before the line is inserted.
tableextension 50120 "Job Planning Line Milestone" extends "Job Planning Line"
{
    fields
    {
        field(50120; "Billing Milestone"; Code[20])
        {
            Caption = 'Billing Milestone';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50121 "Sales Line Milestone" extends "Sales Line"
{
    fields
    {
        field(50120; "Billing Milestone"; Code[20])
        {
            Caption = 'Billing Milestone';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50120 "Project Invoice Milestone"
{
    // Raised by CreateSalesLine, which serves both CreateSalesInvoiceLines and CreateSalesInvoiceJobTask.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnBeforeInsertSalesLine', '', false, false)]
    local procedure CopyMilestoneToSalesLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line"; JobInvCurrency: Boolean)
    begin
        SalesLine."Billing Milestone" := JobPlanningLine."Billing Milestone";
    end;
}
