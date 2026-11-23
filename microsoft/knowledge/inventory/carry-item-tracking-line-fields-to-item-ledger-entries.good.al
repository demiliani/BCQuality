// Demonstration only; independently authored, not copied from BaseApp.
// The same field number on Tracking Specification and Reservation Entry, plus one subscriber per hop.
tableextension 50171 "Tracking Spec. Supplier Lot" extends "Tracking Specification"
{
    fields
    {
        field(50171; "Supplier Lot Ref."; Code[30])
        {
            Caption = 'Supplier Lot Ref.';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50172 "Reserv. Entry Supplier Lot" extends "Reservation Entry"
{
    fields
    {
        field(50171; "Supplier Lot Ref."; Code[30])
        {
            Caption = 'Supplier Lot Ref.';
            DataClassification = CustomerContent;
        }
    }
}

// Item Journal Line and Item Ledger Entry carry the same field 50171 through their own table extensions.
codeunit 50171 "Supplier Lot Ref. Tracking"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnCreateReservEntryExtraFields', '', false, false)]
    local procedure CopyOnCreate(var InsertReservEntry: Record "Reservation Entry"; NewTrackingSpecification: Record "Tracking Specification")
    begin
        InsertReservEntry."Supplier Lot Ref." := NewTrackingSpecification."Supplier Lot Ref.";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", 'OnAfterEntriesAreIdentical', '', false, false)]
    local procedure CompareCustomField(ReservEntry1: Record "Reservation Entry"; ReservEntry2: Record "Reservation Entry"; var IdenticalArray: array[2] of Boolean)
    begin
        IdenticalArray[2] := IdenticalArray[2] and (ReservEntry1."Supplier Lot Ref." = ReservEntry2."Supplier Lot Ref.");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", 'OnAfterMoveFields', '', false, false)]
    local procedure CopyOnModify(var TrkgSpec: Record "Tracking Specification"; var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry."Supplier Lot Ref." := TrkgSpec."Supplier Lot Ref.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyTrackingFromSpec', '', false, false)]
    local procedure CopyToJournalLine(var ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemJournalLine."Supplier Lot Ref." := TrackingSpecification."Supplier Lot Ref.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterCopyTrackingFromItemJnlLine', '', false, false)]
    local procedure CopyToLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
        ItemLedgerEntry."Supplier Lot Ref." := ItemJnlLine."Supplier Lot Ref.";
    end;
}
