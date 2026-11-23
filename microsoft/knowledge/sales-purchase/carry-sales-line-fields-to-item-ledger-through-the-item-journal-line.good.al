// Demonstration only; independently authored, not copied from BaseApp.
// The value travels Sales Line -> Item Journal Line -> Item Ledger Entry during posting.
// Assumes a Sales Line table extension with field 50120 "Customer Batch Ref." Code[30].
tableextension 50120 "Item Jnl. Line Batch Ref." extends "Item Journal Line"
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

tableextension 50121 "Item Ledg. Entry Batch Ref." extends "Item Ledger Entry"
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

codeunit 50120 "Batch Ref. Item Posting"
{
    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyItemJnlLineFromSalesLine', '', false, false)]
    local procedure CopyToItemJournalLine(var ItemJnlLine: Record "Item Journal Line"; SalesLine: Record "Sales Line")
    begin
        ItemJnlLine."Customer Batch Ref." := SalesLine."Customer Batch Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure CopyToItemLedgerEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        NewItemLedgEntry."Customer Batch Ref." := ItemJournalLine."Customer Batch Ref.";
    end;
}
