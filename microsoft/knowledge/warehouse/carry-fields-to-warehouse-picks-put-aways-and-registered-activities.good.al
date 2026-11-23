// Demonstration only; independently authored, not copied from BaseApp.
// Shipment line -> pick lines, posted receipt line -> put-away lines, activity line -> registered line and warehouse entry.
// Assumes field 50130 "Handling Class" Code[10] on Warehouse Shipment Line, Posted Whse. Receipt Line,
// Warehouse Journal Line and Warehouse Entry (the last two copied in OnBeforeInsertWhseEntry).
tableextension 50130 "Whse. Act. Line Handling" extends "Warehouse Activity Line"
{
    fields
    {
        field(50130; "Handling Class"; Code[10])
        {
            Caption = 'Handling Class';
            DataClassification = CustomerContent;
        }
    }
}

// Same field number: Whse.-Activity-Register copies it with TransferFields.
tableextension 50131 "Reg. Whse. Act. Line Handling" extends "Registered Whse. Activity Line"
{
    fields
    {
        field(50130; "Handling Class"; Code[10])
        {
            Caption = 'Handling Class';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50130 "Handling Class Whse. Activity"
{
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterTransferFromShptLine', '', false, false)]
    local procedure CopyFromShipmentLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        WarehouseActivityLine."Handling Class" := WarehouseShipmentLine."Handling Class";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Put-away", 'OnBeforeWhseActivLineInsert', '', false, false)]
    local procedure CopyFromPostedReceiptLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
        WarehouseActivityLine."Handling Class" := PostedWhseRcptLine."Handling Class";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnBeforeWhseJnlRegisterLine', '', false, false)]
    local procedure CopyToWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseJournalLine."Handling Class" := WarehouseActivityLine."Handling Class";
    end;
}
