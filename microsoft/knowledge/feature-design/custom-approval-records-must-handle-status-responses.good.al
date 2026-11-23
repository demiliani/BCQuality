// Demonstration only; independently authored, not copied from BaseApp.
// Handles the three status responses for one custom table, and only for that table.
// Assumes table 50170 "Maintenance Contract" with a Status enum field (Open, "Pending Approval", Released).
codeunit 50170 "Contract Approval Responses"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', false, false)]
    local procedure SetPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    var
        MaintenanceContract: Record "Maintenance Contract";
    begin
        if RecRef.Number <> Database::"Maintenance Contract" then
            exit;
        RecRef.SetTable(MaintenanceContract);
        MaintenanceContract.Validate(Status, MaintenanceContract.Status::"Pending Approval");
        MaintenanceContract.Modify(true);
        Variant := MaintenanceContract;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', false, false)]
    local procedure Release(RecRef: RecordRef; var Handled: Boolean)
    var
        MaintenanceContract: Record "Maintenance Contract";
    begin
        if RecRef.Number <> Database::"Maintenance Contract" then
            exit;
        RecRef.SetTable(MaintenanceContract);
        MaintenanceContract.Validate(Status, MaintenanceContract.Status::Released);
        MaintenanceContract.Modify(true);
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', false, false)]
    local procedure Reopen(RecRef: RecordRef; var Handled: Boolean)
    var
        MaintenanceContract: Record "Maintenance Contract";
    begin
        if RecRef.Number <> Database::"Maintenance Contract" then
            exit;
        RecRef.SetTable(MaintenanceContract);
        MaintenanceContract.Validate(Status, MaintenanceContract.Status::Open);
        MaintenanceContract.Modify(true);
        Handled := true;
    end;
}
