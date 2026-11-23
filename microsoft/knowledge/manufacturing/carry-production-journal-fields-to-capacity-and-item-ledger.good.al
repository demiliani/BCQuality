// Demonstration only; independently authored, not copied from BaseApp.
// The value travels Item Journal Line -> Capacity Ledger Entry and Item Ledger Entry during posting.
// Assumes Item Journal Line, Capacity Ledger Entry and Item Ledger Entry extensions with field 50175 "Customer Batch Ref." Code[30].
codeunit 50176 "Prod. Batch Ref. Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertCapLedgEntry', '', false, false)]
    local procedure CopyToCapacityEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        CapLedgEntry."Customer Batch Ref." := ItemJournalLine."Customer Batch Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure CopyToItemEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        NewItemLedgEntry."Customer Batch Ref." := ItemJournalLine."Customer Batch Ref.";
    end;
}
