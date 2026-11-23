// Demonstration only; independently authored, not copied from BaseApp.
// Covers only the FA journal source; FA G/L journals and purchase invoices leave the field blank.
codeunit 50300 "Asset Project FA Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Make FA Ledger Entry", 'OnAfterCopyFromFAJnlLine', '', false, false)]
    local procedure CopyFromFAJournal(var FALedgerEntry: Record "FA Ledger Entry"; FAJournalLine: Record "FA Journal Line")
    begin
        FALedgerEntry."Asset Project Code" := FAJournalLine."Asset Project Code";
    end;
}
