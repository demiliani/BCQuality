using Microsoft.Inventory.Ledger;

codeunit 50199 "Current Sales Cost"
{
    procedure GetActualCost(ItemLedgerEntryNo: Integer): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgerEntry.Get(ItemLedgerEntryNo);
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange(Adjustment, false);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        exit(ValueEntry."Cost Amount (Actual)");
    end;
}
