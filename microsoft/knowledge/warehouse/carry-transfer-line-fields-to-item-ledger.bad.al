// Demonstration only; independently authored, not copied from BaseApp.
// Patches item ledger entries after the transfer shipment has been posted and committed.
codeunit 50175 "Quality Ref. Transfer Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterTransferOrderPostShipment', '', false, false)]
    local procedure PatchItemEntries(var TransferShipmentHeader: Record "Transfer Shipment Header")
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
        if TransferShipmentLine.FindSet() then
            repeat
                ItemLedgerEntry.SetRange("Document No.", TransferShipmentHeader."No.");
                ItemLedgerEntry.SetRange("Document Line No.", TransferShipmentLine."Line No.");
                ItemLedgerEntry.ModifyAll("Quality Lot Ref.", TransferShipmentLine."Quality Lot Ref.");
            until TransferShipmentLine.Next() = 0;
    end;
}
