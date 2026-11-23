// Demonstration only; independently authored, not copied from BaseApp.
// Copies a custom line field into the warehouse line before it is inserted.
// Assumes Sales Line and Purchase Line table extensions with field 50170 "Handling Code" Code[10].
tableextension 50170 "Whse. Shpt. Line Handling" extends "Warehouse Shipment Line"
{
    fields
    {
        field(50170; "Handling Code"; Code[10])
        {
            Caption = 'Handling Code';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50171 "Whse. Rcpt. Line Handling" extends "Warehouse Receipt Line"
{
    fields
    {
        field(50170; "Handling Code"; Code[10])
        {
            Caption = 'Handling Code';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50170 "Handling Code Whse. Lines"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Warehouse Mgt.", 'OnBeforeCreateShptLineFromSalesLine', '', false, false)]
    local procedure CopyToShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SalesLine: Record "Sales Line")
    begin
        WarehouseShipmentLine."Handling Code" := SalesLine."Handling Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchases Warehouse Mgt.", 'OnPurchLine2ReceiptLineOnAfterUpdateReceiptLine', '', false, false)]
    local procedure CopyToReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseLine: Record "Purchase Line")
    begin
        WarehouseReceiptLine."Handling Code" := PurchaseLine."Handling Code";
    end;
}
