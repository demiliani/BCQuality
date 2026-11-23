// Demonstration only; independently authored, not copied from BaseApp.
// Copies a value the status change already copied, with an extra Modify per order.
codeunit 50170 "Prod. Order Status Handling"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", 'OnAfterTransProdOrder', '', false, false)]
    local procedure CopyBatchRef(var FromProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order")
    var
        NewProdOrder: Record "Production Order";
    begin
        NewProdOrder.Get(ToProdOrder.Status, ToProdOrder."No.");
        NewProdOrder."Customer Batch Ref." := FromProdOrder."Customer Batch Ref.";
        NewProdOrder.Modify();
    end;
}
