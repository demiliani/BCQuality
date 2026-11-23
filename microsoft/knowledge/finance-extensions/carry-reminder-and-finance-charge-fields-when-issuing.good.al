// Demonstration only; independently authored, not copied from BaseApp.
// Issued documents get the field by TransferFields; journal lines get it in each issuing codeunit's own event.
// Assumes Reminder Header, Finance Charge Memo Header and Gen. Journal Line extensions with field 50230
// "Collection Agent Code" Code[20].
tableextension 50230 "Issued Rem. Hdr. Collection" extends "Issued Reminder Header"
{
    fields
    {
        field(50230; "Collection Agent Code"; Code[20])
        {
            Caption = 'Collection Agent Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50230 "Collection Agent Issuing"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reminder-Issue", 'OnAfterInitGenJnlLine', '', false, false)]
    local procedure ReminderJournalLine(var GenJournalLine: Record "Gen. Journal Line"; ReminderHeader: Record "Reminder Header")
    begin
        GenJournalLine."Collection Agent Code" := ReminderHeader."Collection Agent Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FinChrgMemo-Issue", 'OnAfterInitGenJnlLine', '', false, false)]
    local procedure FinChargeJournalLine(var GenJnlLine: Record "Gen. Journal Line"; FinChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
        GenJnlLine."Collection Agent Code" := FinChargeMemoHeader."Collection Agent Code";
    end;
}
