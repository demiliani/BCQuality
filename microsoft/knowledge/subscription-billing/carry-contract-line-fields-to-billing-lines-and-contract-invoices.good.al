// Demonstration only; independently authored, not copied from BaseApp.
// Requires a dependency on "Subscription Billing" (Microsoft, 3099ffc7-4cf7-4df6-9b96-7e4bc2bb587c).
// Field 50100 "Cost Center Ref." also exists with the same number and type on
// "Billing Line Archive", "Sales Line" and "Sales Invoice Line" (not repeated here).
tableextension 50110 "CC Ref Contract Line" extends "Cust. Sub. Contract Line"
{
    fields
    {
        field(50100; "Cost Center Ref."; Code[20])
        {
            Caption = 'Cost Center Ref.';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50111 "CC Ref Billing Line" extends "Billing Line"
{
    fields
    {
        field(50100; "Cost Center Ref."; Code[20])
        {
            Caption = 'Cost Center Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50110 "CC Ref Billing"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Billing Proposal", OnAfterUpdateBillingLineFromSubscriptionLine, '', false, false)]
    local procedure ContractLineToBillingLine(var BillingLine: Record "Billing Line"; SubscriptionLine: Record "Subscription Line")
    var
        ContractLine: Record "Cust. Sub. Contract Line";
    begin
        if SubscriptionLine.Partner <> SubscriptionLine.Partner::Customer then
            exit;
        ContractLine.SetLoadFields("Cost Center Ref.");
        if ContractLine.Get(SubscriptionLine."Subscription Contract No.", SubscriptionLine."Subscription Contract Line No.") then
            BillingLine."Cost Center Ref." := ContractLine."Cost Center Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Billing Documents", OnBeforeInsertTempBillingLine, '', false, false)]
    local procedure BillingLineToTempLine(var TempBillingLine: Record "Billing Line" temporary; var BillingLine: Record "Billing Line")
    begin
        TempBillingLine."Cost Center Ref." := BillingLine."Cost Center Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Billing Documents", OnBeforeInsertSalesLineFromContractLine, '', false, false)]
    local procedure TempLineToSalesLine(var SalesLine: Record "Sales Line"; var TempBillingLine: Record "Billing Line" temporary)
    begin
        SalesLine."Cost Center Ref." := TempBillingLine."Cost Center Ref."; // inserted right after this event
    end;
}
