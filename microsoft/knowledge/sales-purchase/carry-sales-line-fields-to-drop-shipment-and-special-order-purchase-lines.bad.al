// Demonstration only; independently authored, not copied from BaseApp.
// Covers only Get Sales Order, patches after insert, misses special orders and the requisition worksheet.
codeunit 50150 "Customer PO Ref. Linking"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Get Drop Shpt.", 'OnAfterPurchaseLineInsert', '', false, false)]
    local procedure PatchPurchLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
        PurchaseLine."Customer PO Ref." := SalesLine."Customer PO Ref.";
        PurchaseLine.Modify();
    end;
}
