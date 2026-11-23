// Demonstration only; independently authored, not copied from BaseApp.
// Patches suggested payment lines afterwards by guessing their source vendor ledger entry.
codeunit 50200 "Payment Priority Suggest"
{
    procedure FillPriorityAfterSuggest(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        if GenJournalLine.FindSet(true) then
            repeat
                // A summarized line pays several entries; this picks whichever one comes first.
                VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
                VendorLedgerEntry.SetRange(Open, true);
                if VendorLedgerEntry.FindFirst() then begin
                    GenJournalLine."Payment Priority Code" := VendorLedgerEntry."Payment Priority Code";
                    GenJournalLine.Modify();
                end;
            until GenJournalLine.Next() = 0;
    end;
}
