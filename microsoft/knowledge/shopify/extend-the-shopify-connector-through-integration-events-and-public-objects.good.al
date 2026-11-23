// Demonstration only; independently authored, not copied from BaseApp.
// app.json dependency: { "id": "ec255f57-31d0-4ca2-b751-f2fa7c745abb", "name": "Shopify Connector", "publisher": "Microsoft", "version": "<platform version>" }
tableextension 50102 "POS Customer Shop" extends "Shpfy Shop"
{
    fields
    {
        field(50100; "POS Customer No."; Code[20])
        {
            Caption = 'POS Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer;
        }
    }
}

codeunit 50101 "Shopify POS Customer"
{
    // Integration event: subscribable from another app.
    // Prefilling Bill-to makes the built-in customer mapping skip this order.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterImportShopifyOrderHeader, '', false, false)]
    local procedure SetPosCustomer(var ShopifyOrderHeader: Record "Shpfy Order Header"; IsNew: Boolean)
    var
        Shop: Record "Shpfy Shop";
    begin
        if ShopifyOrderHeader."Channel Name" <> 'Point of Sale' then
            exit;
        Shop.Get(ShopifyOrderHeader."Shop Code");
        if Shop."POS Customer No." = '' then
            exit; // no dialog: this can run in a job queue session
        ShopifyOrderHeader."Sell-to Customer No." := Shop."POS Customer No.";
        ShopifyOrderHeader."Bill-to Customer No." := Shop."POS Customer No.";
        ShopifyOrderHeader.Modify();
    end;

    // Public facade instead of the internal export codeunits.
    procedure PublishItem(Item: Record Item; ShopCode: Code[20])
    var
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Codeunit "Shpfy Product";
    begin
        Shop.Get(ShopCode);
        ShopifyProduct.AddItemToShopify(Item, Shop);
    end;
}
