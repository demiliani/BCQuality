// Demonstration only; independently authored, not copied from BaseApp.
// Covers only the batch job, and writes the header from inside the event.
codeunit 50140 "Dunning Contact Defaults"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reminder-Make", 'OnBeforeReminderHeaderInsert', '', false, false)]
    local procedure ReminderFromBatch(var ReminderHeader: Record "Reminder Header"; Customer: Record Customer)
    begin
        // Manually created reminders never get the value.
        ReminderHeader."Dunning Contact Code" := Customer."Dunning Contact Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Finance Charge Memo Header", 'OnValidateCustomerNoOnAfterAssignCustomerValues', '', false, false)]
    local procedure FinChargeMemoFromCustomer(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; Customer: Record Customer)
    begin
        FinanceChargeMemoHeader."Dunning Contact Code" := Customer."Dunning Contact Code";
        // Fails in the checking mode of FinChrgMemo-Make, where the header is never inserted.
        FinanceChargeMemoHeader.Modify();
    end;
}
