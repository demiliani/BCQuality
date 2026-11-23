// Demonstration only; independently authored, not copied from BaseApp.
// Anti-pattern: looks the value up from the internal movement at registration time
// and writes it only to Registered Whse. Activity Line. Assumes the fields from the good sample.
codeunit 50141 "Move Reason Movements Bad"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnBeforeRegisteredWhseActivLineInsert', '', false, false)]
    local procedure LookUpOnRegister(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        // Never runs for inventory movements, and the internal movement line is usually deleted already.
        InternalMovementLine.SetRange("Item No.", WarehouseActivityLine."Item No.");
        InternalMovementLine.SetRange("To Bin Code", WarehouseActivityLine."Bin Code");
        if InternalMovementLine.FindFirst() then
            RegisteredWhseActivityLine."Move Reason" := InternalMovementLine."Move Reason";
    end;
}
