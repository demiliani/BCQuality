// Demonstration only; independently authored, not copied from BaseApp.
// The productUpdate mutation only sends the connector's own fields,
// so "Warranty Months" stays in Business Central and never reaches Shopify.
// Assumes the Item table extension with field 50100 "Warranty Months".
tableextension 50104 "Warranty Shpfy Product" extends "Shpfy Product"
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
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product Events", OnAfterFillInShopifyProductFields, '', false, false)]
    local procedure SetWarranty(Item: Record Item; var ShopifyProduct: Record "Shpfy Product")
    begin
        ShopifyProduct."Warranty Months" := Item."Warranty Months";
    end;
}
