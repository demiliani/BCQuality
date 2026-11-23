// Demonstration only; independently authored, not copied from BaseApp.
// Duplicates what registration already does and reads lot stock where bins do not exist.
codeunit 50151 "Pick Lot Scanning"
{
    procedure AssignLotToPickLine(var TakeLine: Record "Warehouse Activity Line"; LotNo: Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Item ledger entries have no bin, so this does not prove the lot is in TakeLine's bin.
        ItemLedgerEntry.SetRange("Item No.", TakeLine."Item No.");
        ItemLedgerEntry.SetRange("Location Code", TakeLine."Location Code");
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.SetRange(Open, true);
        if ItemLedgerEntry.IsEmpty() then
            Error('Lot not found.');

        // Only the take line gets the lot; the place line's warehouse entry stays without it.
        TakeLine."Lot No." := LotNo;
        TakeLine.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterRegisterWhseActivity', '', false, false)]
    local procedure CopyLotToSalesLine(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SuppressCommit: Boolean)
    begin
        // Registration already synchronized the picked lots to the sales line's reservation entries.
        // Writing them again here doubles or overrides Qty. to Handle (Base).
    end;
}
