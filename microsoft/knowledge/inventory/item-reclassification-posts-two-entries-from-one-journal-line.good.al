// Demonstration only; independently authored, not copied from BaseApp.
// One reclassification line -> negative entry with "Storage Zone", positive entries with "New Storage Zone".
tableextension 50160 "Item Jnl. Line Storage Zone" extends "Item Journal Line"
{
    fields
    {
        field(50160; "Storage Zone"; Code[10])
        {
            Caption = 'Storage Zone';
            DataClassification = CustomerContent;
        }
        field(50161; "New Storage Zone"; Code[10])
        {
            Caption = 'New Storage Zone';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50161 "Item Ledg. Entry Storage Zone" extends "Item Ledger Entry"
{
    fields
    {
        field(50160; "Storage Zone"; Code[10])
        {
            Caption = 'Storage Zone';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50160 "Storage Zone Reclass Posting"
{
    // Runs for every entry, including each positive transfer entry, before its side-specific values are set.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure CopyStorageZone(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: BigInteger)
    begin
        NewItemLedgEntry."Storage Zone" := ItemJournalLine."Storage Zone";
    end;

    // Runs only for the positive entries of a transfer, like New Location Code.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertTransferEntry', '', false, false)]
    local procedure ApplyNewStorageZone(var NewItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        if ItemJournalLine."New Storage Zone" <> '' then
            NewItemLedgerEntry."Storage Zone" := ItemJournalLine."New Storage Zone";
    end;
}
