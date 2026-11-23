// Demonstration only; independently authored, not copied from BaseApp.
// The value travels Job Journal Line -> Job Ledger Entry while the entry is built.
tableextension 50170 "Job Jnl. Line Site Visit" extends "Job Journal Line"
{
    fields
    {
        field(50170; "Site Visit Code"; Code[20])
        {
            Caption = 'Site Visit Code';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50171 "Job Ledg. Entry Site Visit" extends "Job Ledger Entry"
{
    fields
    {
        field(50170; "Site Visit Code"; Code[20])
        {
            Caption = 'Site Visit Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50170 "Site Visit Job Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromJnlLineToLedgEntry', '', false, false)]
    local procedure CopyToJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."Site Visit Code" := JobJournalLine."Site Visit Code";
    end;
}
