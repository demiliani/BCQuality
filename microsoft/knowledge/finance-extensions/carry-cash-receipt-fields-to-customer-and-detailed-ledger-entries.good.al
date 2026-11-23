// Demonstration only; independently authored, not copied from BaseApp.
// The customer entry takes the value from the journal line; each detailed row takes it from its own customer entry.
// Assumes Gen. Journal Line, Cust. Ledger Entry and Detailed Cust. Ledg. Entry extensions with field 50150
// "Collection Channel" Code[20].
codeunit 50150 "Collection Channel Posting"
{
    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterCopyCustLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure CopyToCustomerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CustLedgerEntry."Collection Channel" := GenJournalLine."Collection Channel";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertDtldCustLedgEntry', '', false, false)]
    local procedure CopyToDetailedEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetLoadFields("Collection Channel");
        if CustLedgerEntry.Get(DtldCVLedgEntryBuffer."CV Ledger Entry No.") then
            DtldCustLedgEntry."Collection Channel" := CustLedgerEntry."Collection Channel";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromCustLedgEntry', '', false, false)]
    local procedure CopyToApplicationJournalLine(CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        // Gives the application posting, and its G/L entries, the applying entry's value.
        GenJournalLine."Collection Channel" := CustLedgerEntry."Collection Channel";
    end;
}
