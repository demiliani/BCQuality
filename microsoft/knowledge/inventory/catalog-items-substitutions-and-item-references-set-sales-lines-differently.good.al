// Demonstration only; independently authored, not copied from BaseApp.
// "Brand Code" on Item and Sales Line, filled on every route that sets the line's item.
// Assumes Item, Item Templ., Nonstock Item and Sales Line extensions with field 50140 "Brand Code" Code[20],
// Sales Line field 50141 "Requested Brand" Code[20], and Item Reference and Sales Line field 50142 "Customer Label" Text[50].
codeunit 50140 "Brand Code Defaults"
{
    // General item default. Runs for typed items, catalog items, substitutes (on a temporary line)
    // and item references. No IsTemporary guard, or substitutes lose the value.
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignItemValues', '', false, false)]
    local procedure LineFromItem(var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
        SalesLine."Brand Code" := Item."Brand Code";
    end;

    // Item created from a catalog item: Insert() ran without the OnInsert trigger.
    // The template already copied a same-numbered Item Templ. field; the catalog value wins here.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Catalog Item Management", 'OnCreateNewItemOnBeforeItemModify', '', false, false)]
    local procedure ItemFromCatalogItem(var Item: Record Item; NonstockItem: Record "Nonstock Item")
    begin
        if NonstockItem."Brand Code" <> '' then
            Item."Brand Code" := NonstockItem."Brand Code";
    end;

    // Substitution: first parameter is the new line, second is the line before substitution.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Subst.", 'OnItemSubstGetOnAfterSubstSalesLineItem', '', false, false)]
    local procedure KeepRequestedBrand(var SalesLine: Record "Sales Line"; var SourceSalesLine: Record "Sales Line")
    begin
        SalesLine."Requested Brand" := SourceSalesLine."Brand Code";
    end;

    // Item reference: runs even when the reference points to the item already on the line.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Reference Management", 'OnAfterValidateSalesReferenceNo', '', false, false)]
    local procedure RequestedBrandFromReference(var SalesLine: Record "Sales Line"; ReturnedItemReference: Record "Item Reference")
    begin
        SalesLine."Customer Label" := ReturnedItemReference."Customer Label";
    end;
}
