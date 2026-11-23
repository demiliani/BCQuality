// Demonstration only; independently authored, not copied from BaseApp.
// Anti-pattern: expects the activity line value to reach item ledger entries by itself,
// and patches the entries after the post. Assumes the fields from the good sample.
codeunit 50151 "Export Ref. Invt. Bad"
{
    // Wrong codeunit for purchase put-aways: this one creates picks for outbound purchase lines.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnBeforeNewWhseActivLineInsertFromPurchase', '', false, false)]
    local procedure PutAwayFromPurchaseLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var PurchaseLine: Record "Purchase Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
        WarehouseActivityLine."Export Ref." := PurchaseLine."Export Ref.";
    end;

    // Item ledger entries were built from the sales line; editing them afterwards bypasses posting.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", 'OnBeforePostedInvtPickLineInsert', '', false, false)]
    local procedure PatchItemLedger(var PostedInvtPickLine: Record "Posted Invt. Pick Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", PostedInvtPickLine."Source No.");
        ItemLedgerEntry.ModifyAll("Export Ref.", WarehouseActivityLine."Export Ref.");
    end;
}
