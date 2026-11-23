// Demonstration only; independently authored, not copied from BaseApp.
// Patches the issued reminder after issuing; reminder fee and interest entries still miss the value,
// because the sales journal-line subscriber never fires for them.
codeunit 50230 "Collection Agent Issuing"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reminder-Issue", 'OnAfterIssueReminder', '', false, false)]
    local procedure PatchIssuedReminder(var ReminderHeader: Record "Reminder Header"; IssuedReminderNo: Code[20])
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        IssuedReminderHeader.Get(IssuedReminderNo);
        IssuedReminderHeader."Collection Agent Code" := ReminderHeader."Collection Agent Code";
        IssuedReminderHeader.Modify();
    end;
}
