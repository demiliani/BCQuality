// Demonstration only; independently authored, not copied from BaseApp.
// Wrong: fills approval entries in a table trigger and never feeds the limit check.
// Assumes table 50140 "Capex Request" as in the good sample.
codeunit 50142 "Capex Approval Arguments Bad"
{
    [EventSubscriber(ObjectType::Table, Database::"Approval Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure FillEntry(var Rec: Record "Approval Entry"; RunTrigger: Boolean)
    var
        CapexRequest: Record "Capex Request";
        RecRef: RecordRef;
    begin
        // Runs for every approval entry of every table. The approver was already chosen
        // from an argument with Amount (LCY) = 0, and IsSufficientApprover returned true
        // for this table, so an Approver Chain workflow never escalates.
        if Rec."Table ID" <> Database::"Capex Request" then
            exit;
        if RecRef.Get(Rec."Record ID to Approve") then begin
            RecRef.SetTable(CapexRequest);
            Rec.Amount := CapexRequest.Amount;
            Rec."Amount (LCY)" := CapexRequest."Amount (LCY)";
        end;
    end;
}
