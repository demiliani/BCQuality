// Demonstration only; independently authored, not copied from BaseApp.
// The value travels Time Sheet Line -> Job Journal Line -> Job Ledger Entry.
tableextension 50180 "TS Line Activity Code" extends "Time Sheet Line"
{
    fields
    {
        field(50180; "Activity Code"; Code[20])
        {
            Caption = 'Activity Code';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50181 "Job Jnl. Line Activity Code" extends "Job Journal Line"
{
    fields
    {
        field(50180; "Activity Code"; Code[20])
        {
            Caption = 'Activity Code';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50182 "Job Ledg. Entry Activity Code" extends "Job Ledger Entry"
{
    fields
    {
        field(50180; "Activity Code"; Code[20])
        {
            Caption = 'Activity Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50180 "Activity Code Time Sheet Flow"
{
    // Raised once per time sheet detail (one day), before the journal line is inserted.
    [EventSubscriber(ObjectType::Report, Report::"Suggest Job Jnl. Lines", 'OnAfterTransferTimeSheetDetailToJobJnlLine', '', false, false)]
    local procedure CopyToJobJournalLine(var JobJournalLine: Record "Job Journal Line"; var TempTimeSheetLine: Record "Time Sheet Line" temporary)
    begin
        JobJournalLine."Activity Code" := TempTimeSheetLine."Activity Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromJnlLineToLedgEntry', '', false, false)]
    local procedure CopyToJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."Activity Code" := JobJournalLine."Activity Code";
    end;
}
