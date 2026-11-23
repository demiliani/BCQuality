// Demonstration only; independently authored, not copied from BaseApp.
// Writes the lot where the warehouse document does not read it.
codeunit 50150 "Whse. Lot Assignment"
{
    procedure AssignLotToWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; LotNo: Code[50])
    begin
        // Registering a tracked item ignores this field and requires Whse. Item Tracking Line rows.
        WarehouseJournalLine."Lot No." := LotNo;
        WarehouseJournalLine.Modify();
    end;

    procedure AssignLotForShipment(SalesLine: Record "Sales Line"; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
        EntryNo: Integer;
    begin
        // Hand-built entry, added after the warehouse shipment copied the tracking: the pick never sees it.
        if ReservationEntry.FindLast() then
            EntryNo := ReservationEntry."Entry No.";
        ReservationEntry.Init();
        ReservationEntry."Entry No." := EntryNo + 1;
        ReservationEntry."Item No." := SalesLine."No.";
        ReservationEntry."Location Code" := SalesLine."Location Code";
        ReservationEntry."Source Type" := Database::"Sales Line";
        ReservationEntry."Source Subtype" := SalesLine."Document Type".AsInteger();
        ReservationEntry."Source ID" := SalesLine."Document No.";
        ReservationEntry."Source Ref. No." := SalesLine."Line No.";
        ReservationEntry."Lot No." := LotNo;
        ReservationEntry."Quantity (Base)" := -SalesLine."Quantity (Base)";
        ReservationEntry.Insert();
    end;
}
