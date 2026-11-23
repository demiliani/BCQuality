// Demonstration only; independently authored, not copied from BaseApp.
// Assumes document-level lot tracking also applies inside the warehouse.
codeunit 50152 "Lot Bin Report Setup Check"
{
    procedure ShouldAskForLotOnPick(WarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.Get(WarehouseActivityLine."Item No.");
        if Item."Item Tracking Code" = '' then
            exit(false);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        // Lot Warehouse Tracking can be off even when Lot Specific Tracking is on, and the
        // per-transaction lot flags (Lot Purchase Inbound Tracking, ...) never enable it;
        // validating Lot No. on the pick line then fails, and warehouse entries carry no lot.
        exit(ItemTrackingCode."Lot Specific Tracking" and (WarehouseActivityLine."Lot No." = ''));
    end;
}
