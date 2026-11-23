// Demonstration only; independently authored, not copied from BaseApp.
// Internal Movement Line -> inventory movement lines -> Registered Invt. Movement Line,
// and Whse. Worksheet Line -> movement lines -> Registered Whse. Activity Line.
// Assumes field 50140 "Move Reason" Code[10] on Internal Movement Line and Whse. Worksheet Line.
tableextension 50140 "Whse. Act. Line Move Reason" extends "Warehouse Activity Line"
{
    fields
    {
        field(50140; "Move Reason"; Code[10])
        {
            Caption = 'Move Reason';
            DataClassification = CustomerContent;
        }
    }
}

// Inventory movements are registered here, by TransferFields.
tableextension 50141 "Reg. Invt. Mvmt. Move Reason" extends "Registered Invt. Movement Line"
{
    fields
    {
        field(50140; "Move Reason"; Code[10])
        {
            Caption = 'Move Reason';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

// Warehouse movements from the movement worksheet are registered here, by TransferFields.
tableextension 50142 "Reg. Whse. Act. Move Reason" extends "Registered Whse. Activity Line"
{
    fields
    {
        field(50140; "Move Reason"; Code[10])
        {
            Caption = 'Move Reason';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50140 "Move Reason Movements"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnCreateInvtMvntWithoutSourceOnAfterTransferFields', '', false, false)]
    local procedure CopyFromInternalMovementLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; InternalMovementLine: Record "Internal Movement Line")
    begin
        WarehouseActivityLine."Move Reason" := InternalMovementLine."Move Reason";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterTransferFromMovWkshLine', '', false, false)]
    local procedure CopyFromMovementWorksheetLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
        WarehouseActivityLine."Move Reason" := WhseWorksheetLine."Move Reason";
    end;
}
