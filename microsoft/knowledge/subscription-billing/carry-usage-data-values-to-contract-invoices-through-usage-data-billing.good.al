// Demonstration only; independently authored, not copied from BaseApp.
// The supplier file has a "Region" column, mapped to "Usage Data Generic Import".Text1
// in the supplier's Data Exchange Definition. The value travels:
// Usage Data Generic Import -> Usage Data Billing -> Sales Line (contract invoice).
tableextension 50120 "Usage Billing Region" extends "Usage Data Billing"
{
    fields
    {
        field(50120; "Usage Region"; Code[10])
        {
            Caption = 'Usage Region';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50121 "Sales Line Usage Region" extends "Sales Line"
{
    fields
    {
        field(50120; "Usage Region"; Code[10])
        {
            Caption = 'Usage Region';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50120 "Usage Region Flow"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Usage Data Billing", OnBeforInsertUsageDataBilling, '', false, false)]
    local procedure ImportLineToUsageBilling(var UsageDataBilling: Record "Usage Data Billing"; UsageDataGenericImportGlobal: Record "Usage Data Generic Import")
    begin
        // Runs before Insert(true): assign only.
        UsageDataBilling."Usage Region" := CopyStr(UsageDataGenericImportGlobal.Text1, 1, MaxStrLen(UsageDataBilling."Usage Region"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Billing Documents", OnBeforeInsertSalesLineFromContractLine, '', false, false)]
    local procedure UsageBillingToSalesLine(var SalesLine: Record "Sales Line"; var TempBillingLine: Record "Billing Line" temporary)
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // Same filters the app uses: the rows are not linked to the document yet.
        UsageDataBilling.SetRange(Partner, Enum::"Service Partner"::Customer);
        UsageDataBilling.SetRange("Subscription Contract No.", TempBillingLine."Subscription Contract No.");
        UsageDataBilling.SetRange("Subscription Contract Line No.", TempBillingLine."Subscription Contract Line No.");
        UsageDataBilling.SetRange("Document Type", Enum::"Usage Based Billing Doc. Type"::None);
        UsageDataBilling.SetRange("Document No.", '');
        // Design rule: the latest charge period wins.
        UsageDataBilling.SetCurrentKey("Charge End Date");
        if UsageDataBilling.FindLast() then
            SalesLine."Usage Region" := UsageDataBilling."Usage Region";
    end;
}
