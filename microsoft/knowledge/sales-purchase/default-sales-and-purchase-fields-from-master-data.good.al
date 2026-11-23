// Demonstration only; independently authored, not copied from BaseApp.
// Assumes table extensions adding "Delivery Window" (Code[10]) to Customer and Sales Header,
// "Collection Group" (Code[10]) to Customer, Sales Header, Vendor and Purchase Header,
// and "Handling Class" (Code[10]) to Item, Sales Line and Purchase Line.
codeunit 50170 "Document Defaults"
{
    // Delivery data follows the sell-to customer.
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterCopySellToCustomerAddressFieldsFromCustomer', '', false, false)]
    local procedure SalesSellToDefaults(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer)
    begin
        SalesHeader."Delivery Window" := SellToCustomer."Delivery Window";
    end;

    // Payment data follows the bill-to customer, which can differ from the sell-to customer.
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterSetFieldsBilltoCustomer', '', false, false)]
    local procedure SalesBillToDefaults(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        SalesHeader."Collection Group" := Customer."Collection Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterCopyPayToVendorFieldsFromVendor', '', false, false)]
    local procedure PurchasePayToDefaults(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        PurchaseHeader."Collection Group" := Vendor."Collection Group";
    end;

    // Same event name on both line tables, different parameters: declare only what each publisher passes.
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignItemValues', '', false, false)]
    local procedure SalesLineItemDefaults(var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
        SalesLine."Handling Class" := Item."Handling Class";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignItemValues', '', false, false)]
    local procedure PurchaseLineItemDefaults(var PurchLine: Record "Purchase Line"; Item: Record Item)
    begin
        PurchLine."Handling Class" := Item."Handling Class";
    end;
}
