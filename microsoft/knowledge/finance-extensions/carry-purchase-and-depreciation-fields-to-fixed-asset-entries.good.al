// Demonstration only; independently authored, not copied from BaseApp.
// Purchase header field to FA ledger entries, and the same value on depreciation lines
// whatever the depreciation book's G/L integration.
// Assumes field 50300 "Asset Project Code" Code[20] on "Purchase Header", "Gen. Journal Line",
// "FA Journal Line" and "FA Ledger Entry", and a setup function GetDefaultAssetProject().
codeunit 50310 "Asset Project FA Sources"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeader', '', false, false)]
    local procedure CopyFromPurchaseHeader(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Asset Project Code" := PurchaseHeader."Asset Project Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Make FA Ledger Entry", 'OnAfterCopyFromGenJnlLine', '', false, false)]
    local procedure CopyToFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        FALedgerEntry."Asset Project Code" := GenJournalLine."Asset Project Code";
    end;

    [EventSubscriber(ObjectType::Report, Report::"Calculate Depreciation", 'OnBeforeFAJnlLineInsert', '', false, false)]
    local procedure SetOnFAJournalLine(var TempFAJournalLine: Record "FA Journal Line" temporary; var FAJournalLine: Record "FA Journal Line")
    begin
        FAJournalLine."Asset Project Code" := GetDefaultAssetProject();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Calculate Depreciation", 'OnBeforeGenJnlLineInsert', '', false, false)]
    local procedure SetOnGenJournalLine(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Asset Project Code" := GetDefaultAssetProject();
    end;

    local procedure GetDefaultAssetProject(): Code[20]
    begin
        // Read the value from the feature's setup table.
    end;
}
