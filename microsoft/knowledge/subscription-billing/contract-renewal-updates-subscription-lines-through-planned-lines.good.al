// Demonstration only; independently authored, not copied from BaseApp.
// "Support Level" is renewed: Subscription Line -> Sales Subscription Line (quote/order)
// -> temporary Subscription Line -> Planned Subscription Line (TransferFields) -> Subscription Line.
tableextension 50130 "Sub. Line Support Level" extends "Subscription Line"
{
    fields
    {
        field(50130; "Support Level"; Code[10])
        {
            Caption = 'Support Level';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50131 "Sales Sub. Line Support Level" extends "Sales Subscription Line"
{
    fields
    {
        field(50130; "Support Level"; Code[10])
        {
            Caption = 'Support Level';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50132 "Planned Sub. Line Support Lvl" extends "Planned Subscription Line"
{
    fields
    {
        // Same number and type as on Subscription Line: TransferFields copies it.
        field(50130; "Support Level"; Code[10])
        {
            Caption = 'Support Level';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50130 "Support Level Renewal"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Sub. Contract Renewal", OnAfterInsertSubscriptionLine, '', false, false)]
    local procedure FillRenewalQuote(var SalesLine: Record "Sales Line"; var SubContractRenewalLine: Record "Sub. Contract Renewal Line"; var SalesSubscriptionLine: Record "Sales Subscription Line")
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        if not SubscriptionLine.Get(SalesSubscriptionLine."Subscription Line Entry No.") then
            exit;
        // The sales subscription line is already inserted: assign, then Modify.
        SalesSubscriptionLine."Support Level" := SubscriptionLine."Support Level";
        SalesSubscriptionLine.Modify(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Subscription Line", OnAfterCopyFromSalesSubscriptionLine, '', false, false)]
    local procedure SalesToTempSubscriptionLine(var SubscriptionLine: Record "Subscription Line"; SalesSubscriptionLine: Record "Sales Subscription Line")
    begin
        SubscriptionLine."Support Level" := SalesSubscriptionLine."Support Level";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Post Sub. Contract Renewal", OnBeforeUpdateSubscriptionLineFromPlannedSubscriptionLine, '', false, false)]
    local procedure PlannedToSubscriptionLine(var SubscriptionLine: Record "Subscription Line"; var PlannedSubscriptionLine: Record "Planned Subscription Line")
    begin
        // The app archives the old values and calls Modify(false) right after this event.
        SubscriptionLine."Support Level" := PlannedSubscriptionLine."Support Level";
    end;
}
