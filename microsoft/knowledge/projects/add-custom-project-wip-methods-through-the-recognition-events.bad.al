// Demonstration only; independently authored, not copied from BaseApp.
// Anti-pattern: overwrites recognized amounts after the WIP buffers were already built from the old values.
codeunit 50131 "Milestone WIP Override Bad"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Calculate WIP", 'OnAfterJobTaskCalcWIP', '', false, false)]
    local procedure OverrideRecognizedSales(var Job: Record Job; FromJobTask: Code[20]; ToJobTask: Code[20]; var JobWIPTotal: Record "Job WIP Total")
    var
        JobTask: Record "Job Task";
    begin
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.SetRange("Job Task No.", FromJobTask, ToJobTask);
        if JobTask.FindSet(true) then
            repeat
                // Job WIP Entry rows and the later G/L posting still use the standard amount.
                JobTask."Recognized Sales Amount" := JobTask."Milestone Value Reached";
                JobTask.Modify();
            until JobTask.Next() = 0;
    end;
}
