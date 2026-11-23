// Demonstration only; independently authored, not copied from BaseApp.
// Copies a Transfer Line field into the item journal line of the shipment and receipt legs.
// Assumes table extensions with field 50175 "Quality Lot Ref." Code[20] on Transfer Line,
// Item Journal Line and Item Ledger Entry, and the OnAfterInitItemLedgEntry subscriber
// shown in carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.
codeunit 50175 "Quality Ref. Transfer Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterCreateItemJnlLine', '', false, false)]
    local procedure CopyOnShipment(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line")
    begin
        ItemJournalLine."Quality Lot Ref." := TransferLine."Quality Lot Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforePostItemJournalLine', '', false, false)]
    local procedure CopyOnReceipt(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line")
    begin
        ItemJournalLine."Quality Lot Ref." := TransferLine."Quality Lot Ref.";
    end;
}
