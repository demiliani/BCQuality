// Demonstration only; independently authored, not copied from BaseApp.
// Posted assembly lines get the field by TransferFields; consumption journal lines get it from the item-component event.
// Assumes an Item Journal Line extension with field 50180 "Quality Grade" Code[10], carried on to Item Ledger Entry with OnAfterInitItemLedgEntry.
tableextension 50180 "Asm. Line Quality Grade" extends "Assembly Line"
{
    fields
    {
        field(50180; "Quality Grade"; Code[10])
        {
            Caption = 'Quality Grade';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50181 "Pstd. Asm. Line Quality Grade" extends "Posted Assembly Line"
{
    fields
    {
        field(50180; "Quality Grade"; Code[10])
        {
            Caption = 'Quality Grade';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50180 "Asm. Quality Grade Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", 'OnBeforePostItemConsumption', '', false, false)]
    local procedure CopyToConsumptionLine(var AssemblyLine: Record "Assembly Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine."Quality Grade" := AssemblyLine."Quality Grade";
    end;
}
