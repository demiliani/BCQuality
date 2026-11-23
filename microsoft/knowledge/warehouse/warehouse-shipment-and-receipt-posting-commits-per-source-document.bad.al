// Demonstration only; independently authored, not copied from BaseApp.
// Writes the seal to the source and posted documents after the whole warehouse run.
codeunit 50145 "Seal Follow-up"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnAfterPostWhseShipment', '', false, false)]
    local procedure StampSeal(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
    begin
        // Every source document is already posted and committed; some may have failed and are skipped silently.
        // Not raised in preview, so the preview shows no seal at all.
        SalesShipmentHeader.SetRange("Posting Date", WarehouseShipmentHeader."Posting Date");
        SalesShipmentHeader.SetRange("Shipping Agent Code", WarehouseShipmentHeader."Shipping Agent Code");
        if SalesShipmentHeader.FindSet(true) then
            repeat
                SalesShipmentHeader."Carrier Seal No." := WarehouseShipmentHeader."Carrier Seal No.";
                SalesShipmentHeader.Modify();
                // The order may already be deleted after a full ship and invoice.
                if SalesHeader.Get(SalesHeader."Document Type"::Order, SalesShipmentHeader."Order No.") then begin
                    SalesHeader."Carrier Seal No." := WarehouseShipmentHeader."Carrier Seal No.";
                    SalesHeader.Modify();
                end;
            until SalesShipmentHeader.Next() = 0;
        // Item ledger entries keep a blank seal.
    end;
}
