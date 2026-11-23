// Demonstration only; independently authored, not copied from BaseApp.
// Item Journal Line -> Warehouse Journal Line -> Warehouse Entry during document posting at a bin location.
// Assumes an Item Journal Line table extension with field 50120 "Customer Batch Ref." Code[30].
tableextension 50190 "Whse. Jnl. Line Batch Ref." extends "Warehouse Journal Line"
{
    fields
    {
        field(50120; "Customer Batch Ref."; Code[30])
        {
            Caption = 'Customer Batch Ref.';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50191 "Whse. Entry Batch Ref." extends "Warehouse Entry"
{
    fields
    {
        field(50120; "Customer Batch Ref."; Code[30])
        {
            Caption = 'Customer Batch Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50190 "Batch Ref. Whse. Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnAfterCreateWhseJnlLine', '', false, false)]
    local procedure CopyToWhseJournalLine(var WhseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
        WhseJournalLine."Customer Batch Ref." := ItemJournalLine."Customer Batch Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register Line", 'OnBeforeInsertWhseEntry', '', false, false)]
    local procedure CopyToWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        WarehouseEntry."Customer Batch Ref." := WarehouseJournalLine."Customer Batch Ref.";
    end;
}
