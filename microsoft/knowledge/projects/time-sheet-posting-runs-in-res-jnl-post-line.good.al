// Demonstration only; independently authored, not copied from BaseApp.
// The value travels Job Journal Line -> Res. Journal Line -> Res. Ledger Entry,
// inside the same posting that marks the time sheet detail as posted.
// Assumes the Job Journal Line extension with field 50190 "Billing Category" Code[20].
tableextension 50190 "Res. Jnl. Line Billing Cat." extends "Res. Journal Line"
{
    fields
    {
        field(50190; "Billing Category"; Code[20])
        {
            Caption = 'Billing Category';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50191 "Res. Ledg. Entry Billing Cat." extends "Res. Ledger Entry"
{
    fields
    {
        field(50190; "Billing Category"; Code[20])
        {
            Caption = 'Billing Category';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50190 "Billing Category Res. Posting"
{
    [EventSubscriber(ObjectType::Table, Database::"Res. Journal Line", 'OnAfterCopyResJnlLineFromJobJnlLine', '', false, false)]
    local procedure CopyFromJobJournalLine(var ResJnlLine: Record "Res. Journal Line"; var JobJnlLine: Record "Job Journal Line")
    begin
        ResJnlLine."Billing Category" := JobJnlLine."Billing Category";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Res. Ledger Entry", 'OnAfterCopyFromResJnlLine', '', false, false)]
    local procedure CopyToResourceLedger(var ResLedgerEntry: Record "Res. Ledger Entry"; ResJournalLine: Record "Res. Journal Line")
    begin
        ResLedgerEntry."Billing Category" := ResJournalLine."Billing Category";
    end;
}
