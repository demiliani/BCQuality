// Demonstration only; independently authored, not copied from BaseApp.
// Covers both sources of FA ledger entries: FA journal lines and general journal lines.
// Assumes table extensions with field 50300 "Asset Project Code" Code[20] on
// "FA Journal Line", "Gen. Journal Line" and "FA Ledger Entry".
codeunit 50300 "Asset Project FA Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Make FA Ledger Entry", 'OnAfterCopyFromFAJnlLine', '', false, false)]
    local procedure CopyFromFAJournal(var FALedgerEntry: Record "FA Ledger Entry"; FAJournalLine: Record "FA Journal Line")
    begin
        FALedgerEntry."Asset Project Code" := FAJournalLine."Asset Project Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Make FA Ledger Entry", 'OnAfterCopyFromGenJnlLine', '', false, false)]
    local procedure CopyFromGenJournal(var FALedgerEntry: Record "FA Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        FALedgerEntry."Asset Project Code" := GenJournalLine."Asset Project Code";
    end;
}
