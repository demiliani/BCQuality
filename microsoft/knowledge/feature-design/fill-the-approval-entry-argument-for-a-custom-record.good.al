// Demonstration only; independently authored, not copied from BaseApp.
// Fills the approval entry argument for one custom table and checks its own limit.
// Assumes table 50140 "Capex Request" with "No.", Amount, "Amount (LCY)", "Currency Code",
// "Purchaser Code" and "Asset Class" fields.
tableextension 50140 "Capex User Setup" extends "User Setup"
{
    fields
    {
        field(50140; "Capex Approval Limit"; Decimal)
        {
            Caption = 'Capex Approval Limit';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
        }
        field(50141; "Unlimited Capex Approval"; Boolean)
        {
            Caption = 'Unlimited Capex Approval';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50141 "Capex Approval Entry" extends "Approval Entry"
{
    fields
    {
        field(50140; "Capex Asset Class"; Code[10])
        {
            Caption = 'Capex Asset Class';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50140 "Capex Approval Arguments"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', false, false)]
    local procedure FillArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        CapexRequest: Record "Capex Request";
    begin
        if RecRef.Number <> Database::"Capex Request" then
            exit;
        RecRef.SetTable(CapexRequest);
        ApprovalEntryArgument."Document No." := CapexRequest."No.";
        ApprovalEntryArgument.Amount := CapexRequest.Amount;
        ApprovalEntryArgument."Amount (LCY)" := CapexRequest."Amount (LCY)";
        ApprovalEntryArgument."Currency Code" := CapexRequest."Currency Code";
        ApprovalEntryArgument."Salespers./Purch. Code" := CapexRequest."Purchaser Code";
        ApprovalEntryArgument."Capex Asset Class" := CapexRequest."Asset Class";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSufficientApproverElseCase', '', false, false)]
    local procedure CheckCapexLimit(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"; var IsSufficient: Boolean)
    begin
        if ApprovalEntryArgument."Table ID" <> Database::"Capex Request" then
            exit;
        if UserSetup."User ID" = UserSetup."Approver ID" then begin
            IsSufficient := true;
            exit;
        end;
        IsSufficient :=
            UserSetup."Unlimited Capex Approval" or
            ((ApprovalEntryArgument."Amount (LCY)" <= UserSetup."Capex Approval Limit") and (UserSetup."Capex Approval Limit" <> 0));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnBeforeApprovalEntryInsert', '', false, false)]
    local procedure CopyExtraValue(var ApprovalEntry: Record "Approval Entry"; ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepArgument: Record "Workflow Step Argument"; ApproverId: Code[50]; var IsHandled: Boolean)
    begin
        if ApprovalEntryArgument."Table ID" <> Database::"Capex Request" then
            exit;
        ApprovalEntry."Capex Asset Class" := ApprovalEntryArgument."Capex Asset Class";
    end;
}
