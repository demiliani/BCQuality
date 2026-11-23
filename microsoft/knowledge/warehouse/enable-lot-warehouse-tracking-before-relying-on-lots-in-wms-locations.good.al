// Demonstration only; independently authored, not copied from BaseApp.
// Branches on the warehouse tracking setup, not on document-level tracking.
codeunit 50152 "Lot Bin Report Setup Check"
{
    procedure CheckItemSupportsLotPerBin(ItemNo: Code[20])
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        // Reads Lot Warehouse Tracking / SN Warehouse Tracking from the item tracking code.
        ItemTrackingManagement.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
        if not WhseItemTrackingSetup."Lot No. Required" then
            Error(NoWarehouseLotTrackingErr, ItemNo);
    end;

    procedure ShouldAskForLotOnPick(WarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if not ItemTrackingManagement.GetWhseItemTrkgSetup(WarehouseActivityLine."Item No.", WhseItemTrackingSetup) then
            exit(false);
        exit(WhseItemTrackingSetup."Lot No. Required" and (WarehouseActivityLine."Lot No." = ''));
    end;

    var
        NoWarehouseLotTrackingErr: Label 'Item %1 does not use Lot Warehouse Tracking, so its warehouse entries do not record lots. Enable it on the item tracking code before the first warehouse posting.', Comment = '%1 = item number';
}
