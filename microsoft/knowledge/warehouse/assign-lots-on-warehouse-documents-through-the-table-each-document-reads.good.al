// Demonstration only; independently authored, not copied from BaseApp.
// Writes lot tracking into the table each warehouse document reads.
codeunit 50150 "Whse. Lot Assignment"
{
    procedure AssignLotToWhseJournalLine(WarehouseJournalLine: Record "Warehouse Journal Line"; LotNo: Code[50]; QuantityBase: Decimal)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        ItemTrackingManagement.CheckWhseItemTrkgSetup(WarehouseJournalLine."Item No.");
        if (QuantityBase <= 0) or (QuantityBase > Abs(WarehouseJournalLine."Qty. (Absolute, Base)")) then
            Error(InvalidQuantityErr);

        WhseItemTrackingLine.Init();
        WhseItemTrackingLine."Entry No." := WhseItemTrackingLine.GetNextEntryNo();
        // Same key as the Whse. Item Tracking Lines page: batch in Source ID, template in Source Batch Name.
        WhseItemTrackingLine.SetSource(
            Database::"Warehouse Journal Line", 0, WarehouseJournalLine."Journal Batch Name",
            WarehouseJournalLine."Line No.", WarehouseJournalLine."Journal Template Name", 0);
        WhseItemTrackingLine."Item No." := WarehouseJournalLine."Item No.";
        WhseItemTrackingLine."Variant Code" := WarehouseJournalLine."Variant Code";
        WhseItemTrackingLine."Location Code" := WarehouseJournalLine."Location Code";
        WhseItemTrackingLine.Description := WarehouseJournalLine.Description;
        WhseItemTrackingLine."Qty. per Unit of Measure" := WarehouseJournalLine."Qty. per Unit of Measure";
        WhseItemTrackingLine.Validate("Lot No.", LotNo);
        WhseItemTrackingLine.Validate("Quantity (Base)", QuantityBase);
        WhseItemTrackingLine.Insert(true);
    end;

    // Call after assigning tracking on the sales line with Create Reserv. Entry,
    // when the warehouse shipment line already exists but has no pick yet.
    procedure RefreshShipmentTracking(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        WarehouseShipmentLine.CalcFields("Pick Qty. (Base)");
        if (WarehouseShipmentLine."Pick Qty. (Base)" <> 0) or (WarehouseShipmentLine."Qty. Picked (Base)" <> 0) then
            Error(PickExistsErr);
        WarehouseShipmentLine.DeleteWhseItemTrackingLines();
        WarehouseShipmentLine.CreateWhseItemTrackingLines();
    end;

    var
        InvalidQuantityErr: Label 'The quantity to track must be positive and not exceed the journal line quantity.';
        PickExistsErr: Label 'A pick already exists for this shipment line. Set the lot on the pick lines instead.';
}
