// Demonstration only; independently authored, not copied from BaseApp.
// Reads the last split line and patches item ledger entries after posting.
codeunit 50176 "Count Team Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertPhysInvtLedgEntry', '', false, false)]
    local procedure CopyToPhysInventoryLedgerEntry(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; LastSplitItemJournalLine: Record "Item Journal Line")
    begin
        // Only the last lot's split line: other lots' values are lost.
        PhysInventoryLedgerEntry."Count Team Code" := LastSplitItemJournalLine."Count Team Code";
    end;

    procedure PatchItemLedgerEntries(DocumentNo: Code[20]; CountTeamCode: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.ModifyAll("Count Team Code", CountTeamCode);
    end;
}
