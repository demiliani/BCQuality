// Demonstration only; independently authored, not copied from BaseApp.
// The count team code travels Item Journal Line -> Item Ledger Entry and Phys. Inventory Ledger Entry.
// Assumes table extensions with field 50176 "Count Team Code" Code[20] on all three tables.
codeunit 50176 "Count Team Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure CopyToItemLedgerEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        NewItemLedgEntry."Count Team Code" := ItemJournalLine."Count Team Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertPhysInvtLedgEntry', '', false, false)]
    local procedure CopyToPhysInventoryLedgerEntry(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        // ItemJournalLine is the original, unsplit journal line.
        PhysInventoryLedgerEntry."Count Team Code" := ItemJournalLine."Count Team Code";
    end;
}
