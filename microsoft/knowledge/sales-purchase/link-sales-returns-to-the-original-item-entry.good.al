using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Document;

codeunit 50198 "Sales Return Cost"
{
    procedure SetReturnCost(var ReturnLine: Record "Sales Line"; OriginalSaleEntry: Record "Item Ledger Entry")
    begin
        OriginalSaleEntry.TestField("Entry No.");
        ReturnLine.Validate("Appl.-from Item Entry", OriginalSaleEntry."Entry No.");
    end;
}
