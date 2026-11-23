// Demonstration only; independently authored, not copied from BaseApp.
// The region dimension is decided before the sales line is inserted, so the
// contract-change checks on the created invoice are never involved.
tableextension 50114 "Region Contract Line" extends "Cust. Sub. Contract Line"
{
    fields
    {
        field(50101; "Region Code"; Code[20])
        {
            Caption = 'Region Code';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50112 "Region Dimension Billing"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Billing Documents", OnBeforeInsertSalesLineFromContractLine, '', false, false)]
    local procedure SetRegionBeforeInsert(var SalesLine: Record "Sales Line"; var TempBillingLine: Record "Billing Line" temporary)
    var
        ContractLine: Record "Cust. Sub. Contract Line";
    begin
        ContractLine.SetLoadFields("Region Code");
        if not ContractLine.Get(TempBillingLine."Subscription Contract No.", TempBillingLine."Subscription Contract Line No.") then
            exit;
        if ContractLine."Region Code" = '' then
            exit;
        // Not inserted yet: validate from code, no Modify, no dialog (may run in a job queue).
        SalesLine.Validate("Shortcut Dimension 2 Code", ContractLine."Region Code");
    end;
}
