// Demonstration only; independently authored, not copied from BaseApp.
// Requires Shop "Can Update Shopify Products" and "Product Metafields To Shopify".
tableextension 50103 "Warranty Item" extends Item
{
    fields
    {
        field(50100; "Warranty Months"; Integer)
        {
            Caption = 'Warranty Months';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50102 "Shopify Warranty Metafield"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product Events", OnBeforeUpdateProductMetafields, '', false, false)]
    local procedure SetWarrantyMetafield(ProductId: BigInteger)
    var
        ShopifyProduct: Record "Shpfy Product";
        Item: Record Item;
        Metafield: Record "Shpfy Metafield";
        NewValue: Text[2048];
    begin
        if not ShopifyProduct.Get(ProductId) then
            exit;
        if not Item.GetBySystemId(ShopifyProduct."Item SystemId") then
            exit;
        NewValue := Format(Item."Warranty Months", 0, 9);

        Metafield.SetRange("Parent Table No.", Database::"Shpfy Product");
        Metafield.SetRange("Owner Id", ProductId);
        Metafield.SetRange(Namespace, 'custom');
        Metafield.SetRange(Name, 'warranty_months');
        if Metafield.FindFirst() then begin
            if Metafield.Value = NewValue then
                exit; // unchanged: do not touch "Last Updated by BC"
            Metafield.Validate(Value, NewValue);
            Metafield.Modify(true);
            exit;
        end;

        Metafield.Init();
        Metafield.Validate("Parent Table No.", Database::"Shpfy Product");
        Metafield."Owner Id" := ProductId;
        Metafield.Namespace := 'custom';
        Metafield.Name := 'warranty_months';
        Metafield.Validate(Type, Metafield.Type::number_integer);
        Metafield.Validate(Value, NewValue);
        Metafield.Insert(true); // the connector syncs it right after this event
    end;
}
