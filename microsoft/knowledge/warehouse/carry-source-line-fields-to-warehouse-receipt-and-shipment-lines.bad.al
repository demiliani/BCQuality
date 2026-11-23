// Demonstration only; independently authored, not copied from BaseApp.
// Copies the value after the warehouse line is inserted, adding a write per line.
codeunit 50170 "Handling Code Whse. Lines"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Warehouse Mgt.", 'OnAfterCreateShptLineFromSalesLine', '', false, false)]
    local procedure CopyToShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SalesLine: Record "Sales Line")
    begin
        WarehouseShipmentLine."Handling Code" := SalesLine."Handling Code";
        WarehouseShipmentLine.Modify();
    end;
}
