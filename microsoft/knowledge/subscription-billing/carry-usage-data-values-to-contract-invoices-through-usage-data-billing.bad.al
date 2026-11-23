// Demonstration only; independently authored, not copied from BaseApp.
// Wrong: relies on matching field numbers, writes after insert without Modify,
// and looks for the usage rows by a document link that does not exist yet.
// Assumes the Usage Data Billing and Sales Line extensions from the good sample.
tableextension 50122 "Generic Import Region Bad" extends "Usage Data Generic Import"
{
    fields
    {
        // Same number as the Usage Data Billing field, but nothing copies by field number here.
        field(50120; "Usage Region"; Code[10])
        {
            Caption = 'Usage Region';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50122 "Usage Region Flow Bad"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Usage Data Billing", OnAfterCreateUsageDataBillingFromTempSubscriptionLine, '', false, false)]
    local procedure AfterInsert(var TempSubscriptionLine: Record "Subscription Line"; var UsageDataBilling: Record "Usage Data Billing")
    begin
        // The row is already inserted; without Modify the value is never stored.
        UsageDataBilling."Usage Region" := 'EU';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Billing Documents", OnBeforeInsertSalesLineFromContractLine, '', false, false)]
    local procedure UsageBillingToSalesLine(var SalesLine: Record "Sales Line"; var TempBillingLine: Record "Billing Line" temporary)
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // SaveDocumentValues runs after the sales line insert, so no row matches yet.
        UsageDataBilling.SetRange("Document No.", SalesLine."Document No.");
        UsageDataBilling.SetRange("Document Line No.", SalesLine."Line No.");
        if UsageDataBilling.FindFirst() then
            SalesLine."Usage Region" := UsageDataBilling."Usage Region";
    end;
}
