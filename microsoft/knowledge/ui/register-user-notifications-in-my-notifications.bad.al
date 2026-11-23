// Demonstration only; independently authored, not copied from BaseApp.
// A blocking Message for an advisory check, with no way for the user to turn it off.
tableextension 50110 "Sales Header Late Delivery" extends "Sales Header"
{
    fields
    {
        modify("Requested Delivery Date")
        {
            trigger OnAfterValidate()
            begin
                if ("Requested Delivery Date" <> 0D) and ("Requested Delivery Date" < WorkDate()) then
                    Message('The requested delivery date of order %1 is in the past.', "No.");
            end;
        }
    }
}

codeunit 50111 "Late Delivery Check"
{
    // Registered nowhere, and gated by a check that is false until the user has a My Notifications row:
    // the notification never shows for most users, and nobody can find it on the My Notifications page.
    procedure ShowIfLate(SalesHeader: Record "Sales Header")
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
        LateNotification: Notification;
    begin
        if not InstructionMgt.IsMyNotificationEnabled('6a1f0c52-3d7e-4b8a-9f21-5c0d7e3a4b10') then
            exit;
        LateNotification.Id := CreateGuid();
        LateNotification.Message('The requested delivery date is in the past.');
        LateNotification.Send();
    end;
}
