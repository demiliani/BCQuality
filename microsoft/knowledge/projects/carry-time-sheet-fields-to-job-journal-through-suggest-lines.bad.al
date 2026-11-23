// Demonstration only; independently authored, not copied from BaseApp.
// Wrong: the value is patched onto the ledger entry after it is inserted.
// Assumes "Activity Code" (field 50180) on Time Sheet Line and Job Ledger Entry only.
codeunit 50183 "Activity Code Ledger Patch"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", 'OnAfterJobLedgEntryInsert', '', false, false)]
    local procedure PatchLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // Extra read and write for every posted entry; the journal line never shows the value.
        if not TimeSheetLine.Get(JobJournalLine."Time Sheet No.", JobJournalLine."Time Sheet Line No.") then
            exit;
        JobLedgerEntry."Activity Code" := TimeSheetLine."Activity Code";
        JobLedgerEntry.Modify();
    end;
}
