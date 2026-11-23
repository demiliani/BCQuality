// Demonstration only; independently authored, not copied from BaseApp.
// Release is handled for every table, and the pending-approval and reopen responses are not handled at all.
// Assumes table 50170 "Maintenance Contract" with a Status enum field (Open, "Pending Approval", Released).
codeunit 50170 "Contract Approval Responses"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', false, false)]
    local procedure Release(RecRef: RecordRef; var Handled: Boolean)
    var
        MaintenanceContract: Record "Maintenance Contract";
    begin
        // No table check: claims records owned by other extensions.
        if RecRef.Number = Database::"Maintenance Contract" then begin
            RecRef.SetTable(MaintenanceContract);
            MaintenanceContract.Status := MaintenanceContract.Status::Released;
            MaintenanceContract.Modify();
        end;
        Handled := true;
    end;
}
