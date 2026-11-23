// Demonstration only; independently authored, not copied from BaseApp.
// Only the journal-to-ledger hop is covered. Project journal lines built from purchase lines
// or planning lines never receive the value, so their ledger entries stay blank.
codeunit 50175 "Site Visit Job Sources"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromJnlLineToLedgEntry', '', false, false)]
    local procedure CopyToJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."Site Visit Code" := JobJournalLine."Site Visit Code";
    end;
}
