// Demonstration only; independently authored, not copied from BaseApp.
// Wrong: hooks that ignore the sync direction and the moment each record is saved.
// Assumes the Customer and Item table extensions from the good sample.
codeunit 50102 "Shpfy Demo Inbound Sync Bad"
{
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterInsertEvent', '', false, false)]
    local procedure DetectShopifyCustomer(var Rec: Record Customer; RunTrigger: Boolean)
    var
        ShopifyCustomer: Record "Shpfy Customer";
    begin
        // The template insert happens before the connector stores "Customer SystemId",
        // so this lookup never finds the Shopify customer.
        ShopifyCustomer.SetRange("Customer SystemId", Rec.SystemId);
        if ShopifyCustomer.FindFirst() then
            Rec."Shopify Customer Id" := ShopifyCustomer.Id;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product Events", 'OnAfterUpdateItem', '', false, false)]
    local procedure UpdateItemAfterwards(Shop: Record "Shpfy Shop"; var ShopifyProduct: Record "Shpfy Product"; ShopifyVariant: Record "Shpfy Variant"; var Item: Record Item)
    begin
        // Raised only when a standard field changed, and never in a shop where BC is the
        // master ("Can Update Shopify Products" on). The item is already saved and no
        // Modify follows, so the value is lost.
        Item."Shopify Product Type" := CopyStr(ShopifyProduct."Product Type", 1, MaxStrLen(Item."Shopify Product Type"));
    end;
}
