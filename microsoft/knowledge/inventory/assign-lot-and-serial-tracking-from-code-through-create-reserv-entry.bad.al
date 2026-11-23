// Demonstration only; independently authored, not copied from BaseApp.
// Hand-builds a reservation entry: no sign handling, no status rule, fields the engine maintains are missing.
codeunit 50170 "Scanner Lot Assignment"
{
    procedure AssignLot(ItemJournalLine: Record "Item Journal Line"; LotNo: Code[50]; QuantityBase: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        NextEntryNo: Integer;
    begin
        if ReservationEntry.FindLast() then
            NextEntryNo := ReservationEntry."Entry No." + 1
        else
            NextEntryNo := 1;

        ReservationEntry.Init();
        ReservationEntry."Entry No." := NextEntryNo;
        ReservationEntry."Item No." := ItemJournalLine."Item No.";
        ReservationEntry."Location Code" := ItemJournalLine."Location Code";
        ReservationEntry."Source Type" := Database::"Item Journal Line";
        ReservationEntry."Source ID" := ItemJournalLine."Journal Template Name";
        ReservationEntry."Source Batch Name" := ItemJournalLine."Journal Batch Name";
        ReservationEntry."Source Ref. No." := ItemJournalLine."Line No.";
        ReservationEntry."Quantity (Base)" := QuantityBase;
        ReservationEntry."Lot No." := LotNo;
        ReservationEntry.Insert();
    end;
}
