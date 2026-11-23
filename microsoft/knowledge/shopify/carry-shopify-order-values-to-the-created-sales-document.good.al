// Demonstration only; independently authored, not copied from BaseApp.
// Requires a dependency on "Shopify Connector" (Microsoft, ec255f57-31d0-4ca2-b751-f2fa7c745abb).
// The checkout stores a "gift-message" order attribute and a "engraving" line attribute.
tableextension 50100 "Gift Msg Sales Header" extends "Sales Header"
{
    fields
    {
        field(50100; "Gift Message"; Text[250])
        {
            Caption = 'Gift Message';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50101 "Engraving Sales Line" extends "Sales Line"
{
    fields
    {
        field(50100; "Engraving Text"; Text[100])
        {
            Caption = 'Engraving Text';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50100 "Shopify Order Extra Values"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterCreateSalesHeader, '', false, false)]
    local procedure CopyGiftMessage(OrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header")
    var
        OrderAttribute: Record "Shpfy Order Attribute";
    begin
        if not OrderAttribute.Get(OrderHeader."Shopify Order Id", 'gift-message') then
            exit;
        SalesHeader."Gift Message" := CopyStr(OrderAttribute."Attribute Value", 1, MaxStrLen(SalesHeader."Gift Message"));
        SalesHeader.Modify(true); // the header already exists at this point
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterCreateItemSalesLine, '', false, false)]
    local procedure CopyEngraving(ShopifyOrderHeader: Record "Shpfy Order Header"; ShopifyOrderLine: Record "Shpfy Order Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        OrderLineAttribute: Record "Shpfy Order Line Attribute";
    begin
        if not OrderLineAttribute.Get(ShopifyOrderHeader."Shopify Order Id", ShopifyOrderLine.SystemId, 'engraving') then
            exit;
        SalesLine."Engraving Text" := CopyStr(OrderLineAttribute.Value, 1, MaxStrLen(SalesLine."Engraving Text"));
        SalesLine.Modify(true);
    end;
}
