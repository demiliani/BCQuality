// Demonstration only; independently authored, not copied from BaseApp.
// This event is raised only for resource lines, so item component consumption never gets the value.
codeunit 50180 "Asm. Quality Grade Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", 'OnAfterCreateItemJnlLineFromAssemblyLine', '', false, false)]
    local procedure CopyToConsumptionLine(var ItemJournalLine: Record "Item Journal Line"; AssemblyLine: Record "Assembly Line")
    begin
        ItemJournalLine."Quality Grade" := AssemblyLine."Quality Grade";
    end;
}
