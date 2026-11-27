using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Document;

codeunit 50198 "Sales Return Cost"
{
    procedure SetReturnCost(var ReturnLine: Record "Sales Line"; OriginalSaleEntry: Record "Item Ledger Entry")
    begin
        OriginalSaleEntry.TestField("Entry No.");
        OriginalSaleEntry.CalcFields("Cost Amount (Actual)");
        ReturnLine.Validate("Unit Cost (LCY)", OriginalSaleEntry."Cost Amount (Actual)" / OriginalSaleEntry.Quantity);
    end;
}
