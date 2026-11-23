// Demonstration only; independently authored, not copied from BaseApp.
// A custom recognized-sales method computed inside Job Calculate WIP, before WIP buffers are built.
// Assumes a Job Task table extension with field 50130 "Milestone Value Reached" (Decimal).
enumextension 50130 "Milestone WIP Sales" extends "Job WIP Recognized Sales Type"
{
    value(50130; "Milestone Value")
    {
        Caption = 'Milestone Value';
    }
}

codeunit 50130 "Milestone WIP Method"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Calculate WIP", 'OnBeforeCalcRecognizedSales', '', false, false)]
    local procedure CalcMilestoneSales(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; var JobWIPMethod: Record "Job WIP Method"; var IsHandled: Boolean)
    begin
        if JobWIPMethod."Recognized Sales" <> JobWIPMethod."Recognized Sales"::"Milestone Value" then
            exit;
        // The amount is set before CreateTempJobWIPBuffers reads it, so WIP entries and G/L agree with the task.
        JobTask."Recognized Sales Amount" := JobTask."Milestone Value Reached";
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Calculate WIP", 'OnInsertWIPGLOnBeforeGenJnPostLine', '', false, false)]
    local procedure TagWIPJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Reversed: Boolean)
    begin
        // Runs for every WIP posting and reversal, just before Gen. Jnl.-Post Line.RunWithCheck.
        if Reversed then
            GenJournalLine.Comment := 'WIP reversal';
    end;
}
