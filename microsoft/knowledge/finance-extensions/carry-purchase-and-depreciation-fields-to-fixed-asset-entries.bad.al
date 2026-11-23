// Demonstration only; independently authored, not copied from BaseApp.
// Relies on matching field numbers, which no hop of the purchase-to-FA path uses,
// and sets the depreciation value only when the book is not integrated with G/L.
tableextension 50310 "Purch. Line Asset Project" extends "Purchase Line"
{
    fields
    {
        field(50300; "Asset Project Code"; Code[20])
        {
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50311 "FA Ledg. Entry Asset Project" extends "FA Ledger Entry"
{
    fields
    {
        // Same number as on Purchase Line, but nothing copies it.
        field(50300; "Asset Project Code"; Code[20])
        {
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50310 "Asset Project FA Sources"
{
    [EventSubscriber(ObjectType::Report, Report::"Calculate Depreciation", 'OnBeforeFAJnlLineInsert', '', false, false)]
    local procedure SetOnFAJournalLine(var TempFAJournalLine: Record "FA Journal Line" temporary; var FAJournalLine: Record "FA Journal Line")
    begin
        FAJournalLine."Asset Project Code" := 'DEFAULT';
    end;
}
