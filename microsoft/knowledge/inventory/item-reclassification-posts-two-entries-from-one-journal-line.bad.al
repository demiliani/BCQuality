// Demonstration only; independently authored, not copied from BaseApp.
// Anti-pattern: tries to detect the positive side inside OnAfterInitItemLedgEntry.
// Assumes the fields from the good sample.
codeunit 50161 "Storage Zone Reclass Bad"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure CopyStorageZone(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: BigInteger)
    begin
        // Every transfer entry is still negative and at the old location here,
        // so the positive entry never gets the new value.
        if NewItemLedgEntry.Quantity > 0 then
            NewItemLedgEntry."Storage Zone" := ItemJournalLine."New Storage Zone"
        else
            NewItemLedgEntry."Storage Zone" := ItemJournalLine."Storage Zone";
    end;
}
