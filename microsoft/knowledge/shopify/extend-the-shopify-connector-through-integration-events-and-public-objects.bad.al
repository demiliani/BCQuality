// Demonstration only; independently authored, not copied from BaseApp.
// Does not compile from a separate app, and would block a background sync.
codeunit 50101 "Shopify POS Customer"
{
    // OnBeforeMapCustomer is an [InternalEvent]: only the connector itself can subscribe.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnBeforeMapCustomer, '', false, false)]
    local procedure SetPosCustomer(var ShopifyOrderHeader: Record "Shpfy Order Header"; var Handled: Boolean)
    begin
        if not Confirm('Use the POS customer for order %1?', true, ShopifyOrderHeader."Shopify Order No.") then
            exit; // Confirm fails when the order sync runs as a job queue entry
        ShopifyOrderHeader."Bill-to Customer No." := 'POS';
        Handled := true;
    end;

    procedure Reprocess(var ShopifyOrderHeader: Record "Shpfy Order Header")
    var
        ProcessOrder: Codeunit "Shpfy Process Order"; // Access = Internal
    begin
        ProcessOrder.Run(ShopifyOrderHeader);
    end;
}
