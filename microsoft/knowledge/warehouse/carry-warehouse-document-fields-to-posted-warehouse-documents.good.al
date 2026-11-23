// Demonstration only; independently authored, not copied from BaseApp.
// The posted shipment header is filled field by field, so it needs a subscriber.
// Assumes a Warehouse Shipment Header table extension with field 50180 "Carrier Slot" Code[20].
tableextension 50180 "Posted Whse. Shpt. Hdr. Slot" extends "Posted Whse. Shipment Header"
{
    fields
    {
        field(50180; "Carrier Slot"; Code[20])
        {
            Caption = 'Carrier Slot';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50180 "Carrier Slot Whse. Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnBeforePostedWhseShptHeaderInsert', '', false, false)]
    local procedure CopyToPostedShipmentHeader(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        PostedWhseShipmentHeader."Carrier Slot" := WarehouseShipmentHeader."Carrier Slot";
    end;
}
