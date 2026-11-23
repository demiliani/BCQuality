// Demonstration only; independently authored, not copied from BaseApp.
// A per-lot quality status on Lot No. Information that stops warehouse picking.
enum 50153 "Lot Quality Status"
{
    Extensible = true;
    value(0; Released) { Caption = 'Released'; }
    value(1; Quarantine) { Caption = 'Quarantine'; }
}

tableextension 50153 "Lot Info Quality Status" extends "Lot No. Information"
{
    fields
    {
        field(50100; "Quality Status"; Enum "Lot Quality Status")
        {
            Caption = 'Quality Status';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50153 "Lot Quality Pick Guard"
{
    // Keeps quarantined lots out of FEFO lot suggestions during Create Pick.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Item Tracking FEFO", 'OnAfterIsItemTrackingBlocked', '', false, false)]
    local procedure ExcludeFromFEFO(var ReservEntry: Record "Reservation Entry"; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; var IsBlocked: Boolean; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if not IsBlocked then
            IsBlocked := IsQuarantined(ItemNo, VariantCode, LotNo);
    end;

    // Rejects a quarantined lot typed or scanned on a pick line.
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnBeforeValidateLotNo', '', false, false)]
    local procedure RejectOnEntry(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        CheckLine(WarehouseActivityLine);
    end;

    // Final check at registration, also for lines created before the status changed.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnCheckWhseItemTrkgLineOnBeforeTestTracking', '', false, false)]
    local procedure RejectOnRegister(WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        CheckLine(WarehouseActivityLine);
    end;

    local procedure CheckLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        if WarehouseActivityLine."Activity Type" <> WarehouseActivityLine."Activity Type"::Pick then
            exit;
        if IsQuarantined(WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", WarehouseActivityLine."Lot No.") then
            Error(QuarantinedLotErr, WarehouseActivityLine."Lot No.", WarehouseActivityLine."Item No.");
    end;

    local procedure IsQuarantined(ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]): Boolean
    var
        LotNoInformation: Record "Lot No. Information";
    begin
        if LotNo = '' then
            exit(false);
        LotNoInformation.SetLoadFields("Quality Status");
        if not LotNoInformation.Get(ItemNo, VariantCode, LotNo) then
            exit(false);
        exit(LotNoInformation."Quality Status" = LotNoInformation."Quality Status"::Quarantine);
    end;

    var
        QuarantinedLotErr: Label 'Lot %1 of item %2 is in quarantine and cannot be picked.', Comment = '%1 = lot number, %2 = item number';
}
