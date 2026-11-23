// Demonstration only; independently authored, not copied from BaseApp.
// Carries a custom line field on the Copy Document recalculation path.
// Assumes "Packing Note" (field 50120, Text[50]) on Sales Line, Purchase Line and their posted and archive line tables.
codeunit 50120 "Packing Note Copy Document"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterRecalculateSalesLine', '', false, false)]
    local procedure CopySalesPackingNote(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line")
    begin
        // Runs before the target line is inserted: assign only.
        ToSalesLine."Packing Note" := FromSalesLine."Packing Note";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterRecalculatePurchLine', '', false, false)]
    local procedure CopyPurchPackingNote(var PurchaseLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
        PurchaseLine."Packing Note" := FromPurchLine."Packing Note";
    end;
}
