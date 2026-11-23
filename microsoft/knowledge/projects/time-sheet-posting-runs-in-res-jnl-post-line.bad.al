// Demonstration only; independently authored, not copied from BaseApp.
// Wrong: posts resource usage without the time sheet link and marks the time sheet by hand.
codeunit 50192 "Manual Time Sheet Posting"
{
    procedure PostHours(TimeSheetLine: Record "Time Sheet Line"; ResourceNo: Code[20]; PostingDate: Date; Qty: Decimal)
    var
        ResJournalLine: Record "Res. Journal Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
    begin
        ResJournalLine.Init();
        ResJournalLine."Entry Type" := ResJournalLine."Entry Type"::Usage;
        ResJournalLine."Posting Date" := PostingDate;
        ResJournalLine."Resource No." := ResourceNo;
        ResJournalLine.Quantity := Qty;
        // Time Sheet No., Line No. and Date are left empty: no posted quantity, no posting entry.
        ResJnlPostLine.RunWithCheck(ResJournalLine);

        TimeSheetLine.Posted := true;
        TimeSheetLine.Modify();
    end;
}
