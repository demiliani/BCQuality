// Demonstration only; independently authored, not copied from BaseApp.
// Assigns a lot to an item journal line the way the Item Tracking Lines page does.
codeunit 50170 "Scanner Lot Assignment"
{
    procedure AssignLot(ItemJournalLine: Record "Item Journal Line"; LotNo: Code[50]; QuantityBase: Decimal)
    var
        ForReservationEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        EntryStatus: Enum "Reservation Status";
    begin
        ItemJournalLine.TestField("Item No.");
        if (QuantityBase <= 0) or (QuantityBase > Abs(ItemJournalLine."Quantity (Base)")) then
            Error(InvalidQuantityErr);

        ForReservationEntry."Lot No." := LotNo;
        CreateReservEntry.CreateReservEntryFor(
            Database::"Item Journal Line", ItemJournalLine."Entry Type".AsInteger(),
            ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
            ItemJournalLine."Qty. per Unit of Measure", 0, QuantityBase, ForReservationEntry);

        if ItemTrackingManagement.IsOrderNetworkEntity(Database::"Item Journal Line", ItemJournalLine."Entry Type".AsInteger()) then
            EntryStatus := EntryStatus::Surplus
        else
            EntryStatus := EntryStatus::Prospect;

        CreateReservEntry.CreateEntry(
            ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."Location Code",
            ItemJournalLine.Description, ItemJournalLine."Posting Date", ItemJournalLine."Posting Date", 0, EntryStatus);
    end;

    var
        InvalidQuantityErr: Label 'The quantity to track must be positive and not exceed the journal line quantity.';
}
