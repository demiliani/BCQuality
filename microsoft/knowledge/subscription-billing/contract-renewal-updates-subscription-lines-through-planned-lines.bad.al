// Demonstration only; independently authored, not copied from BaseApp.
// Wrong: no field on Planned Subscription Line, and the subscription line is written
// as soon as the planned line exists, even when the app keeps it waiting.
// Assumes the Subscription Line and Sales Subscription Line extensions from the good sample.
codeunit 50133 "Support Level Renewal Bad"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Post Sub. Contract Renewal", OnAfterInsertPlannedSubscriptionLineFromSalesSubscriptionLine, '', false, false)]
    local procedure ApplyImmediately(SalesLine: Record "Sales Line"; var TempSubscriptionLine: Record "Subscription Line"; var PlannedSubscriptionLine: Record "Planned Subscription Line")
    var
        SubscriptionLine: Record "Subscription Line";
        SalesSubscriptionLine: Record "Sales Subscription Line";
    begin
        // TempSubscriptionLine has no support level: no subscriber copied it in
        // OnAfterCopyFromSalesSubscriptionLine. The value is read again from the sales line
        // and written now, before the old term is fully billed.
        SalesSubscriptionLine.SetRange("Subscription Line Entry No.", PlannedSubscriptionLine."Entry No.");
        if not SalesSubscriptionLine.FindFirst() then
            exit;
        SubscriptionLine.Get(PlannedSubscriptionLine."Entry No.");
        SubscriptionLine."Support Level" := SalesSubscriptionLine."Support Level";
        SubscriptionLine.Modify(false);
    end;
}
