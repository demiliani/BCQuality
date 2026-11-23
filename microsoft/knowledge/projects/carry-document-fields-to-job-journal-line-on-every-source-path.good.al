// Demonstration only; independently authored, not copied from BaseApp.
// The value reaches the Job Journal Line from purchase lines and planning lines, not only from manual entry.
// Assumes "Site Visit Code" Code[20] on Purchase Line, Job Planning Line and Job Journal Line.
codeunit 50175 "Site Visit Job Sources"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromPurchaseLineToJnlLine', '', false, false)]
    local procedure FromPurchaseLine(var JobJnlLine: Record "Job Journal Line"; PurchLine: Record "Purchase Line")
    begin
        JobJnlLine."Site Visit Code" := PurchLine."Site Visit Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromPlanningLineToJnlLine', '', false, false)]
    local procedure FromPlanningLine(var JobJournalLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
        JobJournalLine."Site Visit Code" := JobPlanningLine."Site Visit Code";
    end;
}
