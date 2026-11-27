using Microsoft.Inventory.Ledger;

codeunit 50199 "Current Sales Cost"
{
    procedure GetActualCost(ItemLedgerEntryNo: Integer): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Get(ItemLedgerEntryNo);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        exit(ItemLedgerEntry."Cost Amount (Actual)");
    end;
}
