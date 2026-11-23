// Demonstration only; independently authored, not copied from BaseApp.
// Patches the project ledger entry after it was inserted.
codeunit 50170 "Site Visit Job Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", 'OnAfterJobLedgEntryInsert', '', false, false)]
    local procedure PatchJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."Site Visit Code" := JobJournalLine."Site Visit Code";
        JobLedgerEntry.Modify();
    end;
}
