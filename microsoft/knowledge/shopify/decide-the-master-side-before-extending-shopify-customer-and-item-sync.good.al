// Demonstration only; independently authored, not copied from BaseApp.
// Shopify is the master in this shop: "Shopify Can Update Customer" and
// "Shopify Can Update Items" are on, so the BC-side create and update events run.
tableextension 50100 "Shpfy Demo Customer" extends Customer
{
    fields
    {
        field(50100; "Shopify Customer Id"; BigInteger)
        {
            Caption = 'Shopify Customer Id';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50101 "Shpfy Demo Item" extends Item
{
    fields
    {
        field(50100; "Shopify Product Type"; Text[100])
        {
            Caption = 'Shopify Product Type';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50100 "Shpfy Demo Inbound Sync"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Customer Events", 'OnAfterCreateCustomer', '', false, false)]
    local procedure StampNewCustomer(Shop: Record "Shpfy Shop"; var ShopifyCustomerAddress: Record "Shpfy Customer Address"; var Customer: Record Customer)
    begin
        if Customer."No." = '' then
            exit;
        // The customer is already inserted and modified: assign, then Modify.
        Customer."Shopify Customer Id" := ShopifyCustomerAddress."Customer Id";
        Customer.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Customer Events", 'OnAfterUpdateCustomer', '', false, false)]
    local procedure KeepCustomerStamp(Shop: Record "Shpfy Shop"; var ShopifyCustomer: Record "Shpfy Customer"; var Customer: Record Customer)
    begin
        if Customer."Shopify Customer Id" = ShopifyCustomer.Id then
            exit;
        Customer."Shopify Customer Id" := ShopifyCustomer.Id;
        Customer.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product Events", 'OnAfterCreateItem', '', false, false)]
    local procedure StampNewItem(Shop: Record "Shpfy Shop"; var ShopifyProduct: Record "Shpfy Product"; ShopifyVariant: Record "Shpfy Variant"; var Item: Record Item)
    begin
        if Item."No." = '' then
            exit;
        Item."Shopify Product Type" := CopyStr(ShopifyProduct."Product Type", 1, MaxStrLen(Item."Shopify Product Type"));
        Item.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product Events", 'OnDoUpdateItemBeforeModify', '', false, false)]
    local procedure UpdateItemBeforeModify(var ShopifyShop: Record "Shpfy Shop"; var ShopifyProduct: Record "Shpfy Product"; var Item: Record Item; var IsModifiedByEvent: Boolean)
    var
        NewProductType: Text[100];
    begin
        NewProductType := CopyStr(ShopifyProduct."Product Type", 1, MaxStrLen(NewProductType));
        if Item."Shopify Product Type" = NewProductType then
            exit;
        // No Modify here: the connector modifies the item when IsModifiedByEvent is true.
        Item."Shopify Product Type" := NewProductType;
        IsModifiedByEvent := true;
    end;
}
