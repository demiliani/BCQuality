// Demonstration only; independently authored, not copied from BaseApp.
// Copies a lot status into warehouse entries and cleans up picks afterwards.
tableextension 50153 "Whse. Entry Quality Status" extends "Warehouse Entry"
{
    fields
    {
        field(50100; Quarantined; Boolean)
        {
            Caption = 'Quarantined';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50153 "Lot Quality Pick Guard"
{
    // Snapshot at registration time; stale as soon as the lot is released or quarantined later.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register Line", 'OnBeforeInsertWhseEntry', '', false, false)]
    local procedure StampStatus(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        WarehouseEntry.Quarantined := IsQuarantinedSomewhere(WarehouseEntry."Lot No.");
    end;

    // Create Pick never reads the copied field, so the lines are removed after the fact.
    procedure RemoveQuarantinedPickLines(PickNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("No.", PickNo);
        if WarehouseActivityLine.FindSet() then
            repeat
                if IsQuarantinedSomewhere(WarehouseActivityLine."Lot No.") then
                    WarehouseActivityLine.Delete();
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure IsQuarantinedSomewhere(LotNo: Code[50]): Boolean
    begin
        exit(false);
    end;
}
