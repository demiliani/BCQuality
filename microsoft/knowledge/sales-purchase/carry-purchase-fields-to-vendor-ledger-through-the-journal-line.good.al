// Demonstration only; independently authored, not copied from BaseApp.
// The value travels Purchase Header -> Gen. Journal Line -> Vendor Ledger Entry during posting.
// Assumes the Purchase Header table extension with field 50140 "Supplier Contract Ref." Code[20].
tableextension 50150 "Gen. Jnl. Line Supplier Ref." extends "Gen. Journal Line"
{
    fields
    {
        field(50140; "Supplier Contract Ref."; Code[20])
        {
            Caption = 'Supplier Contract Ref.';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50151 "Vend. Ledg. Supplier Ref." extends "Vendor Ledger Entry"
{
    fields
    {
        field(50140; "Supplier Contract Ref."; Code[20])
        {
            Caption = 'Supplier Contract Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50150 "Supplier Ref. Posting"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeader', '', false, false)]
    local procedure CopyToJournalLine(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Supplier Contract Ref." := PurchaseHeader."Supplier Contract Ref.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterCopyVendLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure CopyToVendorEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VendorLedgerEntry."Supplier Contract Ref." := GenJournalLine."Supplier Contract Ref.";
    end;
}
