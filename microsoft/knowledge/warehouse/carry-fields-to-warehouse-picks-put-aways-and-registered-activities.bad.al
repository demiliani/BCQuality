// Demonstration only; independently authored, not copied from BaseApp.
// Anti-pattern: wrong events and a write after registration. Assumes the fields from the good sample.
codeunit 50131 "Handling Class Whse. Bad"
{
    // Create Pick passes only the activity line and header here; place and breakbulk lines use other inserts.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnBeforeWhseActivLineInsert', '', false, false)]
    local procedure CopyOnPickInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if WarehouseShipmentLine.Get(WarehouseActivityLine."Whse. Document No.", WarehouseActivityLine."Whse. Document Line No.") then
            WarehouseActivityLine."Handling Class" := WarehouseShipmentLine."Handling Class";
    end;

    // Patching registered lines after the fact: an extra write outside the register codeunit.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterRegisterWhseActivity', '', false, false)]
    local procedure PatchRegisteredLines(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Whse. Activity No.", WarehouseActivityHeader."No.");
        RegisteredWhseActivityLine.ModifyAll("Handling Class", 'STD');
    end;
}
