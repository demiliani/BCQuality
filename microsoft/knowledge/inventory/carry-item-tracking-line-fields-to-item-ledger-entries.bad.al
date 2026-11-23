// Demonstration only; independently authored, not copied from BaseApp.
// Different field number on Reservation Entry, and the ledger entries are patched after posting.
tableextension 50171 "Tracking Spec. Supplier Lot" extends "Tracking Specification"
{
    fields
    {
        field(50171; "Supplier Lot Ref."; Code[30])
        {
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50172 "Reserv. Entry Supplier Lot" extends "Reservation Entry"
{
    fields
    {
        // Different number: TransferFields between the two tables never carries the value.
        field(50180; "Supplier Lot Ref."; Code[30])
        {
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50171 "Supplier Lot Ref. Tracking"
{
    procedure PatchLedgerEntries(DocumentNo: Code[20]; LotNo: Code[50]; SupplierLotRef: Code[30])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.ModifyAll("Supplier Lot Ref.", SupplierLotRef);
    end;
}
