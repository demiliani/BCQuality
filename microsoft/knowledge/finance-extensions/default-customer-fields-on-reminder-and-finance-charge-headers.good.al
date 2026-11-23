// Demonstration only; independently authored, not copied from BaseApp.
// One subscriber per header covers manual entry, Create Reminders, Create Finance Charge Memos and reminder automation.
// Assumes a Customer table extension with field 50140 "Dunning Contact Code" Code[20].
tableextension 50141 "Reminder Hdr. Dunning Contact" extends "Reminder Header"
{
    fields
    {
        field(50140; "Dunning Contact Code"; Code[20])
        {
            Caption = 'Dunning Contact Code';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50142 "Fin. Chrg. Hdr. Dunning Contact" extends "Finance Charge Memo Header"
{
    fields
    {
        field(50140; "Dunning Contact Code"; Code[20])
        {
            Caption = 'Dunning Contact Code';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50140 "Dunning Contact Defaults"
{
    [EventSubscriber(ObjectType::Table, Database::"Reminder Header", 'OnValidateCustomerNoOnAfterAssignCustomerValues', '', false, false)]
    local procedure ReminderFromCustomer(var ReminderHeader: Record "Reminder Header"; Customer: Record Customer)
    begin
        ReminderHeader."Dunning Contact Code" := Customer."Dunning Contact Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Finance Charge Memo Header", 'OnValidateCustomerNoOnAfterAssignCustomerValues', '', false, false)]
    local procedure FinChargeMemoFromCustomer(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; Customer: Record Customer)
    begin
        FinanceChargeMemoHeader."Dunning Contact Code" := Customer."Dunning Contact Code";
    end;
}
