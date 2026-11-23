// Demonstration only; independently authored, not copied from BaseApp.
// Every detailed row takes the value of the line being posted, whichever entry the row belongs to.
codeunit 50150 "Collection Channel Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertDtldCustLedgEntry', '', false, false)]
    local procedure CopyToDetailedEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        // Invoice application rows get the payment's value.
        // Rows from Apply Customer Entries get blank: that journal line was created with Init.
        DtldCustLedgEntry."Collection Channel" := GenJournalLine."Collection Channel";
    end;
}
